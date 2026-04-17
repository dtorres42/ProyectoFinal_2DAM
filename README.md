PROYECTO INTERMODULARe

Este proyecto es un sistema basado en **Visión Artificial** y una arquitectura cliente-servidor para monitorizar espacios en tiempo real. Permite el control de aforo y la detección de objetos específicos mediante cámaras IP, centralizando y mostrando toda la información al instante en una aplicación móvil para el personal de seguridad

## Tecnologías utilizadas
* **IA y Servidor:** Python, YOLOv8, OpenCV
* **Base de Datos:** Firebase
* **App Móvil:** Flutter
---

## Arquitectura y Estructura de Datos
El proyecto se divide en dos bloques principales que se comunican en tiempo real mediante Firestore:

1. **Backend AI (Python):** Se encarga de capturar el vídeo, procesar los fotogramas con YOLOv8 y determinar si hay exceso de aforo o se detectan objetos peligrosos
2. **Frontend App (Flutter):** Consume los datos de la nube mediante *Streams* y alerta al vigilante

### Base de Datos (Colecciones)
* `espacios`: Configuración dinámica (aforo máximo, objetos a vigilar) y estado en vivo de cada cámara
* `alertas`: Registro de incidencias urgentes (ej. "Aforo superado" o "Mochila detectada")
* `historial`: Datos agregados cada 10 minutos para generar gráficas de afluencia



## Cómo ejecutar el proyecto

Iniciar el Servidor (Python)
Requisitos: Python 3.9+
1. Clonar el repositorio.
2. Instalar las dependencias:
   ```bash
   pip install ultralytics opencv-python firebase-admin
