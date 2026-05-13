# PROYECTO INTERMODULAR

Sistema de videovigilancia inteligente basado en **Visión Artificial** y arquitectura cliente-servidor para monitorizar espacios en tiempo real. Permite el control de aforo y la detección de objetos configurables mediante cámaras IP, centralizando toda la información en una aplicación móvil orientada al personal de seguridad.

## Tecnologías utilizadas

- **Servidor:** Python, YOLOv8, OpenCV
- **Base de datos:** Firebase Firestore, Firebase Authentication, Firebase Cloud Messaging
- **App móvil:** Flutter

---

## Arquitectura

El proyecto se divide en dos bloques que se comunican en tiempo real mediante Firestore:

1. **Servidor Python:** captura el vídeo de las cámaras IP vía RTSP, procesa los fotogramas con YOLOv8 y genera alertas automáticas cuando se supera el límite configurado para un objeto o persona. Procesa múltiples cámaras simultáneamente mediante hilos y gestiona las caídas de conexión de forma controlada.

2. **App Flutter:** consume los datos de Firestore mediante streams y los muestra en tiempo real al usuario. Permite gestionar zonas, alertas y usuarios según el rol asignado. Las notificaciones push se gestionan mediante Firebase Cloud Messaging.

### Base de datos (colecciones principales)

- `zonas`: configuración de cada cámara y su estado en tiempo real
- `alertas`: incidencias generadas automáticamente por el servidor
- `historial`: estadísticas resumidas periódicas para consulta histórica
- `usuarios`: cuentas y roles del sistema
- `objetos_detectables`: clases configurables para la detección
