import cv2
import time
import os
import threading
from datetime import datetime
from ultralytics import YOLO
import firebase_admin
from firebase_admin import credentials, firestore

FRAMES_SKIP = 5
INTERVALO_FIRESTORE = 5
INTERVALO_HISTORIAL = 300
CONFIANZA_MINIMA = 0.4
REINTENTOS_CAMARA = 3
PAUSA_REINTENTO = 10
COOLDOWN_ALERTA = 300

CAMPOS_ADMIN = ["nombre", "descripcion", "url_conexion", "activo", "objetivos"]


class ProcesadorZona(threading.Thread):

    def __init__(self, zona_id, config, modelo: YOLO, modelo_lock, db):
        super().__init__(daemon=True, name=f"zona-{zona_id}")
        self.zona_id = zona_id
        self.config = config
        self._cfg_lock = threading.Lock()
        self.modelo = modelo
        self.modelo_lock = modelo_lock
        self.db = db
        self._stop = threading.Event()

        self._ref_zona = db.collection("zonas").document(zona_id)
        self._cooldowns = {}
        self._buf_hist = {}

    def _get_config(self):
        with self._cfg_lock:
            return dict(self.config)

    def _objetivos(self, cfg):
        return cfg.get("objetivos", {})

    def _ids_clases_yolo(self, cfg):
        nombres = list(self._objetivos(cfg).keys())
        ids = []
        for id, nombre in self.modelo.names.items():
            if nombre in nombres:
                ids.append(id)
        return ids or [0]

    def _publicar_estado(self, conteo):
        self._ref_zona.update({
            "estado.objetos": conteo,
            "estado.online": True,
            "estado.actualizado_el": datetime.now(),
        })

    def _publicar_historial(self, conteo):
        if not self._buf_hist:
            return

        medias = {}
        maximos = {}

        for obj, hist in self._buf_hist.items():
            if hist:
                medias[obj] = round(sum(hist) / len(hist))
                maximos[obj] = max(hist)

        self._buf_hist = {}
        cfg = self._get_config()
        limites = self._objetivos(cfg)

        self.db.collection("historial").add({
            "zona_id": self.zona_id,
            "medias": medias,
            "maximos": maximos,
            "limites": limites,
            "timestamp": datetime.now(),
        })

    def _alerta_activa(self, tipo):
        try:
            res = (
                self.db.collection("alertas")
                .where(filter=firestore.FieldFilter("zona_id", "==", self.zona_id))
                .where(filter=firestore.FieldFilter("tipo", "==", tipo))
                .where(filter=firestore.FieldFilter("estado", "in", ["activa", "en_proceso"]))
                .limit(1)
                .get()
            )
            return len(res) > 0
        except Exception:
            return False

    def _crear_alerta(self, tipo, descripcion, objeto, cantidad, limite):
        ahora = time.time()
        if ahora - self._cooldowns.get(tipo, 0) < COOLDOWN_ALERTA:
            return
        if self._alerta_activa(tipo):
            return

        self._cooldowns[tipo] = ahora
        cfg = self._get_config()

        self.db.collection("alertas").add({
            "zona_id": self.zona_id,
            "zona_nombre": cfg.get("nombre", self.zona_id),
            "tipo": tipo,
            "descripcion": descripcion,
            "objeto": objeto,
            "cantidad": cantidad,
            "limite": limite,
            "estado": "activa",
            "atendida_por": None,
            "fecha": datetime.now().strftime("%Y-%m-%d"),
            "timestamp": datetime.now(),
        })

    def _marcar_offline(self):
        self._ref_zona.update({
            "estado.online": False,
            "estado.actualizado_el": datetime.now(),
        })

    def run(self):
        cap = None
        n_frames = 0
        t_envio = 0
        t_hist = time.time()
        ultimo_conteo = {}

        while not self._stop.is_set():

            if cap is None or not cap.isOpened():
                conectado = False
                for intento in range(1, REINTENTOS_CAMARA + 1):
                    if self._stop.is_set():
                        break
                    cfg = self._get_config()
                    url = cfg.get("url_conexion", "0")
                    src = int(url) if url.isdigit() else url
                    cap = cv2.VideoCapture(src)
                    if cap.isOpened():
                        print(f"[{self.zona_id}] Conectado en el intento {intento}")
                        conectado = True
                        break
                    print(f"[{self.zona_id}] Intento {intento}/{REINTENTOS_CAMARA} fallido")
                    if self._stop.wait(PAUSA_REINTENTO):
                        break

                if not conectado:
                    if not self._stop.is_set():
                        print(f"[{self.zona_id}] No hay conexion, marcando offline")
                        self._marcar_offline()
                        self._stop.wait(30)
                    continue

            if self._stop.is_set():
                continue

            ok, frame = cap.read()
            n_frames += 1

            if not ok:
                print(f"[{self.zona_id}] Frame perdido, reconectando...")
                cap.release()
                cap = None
                continue

            if n_frames % FRAMES_SKIP != 0:
                continue

            cfg = self._get_config()
            objetivos = self._objetivos(cfg)
            clases_ids = self._ids_clases_yolo(cfg)

            frame = cv2.resize(frame, (512, 384))

            with self.modelo_lock:
                res = self.modelo(
                    frame,
                    classes=clases_ids,
                    conf=CONFIANZA_MINIMA,
                    iou=0.45,
                    verbose=False,
                )

            conteo = {}
            for cls_id in res[0].boxes.cls:
                nombre = self.modelo.names[int(cls_id)]
                conteo[nombre] = conteo.get(nombre, 0) + 1

            ahora = time.time()

            for obj in objetivos:
                if obj not in self._buf_hist:
                    self._buf_hist[obj] = []
                self._buf_hist[obj].append(conteo.get(obj, 0))

            if conteo != ultimo_conteo and (ahora - t_envio) > INTERVALO_FIRESTORE:
                self._publicar_estado(conteo)
                t_envio = ahora
                ultimo_conteo = conteo.copy()

            for obj, limite in objetivos.items():
                cantidad = conteo.get(obj, 0)
                tipo = f"exceso_{obj.replace(' ', '_')}"
                if cantidad > limite:
                    self._crear_alerta(
                        tipo=tipo,
                        descripcion=f"{cantidad} '{obj}' detectados (limite: {limite}) en {cfg.get('nombre', self.zona_id)}",
                        objeto=obj,
                        cantidad=cantidad,
                        limite=limite,
                    )

            if (ahora - t_hist) > INTERVALO_HISTORIAL:
                self._publicar_historial(conteo)
                t_hist = ahora

        if cap:
            cap.release()

    def detener(self):
        self._stop.set()


class GestorZonas:

    def __init__(self, db, modelo):
        self.db = db
        self.modelo = modelo
        self.modelo_lock = threading.Lock()
        self.hilos = {}
        self._lock = threading.Lock()

    def iniciar(self):
        self._unsub = (
            self.db.collection("zonas")
            .where(filter=firestore.FieldFilter("activo", "==", True))
            .on_snapshot(self._on_cambio_zonas)
        )

    def _crear_hilo(self, zona_id, config):
        return ProcesadorZona(zona_id, config, self.modelo, self.modelo_lock, self.db)

    def _on_cambio_zonas(self, snapshots, changes, read_time):
        for cambio in changes:
            zona_id = cambio.document.id
            config = cambio.document.to_dict()
            tipo = cambio.type.name

            with self._lock:
                if tipo == "ADDED" and zona_id not in self.hilos:
                    hilo = self._crear_hilo(zona_id, config)
                    hilo.start()
                    self.hilos[zona_id] = hilo

                elif tipo == "MODIFIED" and zona_id in self.hilos:
                    cfg_prev = self.hilos[zona_id]._get_config()

                    cambio_relevante = False
                    for campo in CAMPOS_ADMIN:
                        if cfg_prev.get(campo) != config.get(campo):
                            cambio_relevante = True
                            break

                    if not cambio_relevante:
                        continue

                    if cfg_prev.get("url_conexion") != config.get("url_conexion"):
                        self.hilos[zona_id].detener()
                        hilo = self._crear_hilo(zona_id, config)
                        hilo.start()
                        self.hilos[zona_id] = hilo
                    else:
                        with self.hilos[zona_id]._cfg_lock:
                            self.hilos[zona_id].config = config

                elif tipo == "REMOVED":
                    hilo = self.hilos.pop(zona_id, None)
                    if hilo:
                        hilo.detener()

    def detener_todo(self):
        with self._lock:
            for h in self.hilos.values():
                h.detener()
            for h in self.hilos.values():
                h.join(timeout=2.0)
        self._unsub.unsubscribe()


def main():
    cred = credentials.Certificate("credenciales.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    modelo = YOLO("yolov8s.pt")
    modelo.to("cpu")

    gestor = GestorZonas(db, modelo)
    gestor.iniciar()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        gestor.detener_todo()
        os._exit(0)


main()