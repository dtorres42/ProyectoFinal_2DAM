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

FRAMES_SKIP= 5
INTERVALO_FIRESTORE = 5
INTERVALO_HISTORIAL = 600
CONFIANZA_MINIMA = 0.5
REINTENTOS_CAMARA = 3
PAUSA_REINTENTO = 10
COOLDOWN_ALERTA = 300

CAMPOS_ADMIN = ["nombre", "descripcion", "url_conexion", "activo", "objetivos"]


def _franja_horaria() -> str:
    hora = datetime.now().hour
    if 6  <= hora < 14: return "manana"
    if 14 <= hora < 22: return "tarde"
    return "noche"


class ProcesadorZona(threading.Thread):

    def __init__(self, zona_id: str, config: dict, modelo: YOLO,
                 modelo_lock: threading.Lock, db):
        super().__init__(daemon=True, name=f"zona-{zona_id}")
        self.zona_id = zona_id
        self.config = config
        self._cfg_lock = threading.Lock()
        self.modelo = modelo
        self.modelo_lock = modelo_lock
        self.db = db
        self._stop = threading.Event()
        self.log = logging.getLogger(f"zona.{zona_id}")

        self._ref_zona = db.collection("zonas").document(zona_id)

        self._cooldowns_alerta: dict[str, float] = {}
        self._buffer_historial: dict[str, list[int]] = {}

    def _config_actual(self) -> dict:
        with self._cfg_lock:
            return dict(self.config)

    def _objetivos(self, config: dict) -> dict[str, int]:
        return config.get("objetivos", {})

    def _ids_clases_yolo(self, config: dict) -> list[int]:
        nombres = list(self._objetivos(config).keys())
        nombre_a_id = {nombre: idx for idx, nombre in self.modelo.names.items()}
        ids = [nombre_a_id[n] for n in nombres if n in nombre_a_id]
        return ids if ids else [0]

    def _publicar_estado(self, conteo: dict):
        self._ref_zona.update({
            "estado.objetos": conteo,
            "estado.online": True,
            "estado.actualizado_el": firestore.SERVER_TIMESTAMP,
        })
        self.log.info(f"Detecciones: {conteo}")

    def _publicar_historial(self, conteo_actual: dict):
        if not self._buffer_historial:
            return

        medias = {}
        maximos = {}

        for objeto, historial in self._buffer_historial.items():
            if historial:
                medias[objeto] = round(sum(historial) / len(historial))
                maximos[objeto] = max(historial)

        self._buffer_historial = {}
        
        self.db.collection("historial").add({
            "zona_id": self.zona_id,
            "medias": medias,
            "maximos": maximos,
            "conteo_actual": conteo_actual,
            "franja": _franja_horaria(),
            "timestamp": firestore.SERVER_TIMESTAMP,
        })
        self.log.info(f"Historial publicado — Medias: {medias} | Máximos: {maximos}")

    def _existe_alerta_activa(self, tipo: str) -> bool:
        """Comprueba si ya existe una alerta activa o en_proceso para este tipo.
        Evita duplicados cuando el usuario ya está gestionando la alerta."""
        try:
            resultado = (
                self.db.collection("alertas")
                .where(filter=firestore.FieldFilter("zona_id", "==", self.zona_id))
                .where(filter=firestore.FieldFilter("tipo", "==", tipo))
                .where(filter=firestore.FieldFilter("estado", "in", ["activa", "en_proceso"]))
                .limit(1)
                .get()
            )
            return len(resultado) > 0
        except Exception:
            return False

    def _crear_alerta(self, tipo: str, descripcion: str,
                      objeto: str, cantidad: int, limite: int):
        ahora = time.time()
        if ahora - self._cooldowns_alerta.get(tipo, 0) < COOLDOWN_ALERTA:
            return
        # No crear si ya existe una sin resolver — la resolución es siempre manual
        if self._existe_alerta_activa(tipo):
            return
        self._cooldowns_alerta[tipo] = ahora
        config = self._config_actual()
        self.db.collection("alertas").add({
            "zona_id": self.zona_id,
            "zona_nombre": config.get("nombre", self.zona_id),
            "tipo": tipo,
            "descripcion": descripcion,
            "objeto": objeto,
            "cantidad": cantidad,
            "limite": limite,
            "estado": "activa",
            "atendida_por": None,
            "fecha": datetime.now().strftime("%Y-%m-%d"), 
            "timestamp": firestore.SERVER_TIMESTAMP,
        })
        self.log.warning(f" [{tipo}] {descripcion}")

    def _marcar_offline(self):
        self._ref_zona.update({
            "estado.online": False,
            "estado.actualizado_el": firestore.SERVER_TIMESTAMP,
        })

    def run(self):
        captura = None
        contador_frames = 0
        ultimo_envio = 0
        ultimo_historial = time.time()
        ultimo_conteo = {}

        while not self._stop.is_set():

            if captura is None or not captura.isOpened():
                self.log.warning("Conectando con la cámara...")
                for intento in range(1, REINTENTOS_CAMARA + 1):
                    if self._stop.is_set():
                        break
                    config = self._config_actual()
                    url = config.get("url_conexion", "0")
                    fuente = int(url) if url.isdigit() else url
                    captura = cv2.VideoCapture(fuente)
                    if captura.isOpened():
                        self.log.info(f"Conectado (intento {intento})")
                        break
                    self.log.warning(f"Intento {intento}/{REINTENTOS_CAMARA} fallido")
                    if self._stop.wait(PAUSA_REINTENTO):
                        break
                else:
                    if not self._stop.is_set():
                        self.log.error("Sin conexión. Marcando offline.")
                        self._marcar_offline()
                        self._stop.wait(30)
                    continue

            if self._stop.is_set():
                continue

            exito, fotograma = captura.read()
            contador_frames += 1

            if not exito:
                self.log.warning("Frame perdido, reconectando...")
                captura.release()
                captura = None
                continue

            if contador_frames % FRAMES_SKIP != 0:
                continue

            config = self._config_actual()
            objetivos  = self._objetivos(config)
            clases_ids = self._ids_clases_yolo(config)

            with self.modelo_lock:
                resultados = self.modelo(
                    fotograma,
                    classes=clases_ids,
                    conf=CONFIANZA_MINIMA,
                    verbose=False,
                )

            # --- ELIMINAR PARA AL FINAL ---
            fotograma_anotado = resultados[0].plot()
            cv2.imshow(f"Zona: {self.zona_id}", fotograma_anotado)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                self.detener()
            # --- ELIMINAR PARA AL FINAL ---

            conteo: dict[str, int] = {}
            for cls_id in resultados[0].boxes.cls:
                nombre = self.modelo.names[int(cls_id)]
                conteo[nombre] = conteo.get(nombre, 0) + 1

            tiempo_actual = time.time()
            
            for objeto in objetivos.keys():
                if objeto not in self._buffer_historial:
                    self._buffer_historial[objeto] = []
                self._buffer_historial[objeto].append(conteo.get(objeto, 0))

            if conteo != ultimo_conteo and (tiempo_actual - ultimo_envio) > INTERVALO_FIRESTORE:
                self._publicar_estado(conteo)
                ultimo_envio = tiempo_actual
                ultimo_conteo = conteo.copy()

            for objeto, limite in objetivos.items():
                cantidad = conteo.get(objeto, 0)
                tipo = f"exceso_{objeto.replace(' ', '_')}"

                if cantidad > limite:
                    self._crear_alerta(
                        tipo = tipo,
                        descripcion = (
                            f"{cantidad} '{objeto}' detectados "
                            f"(límite: {limite}) "
                            f"en {config.get('nombre', self.zona_id)}"
                        ),
                        objeto = objeto,
                        cantidad = cantidad,
                        limite = limite,
                    )

            if (tiempo_actual - ultimo_historial) > INTERVALO_HISTORIAL:
                self._publicar_historial(conteo)
                ultimo_historial = tiempo_actual

        if captura:
            captura.release()

        # --- ELIMINAR PARA AL FINAL ---
        try:
            cv2.destroyWindow(f"Zona: {self.zona_id}")
        except Exception:
            pass
        # --- ELIMINAR PARA AL FINAL ---

        self.log.info("Hilo detenido")

    def detener(self):
        self._stop.set()


class GestorZonas:

    def __init__(self, db, modelo: YOLO):
        self.db = db
        self.modelo = modelo
        self.modelo_lock = threading.Lock()
        self.hilos : dict[str, ProcesadorZona] = {}
        self._lock = threading.Lock()
        self.log = logging.getLogger("gestor")

    def iniciar(self):
        self.log.info("Escuchando colección 'zonas'...")
        self._unsub = (
            self.db.collection("zonas")
            .where(filter=firestore.FieldFilter("activo", "==", True))
            .on_snapshot(self._on_cambio_zonas)
        )

    def _crear_hilo(self, zona_id: str, config: dict) -> ProcesadorZona:
        return ProcesadorZona(zona_id, config, self.modelo, self.modelo_lock, self.db)

    def _on_cambio_zonas(self, snapshots, changes, read_time):
        for cambio in changes:
            zona_id = cambio.document.id
            config = cambio.document.to_dict()
            tipo = cambio.type.name

            with self._lock:

                if tipo == "ADDED" and zona_id not in self.hilos:
                    self.log.info(f"Nueva zona: {zona_id}")
                    hilo = self._crear_hilo(zona_id, config)
                    hilo.start()
                    self.hilos[zona_id] = hilo

                elif tipo == "MODIFIED" and zona_id in self.hilos:
                    config_anterior = self.hilos[zona_id]._config_actual()
                    hubo_cambio_admin = any(
                        config_anterior.get(c) != config.get(c) for c in CAMPOS_ADMIN
                    )

                    if not hubo_cambio_admin:
                        continue

                    if config_anterior.get("url_conexion") != config.get("url_conexion"):
                        self.log.info(f"URL cambiada en {zona_id}, reiniciando hilo")
                        self.hilos[zona_id].detener()
                        hilo = self._crear_hilo(zona_id, config)
                        hilo.start()
                        self.hilos[zona_id] = hilo
                    else:
                        with self.hilos[zona_id]._cfg_lock:
                            self.hilos[zona_id].config = config
                        self.hilos[zona_id].log.info("⚙️  Configuración recargada")

                elif tipo == "REMOVED":
                    self.log.info(f"Zona eliminada: {zona_id}")
                    hilo = self.hilos.pop(zona_id, None)
                    if hilo:
                        hilo.detener()

    def detener_todo(self):
        with self._lock:
            for hilo in self.hilos.values():
                hilo.detener()
            for hilo in self.hilos.values():
                hilo.join(timeout=2.0)
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


    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        log.info("Deteniendo servidor...")
        gestor.detener_todo()
        log.info("Servidor detenido")

        # --- ELIMINAR PARA AL FINAL ---
        cv2.destroyAllWindows()
        # --- ELIMINAR PARA AL FINAL ---

        os._exit(0)


if __name__ == "__main__":
    main()