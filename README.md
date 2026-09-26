# Arquitectura de LumiIa

LumiIa es un proyecto orientado a mejorar hábitos de estudio y organización académica mediante una experiencia móvil y un backend que puede crecer hacia funcionalidades de inteligencia artificial y gamificación. En su estado actual, el proyecto está estructurado en dos capas principales:

- Frontend: aplicación desarrollada con Flutter y Dart para la interfaz de usuario.
- Backend: API desarrollada con Node.js, Express y TypeScript para la lógica de negocio y acceso a datos.
- Base de datos: PostgreSQL, con el esquema definido en la carpeta de base de datos.

## 1. Visión general del proyecto

El proyecto está pensado como una arquitectura modular con separación entre:

- interfaz de usuario,
- lógica de presentación,
- servicios de backend,
- persistencia de datos.

Actualmente se implementan autenticación con Supabase, registro y login sincronizados con PostgreSQL, dashboard, planes de estudio con Gemini, tareas, calendario, perfil, progreso, gamificación, técnicas de aprendizaje y panel administrativo. El frontend se comunica con el backend desplegable y conserva la navegación responsive para móvil, web y escritorio.

## 2. Arquitectura general

El flujo actual del sistema es el siguiente:

1. El usuario interactúa con la app en Flutter.
2. La interfaz captura datos como correo y contraseña.
3. El frontend presenta validaciones locales y navegación entre pantallas.
4. El backend recibe peticiones HTTP mediante Express.
5. El backend se conecta a PostgreSQL mediante un pool de conexiones.

Diagrama conceptual:

Cliente Flutter -> Pantallas y widgets -> API REST (Express) -> PostgreSQL

## 3. Estructura de carpetas y archivos

### Raíz del proyecto

- [README.md](README.md): documento de documentación general del proyecto.
- [LUMIA_DETAILED_EXPLANATION.md](LUMIA_DETAILED_EXPLANATION.md): explicación funcional completa.
- [LUMIIA_COMPLETE_DOCUMENTATION.md](LUMIIA_COMPLETE_DOCUMENTATION.md): arquitectura, mapa de navegación, API y despliegue.
- [basededatos/lumi.sql](basededatos/lumi.sql): esquema PostgreSQL.

### Carpeta frontend

Ubicación: [frontend](frontend)

Esta carpeta contiene toda la aplicación móvil desarrollada con Flutter.

#### Archivos principales

- [frontend/pubspec.yaml](frontend/pubspec.yaml): define las dependencias, versión de Flutter/Dart y los assets usados por la app.
- [frontend/analysis_options.yaml](frontend/analysis_options.yaml): reglas de linting y calidad del código.

#### Código fuente

- [frontend/lib/main.dart](frontend/lib/main.dart): punto de entrada principal de la aplicación. Aquí se inicializa la app, se define la pantalla de inicio de sesión y se gestiona la navegación hacia otras pantallas.
- [frontend/lib/screens/register_screen.dart](frontend/lib/screens/register_screen.dart): pantalla de registro de usuarios.
- [frontend/lib/screens/olvidar_contraseña.dart](frontend/lib/screens/olvidar_contraseña.dart): recuperación de contraseña y opciones biométricas.
- [frontend/lib/screens/app_bottom_navbar.dart](frontend/lib/screens/app_bottom_navbar.dart): navegación autenticada entre inicio, calendario, historial IA, progreso y perfil.

#### Recursos y assets

- [frontend/logo/Lumi.png](frontend/logo/Lumi.png): imagen principal utilizada en la interfaz.

#### Carpetas de plataforma

- [frontend/android](frontend/android): configuración nativa para Android.
- [frontend/ios](frontend/ios): configuración nativa para iOS.
- [frontend/linux](frontend/linux): configuración para Linux.
- [frontend/macos](frontend/macos): configuración para macOS.
- [frontend/windows](frontend/windows): configuración para Windows.
- [frontend/web](frontend/web): soporte para la web.
- [frontend/build](frontend/build): archivos generados por Flutter durante compilaciones.

#### Propósito general de frontend

La interfaz actual está enfocada en:

- mostrar pantallas de autenticación,
- validar entradas del usuario,
- ofrecer navegación entre autenticación, dashboard, calendario, historial IA, progreso, perfil y administración,
- generar y consultar planes de estudio personalizados,
- registrar tareas, horarios, técnicas, logros, XP y progreso,
- aplicar una experiencia responsive con componentes Material.

### Carpeta backend

Ubicación: [backend](backend)

Esta carpeta contiene la API del proyecto, construida con Node.js, Express y TypeScript.

#### Archivos principales

- [backend/package.json](backend/package.json): define el nombre del proyecto, scripts de ejecución y dependencias del backend.
- [backend/tsconfig.json](backend/tsconfig.json): configuración de TypeScript para compilar el código a JavaScript.

#### Código fuente

- [backend/src/server.ts](backend/src/server.ts): punto de entrada del servidor. Inicializa Express, CORS, JSON y las rutas de autenticación, horarios, tareas, IA, historial, administración y progreso. Usa `PORT` o 3000 por defecto.
- [backend/src/config/db.ts](backend/src/config/db.ts): configuración de conexión a PostgreSQL mediante el cliente pg. Lee variables de entorno como host, puerto, usuario, contraseña y nombre de la base de datos.
- [backend/src/rutas/authRoutes.ts](backend/src/rutas/authRoutes.ts): registro, login, perfil, estadísticas, personajes y actualización de disponibilidad.

#### Propósito general de backend

El backend tiene como responsabilidad:

- exponer endpoints HTTP para el frontend,
- validar y procesar solicitudes de autenticación,
- conectarse a PostgreSQL,
- guardar información de usuarios y preparar la arquitectura para futuras funcionalidades.

### Carpeta basededatos

Ubicación: [basededatos](basededatos)

Contiene la definición del modelo de datos.

- [basededatos/lumi.sql](basededatos/lumi.sql): script SQL con la estructura de la base de datos. En él se define la tabla de usuarios utilizada por la ruta de registro del backend.

## 4. Función de cada archivo clave

### Frontend

- [frontend/lib/main.dart](frontend/lib/main.dart)
  - Inicializa la app.
  - Define el widget principal de login.
  - Maneja la navegación a registro y recuperación de contraseña.

- [frontend/lib/register_screen.dart](frontend/lib/register_screen.dart)
  - Implementa la pantalla de registro.
  - Valida formato de correo, longitud de contraseña y coincidencia entre contraseñas.
  - Presenta una interfaz visual con estilo propio del proyecto.

- [frontend/lib/olvidar_contraseña.dart](frontend/lib/olvidar_contraseña.dart)
  - Implementa el flujo de recuperación de contraseña.
  - Permite elegir entre correo o autenticación biométrica.
  - Reproduce validaciones de lógica de negocio en la interfaz.

### Backend

- [backend/src/server.ts](backend/src/server.ts)
  - Levanta el servidor Express.
  - Monta la ruta de autenticación bajo /api/auth.
  - Expone una ruta raíz para comprobar la conexión con la base de datos.

- [backend/src/config/db.ts](backend/src/config/db.ts)
  - Centraliza la conexión a PostgreSQL.
  - Usa un pool de conexiones para manejar consultas.

- [backend/src/rutas/authRoutes.ts](backend/src/rutas/authRoutes.ts)
  - Contiene rutas como POST /api/auth/register, POST /api/auth/login, GET/PUT /api/auth/profile/:id y operaciones de personajes.
  - Sincroniza usuarios, perfiles, estadísticas y horarios con PostgreSQL.

## 5. Dependencias usadas

### Dependencias del frontend

En [frontend/pubspec.yaml](frontend/pubspec.yaml) se utilizan:

- flutter: SDK oficial de Flutter.
- cupertino_icons: iconos del estilo iOS.
- supabase_flutter: paquete para integrar servicios de Supabase, aunque en el código actual aún no se usa de forma activa.
- google_fonts: uso de tipografías personalizadas.
- local_auth: autenticación biométrica con huella dactilar.

### Dependencias de desarrollo del frontend

- flutter_test: pruebas del framework Flutter.
- flutter_lints: reglas recomendadas para mantener calidad de código.

### Dependencias del backend

En [backend/package.json](backend/package.json) se utilizan:

- express: framework para crear la API.
- dotenv: carga de variables de entorno desde archivos .env.
- pg: cliente oficial de PostgreSQL para Node.js.
- postgres: cliente alternativo para PostgreSQL.

### Dependencias de desarrollo del backend

- typescript: lenguaje tipado para compilar el backend.
- tsx: ejecución directa de archivos TypeScript en desarrollo.
- @types/express: definiciones de tipos para Express.
- @types/node: definiciones de tipos para Node.js.
- @types/pg: definiciones de tipos para pg.

## 6. Variables de entorno

El backend espera variables de configuración para conectar con la base de datos. Entre ellas están:

- DB_HOST
- DB_PORT
- DB_USER
- DB_PASSWORD
- DB_NAME

Estas variables deben definirse en un archivo .env en la raíz del proyecto o en la carpeta backend según la configuración utilizada.

## 7. Estado actual del proyecto

En esta versión del repositorio se observa que:

- el frontend tiene autenticación, dashboard, navegación principal, perfil, planes, calendario, técnicas, progreso, gamificación y administración,
- el backend monta `/api/auth`, `/api/horarios`, `/api/tareas`, `/api/ia`, `/api/ia/historial`, `/api/admin` y `/api/progreso`,
- Gemini genera planes, evalúa Feynman y permite reajustar planes cuando cambia la disponibilidad,
- la base de datos contiene usuarios, perfiles, horarios, planes, actividades, tareas, historial, estadísticas, recompensas, notificaciones y personajes,
- el backend está preparado para Render y el frontend web para GitHub Pages.

## 8. Cómo ejecutar el proyecto

### Backend

1. Entrar a [backend](backend).
2. Instalar dependencias con npm install.
3. Ejecutar el servidor con npm run dev.

### Frontend

1. Entrar a [frontend](frontend).
2. Instalar dependencias con flutter pub get.
3. Ejecutar la app con flutter run.

## 9. Resumen ejecutivo

LumiIa está compuesto por una app frontend en Flutter y un backend en Node.js/Express. La arquitectura actual es sencilla y modular, con una separación clara entre interfaz, lógica de presentación y acceso a datos. El proyecto ya cuenta con componentes visuales y una base para autenticación, pero su evolución natural será integrar mejor la comunicación frontend-backend, ampliar la base de datos y añadir la capa de inteligencia artificial prevista en la propuesta inicial.
