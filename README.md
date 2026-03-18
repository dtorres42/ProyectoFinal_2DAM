# ProyectoFinal_2DAM

# Smart-Vigilance: Monitoreo de Aforo e IA
Sistema de videovigilancia inteligente basado en una arquitectura Cliente-Servidor. El proyecto permite la detección de personas y objetos en tiempo real mediante Inteligencia Artificial, optimizando la seguridad y el control de afluencia en espacios físicos sin intervención humana constante.

# Requisitos Funcionales
Procesamiento Desacoplado: Captura de vídeo mediante cámaras IP/móviles y procesamiento en servidor externo mediante visión computacional, evitando sobrecargar el dispositivo cliente.

Conteo y Tracking: Detección en tiempo real de personas con algoritmos de seguimiento para evitar duplicados en el conteo.

Detección Filtrada de Objetos: Configuración dinámica desde la app para decidir qué objetos generan alertas o son ignorados por cámara.

Gestión Dinámica de Dispositivos: Registro de nuevas cámaras mediante URL (RTSP/HTTP) desde la interfaz, sin tocar el código del servidor.

Alertas en Tiempo Real: Notificaciones push automáticas ante exceso de aforo u objetos no permitidos.

Visualización en Directo: Acceso al flujo de vídeo original desde la app para verificación manual de alertas.

Registro Histórico: Almacenamiento periódico (ej. cada 10 min) de datos para análisis estadístico de afluencia.

# Requisitos NO Funcionales
Rendimiento y Optimización: El servidor envía únicamente metadatos numéricos a Firebase, separando el tiempo real del historial para minimizar el consumo de ancho de banda.

Seguridad: Autenticación robusta mediante Firebase Auth y control de acceso basado en roles (Admin/Usuario).

Escalabilidad: Procesamiento asíncrono capaz de gestionar múltiples flujos de vídeo simultáneos.

Usabilidad: Interfaz móvil fluida y reactiva (Multiplataforma) sincronizada en tiempo real.

# Stack Tecnológico 
IA y Visión (YOLOv8 + OpenCV): * YOLOv8: Permite detección ultrarrápida y tracking integrado bajo licencia open-source (AGPL-3.0).

OpenCV: Motor principal para la gestión y decodificación de flujos de vídeo de red.

Servidor (Python): Lenguaje estándar de la industria para IA, facilitando la integración nativa con el Firebase Admin SDK.

Backend (Firebase): * Firestore: Sincronización en tiempo real sin necesidad de gestionar WebSockets manualmente.

Cloud Messaging: Gestión eficiente de notificaciones push multiplataforma.

App Móvil (Flutter): Desarrollo híbrido (Android/iOS) con un único código base y una interfaz reactiva de alto rendimiento.

# Arquitectura de Datos y Calidad
Optimización: El servidor envía únicamente metadatos numéricos a Firebase, reduciendo drásticamente el uso de ancho de banda.

Seguridad: Autenticación mediante Firebase Auth y control de acceso basado en roles (Admin/Usuario).

Escalabilidad: Procesamiento asíncrono para gestionar múltiples flujos de vídeo en paralelo.

# Estructura 
├── servidor_python/             # Backend Python (YOLOv8 + Firebase Admin)
│   ├── models/         # Pesos de YOLOv8 (.pt)
│   └── processor.py    # Lógica de detección y tracking
├── app_flutter/         # Aplicación Flutter (UI y Firebase Client)
├── docs/               # Documentación técnica y licencias
└── README.md
