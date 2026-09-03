# 🎓 LumiIa - Explicación Detallada Completa

## 📌 ¿Qué es LumiIa?

**LumiIa** es una **plataforma educativa integral y personalizada** diseñada para ayudar a estudiantes a **mejorar sus hábitos de estudio, organización académica y aprendizaje** mediante tecnología de IA y gamificación.

### Objetivo Principal
Transformar la experiencia de estudio proporcionando:
- 🤖 **Planes de estudio personalizados** generados con IA (Google Gemini)
- 📅 **Organización y gestión** de tareas y horarios
- 🎮 **Gamificación** con recompensas y estadísticas
- 🧠 **Técnicas de aprendizaje científicas** (Pomodoro, Spaced Repetition, Feynman)
- 📊 **Seguimiento del progreso** y análisis de rendimiento
- 💪 **Motivación continuada** mediante logros y racha de días

---

## 🏗️ Arquitectura General

LumiIa es una **arquitectura de tres capas**:

```
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                     │
│                  Flutter App (Multi-plataforma)             │
│        iOS, Android, Web, Windows, Linux, macOS             │
└──────────────────┬──────────────────────────────────────────┘
                   │ HTTP/REST API
                   ↓
┌─────────────────────────────────────────────────────────────┐
│                     CAPA DE APLICACIÓN                       │
│              Node.js/Express + TypeScript                   │
│        - Controladores de lógica de negocio                 │
│        - Servicios (IA, histórico, validación)              │
│        - Rutas de API                                        │
└──────────────────┬──────────────────────────────────────────┘
                   │ SQL Queries
                   ↓
┌─────────────────────────────────────────────────────────────┐
│                    CAPA DE DATOS                             │
│            PostgreSQL (via Supabase)                         │
│        - Usuarios, Planes, Tareas, Horarios                 │
│        - Historial de IA, Estadísticas, Recompensas         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 Conceptos Clave

### 1. **Usuarios y Perfiles**
- Cada usuario tiene un **perfil de estudio** personalizado
- Datos: horas disponibles, objetivo académico, nivel de procrastinación
- Foto de perfil y preferencias

### 2. **Planes de Estudio**
- Plan generado por IA para un tema/asignatura específico
- Contiene: método de estudio, duración total, consejos, recursos
- Estado: ACTIVO, COMPLETADO, PAUSADO
- Asociados a **actividades** y **tareas**

### 3. **Horarios**
- Disponibilidad de estudio del usuario por día
- Formato: Día de la semana → Hora inicio → Hora fin
- Sistema calcula horas disponibles basadas en horarios

### 4. **Historial IA**
- Registro de todas las preguntas/respuestas con Gemini
- Vinculadas a planes específicos
- Permite seguimiento de interacciones

### 5. **Estadísticas y Gamificación**
- Tareas completadas
- Horas de estudio totales
- Racha (días consecutivos estudiando)
- Recompensas desbloqueadas
- Puntos y logros

### 6. **Métodos de Estudio**
- **Pomodoro**: Ciclos de 25 min estudio + 5 min descanso
- **Spaced Repetition**: Repaso espaciado de conceptos
- **Feynman Technique**: Explicación simplificada de conceptos
- **Active Recall**: Recuperación activa de información

---

## 📁 Estructura Detallada de Carpetas

### 🖥️ BACKEND (`/backend`)

Servidor API que gestiona toda la lógica de negocio.

#### **Archivos Configuración**

| Archivo | Propósito |
|---------|-----------|
| `package.json` | Define dependencias npm, scripts de ejecución |
| `tsconfig.json` | Configuración de TypeScript (tipado, compilación) |

#### **`src/server.ts`** - Punto de Entrada Principal
```
✓ Inicializa Express
✓ Habilita CORS (acceso desde frontend)
✓ Parsea JSON en requests
✓ Registra todas las rutas (/api/auth, /api/tareas, etc.)
✓ Levanta servidor en puerto 3000
```

#### **`src/config/db.ts`** - Conexión a Base de Datos
```
✓ Pool de conexiones PostgreSQL
✓ Lee credenciales de variables de entorno
✓ Gestiona conexiones reutilizables
✓ Host: conectado a Supabase (servicio cloud PostgreSQL)
```

#### **`src/config/ia/gemini.config.ts`** - Configuración IA
```
✓ API Key de Google Gemini
✓ Modelo IA: "gemini-1.5-pro" (principal)
✓ Fallback: "gemini-1.5-flash" (si está ocupado)
✓ Configuración de parámetros de generación
```

#### **🛣️ RUTAS (API Endpoints) - `/src/rutas`**

**`authRoutes.ts` - Autenticación**
- `POST /api/auth/register` - Registrar nuevo usuario
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `POST /api/auth/forgot-password` - Recuperar contraseña

**`tareas.routes.ts` - Gestión de Tareas**
- `GET /api/tareas` - Listar tareas del usuario
- `POST /api/tareas` - Crear nueva tarea
- `PUT /api/tareas/:id` - Actualizar tarea
- `DELETE /api/tareas/:id` - Eliminar tarea
- `PATCH /api/tareas/:id/completar` - Marcar como completada

**`horarios.routes.ts` - Gestión de Horarios**
- `GET /api/horarios` - Obtener horarios disponibles
- `POST /api/horarios` - Crear horario
- `PUT /api/horarios/:id` - Actualizar horario
- `DELETE /api/horarios/:id` - Eliminar horario

**`ia.routes.ts` - Generación de Planes con IA**
- `POST /api/ia/generar-plan` - Generar plan de estudio (llama a Gemini)
- `POST /api/ia/evaluar-feynman` - Evaluar explicación Feynman
- `POST /api/ia/preguntar` - Hacer pregunta a IA

**`historial.routes.ts` - Historial de Interacciones**
- `GET /api/ia/historial` - Obtener historial de IA del usuario
- `GET /api/ia/historial/:plan_id` - Historial por plan específico
- `DELETE /api/ia/historial/:id` - Eliminar entrada de historial

**`adminRoutes.ts` - Panel Administrativo**
- `GET /api/admin/usuarios` - Listar todos los usuarios
- `GET /api/admin/usuarios/:id` - Detalles de usuario
- `PUT /api/admin/usuarios/:id` - Editar usuario
- `DELETE /api/admin/usuarios/:id` - Eliminar usuario
- `GET /api/admin/estadisticas` - Estadísticas globales

#### **🎮 CONTROLADORES (Lógica de Negocio) - `/src/controllers`**

**`tareas.controller.ts` - Gestión de Tareas**
```
Funciones principales:
- crearTarea(): Valida datos, inserta en DB
- listarTareas(): Filtra por usuario
- actualizarTarea(): Valida cambios, actualiza
- completarTarea(): Marca como completada, actualiza estadísticas
- eliminarTarea(): Borra de DB

Validaciones:
- UUID válido de usuario
- Nombre de tarea no vacío
- Estado válido (PENDIENTE, COMPLETADA, etc.)
```

**`ia.controller.ts` - Generación de Planes con IA**
```
Función principal: generarPlan()

Flujo:
1. Recibe parámetros: tema, fecha entrega, método, dificultad
2. Obtiene perfil del usuario (objetivo, nivel procrastinación)
3. Calcula horas disponibles basada en horarios
4. Calcula días restantes hasta entrega
5. Llama a gemini.service para generar plan
6. Inserta plan en tabla planes_estudio
7. Inserta datos de IA en tabla planes_ia
8. Guarda actividades y tareas generadas
9. Retorna plan completo al frontend
```

**`historial.controller.ts` - Historial de IA**
```
- obtenerHistorial(): Trae conversaciones previas con IA
- guardarInteraccion(): Registra pregunta/respuesta
- EliminarHistorial(): Limpia historial antiguo
```

**`horariosController.js` - Gestión de Horarios**
```
- crearHorario(): Define disponibilidad de estudio
- listarHorarios(): Obtiene horarios del usuario
- actualizarHorario(): Modifica disponibilidad
- eliminarHorario(): Borra horario
```

#### **🧠 SERVICIOS (Lógica Reutilizable) - `/src/services`**

**`gemini.service.ts` - Integración con IA Google Gemini**
```
Función: generarPlanIA()
- Toma entrada con: tema, objetivo, horas, días, dificultad
- Construye prompt detallado (sistema + usuario)
- Llama a Google Gemini con modelo gemini-1.5-pro
- Implementa retry automático con exponential backoff
- Si falla por sobrecarga (503), cambia a modelo fallback
- Parsea respuesta JSON
- Retorna estructura: PlanIA con métodos, duración, consejos, recursos

Función: evaluarExplicacionFeynmanIA()
- Evalúa si estudiante comprende un concepto
- Usa técnica Feynman (explicar con palabras simples)
- Retorna: {aprobado: boolean, mensaje: string}
```

**`historial.service.ts` - Gestión de Historial**
```
- guardarPreguntaRespuesta(): Registra en tabla historial_ia
- obtenerConversaciones(): Filtra por usuario/plan
- análisisPatrones(): Identifica patrones de estudio
```

#### **📋 PROMPTS - `/src/prompts`**

**`plan.prompt.ts` - Generación de Prompts para IA**
```
Función: construirPromptPlan()
- Toma datos de entrada (tema, objetivo, etc.)
- Construye prompt especializado para Gemini
- Formato: Sistema + Contexto + Instrucciones específicas
- Solicita respuesta en JSON estructurado

Ejemplo de prompt generado:
"Eres Lumi, tutora IA experta en educación.
El estudiante debe aprender: [tema]
Objetivo: [objetivo]
Disponibilidad: [horas] horas en [días] días
Método preferido: [método]
Genera plan detallado con:
- Estructura de estudio
- Actividades por día
- Recursos recomendados
- Consejos personalizados
Responde en JSON..."
```

#### **🔧 TIPOS - `/src/types`**

**`plan.types.ts` - Definiciones de Tipos TypeScript**
```
Interface PlanIA:
{
  metodo_estudio: string,
  justificacion: string,
  tiempo_estimado_total: number (minutos),
  estructura: string,
  consejos: string[],
  recursos: {nombre, enlace, descripcion}[],
  actividades: {dia, titulo, duracion, descripcion}[],
  resumen_final: string,
  dificultad: string
}

Permite tipado seguro en TypeScript
```

---

### 📱 FRONTEND (`/frontend`)

Aplicación móvil multiplataforma con Flutter/Dart.

#### **Archivos Configuración**

| Archivo | Propósito |
|---------|-----------|
| `pubspec.yaml` | Define dependencias Dart/Flutter, versiones, assets |
| `analysis_options.yaml` | Reglas de linting y calidad de código |
| `devtools_options.yaml` | Configuración de herramientas de debugging |

#### **`lib/main.dart`** - Punto de Entrada
```dart
Funciones:
✓ Inicializa Supabase (auth y BD en la nube)
✓ Configura tema oscuro (Color: #080D2B azul oscuro)
✓ Define rutas iniciales: /splash → /login → /configuracion
✓ Instancia MaterialApp con configuración global

Supabase:
- URL: https://lsbnizzypdmnvppatzxp.supabase.co
- Proporciona autenticación con JWT
- Base de datos PostgreSQL accesible
```

#### **🎨 PANTALLAS (Screens) - `/lib/screens`**

| Pantalla | Función |
|----------|---------|
| `splash_screen.dart` | Pantalla de carga inicial con logo |
| `login_screen.dart` | Autenticación de usuario (email + contraseña) |
| `register_screen.dart` | Registro de nueva cuenta |
| `olvidar_contraseña.dart` | Recuperación de contraseña (OTP) |
| `dashboard_screen.dart` | Pantalla principal con resumen de tareas/planes |
| `calendar_screen.dart` | Calendario interactivo (table_calendar) |
| `agregar_tarea_screen.dart` | Formulario para crear nueva tarea |
| `profile_screen.dart` | Perfil de usuario (datos, foto, objetivo) |
| `pomodoro_screen.dart` | Timer de Pomodoro (25 min estudio + 5 min descanso) |
| `feynman_screen.dart` | Herramienta Feynman (explicar conceptos) |
| `spaced_repetition_screen.dart` | Repetición espaciada de tarjetas |
| `active_recall_screen.dart` | Recuperación activa de memoria |
| `progreso_screen.dart` | Gráficos de progreso (tareas, horas, racha) |
| `recompensas_screen.dart` | Logros desbloqueados y puntos |
| `gamification_screen.dart` | Panel de gamificación (nivel, insignias) |
| `historial_ia_screen.dart` | Historial de conversaciones con IA |
| `guia_detalle_screen.dart` | Detalle de guía/plan generado |
| `seleccionar_metodo_screen.dart` | Selecciona método de estudio |
| `admin_panel_screen.dart` | Panel de administrador (gestión de usuarios) |
| `admin_user_list_screen.dart` | Listado de usuarios (admin) |
| `admin_user_detail_screen.dart` | Detalles de usuario (admin) |
| `configuracion_screen.dart` | Configuración de la app |

#### **📊 MODELOS (Models) - `/lib/models`**

**`user.dart`** - Modelo de Usuario
```dart
class Usuario {
  String id;
  String nombre;
  String apellido;
  String email;
  String fotoPerfil;
  int rolId;          // 1=Estudiante, 2=Admin
  bool esAdmin;
  DateTime fechaRegistro;
}
```

#### **🔧 SERVICIOS (Services) - `/lib/services`**

Servicios para comunicación con backend y Supabase:
- `auth.service.dart` - Autenticación
- `api.service.dart` - Llamadas HTTP al backend
- `supabase.service.dart` - Acceso a BD Supabase
- `tareas.service.dart` - Obtener/crear/actualizar tareas
- `planes.service.dart` - Interacción con planes de IA
- `historial.service.dart` - Historial de IA

#### **📱 Plataformas Nativas**

**Android** (`android/`)
- `build.gradle.kts` - Configuración Gradle
- Integración con Google Play Services
- Permisos: cámara, micrófono, ubicación

**iOS** (`ios/`)
- `AppDelegate.swift` - Punto de entrada nativo
- `Info.plist` - Configuración de app
- Permisos y capacidades de iOS

**Web** (`web/`)
- `index.html` - HTML base
- Soporta PWA (Progressive Web App)

**Windows, Linux, macOS** - Soporte multiplataforma

#### **🧪 Tests - `/test`**

```
- widget_test.dart - Tests de widgets Flutter
- calendar_screen_test.dart - Tests específicos de calendario
```

---

### 🗄️ BASE DE DATOS (`/basededatos/lumi.sql`)

Schema PostgreSQL alojado en Supabase.

#### **Tablas Principales**

**`usuarios`**
```sql
Campos:
- id (UUID): Identificador único (referencia auth.users de Supabase)
- nombre (VARCHAR): Nombre del estudiante
- apellido (VARCHAR): Apellido
- rol_id (INTEGER FK): Referencia a tabla roles (1=Estudiante, 2=Admin)
- fecha_registro (TIMESTAMP): Cuando se registró
- es_admin (BOOLEAN): Marca si es administrador
```

**`roles`**
```sql
- id (INTEGER PRIMARY KEY)
- nombre (VARCHAR UNIQUE): 'ESTUDIANTE', 'ADMINISTRADOR'
```

**`perfiles_estudio`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- usuario_id (UUID FK): Estudiante dueño del perfil
- horas_disponibles (INTEGER): Horas por semana para estudiar
- objetivo (TEXT): Objetivo académico (ej: "Aprobar Cálculo")
- nivel_procrastinacion (INTEGER): 1-5 (Bajo a Alto)
- foto_perfil (TEXT): URL de foto

Propósito: Almacenar preferencias personalizadas de estudio
```

**`planes_estudio`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- usuario_id (UUID FK): Estudiante
- nombre (VARCHAR): Nombre del plan (ej: "Cálculo Integral")
- descripcion (TEXT): Descripción del tema
- estado (VARCHAR): 'ACTIVO', 'COMPLETADO', 'PAUSADO'
- fecha_creacion (TIMESTAMP): Cuándo se creó

Propósito: Planes de estudio generados por IA
```

**`planes_ia`** (Detalles de planes generados por IA)
```sql
Campos:
- id (UUID PRIMARY KEY)
- plan_id (UUID FK UNIQUE): Referencia a planes_estudio
- proveedor_ia (VARCHAR): 'GEMINI'
- modelo_ia (VARCHAR): 'gemini-1.5-pro'
- metodo_estudio (TEXT): Método elegido (Pomodoro, Spaced Repetition)
- justificacion (TEXT): Por qué Gemini eligió este método
- tiempo_estimado_total (INTEGER): Minutos totales
- consejos (JSONB): Array de consejos personalizados
- recursos (JSONB): Array de recursos {nombre, enlace, descripcion}
- resumen_final (TEXT): Resumen del plan
- version (INTEGER): Versión del plan
- fecha_generacion (TIMESTAMP): Cuándo se generó
- dificultad (VARCHAR): 'Fácil', 'Media', 'Difícil'
- enfoque_adicional (TEXT): Enfoque personalizado

Propósito: Datos completos del plan generado por IA
```

**`actividades`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- plan_id (UUID FK): Dentro de qué plan
- titulo (VARCHAR): Nombre de actividad
- descripcion (TEXT): Detalles
- fecha (DATE): Día de la actividad
- estado (VARCHAR): 'PENDIENTE', 'EN_PROGRESO', 'COMPLETADA'

Propósito: Desglosar plan en actividades diarias
```

**`tareas`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- actividad_id (UUID FK): Dentro de qué actividad
- titulo (VARCHAR): Nombre de tarea
- descripcion (TEXT): Detalles
- completada (BOOLEAN): Completada o no

Propósito: Tareas individuales dentro de actividades
```

**`horarios`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- usuario_id (UUID FK): Estudiante dueño
- dia (VARCHAR): 'Lunes', 'Martes', etc.
- hora_inicio (TIME): Hora de inicio (ej: 14:00)
- hora_fin (TIME): Hora de fin (ej: 16:00)

Propósito: Disponibilidad de estudio del estudiante
```

**`historial_ia`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- usuario_id (UUID FK): Quién preguntó
- pregunta (TEXT): Pregunta del usuario
- respuesta (TEXT): Respuesta de Gemini
- fecha (TIMESTAMP): Cuándo fue
- plan_id (UUID FK): Plan relacionado

Propósito: Registro de todas las interacciones con IA
```

**`estadisticas`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- usuario_id (UUID FK): Estudiante
- tareas_completadas (INTEGER): Total de tareas completadas
- horas_estudio (NUMERIC): Horas totales estudiadas
- racha (INTEGER): Días consecutivos estudiando

Propósito: Gamificación y seguimiento de rendimiento
```

**`recompensas`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- nombre (VARCHAR): 'Primer Día', 'Una Semana de Racha'
- descripcion (TEXT): Descripción del logro
- puntos (INTEGER): Puntos otorgados

Propósito: Definición de recompensas disponibles
```

**`usuario_recompensa`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- usuario_id (UUID FK): Estudiante
- recompensa_id (UUID FK): Recompensa desbloqueada

Propósito: Vincular recompensas desbloqueadas a usuarios
```

**`notificaciones`**
```sql
Campos:
- id (UUID PRIMARY KEY)
- usuario_id (UUID FK): Destinatario
- mensaje (TEXT): Contenido de la notificación
- leida (BOOLEAN): Leída o no
- fecha (TIMESTAMP): Cuándo se creó

Propósito: Sistema de notificaciones push
```

**`metodos_estudio`**
```sql
Campos:
- id (INTEGER PRIMARY KEY)
- nombre (VARCHAR UNIQUE): 'Pomodoro', 'Spaced Repetition', etc.
- descripcion (TEXT): Explicación del método

Propósito: Catálogo de métodos de estudio disponibles
```

---

## 🔄 Flujos de Datos Principales

### 1️⃣ **Flujo de Autenticación**

```
Usuario escribe email + contraseña en LoginScreen
        ↓
Frontend valida formato (email válido)
        ↓
POST /api/auth/login → Backend
        ↓
Backend valida credenciales en Supabase
        ↓
Supabase devuelve JWT token
        ↓
Frontend almacena token localmente
        ↓
Frontend navega a Dashboard
```

### 2️⃣ **Flujo de Generación de Plan de Estudio**

```
Usuario en SeleccionarMetodoScreen ingresa:
- Tema a estudiar
- Fecha de entrega
- Método preferido
- Nivel de dificultad
        ↓
Frontend: POST /api/ia/generar-plan
        ↓
Backend iaController.generarPlan():
  1. Obtiene perfil del usuario (objetivo, procrastinación)
  2. Consulta horarios disponibles → calcula horas/semana
  3. Calcula días restantes hasta entrega
        ↓
gemini.service.ts:
  1. Construye prompt detallado con contexto del usuario
  2. Llama a Google Gemini API con gemini-1.5-pro
  3. Si falla (503/429), intenta con gemini-1.5-flash
  4. Retry automático con exponential backoff
  5. Parsea respuesta JSON
        ↓
Backend guarda en BD:
  1. Inserta en planes_estudio
  2. Inserta en planes_ia (detalles)
  3. Crea actividades por día
  4. Crea tareas dentro de actividades
        ↓
Frontend recibe plan completo
        ↓
Muestra en GuiaDetalleScreen con estructura detallada
```

### 3️⃣ **Flujo de Gestión de Tareas**

```
Usuario en Dashboard ve lista de tareas
        ↓
Click en "Agregar Tarea" → AgregarTareaScreen
        ↓
Ingresa: nombre, descripción, fecha entrega
        ↓
POST /api/tareas → Backend
        ↓
tareas.controller.ts:
  1. Normaliza payload (valida tipos)
  2. Valida UUID de usuario
  3. Inserta en tabla tareas
  4. Retorna tarea creada
        ↓
Frontend actualiza lista local
        ↓
Usuario puede: ver, editar, marcar completada, eliminar
```

### 4️⃣ **Flujo de Técnica Feynman**

```
Usuario en FeynmanScreen ingresa concepto y explicación
        ↓
POST /api/ia/evaluar-feynman
        ↓
gemini.service.ts.evaluarExplicacionFeynmanIA():
  Llama a Gemini con prompt:
  "Evalúa si esta explicación demuestra comprensión real"
        ↓
Gemini retorna: {aprobado: boolean, mensaje: string}
        ↓
Frontend muestra resultado y retroalimentación
```

### 5️⃣ **Flujo de Gamificación**

```
Usuario completa tarea
        ↓
Frontend: PATCH /api/tareas/:id/completar
        ↓
Backend:
  1. Marca tarea como completada
  2. Incrementa tareas_completadas en estadísticas
  3. Verifica logros desbloqueados
  4. Si racha alcanza milestone, crea notificación
        ↓
Frontend actualiza:
  - Contador de tareas
  - Horas de estudio
  - Racha
  - Insignias
```

---

## 🛠️ Tecnologías y Dependencias

### Frontend (Flutter/Dart)

| Dependencia | Propósito |
|------------|-----------|
| `flutter` | Framework UI multiplataforma |
| `supabase_flutter` | Autenticación y BD en tiempo real |
| `google_fonts` | Tipografías Google personalizadas |
| `local_auth` | Autenticación biométrica (huella, cara) |
| `http` | Llamadas HTTP al backend |
| `intl` | Internacionalización (idiomas, fechas) |
| `image_picker` | Seleccionar foto de perfil |
| `table_calendar` | Widget calendario interactivo |
| `cupertino_icons` | Iconos iOS |

### Backend (Node.js/TypeScript)

| Dependencia | Propósito |
|------------|-----------|
| `express` | Framework web HTTP |
| `typescript` | Lenguaje tipado |
| `pg` | Driver PostgreSQL |
| `postgres` | Driver PostgreSQL alternativo |
| `@google/genai` | SDK de Google Gemini AI |
| `bcrypt` | Hash de contraseñas seguro |
| `cors` | Permitir requests desde frontend |
| `multer` | Manejo de upload de archivos |
| `dotenv` | Variables de entorno (.env) |
| `tsx` | Ejecutor TypeScript en desarrollo |

---

## 🎯 Funcionalidades Principales de LumiIa

### ✅ **Autenticación y Perfiles**
- Registro con email verificado
- Login con JWT
- Recuperación de contraseña
- Autenticación biométrica (huella, facial)
- Perfiles personalizados con objetivo y horas disponibles

### 📚 **Generación de Planes de Estudio**
- Crear plan para cualquier tema
- IA genera estructura personalizada
- Basado en: nivel de procrastinación, horas disponibles, fecha límite
- Retorna: cronograma, recursos, consejos personalizados

### 📅 **Gestión de Tareas y Horarios**
- Crear, editar, completar, eliminar tareas
- Definir horarios disponibles de estudio
- Vincular tareas a planes/actividades

### 🧠 **Técnicas de Aprendizaje**
- **Pomodoro Timer**: Ciclos de estudio/descanso
- **Spaced Repetition**: Repaso automático
- **Feynman Technique**: Explicar para aprender
- **Active Recall**: Pruebas de conocimiento

### 📊 **Seguimiento y Estadísticas**
- Horas de estudio totales
- Tareas completadas
- Racha de días consecutivos
- Gráficos de progreso

### 🎮 **Gamificación**
- Sistema de puntos
- Insignias y logros
- Recompensas desbloqueables
- Competencia (futura)

### 💬 **Historial de IA**
- Registro de conversaciones con Gemini
- Búsqueda de interacciones previas
- Vinculadas a planes específicos

### 👨‍💼 **Panel de Administrador**
- Ver todos los usuarios
- Editar/eliminar usuarios
- Ver estadísticas globales
- Gestionar roles

---

## 🚀 Cómo Funciona Todo Junto

### Caso de Uso: Estudiante estudia Cálculo

```
1. Usuario abre app → Splash screen → Login

2. Ingresa a Dashboard, ve:
   - Tareas pendientes
   - Planes activos
   - Estadísticas (racha, horas)
   - Logros desbloqueados

3. Click "Nuevo Plan" → Ingresa:
   - Tema: "Derivadas en Cálculo"
   - Fecha entrega: en 7 días
   - Nivel: Medio
   - Método: Pomodoro

4. Frontend POST /api/ia/generar-plan

5. Backend:
   - Lee perfil: "Objetivo: Ing. en Sistemas, 2h/día disponibles"
   - Lee horarios: 14:00-16:00 = 2 horas/día
   - Calcula: 7 días × 2 horas = 14 horas disponibles
   - Construye prompt para Gemini

6. Gemini genera plan:
   {
     "metodo": "Pomodoro (25min estudio + 5min descanso)",
     "tiempo_total": 840 minutos (14 horas),
     "estructura": "Día 1: Conceptos básicos, Día 2: Derivadas...",
     "consejos": ["Practica ejercicios", "Revisa errores"],
     "recursos": [{"nombre": "Khan Academy", "url": "..."}]
   }

7. Backend guarda en BD (planes_estudio, planes_ia, actividades)

8. Frontend muestra GuiaDetalleScreen:
   ┌─────────────────────────────┐
   │ Derivadas en Cálculo        │
   │ 14 horas totales            │
   │ Pomodoro Method             │
   ├─────────────────────────────┤
   │ Día 1: Conceptos Básicos    │
   │ ├─ Tarea 1: Definición      │
   │ ├─ Tarea 2: Ejemplos        │
   │ └─ Tarea 3: Ejercicios      │
   │ Día 2: Derivadas...         │
   └─────────────────────────────┘

9. Usuario estudia:
   - Abre Pomodoro Timer (25 min)
   - Marca tarea como completada
   - Backend incrementa tareas_completadas
   - Si alcanza 5 tareas → Gana recompensa
   - Racha se incrementa

10. Si duda, usa Feynman:
    - Ingresa concepto
    - Escribe explicación
    - Gemini evalúa
    - Recibe feedback

11. Después de 7 días:
    - Todas las tareas completadas
    - Plan cambia a "COMPLETADO"
    - Desbloq recompensa "Experto en Derivadas"
    - Gana 100 puntos
```

---

## 📝 Archivos Importantes por Categoría

### 🔐 Autenticación
- `backend/src/rutas/authRoutes.ts`
- `frontend/lib/screens/login_screen.dart`
- `frontend/lib/screens/register_screen.dart`
- `frontend/lib/screens/olvidar_contraseña.dart`

### 🤖 Generación de Planes (IA)
- `backend/src/controllers/ia.controller.ts`
- `backend/src/services/gemini.service.ts`
- `backend/src/prompts/plan.prompt.ts`
- `backend/src/types/plan.types.ts`
- `backend/src/config/ia/gemini.config.ts`

### ✅ Tareas
- `backend/src/controllers/tareas.controller.ts`
- `backend/src/rutas/tareas.routes.ts`
- `frontend/lib/screens/agregar_tarea_screen.dart`
- `frontend/lib/screens/dashboard_screen.dart`

### 📅 Horarios
- `backend/src/controllers/horariosController.js`
- `backend/src/rutas/horarios.routes.js`
- `frontend/lib/screens/calendar_screen.dart`

### 🎮 Gamificación
- `frontend/lib/screens/gamification_screen.dart`
- `frontend/lib/screens/recompensas_screen.dart`
- `frontend/lib/screens/progreso_screen.dart`
- `basededatos/lumi.sql` (tablas: estadísticas, recompensas)

### 🧠 Técnicas de Aprendizaje
- `frontend/lib/screens/pomodoro_screen.dart`
- `frontend/lib/screens/feynman_screen.dart`
- `frontend/lib/screens/spaced_repetition_screen.dart`
- `frontend/lib/screens/active_recall_screen.dart`

### 👤 Perfil y Configuración
- `frontend/lib/screens/profile_screen.dart`
- `frontend/lib/screens/configuracion_screen.dart`
- `basededatos/lumi.sql` (tabla: perfiles_estudio)

### 👨‍💼 Admin
- `backend/src/rutas/adminRoutes.ts`
- `frontend/lib/screens/admin_panel_screen.dart`
- `frontend/lib/screens/admin_user_list_screen.dart`
- `frontend/lib/screens/admin_user_detail_screen.dart`

### 💾 Base de Datos
- `basededatos/lumi.sql` - Schema completo PostgreSQL

---

## ⚠️ Notas Técnicas Importantes

### 🔴 Puntos de Atención

1. **Typo en nombre de archivo**
   - `READNE.md` (debería ser `README.md`)
   - Fácil de corregir

2. **Mezcla de JavaScript y TypeScript en Backend**
   - `horariosController.js` (JavaScript)
   - Resto en `.ts` (TypeScript)
   - Recomendación: Estandarizar a TypeScript

3. **Posibles Duplicados en Rutas**
   - `horarios.routes.js` y `horarios.ts`
   - Revisar cuál se usa realmente

4. **Documentación Incompleta en README.md**
   - El main README menciona PostgreSQL
   - Pero también hay referencias a MySQL
   - Aclarar: ¿PostgreSQL vía Supabase o MySQL local?

5. **Archivo profile_screen.dart Vacío**
   - Solo contiene: `// TODO Implement this library.`
   - Necesita implementación

6. **Dependencias de IA**
   - Google Gemini API requiere API key válida
   - Variable `GOOGLE_API_KEY` en `.env`
   - Sin esto, no funciona generación de planes

---

## 🎓 Resumen Ejecutivo

**LumiIa** es una **plataforma educativa basada en IA** que:

- 🎯 **Ayuda a estudiantes** a aprender de forma más eficiente
- 🤖 **Genera planes personalizados** usando Google Gemini
- 📱 **Funciona en múltiples plataformas** (iOS, Android, Web, etc.)
- 🧠 **Enseña técnicas científicas** de aprendizaje (Pomodoro, Spaced Repetition, Feynman)
- 🎮 **Gamifica** el proceso con puntos, insignias y rachas
- 📊 **Rastrea progreso** con estadísticas detalladas
- ☁️ **Usa tecnología cloud** (Supabase para BD, Google Gemini para IA)

Es una **solución integral** para transformar malos hábitos de estudio en prácticas efectivas y sostenibles.

---

**Última actualización**: 2026-09-01  
**Documento**: Explicación Completa de LumiIa  
**Autor**: GitHub Copilot
