import cv2
import time
import os
import threading
import logging
from datetime import datetime
from ultralytics import YOLO
import firebase_admin
from firebase_admin import credentials, firestore

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("servidor")

FRAMES_SKIP         = 5   
INTERVALO_FIRESTORE = 5   
INTERVALO_HISTORIAL = 600  
CONF_MINIMA         = 0.5 
REINTENTOS_CAMARA   = 3   
PAUSA_REINTENTO     = 10  
COOLDOWN_ALERTA     = 300  


def _franja_horaria() -> str:
    hora = datetime.now().hour
    if 6 <= hora < 14:  return "manana"
    if 14 <= hora < 22: return "tarde"
    return "noche"


class ProcesadorEspacio(threading.Thread):

    def __init__(self, espacio_id: str, config: dict, modelo: YOLO, db):
        super().__init__(daemon=True, name=f"cam-{espacio_id}")
        self.espacio_id = espacio_id
        self.config     = config
        self._lock      = threading.Lock()
        self.modelo     = modelo
        self.db         = db
        self._stop      = threading.Event()
        self.log        = logging.getLogger(f"cam.{espacio_id}")

        self._ref = db.collection("zonas").document(espacio_id)
        self._ultima_alerta: dict[str, float] = {}
        self._buffer_hist: list[int] = []

    def _cfg(self) -> dict:
        with self._lock:
            return dict(self.config)

    def _aforo_max(self, cfg) -> int:
        return cfg.get("config", {}).get("aforo_max", 30)

    def _nivel_ocupacion(self, porcentaje: int, cfg: dict) -> str:
        config = cfg.get("config", {})
        umbral_alto    = config.get("umbral_alto", 80)
        umbral_critico = config.get("umbral_critico", 100)
        if porcentaje >= umbral_critico: return "critico"
        if porcentaje >= umbral_alto:    return "alto"
        return "normal"

    def _clases_ids(self, cfg) -> list[int]:
        nombres = cfg.get("config", {}).get("clases", {}).get("vigilar", ["person"])
        nombre_a_id = {v: k for k, v in self.modelo.names.items()}
        ids = [nombre_a_id[n] for n in nombres if n in nombre_a_id]
        return ids if ids else [0]

    def _clases_peligrosas(self, cfg) -> set[str]:
        return set(cfg.get("config", {}).get("clases", {}).get("peligrosas", []))

    def _actualizar_estado(self, personas: int, objetos: dict, aforo: int, cfg: dict):
        pct   = min(100, round(personas / aforo * 100)) if aforo > 0 else 0
        nivel = self._nivel_ocupacion(pct, cfg)
        
        self._ref.update({
            "estado.personas"      : personas,
            "estado.objetos"       : objetos,
            "estado.nivel"         : nivel,
            "estado.online"        : True,
            "estado.actualizado_el": firestore.SERVER_TIMESTAMP,
        })
        self.log.info(f"{personas}/{aforo} personas ({pct}% — {nivel}) | {objetos}")

    def _guardar_historial(self, personas: int, objetos: dict):
        if not self._buffer_hist:
            return
        media  = round(sum(self._buffer_hist) / len(self._buffer_hist))
        maximo = max(self._buffer_hist)
        self._buffer_hist = []

        self.db.collection("historial").add({
            "espacio_id"         : self.espacio_id,
            "num_personas_media" : media,
            "num_personas_maximo": maximo,
            "conteo_objetos"     : objetos,
            "franja"             : _franja_horaria(),
            "timestamp"          : firestore.SERVER_TIMESTAMP,
        })
        self.log.info(f" Historial — media: {media}, máximo: {maximo}")

    def _generar_alerta(self, tipo: str, descripcion: str):
        ahora = time.time()
        if ahora - self._ultima_alerta.get(tipo, 0) < COOLDOWN_ALERTA:
            return
        self._ultima_alerta[tipo] = ahora

        cfg = self._cfg()
        self.db.collection("alertas").add({
            "espacio_id"    : self.espacio_id,
            "espacio_nombre": cfg.get("nombre", self.espacio_id),
            "tipo"          : tipo,
            "descripcion"   : descripcion,
            "estado"        : "activa",
            "atendida_por"  : None,
            "timestamp"     : firestore.SERVER_TIMESTAMP,
        })
        self.log.warning(f"🚨 [{tipo}] {descripcion}")

    def _resolver_alerta(self, tipo: str):
        try:
            alertas = (
                self.db.collection("alertas")
                .where(filter=firestore.FieldFilter("espacio_id", "==", self.espacio_id))
                .where(filter=firestore.FieldFilter("tipo", "==", tipo))
                .where(filter=firestore.FieldFilter("estado", "==", "activa"))
                .get()
            )
            for a in alertas:
                a.reference.update({"estado": "resuelta"})
                self.log.info(f"Alerta resuelta: [{tipo}]")
        except Exception as e:
            self.log.error(f"Error resolviendo alerta: {e}")

    def _marcar_offline(self):
        self._ref.update({
            "estado.online"        : False,
            "estado.nivel"         : "sin_datos",
            "estado.actualizado_el": firestore.SERVER_TIMESTAMP,
        })

    def run(self):
        captura             = None
        contador            = 0
        ultimo_envio        = 0
        ultimo_historial    = time.time()
        ultima_cantidad     = -1
        alerta_aforo_activa = False

        while not self._stop.is_set():

            if captura is None or not captura.isOpened():
                self.log.warning("Conectando con la cámara...")
                for intento in range(1, REINTENTOS_CAMARA + 1):
                    if self._stop.is_set():
                        break

                    cfg = self._cfg()
                    url = cfg.get("url_conexion", "0")
                    src = int(url) if url.isdigit() else url
                    captura = cv2.VideoCapture(src)
                    
                    if captura.isOpened():
                        self.log.info(f"Conectado (intento {intento})")
                        break
                        
                    self.log.warning(f"Intento {intento}/{REINTENTOS_CAMARA} fallido")
                    if self._stop.wait(PAUSA_REINTENTO):
                        break
                else:
                    if not self._stop.is_set():
                        self.log.error("❌ Sin conexión. Marcando offline.")
                        self._marcar_offline()
                        self._stop.wait(30)
                    continue

            if self._stop.is_set():
                continue

            exito, fotograma = captura.read()
            contador += 1

            if not exito:
                self.log.warning("Frame perdido, reconectando...")
                captura.release()
                captura = None
                continue

            if contador % FRAMES_SKIP != 0:
                continue

            cfg             = self._cfg()
            aforo           = self._aforo_max(cfg)
            clases_ids      = self._clases_ids(cfg)
            clases_peligros = self._clases_peligrosas(cfg)

            resultados = self.modelo(
                fotograma,
                classes=clases_ids,
                conf=CONF_MINIMA,
                verbose=False,
            )
            cajas = resultados[0].boxes

            conteo: dict[str, int] = {}
            for cls_id in cajas.cls:
                nombre = self.modelo.names[int(cls_id)]
                conteo[nombre] = conteo.get(nombre, 0) + 1

            personas      = conteo.get("person", 0)
            tiempo_actual = time.time()

            self._buffer_hist.append(personas)

            hubo_cambio = personas != ultima_cantidad
            if hubo_cambio and (tiempo_actual - ultimo_envio) > INTERVALO_FIRESTORE:
                self._actualizar_estado(personas, conteo, aforo, cfg)
                ultimo_envio    = tiempo_actual
                ultima_cantidad = personas

            if aforo > 0:
                if personas > aforo:
                    if not alerta_aforo_activa:
                        self._generar_alerta("aforo_superado", f"Aforo superado: {personas}/{aforo} personas")
                        alerta_aforo_activa = True
                else:
                    if alerta_aforo_activa:
                        self._resolver_alerta("aforo_superado")
                        alerta_aforo_activa = False

            for nombre_obj in conteo:
                if nombre_obj != "person" and nombre_obj in clases_peligros:
                    self._generar_alerta(
                        f"objeto_{nombre_obj}",
                        f"Objeto detectado: {nombre_obj} en {cfg.get('nombre', self.espacio_id)}"
                    )

            if (tiempo_actual - ultimo_historial) > INTERVALO_HISTORIAL:
                self._guardar_historial(personas, conteo)
                ultimo_historial = tiempo_actual

            cv2.imshow(f"[{self.espacio_id}] — pulsa Q para salir", resultados[0].plot())
            if cv2.waitKey(1) & 0xFF == ord("q"):
                self.detener()

        if captura:
            captura.release()
        self.log.info("Hilo detenido")

    def detener(self):
        self._stop.set()


class GestorZonas:

    def __init__(self, db, modelo: YOLO):
        self.db     = db
        self.modelo = modelo
        self.hilos  : dict[str, ProcesadorEspacio] = {}
        self._lock  = threading.Lock()
        self.log    = logging.getLogger("gestor")

    def iniciar(self):
        self.log.info("Escuchando colección 'zonas'...")
        self._unsub = (
            self.db.collection("zonas")
            .where(filter=firestore.FieldFilter("activo", "==", True))
            .on_snapshot(self._on_cambio)
        )

    def _on_cambio(self, snapshots, changes, read_time):
        for cambio in changes:
            doc    = cambio.document
            eid    = doc.id
            config = doc.to_dict()
            tipo   = cambio.type.name

            with self._lock:
                if tipo == "ADDED" and eid not in self.hilos:
                    self.log.info(f"Nuevo espacio: {eid}")
                    hilo = ProcesadorEspacio(eid, config, self.modelo, self.db)
                    hilo.start()
                    self.hilos[eid] = hilo

                elif tipo == "MODIFIED" and eid in self.hilos:
                    url_anterior = self.hilos[eid]._cfg().get("url_conexion")
                    url_nueva    = config.get("url_conexion")
                    
                    if url_anterior != url_nueva:
                        self.log.info(f"URL cambiada en {eid}, reiniciando hilo")
                        self.hilos[eid].detener()
                        hilo = ProcesadorEspacio(eid, config, self.modelo, self.db)
                        hilo.start()
                        self.hilos[eid] = hilo
                    else:
                        with self.hilos[eid]._lock:
                            self.hilos[eid].config = config
                        self.hilos[eid].log.info("⚙️  Configuración recargada desde el Gestor")

                elif tipo == "REMOVED":
                    self.log.info(f"Espacio eliminado: {eid}")
                    hilo = self.hilos.pop(eid, None)
                    if hilo:
                        hilo.detener()

    def detener_todo(self):
        with self._lock:
            for hilo in self.hilos.values():
                hilo.detener()
        self._unsub.unsubscribe()


def main():
    log.info("=" * 55)
    log.info("  SERVIDOR DE VIDEOVIGILANCIA INTELIGENTE")
    log.info("=" * 55)

    cred = credentials.Certificate("credenciales.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    log.info("Firebase conectado")

    log.info("Cargando modelo YOLOv8n...")
    modelo = YOLO("yolov8n.pt")
    log.info("Modelo listo")

    gestor = GestorZonas(db, modelo)
    gestor.iniciar()

    log.info("Servidor en marcha. Ctrl+C para detener.")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log.info("Deteniendo servidor...")
        gestor.detener_todo()
        log.info("Servidor detenido")
        os._exit(0) 


if __name__ == "__main__":
    main()