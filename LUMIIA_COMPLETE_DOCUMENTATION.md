# 📊 DIAGRAMAS Y ARQUITECTURA - PROYECTO LUMIIA

---

## 🏗️ ARQUITECTURA GENERAL DEL SISTEMA

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                         CLIENTE (Navegador / App Móvil)                        │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │                    FRONTEND - Flutter / Web (JavaScript)                   │ │
│  │                                                                            │ │
│  │  • iOS (Cocoa/Swift)    • Android (Kotlin/Java)                           │ │
│  │  • Web (HTML5/CSS)      • Windows (C++)                                   │ │
│  │  • Linux (GTK)          • macOS (Cocoa/Swift)                             │ │
│  │                                                                            │ │
│  │  Pantallas:                                                               │ │
│  │  ├─ Login / Register / Forgot Password                                   │ │
│  │  ├─ Dashboard (Tareas, Planes)                                           │ │
│  │  ├─ Crear/Editar Tareas                                                  │ │
│  │  ├─ Calendario                                                            │ │
│  │  ├─ Técnicas: Pomodoro, Feynman, Spaced Repetition                       │ │
│  │  ├─ Gamificación (Puntos, Insignias, Racha)                              │ │
│  │  ├─ Historial IA                                                          │ │
│  │  ├─ Perfil de Usuario                                                     │ │
│  │  └─ Panel Admin (si es admin)                                             │ │
│  │                                                                            │ │
│  │  Auth: Supabase (JWT)                                                    │ │
│  │  State Management: GetX / Provider / Riverpod                            │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                     │                                            │
│                                     │ HTTP/REST                                 │
│                                     │ (JSON)                                    │
│                                     ↓                                            │
└────────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │
┌────────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET / CLOUD                                  │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │                   🔐 SUPABASE (Auth + PostgreSQL)                         │ │
│  │                   URL: https://lsbnizzypdmnvppatzxp.supabase.co           │ │
│  │                                                                            │ │
│  │  • Autenticación JWT                                                      │ │
│  │  • Base de Datos PostgreSQL                                               │ │
│  │  • Real-time Subscriptions                                                │ │
│  │  • Storage de archivos                                                    │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌───────────────────────────────────────────────────────────────────────────┐ │
│  │                   🤖 GOOGLE GEMINI API                                     │ │
│  │                   (Generación de Planes, Evaluación)                      │ │
│  │                                                                            │ │
│  │  • Modelo: gemini-1.5-pro (principal)                                    │ │
│  │  • Fallback: gemini-1.5-flash                                             │ │
│  │  • Retry automático con exponential backoff                               │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
└────────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ SQL Queries
                                     │ API Calls
                                     ↓
┌────────────────────────────────────────────────────────────────────────────────┐
│                          BACKEND - Node.js/Express                             │
│                     (TypeScript en src/, JavaScript en dist/)                  │
│                                                                                 │
│  Servidor en: http://localhost:3000 (Puerto 3000)                            │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                          RUTAS API                                       │  │
│  │                                                                          │  │
│  │  POST   /api/auth/register         → Registrar usuario                 │  │
│  │  POST   /api/auth/login            → Login                             │  │
│  │  POST   /api/auth/logout           → Logout                            │  │
│  │                                                                          │  │
│  │  POST   /api/tareas                → Crear tarea                       │  │
│  │  GET    /api/tareas                → Listar tareas                     │  │
│  │  PUT    /api/tareas/:id            → Editar tarea                      │  │
│  │  DELETE /api/tareas/:id            → Eliminar tarea                    │  │
│  │  PATCH  /api/tareas/:id/completar  → Marcar completada                │  │
│  │                                                                          │  │
│  │  POST   /api/horarios              → Crear horario                     │  │
│  │  GET    /api/horarios              → Listar horarios                   │  │
│  │  PUT    /api/horarios/:id          → Editar horario                    │  │
│  │  DELETE /api/horarios/:id          → Eliminar horario                  │  │
│  │                                                                          │  │
│  │  POST   /api/ia/generar-plan       → Generar plan (Gemini)            │  │
│  │  POST   /api/ia/evaluar-feynman    → Evaluar Feynman                  │  │
│  │  POST   /api/ia/preguntar          → Hacer pregunta a IA              │  │
│  │                                                                          │  │
│  │  GET    /api/ia/historial          → Obtener historial                │  │
│  │  GET    /api/ia/historial/:id      → Historial por plan               │  │
│  │  DELETE /api/ia/historial/:id      → Eliminar entrada                 │  │
│  │                                                                          │  │
│  │  GET    /api/admin/usuarios        → Listar usuarios (Admin)          │  │
│  │  GET    /api/admin/usuarios/:id    → Detalles usuario (Admin)         │  │
│  │  PUT    /api/admin/usuarios/:id    → Editar usuario (Admin)           │  │
│  │  DELETE /api/admin/usuarios/:id    → Eliminar usuario (Admin)         │  │
│  │  GET    /api/admin/estadisticas    → Estadísticas globales            │  │
│  │                                                                          │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
│                                     │                                           │
│  ┌─────────────────────────────────┼───────────────────────────────────────┐  │
│  │ CONTROLADORES                   │  SERVICIOS                            │  │
│  │                                 │                                        │  │
│  │ • authController.ts             │ • gemini.service.ts                  │  │
│  │ • tareas.controller.ts          │ • historial.service.ts               │  │
│  │ • horariosController.js         │ • auth.service.ts                    │  │
│  │ • ia.controller.ts              │                                        │  │
│  │ • historial.controller.ts       │ CONFIGURACIÓN                         │  │
│  │                                 │                                        │  │
│  │                                 │ • db.ts (Pool PostgreSQL)            │  │
│  │                                 │ • gemini.config.ts (API Key)         │  │
│  │                                 │                                        │  │
│  └─────────────────────────────────┴────────────────────────────────────────┘  │
│                                                                                 │
└────────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ TCP/IP (Puerto 5432)
                                     ↓
┌────────────────────────────────────────────────────────────────────────────────┐
│                      🗄️  BASE DE DATOS - PostgreSQL                            │
│                          (Alojado en Supabase Cloud)                           │
│                                                                                 │
│  Tablas Principales:                                                          │
│  ├─ usuarios              (id, nombre, email, rol_id, es_admin)              │
│  ├─ roles                 (id, nombre: 'ESTUDIANTE', 'ADMIN')               │
│  ├─ perfiles_estudio      (usuario_id, horas, objetivo, procrastinación)    │
│  ├─ planes_estudio        (id, usuario_id, nombre, estado)                   │
│  ├─ planes_ia             (plan_id, método, tiempo, consejos, recursos)     │
│  ├─ actividades           (plan_id, titulo, fecha, estado)                   │
│  ├─ tareas                (actividad_id, titulo, completada)                 │
│  ├─ horarios              (usuario_id, dia, hora_inicio, hora_fin)          │
│  ├─ historial_ia          (usuario_id, pregunta, respuesta, fecha)          │
│  ├─ estadisticas          (usuario_id, tareas_completadas, horas, racha)    │
│  ├─ recompensas           (id, nombre, descripcion, puntos)                  │
│  ├─ usuario_recompensa    (usuario_id, recompensa_id)                        │
│  ├─ notificaciones        (usuario_id, mensaje, leida, fecha)                │
│  └─ metodos_estudio       (id, nombre, descripcion)                          │
│                                                                                 │
│  Conexión: Pool de 10-20 conexiones reutilizables                            │
│                                                                                 │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🤖 FLUJO DE IA - Integración Gemini

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                  USUARIO SOLICITA GENERAR PLAN DE ESTUDIO                   │
│                                                                             │
│  Pantalla: SeleccionarMetodoScreen                                         │
│  Ingresa:                                                                   │
│  • Tema/Asignatura: "Derivadas en Cálculo"                                 │
│  • Fecha de entrega: "15 de septiembre"                                    │
│  • Método preferido: "Pomodoro"                                            │
│  • Nivel de dificultad: "Media"                                            │
│  • Horas disponibles: "2 horas/día"                                        │
│  • Procrastinación: "Nivel 3/5"                                            │
│                                                                             │
└────────────┬──────────────────────────────────────────────────────────────┘
             │
             │ POST /api/ia/generar-plan
             │ Body: {usuario_id, nombre, descripcion, fecha_entrega,
             │        metodo_estudio, dificultad, enfoque_adicional}
             ↓
┌────────────────────────────────────────────────────────────────────────────┐
│                   BACKEND - ia.controller.generarPlan()                    │
│                                                                            │
│  1. Valida datos obligatorios:                                            │
│     ✓ usuario_id existe                                                   │
│     ✓ nombre no vacío                                                     │
│     ✓ fecha_entrega es válida                                             │
│                                                                            │
│  2. Consulta perfil del usuario:                                          │
│     SELECT u.nombre, p.objetivo, p.nivel_procrastinacion                 │
│     FROM usuarios u LEFT JOIN perfiles_estudio p ON ...                  │
│                                                                            │
│  3. Calcula disponibilidad de tiempo:                                     │
│     SELECT dia, hora_inicio, hora_fin FROM horarios WHERE usuario_id=... │
│     Resultado: 2 horas/día × 7 días = 14 horas totales = 840 minutos     │
│                                                                            │
│  4. Calcula días restantes:                                               │
│     diasRestantes = (fecha_entrega - hoy) / 86400 segundos                │
│     Resultado: 7 días                                                      │
│                                                                            │
│  5. Construye datos contextuales:                                         │
│     {                                                                      │
│       titulo: "Derivadas en Cálculo",                                     │
│       descripcion: "...",                                                 │
│       fechaEntrega: "2026-09-15",                                         │
│       metodoEstudio: "Pomodoro",                                          │
│       dificultad: "Media",                                                │
│       nombreUsuario: "Sofia",                                             │
│       objetivo: "Ing. en Sistemas",                                       │
│       horasDisponibles: 14,                                               │
│       diasRestantes: 7,                                                   │
│       minutosDisponibles: 840,                                            │
│       nivelProcrastinacion: 3,                                            │
│       enfoqueAdicional: ""                                                │
│     }                                                                      │
│                                                                            │
└────────────┬──────────────────────────────────────────────────────────────┘
             │
             │ Llama a gemini.service.generarPlanIA(datos)
             ↓
┌────────────────────────────────────────────────────────────────────────────┐
│             BACKEND - gemini.service.generarPlanIA()                       │
│                                                                            │
│  1. Construye PROMPT estructurado:                                        │
│                                                                            │
│     SYSTEM PROMPT:                                                        │
│     "Eres Mumi, una tutora IA especialista en educación..."              │
│     "Debes generar planes de estudio personalizados..."                  │
│     "La respuesta debe ser JSON válido sin markdown..."                  │
│                                                                            │
│     USER PROMPT:                                                          │
│     "Por favor, crea un plan para:                                        │
│      - Estudiante: Sofia                                                 │
│      - Objetivo: Ing. en Sistemas                                        │
│      - Tema: Derivadas en Cálculo                                        │
│      - Disponibilidad: 14 horas en 7 días (2 horas/día)                 │
│      - Procrastinación: Nivel 3/5                                        │
│      - Método preferido: Pomodoro                                        │
│      - Dificultad: Media                                                 │
│                                                                            │
│      Retorna estructura:                                                 │
│      {                                                                    │
│        metodo_estudio: string,                                           │
│        justificacion: string,                                            │
│        tiempo_estimado_total: number,                                    │
│        estructura: string,                                               │
│        consejos: string[],                                               │
│        recursos: {nombre, enlace}[],                                     │
│        resumen_final: string                                             │
│      }"                                                                   │
│                                                                            │
│  2. LLama a Google Gemini API:                                            │
│                                                                            │
│     POST https://generativelanguage.googleapis.com/v1beta/models/...     │
│     Headers:                                                              │
│       x-goog-api-key: ${GOOGLE_API_KEY}                                  │
│       Content-Type: application/json                                      │
│                                                                            │
│     Body:                                                                 │
│     {                                                                     │
│       "model": "gemini-1.5-pro",                                         │
│       "contents": [{role: "user", parts: [{text: prompt}]}],            │
│       "config": {                                                         │
│         "temperature": 0.2,  ← Bajo: respuestas consistentes             │
│         "responseMimeType": "application/json"  ← Esperamos JSON         │
│       }                                                                    │
│     }                                                                      │
│                                                                            │
│  3. RETRY AUTOMÁTICO con Exponential Backoff:                            │
│                                                                            │
│     if (response.status === 503 || response.status === 429) {            │
│       // Gemini está saturado o rate limited                            │
│       espera = esperaMs * 2  (duplica tiempo de espera)                  │
│       intenta con fallback: gemini-1.5-flash                             │
│       reintenta con nuevo modelo                                          │
│     }                                                                      │
│                                                                            │
│     Intentos: 3                                                           │
│     Tiempo inicial: 1000ms                                                │
│     Máximo: 4 segundos                                                    │
│                                                                            │
│  4. Parsea respuesta JSON:                                                │
│                                                                            │
│     response.text:                                                        │
│     "```json                                                              │
│     {                                                                      │
│       "metodo_estudio": "Pomodoro",                                      │
│       "justificacion": "Ideal para procrastinadores...",                │
│       "tiempo_estimado_total": 840,                                       │
│       "estructura": "Día 1: Conceptos básicos...",                       │
│       "consejos": ["Practica ejercicios...", "Revisa errores..."],       │
│       "recursos": [                                                       │
│         {nombre: "Khan Academy", enlace: "..."}                          │
│       ],                                                                   │
│       "resumen_final": "Plan personalizado..."                           │
│     }                                                                      │
│     ```"                                                                   │
│                                                                            │
│     Limpieza: Remove ```json markers                                      │
│     JSON.parse(texto limpio)                                              │
│                                                                            │
│  5. Valida estructura:                                                    │
│                                                                            │
│     if (!plan.metodo_estudio || !plan.estructura) {                       │
│       throw new Error("Gemini devolvió JSON inválido")                   │
│     }                                                                      │
│                                                                            │
│  6. Retorna PlanIA al controlador:                                        │
│                                                                            │
│     return {                                                              │
│       metodo_estudio: "Pomodoro",                                         │
│       justificacion: "...",                                               │
│       tiempo_estimado_total: 840,                                         │
│       ...                                                                  │
│     }                                                                      │
│                                                                            │
└────────────┬──────────────────────────────────────────────────────────────┘
             │ Retorna PlanIA
             ↓
┌────────────────────────────────────────────────────────────────────────────┐
│         BACKEND - ia.controller.generarPlan() continúa...                 │
│                                                                            │
│  6. Guarda plan en transacción SQL:                                       │
│                                                                            │
│     BEGIN TRANSACTION                                                     │
│                                                                            │
│     a) INSERT INTO planes_estudio:                                        │
│        INSERT INTO planes_estudio                                         │
│        (usuario_id, nombre, descripcion, estado)                          │
│        VALUES ($1, $2, $3, 'ACTIVO')                                      │
│        RETURNING id;  ← plan_id                                           │
│                                                                            │
│     b) INSERT INTO planes_ia:                                             │
│        INSERT INTO planes_ia                                              │
│        (plan_id, proveedor_ia, modelo_ia, metodo_estudio,               │
│         justificacion, tiempo_estimado_total, consejos, recursos,        │
│         resumen_final, dificultad, enfoque_adicional)                   │
│        VALUES ($1, 'GEMINI', 'gemini-1.5-pro', ...)                      │
│                                                                            │
│     c) Parsea estructura y crea ACTIVIDADES:                              │
│        FOR cada día en diasRestantes:                                     │
│          INSERT INTO actividades                                          │
│          (plan_id, titulo, descripcion, fecha, estado)                   │
│          VALUES (plan_id, "Día N: ...", "...", fecha, 'PENDIENTE')      │
│                                                                            │
│     d) Crea TAREAS dentro de cada ACTIVIDAD:                              │
│        FOR cada tarea en descripción:                                     │
│          INSERT INTO tareas                                               │
│          (actividad_id, titulo, descripcion, completada)                 │
│          VALUES (actividad_id, "...", "...", false)                      │
│                                                                            │
│     COMMIT TRANSACTION                                                    │
│                                                                            │
│  7. Retorna plan completo al frontend:                                    │
│                                                                            │
│     {                                                                      │
│       statusCode: 200,                                                    │
│       mensaje: "Plan generado exitosamente",                             │
│       plan: {                                                             │
│         id: "uuid-plan",                                                 │
│         nombre: "Derivadas en Cálculo",                                  │
│         metodo: "Pomodoro",                                              │
│         tiempo_total: 840,                                               │
│         estructura: "Día 1: ..., Día 2: ..., ...",                       │
│         consejos: [...],                                                 │
│         recursos: [...],                                                 │
│         actividades: [                                                    │
│           {id, dia, tareas: [...]},                                      │
│           {id, dia, tareas: [...]}                                       │
│         ]                                                                  │
│       }                                                                    │
│     }                                                                      │
│                                                                            │
└────────────┬──────────────────────────────────────────────────────────────┘
             │ HTTP 200 OK + JSON
             ↓
┌─────────────────────────────────────────────────────────────────────────────┐
│                  FRONTEND - Recibe y muestra plan                           │
│                                                                             │
│  1. Parsea respuesta JSON                                                 │
│  2. Almacena en estado global (GetX, Provider, etc.)                      │
│  3. Navega a GuiaDetalleScreen                                            │
│  4. Muestra:                                                               │
│                                                                             │
│     ╔════════════════════════════════════════════════╗                    │
│     ║      Derivadas en Cálculo                      ║                    │
│     ║      Método: Pomodoro                          ║                    │
│     ║      Tiempo: 14 horas en 7 días                ║                    │
│     ╠════════════════════════════════════════════════╣                    │
│     ║ Día 1: Conceptos Básicos                       ║                    │
│     ║ ├─ [  ] Definición de derivada                 ║                    │
│     ║ ├─ [  ] Ejemplos prácticos                     ║                    │
│     ║ └─ [  ] Ejercicios del libro                   ║                    │
│     ║                                                 ║                    │
│     ║ Día 2: Derivadas de Funciones Polinomiales     ║                    │
│     ║ ├─ [  ] Regla de la potencia                   ║                    │
│     ║ ├─ [  ] Aplicaciones                           ║                    │
│     ║ └─ [  ] Problemas resueltos                    ║                    │
│     ║                                                 ║                    │
│     ║ ... más días ...                               ║                    │
│     ╠════════════════════════════════════════════════╣                    │
│     ║ Consejos:                                      ║                    │
│     ║ • Practica ejercicios regularmente              ║                    │
│     ║ • Haz pausas cada 25 minutos                   ║                    │
│     ║ • Repasa conceptos previos si es necesario      ║                    │
│     ╠════════════════════════════════════════════════╣                    │
│     ║ Recursos:                                      ║                    │
│     ║ • Khan Academy: derivadas...                   ║                    │
│     ║ • YouTube: tutoriales...                       ║                    │
│     ╚════════════════════════════════════════════════╝                    │
│                                                                             │
│  5. Usuario puede:                                                        │
│     ✓ Ver detalles de cada día/tarea                                     │
│     ✓ Marcar tareas como completadas                                     │
│     ✓ Usar timer de Pomodoro integrado                                   │
│     ✓ Hacer preguntas a IA sobre el tema                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔐 FLUJO DE AUTENTICACIÓN

```
┌──────────────────────────────────────────────────────────────────────┐
│              PANTALLA LOGIN (frontend/lib/screens/login_screen.dart)  │
│                                                                       │
│   ╔════════════════════════════════════════════════════════╗         │
│   ║      LUMI - Inicia Sesión                             ║         │
│   ╠════════════════════════════════════════════════════════╣         │
│   ║  Email/Usuario:  [_______________________________]     ║         │
│   ║  Contraseña:     [_______________________________]     ║         │
│   ║                                                        ║         │
│   ║  [ Inicio de Sesión ]  [ ¿Olvidaste contraseña? ]    ║         │
│   ║                                                        ║         │
│   ║  ¿No tienes cuenta? [ Registrate ]                    ║         │
│   ╚════════════════════════════════════════════════════════╝         │
│                                                                       │
│  Usuario ingresa:                                                   │
│  • Email: sofia@example.com                                         │
│  • Contraseña: ******* (hasheada en tránsito)                       │
│                                                                       │
└────────────┬──────────────────────────────────────────────────────────┘
             │ Click "Inicio de Sesión"
             ↓
┌──────────────────────────────────────────────────────────────────────┐
│            FRONTEND - auth.service.dart (Supabase)                  │
│                                                                       │
│  Function: loginWithEmail(email, password)                          │
│                                                                       │
│  1. Validaciones locales:                                           │
│     ✓ Email no vacío y formato válido (regex)                       │
│     ✓ Contraseña no vacía y >= 6 caracteres                         │
│                                                                       │
│  2. Llamada a Supabase:                                             │
│                                                                       │
│     final response = await supabase.auth.signInWithPassword(        │
│       email: 'sofia@example.com',                                   │
│       password: 'password123'                                       │
│     );                                                               │
│                                                                       │
│  3. Supabase Auth (en la nube):                                     │
│     POST https://lsbnizzypdmnvppatzxp.supabase.co/auth/v1/token    │
│                                                                       │
│     Headers:                                                         │
│       Content-Type: application/json                                │
│       apikey: sb_publishable_KK0lsvy3EBB8WuHVg2zOiA_WOeJs6RZ       │
│                                                                       │
│     Body:                                                            │
│     {                                                                │
│       "email": "sofia@example.com",                                 │
│       "password": "password123"                                     │
│     }                                                                │
│                                                                       │
│  4. Validación en Supabase:                                         │
│     • Busca usuario en tabla auth.users                            │
│     • Compara password hasheada con argon2                         │
│     • Si coincide: genera JWT token                                │
│     • Si no coincide: retorna error 401                            │
│                                                                       │
│  5. Respuesta Supabase (Exitosa):                                  │
│     {                                                                │
│       "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",  │
│       "token_type": "bearer",                                       │
│       "expires_in": 3600,                                           │
│       "expires_at": 1234567890,                                     │
│       "refresh_token": "refresh_token_value",                       │
│       "user": {                                                      │
│         "id": "uuid-user-123",                                      │
│         "email": "sofia@example.com",                              │
│         "aud": "authenticated",                                     │
│         "created_at": "2026-01-01T10:00:00.000Z",                 │
│         "updated_at": "2026-09-01T14:30:00.000Z"                  │
│       }                                                              │
│     }                                                                │
│                                                                       │
│  6. Frontend guarda token:                                          │
│     • Token en memoria (session)                                    │
│     • Refresh token en Secure Storage (encriptado)                 │
│     • User info en Supabase Auth State                              │
│                                                                       │
│  7. Si error:                                                        │
│     • Email no existe: "User not found"                            │
│     • Contraseña incorrecta: "Invalid login credentials"            │
│     • Email no verificado: "Email not verified"                     │
│                                                                       │
└────────────┬──────────────────────────────────────────────────────────┘
             │ Si exitoso: Token JWT + User ID
             ↓
┌──────────────────────────────────────────────────────────────────────┐
│        FRONTEND - Guarda sesión y consulta datos del usuario         │
│                                                                       │
│  1. Almacena en Global State (GetX):                                │
│     final authState = Get.find<AuthController>();                  │
│     authState.setUser(response.user);                               │
│     authState.setAccessToken(response.access_token);                │
│                                                                       │
│  2. Consulta perfil del usuario:                                    │
│     GET /api/auth/me  ← Backend obtiene datos de perfil             │
│                                                                       │
│     Backend valida JWT token en header Authorization:               │
│     GET /api/auth/me                                                │
│     Headers:                                                         │
│       Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... │
│                                                                       │
│  3. Backend retorna perfil:                                         │
│     {                                                                │
│       "usuario": {                                                   │
│         "id": "uuid-123",                                           │
│         "nombre": "Sofia",                                          │
│         "apellido": "García",                                       │
│         "email": "sofia@example.com",                              │
│         "rol_id": 1,  ← ESTUDIANTE                                  │
│         "es_admin": false                                           │
│       },                                                             │
│       "perfil_estudio": {                                           │
│         "horas_disponibles": 10,                                    │
│         "objetivo": "Ing. en Sistemas",                             │
│         "nivel_procrastinacion": 3,                                 │
│         "foto_perfil": "https://..."                                │
│       }                                                              │
│     }                                                                │
│                                                                       │
│  4. Frontend guarda en estado global                                │
│                                                                       │
└────────────┬──────────────────────────────────────────────────────────┘
             │ Sesión iniciada
             ↓
┌──────────────────────────────────────────────────────────────────────┐
│                   NAVEGACIÓN A DASHBOARD                            │
│                                                                       │
│  Frontend navega a:                                                 │
│  Navigator.of(context).pushReplacementNamed('/dashboard');         │
│                                                                       │
│  Dashboard carga datos:                                             │
│  • GET /api/tareas → Lista de tareas del usuario                   │
│  • GET /api/horarios → Horarios disponibles                        │
│  • GET /api/admin/estadisticas (si es admin)                       │
│                                                                       │
│  Todas las requests incluyen header:                                │
│  Authorization: Bearer <JWT_TOKEN>                                  │
│                                                                       │
│  Backend valida token en cada request:                              │
│                                                                       │
│  app.use((req, res, next) => {                                      │
│    const token = req.headers.authorization?.split(' ')[1];         │
│    if (!token) return res.status(401).json({error: "No auth"});     │
│                                                                       │
│    const decoded = jwt.verify(token, SECRET_KEY);  // Si válido    │
│    req.user = decoded;  // Inyecta usuario en request              │
│    next();                                                           │
│  });                                                                 │
│                                                                       │
│  Si token expirado:                                                 │
│  Frontend intenta refresh con refresh_token                         │
│  Si refresh falla: Logout automático                                │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘

════════════════════════════════════════════════════════════════════════

                            LOGOUT FLOW

┌──────────────────────────────────────────────────────────────────────┐
│              Usuario click "Cerrar Sesión"                           │
│                                                                       │
│  Frontend: authService.logout()                                     │
│                                                                       │
│  1. Borra token de memoria                                          │
│  2. Borra token de Secure Storage                                   │
│  3. Borra perfil de estado global                                   │
│  4. POST /api/auth/logout (opcional, para backend)                 │
│  5. Navega a LoginScreen                                            │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘

════════════════════════════════════════════════════════════════════════

                      RECUPERACIÓN DE CONTRASEÑA

┌──────────────────────────────────────────────────────────────────────┐
│        Pantalla: olvidar_contraseña.dart                            │
│                                                                       │
│  Step 1: Usuario ingresa email                                      │
│  Step 2: Supabase envía código OTP al email                         │
│  Step 3: Usuario ingresa código OTP                                 │
│  Step 4: Usuario ingresa nueva contraseña                           │
│  Step 5: Supabase actualiza contraseña y hasheada                   │
│  Step 6: Usuario puede login con nueva contraseña                   │
│                                                                       │
│  Flujo similar a login, pero con endpoints de recuperación          │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 📁 ÁRBOL DE DEPENDENCIAS

### Backend (package.json)

```
backend/
├── dependencies/
│   ├── @google/genai@^2.10.0
│   │   ├── node_modules/@google/genai/
│   │   ├── Propósito: SDK oficial de Google Gemini
│   │   ├── Funciones: gemini.models.generateContent()
│   │   └── Usada en: src/services/gemini.service.ts
│   │
│   ├── express@^5.2.1
│   │   ├── Propósito: Framework web HTTP
│   │   ├── Funciones: app.get(), app.post(), middleware
│   │   └── Usada en: src/server.ts, todas las rutas
│   │
│   ├── pg@^8.16.0
│   │   ├── Propósito: Driver PostgreSQL
│   │   ├── Funciones: pool.query(), pool.connect()
│   │   └── Usada en: src/config/db.ts
│   │
│   ├── postgres@^3.4.9
│   │   ├── Propósito: Driver PostgreSQL alternativo
│   │   ├── Funciones: SQL queries
│   │   └── Alternativa a pg
│   │
│   ├── bcrypt@^6.0.0
│   │   ├── Propósito: Hashing de contraseñas
│   │   ├── Funciones: bcrypt.hash(), bcrypt.compare()
│   │   └── Usada en: authRoutes (en futuro)
│   │
│   ├── cors@^2.8.6
│   │   ├── Propósito: Habilitar CORS
│   │   ├── Funciones: app.use(cors())
│   │   └── Usada en: src/server.ts
│   │
│   ├── multer@^2.2.0
│   │   ├── Propósito: Upload de archivos
│   │   ├── Funciones: upload.single(), upload.array()
│   │   └── Usada en: rutas de archivos (foto perfil)
│   │
│   └── dotenv@^17.2.0
│       ├── Propósito: Variables de entorno
│       ├── Funciones: dotenv.config()
│       └── Usada en: src/server.ts
│
├── devDependencies/
│   ├── @types/node@^24.0.0
│   │   ├── Propósito: Tipos TypeScript para Node.js
│   │   └── Usada en: IDE autocomplete
│   │
│   ├── @types/express@^5.0.3
│   │   ├── Propósito: Tipos TypeScript para Express
│   │   └── Usada en: IDE autocomplete
│   │
│   ├── @types/pg@^8.15.5
│   │   ├── Propósito: Tipos TypeScript para pg
│   │   └── Usada en: IDE autocomplete
│   │
│   ├── @types/bcrypt@^6.0.0
│   │   ├── Propósito: Tipos TypeScript para bcrypt
│   │   └── Usada en: IDE autocomplete
│   │
│   ├── @types/cors@^2.8.19
│   │   ├── Propósito: Tipos TypeScript para cors
│   │   └── Usada en: IDE autocomplete
│   │
│   ├── @types/multer@^2.1.0
│   │   ├── Propósito: Tipos TypeScript para multer
│   │   └── Usada en: IDE autocomplete
│   │
│   ├── typescript@^5.9.3
│   │   ├── Propósito: Compilador TypeScript
│   │   ├── Funciones: tsc (compilar .ts a .js)
│   │   └── Usada en: scripts build
│   │
│   └── tsx@^4.20.3
│       ├── Propósito: Ejecutor TypeScript en desarrollo
│       ├── Funciones: tsx watch (reload automático)
│       └── Usada en: npm run dev
│
├── scripts/
│   ├── dev
│   │   └── tsx watch src/server.ts
│   │       └── Ejecuta en modo desarrollo con reload
│   │
│   └── build (recomendado)
│       └── tsc
│           └── Compila src/ a dist/
│
└── configuración/
    ├── tsconfig.json
    │   ├── target: "ES2020"
    │   ├── module: "commonjs"
    │   ├── strict: true
    │   ├── esModuleInterop: true
    │   └── skipLibCheck: true
    │
    └── .env
        ├── DATABASE_URL=postgresql://user:pass@host/db
        ├── GOOGLE_API_KEY=your_gemini_api_key
        ├── PORT=3000
        └── NODE_ENV=development
```

### Frontend (pubspec.yaml)

```
frontend/
├── dependencies/
│   ├── flutter (SDK)
│   │   ├── Propósito: Framework UI multiplataforma
│   │   ├── Versión mínima: >=3.11.5 <4.0.0
│   │   └── Proporciona: Material Design, Cupertino (iOS)
│   │
│   ├── supabase_flutter@^2.12.4
│   │   ├── Propósito: Cliente de Supabase (Auth + BD)
│   │   ├── Funciones:
│   │   │   - Supabase.initialize()
│   │   │   - supabase.auth.signInWithPassword()
│   │   │   - supabase.from('tabla').select()
│   │   │   - Real-time subscriptions
│   │   └── Usada en: lib/services/supabase.service.dart
│   │
│   ├── google_fonts@^8.1.0
│   │   ├── Propósito: Tipografías Google en app
│   │   ├── Funciones: GoogleFonts.roboto(), GoogleFonts.openSans()
│   │   └── Usada en: Todos los screens para estilo
│   │
│   ├── local_auth@^3.0.1
│   │   ├── Propósito: Autenticación biométrica
│   │   ├── Funciones:
│   │   │   - BiometricAuth.canCheckBiometrics
│   │   │   - BiometricAuth.authenticate()
│   │   └── Usada en: login_screen.dart (huella, facial)
│   │
│   ├── http@^1.6.0
│   │   ├── Propósito: Llamadas HTTP al backend
│   │   ├── Funciones:
│   │   │   - http.get(), http.post(), http.put()
│   │   │   - Manejo de requests/responses
│   │   └── Usada en: lib/services/api.service.dart
│   │
│   ├── intl@^0.19.0
│   │   ├── Propósito: Internacionalización (fechas, monedas)
│   │   ├── Funciones:
│   │   │   - DateFormat.yMd()
│   │   │   - TimeOfDay formatting
│   │   └── Usada en: calendar_screen.dart, progreso_screen.dart
│   │
│   ├── image_picker@^1.2.2
│   │   ├── Propósito: Seleccionar/tomar fotos
│   │   ├── Funciones:
│   │   │   - ImagePicker.pickImage()
│   │   │   - ImagePicker.pickMultipleImages()
│   │   └── Usada en: profile_screen.dart (foto perfil)
│   │
│   ├── table_calendar@^3.1.3
│   │   ├── Propósito: Widget calendario interactivo
│   │   ├── Funciones:
│   │   │   - TableCalendar widget
│   │   │   - Event markers
│   │   │   - OnDaySelected callback
│   │   └── Usada en: calendar_screen.dart
│   │
│   └── cupertino_icons@^1.0.8
│       ├── Propósito: Iconos iOS (Cupertino)
│       ├── Funciones: CupertinoIcons.xxx
│       └── Usada en: widgets iOS style
│
├── dev_dependencies/
│   ├── flutter_test (SDK)
│   │   ├── Propósito: Testing framework para Flutter
│   │   ├── Funciones: testWidgets(), expect()
│   │   └── Usada en: test/ folder
│   │
│   └── flutter_lints@^6.0.0
│       ├── Propósito: Reglas de linting recomendadas
│       ├── Funciones: Análisis estático de código
│       └── Usada en: analysis_options.yaml
│
├── assets/
│   ├── images/
│   │   ├── logo/
│   │   │   ├── Lumi.png (logo principal)
│   │   │   └── logros/ (imágenes de logros)
│   │   └── otros assets
│   │
│   └── fonts/
│       ├── Google Fonts descargados
│       └── Tipografías personalizadas
│
└── configuración/
    ├── pubspec.yaml
    │   ├── name: frontend
    │   ├── description: Aplicación Flutter Lumi
    │   ├── version: 1.0.0+1
    │   └── publish_to: 'none'
    │
    ├── analysis_options.yaml
    │   ├── rules: Linting (prefer const constructors, etc.)
    │   └── exclude: [generated, bindings]
    │
    └── .env
        ├── SUPABASE_URL=https://lsbnizzypdmnvppatzxp.supabase.co
        ├── SUPABASE_ANON_KEY=sb_publishable_...
        ├── BACKEND_URL=http://localhost:3000
        └── GOOGLE_API_KEY=... (si se necesita desde frontend)
```

---

## 🎯 CASOS DE USO PRINCIPALES

### 1️⃣ Crear Tarea

```
USUARIO CREA TAREA
==================

Precondición: Usuario autenticado, en pantalla Dashboard

Flujo:
------
1. Usuario click en botón "Agregar Tarea"
   └─ Navega a: agregar_tarea_screen.dart

2. Pantalla muestra formulario:
   ┌─────────────────────────────┐
   │ Crear Nueva Tarea           │
   ├─────────────────────────────┤
   │ Nombre: [_________________] │
   │ Descripción: [____________] │
   │ Fecha Entrega: [________]   │
   │ Prioridad: [Baja ▼]         │
   │ Categoría: [Trabajo ▼]      │
   │                             │
   │ [ Guardar ]  [ Cancelar ]   │
   └─────────────────────────────┘

3. Usuario ingresa datos:
   - Nombre: "Estudiar Cálculo"
   - Descripción: "Derivadas e integrales"
   - Fecha: 15/09/2026
   - Prioridad: Alta
   - Categoría: Estudio

4. Frontend valida:
   ✓ Nombre no vacío
   ✓ Nombre <= 200 caracteres
   ✓ Descripción <= 1000 caracteres
   ✓ Fecha es válida y futura

5. User click "Guardar"
   └─ POST /api/tareas
      
      Body:
      {
        "nombre": "Estudiar Cálculo",
        "descripcion": "Derivadas e integrales",
        "fecha_entrega": "2026-09-15",
        "prioridad": "ALTA",
        "categoria": "ESTUDIO",
        "usuario_id": "uuid-user-123"
      }

6. Backend (tareas.controller.ts):
   
   a) Valida usuario existe:
      SELECT * FROM usuarios WHERE id = $1
      
   b) Normaliza payload:
      - Trimea espacios
      - Valida tipos
      - Establece defaults (completada=false, estado=PENDIENTE)
   
   c) Inserta en BD:
      INSERT INTO tareas 
      (usuario_id, titulo, descripcion, fecha_entrega, 
       prioridad, categoria, completada)
      VALUES ($1, $2, $3, $4, $5, $6, false)
      RETURNING id, fecha_creacion
   
   d) Retorna tarea creada:
      HTTP 201 Created
      {
        "id": "uuid-tarea-456",
        "nombre": "Estudiar Cálculo",
        "descripcion": "Derivadas e integrales",
        "fecha_entrega": "2026-09-15",
        "completada": false,
        "estado": "PENDIENTE",
        "fecha_creacion": "2026-09-01T14:30:00Z"
      }

7. Frontend recibe respuesta:
   - Actualiza lista local de tareas
   - Navega de vuelta a Dashboard
   - Muestra notificación "Tarea creada"

8. Dashboard ahora muestra:
   └─ Lista de Tareas:
      ├─ [  ] Estudiar Cálculo (15/09/2026)
      └─ [  ] Otra tarea...

Caso de Error:
--------------
Si usuario_id no existe:
  HTTP 404 Not Found
  {"error": "Usuario no encontrado"}

Si nombre está vacío:
  HTTP 400 Bad Request
  {"error": "El nombre es obligatorio"}

Si fecha es inválida:
  HTTP 400 Bad Request
  {"error": "Fecha inválida"}
```

---

### 2️⃣ Consultar IA

```
USUARIO HACE PREGUNTA A IA
============================

Precondición: Usuario en pantalla con plan activo

Flujo:
------
1. Usuario abre GuiaDetalleScreen (plan generado)
   
2. Ve botón "Hacer pregunta a IA" o "Consultar Gemini"
   
3. Click abre diálogo:
   ┌──────────────────────────┐
   │ Pregunta a Lumi          │
   ├──────────────────────────┤
   │ Tu pregunta:             │
   │ [____________________]   │
   │ [____________________]   │
   │                          │
   │ [ Enviar ]  [ Cancelar ] │
   └──────────────────────────┘

4. Usuario ingresa pregunta:
   "¿Cuál es la diferencia entre derivada e integral?"

5. Frontend valida:
   ✓ Pregunta no vacía
   ✓ <= 1000 caracteres

6. Frontend envía:
   POST /api/ia/preguntar
   
   Headers:
   Authorization: Bearer <JWT_TOKEN>
   
   Body:
   {
     "pregunta": "¿Cuál es la diferencia entre derivada e integral?",
     "plan_id": "uuid-plan-789",
     "usuario_id": "uuid-user-123",
     "contexto": "Estudiando Cálculo Integral"
   }

7. Backend (ia.controller.ts):
   
   a) Valida usuario y plan existen
   
   b) Recupera contexto del plan:
      SELECT * FROM planes_ia WHERE plan_id = $1
      
   c) Construye prompt para Gemini:
      "El estudiante está estudiando: Cálculo Integral
       Plan: [detalles del plan]
       Pregunta: ¿Cuál es la diferencia entre derivada e integral?
       
       Responde de forma clara y educativa."
   
   d) Llama a gemini.service:
      const respuesta = await generarRespuestaIA(prompt)
   
   e) Gemini procesa y retorna respuesta:
      "La derivada mide la tasa de cambio instantáneo de una función,
       mientras que la integral acumula área bajo la curva..."
   
   f) Backend guarda en historial:
      INSERT INTO historial_ia
      (usuario_id, plan_id, pregunta, respuesta, fecha)
      VALUES ($1, $2, $3, $4, NOW())
   
   g) Retorna respuesta:
      HTTP 200 OK
      {
        "respuesta": "La derivada mide...",
        "fuentes": ["Khan Academy", "Libre de Cálculo"],
        "id_historial": "uuid-hist-999"
      }

8. Frontend recibe respuesta:
   - Muestra en pantalla con scroll
   - Guarda en historial local
   - Muestra opciones: "Más info", "Guardar", "Compartir"

9. Pantalla muestra:
   ┌──────────────────────────────────┐
   │ Pregunta: ¿Cuál es la diferencia │
   │ entre derivada e integral?       │
   │                                  │
   │ Respuesta Lumi:                  │
   │ La derivada mide la tasa de      │
   │ cambio instantáneo de una        │
   │ función, mientras que la         │
   │ integral acumula área bajo la    │
   │ curva...                         │
   │                                  │
   │ [ Hacer otra pregunta ]          │
   │ [ Ver historial ]                │
   └──────────────────────────────────┘

Caso de Error:
--------------
Si plan no existe:
  HTTP 404 Not Found
  {"error": "Plan no encontrado"}

Si Gemini está saturado:
  Backend retry automático (hasta 3 intentos)
  Cambio a gemini-1.5-flash
  
  Si aún falla:
  HTTP 503 Service Unavailable
  {"error": "Servicio de IA temporalmente no disponible"}

Caso de Abuso (muchas preguntas):
  Rate limiting: Max 100 preguntas/hora
  HTTP 429 Too Many Requests
  {"error": "Demasiadas solicitudes, intenta más tarde"}
```

---

### 3️⃣ Admin Gestiona Usuarios

```
ADMINISTRADOR GESTIONA USUARIOS
=================================

Precondición: Usuario autenticado como ADMIN (es_admin = true)

Flujo:
------
1. Admin navega a Panel de Control
   └─ URL: /admin/panel

2. Pantalla muestra:
   ┌────────────────────────────────────┐
   │ Panel Administrativo Lumi          │
   ├────────────────────────────────────┤
   │ [ Usuarios ] [ Estadísticas ]      │
   │ [ Reportes ] [ Configuración ]     │
   └────────────────────────────────────┘

3. Admin click en "Usuarios"
   └─ Navega a: admin_user_list_screen.dart

4. Pantalla muestra lista:
   ┌─────────────────────────────────────────┐
   │ Gestión de Usuarios                     │
   ├─────────────────────────────────────────┤
   │ Buscar: [_________________] [ Buscar ]  │
   │                                         │
   │ # │ Nombre    │ Email        │ Rol     │
   ├───┼───────────┼──────────────┼─────────┤
   │ 1 │ Sofia     │ sofia@...    │ Estud.. │
   │ 2 │ Juan      │ juan@...     │ Admin   │
   │ 3 │ María     │ maria@...    │ Estud.. │
   │ 4 │ Carlos    │ carlos@...   │ Estud.. │
   │                                         │
   │ < [ 1 ] [ 2 ] [ 3 ] >                  │
   │                                         │
   │ [ Agregar Usuario ]                     │
   └─────────────────────────────────────────┘

5. Admin puede hacer:

   A) VER DETALLES DE USUARIO
   ────────────────────────────
   Click en fila → admin_user_detail_screen.dart
   
   Muestra:
   ┌──────────────────────────────────┐
   │ Sofia García                     │
   ├──────────────────────────────────┤
   │ Email: sofia@example.com         │
   │ Rol: Estudiante                  │
   │ Registrado: 01/01/2026 10:00     │
   │                                  │
   │ Perfil de Estudio:               │
   │ • Horas disponibles: 10 h/semana │
   │ • Objetivo: Ing. en Sistemas     │
   │ • Procrastinación: Nivel 3/5     │
   │                                  │
   │ Estadísticas:                    │
   │ • Tareas completadas: 45         │
   │ • Horas estudiadas: 120 h        │
   │ • Racha actual: 7 días           │
   │                                  │
   │ [ Editar ] [ Eliminar ]          │
   │ [ Suspender Cuenta ]             │
   └──────────────────────────────────┘

   B) EDITAR USUARIO
   ──────────────────
   Click "Editar":
   
   Formulario editable:
   ┌──────────────────────────────┐
   │ Editar Usuario: Sofia        │
   ├──────────────────────────────┤
   │ Nombre: [Sofia____________]  │
   │ Email: [sofia@example.com]   │
   │ Rol: [Estudiante ▼]          │
   │ Es Admin: [ ] (checkbox)      │
   │                              │
   │ Horas disponibles: [10]       │
   │ Objetivo: [Ing. en Sistemas]  │
   │                              │
   │ [ Guardar ] [ Cancelar ]      │
   └──────────────────────────────┘
   
   Admin modifica y click "Guardar":
   PUT /api/admin/usuarios/uuid-sofia
   
   Body:
   {
     "nombre": "Sofia",
     "email": "sofia@newmail.com",
     "rol_id": 1,
     "es_admin": false,
     "horas_disponibles": 12
   }
   
   Backend valida y actualiza:
   UPDATE usuarios SET nombre=$1, email=$2, ... WHERE id=$3
   UPDATE perfiles_estudio SET horas_disponibles=$1 WHERE usuario_id=$2
   
   Retorna:
   HTTP 200 OK
   {"mensaje": "Usuario actualizado exitosamente"}

   C) ELIMINAR USUARIO
   ────────────────────
   Click "Eliminar":
   
   Confirmación:
   ┌────────────────────────────┐
   │ ¿Eliminar a Sofia?         │
   │                            │
   │ Se eliminarán:             │
   │ • Cuenta de usuario        │
   │ • Todas las tareas         │
   │ • Planes de estudio        │
   │ • Historial                │
   │                            │
   │ Esta acción es IRREVERSIBLE│
   │                            │
   │ [ Cancelar ]  [ Eliminar ] │
   └────────────────────────────┘
   
   Si confirma:
   DELETE /api/admin/usuarios/uuid-sofia
   
   Backend ejecuta:
   BEGIN TRANSACTION
   
   -- Elimina dependencias
   DELETE FROM tareas WHERE actividad_id IN 
     (SELECT id FROM actividades WHERE plan_id IN
       (SELECT id FROM planes_estudio WHERE usuario_id=$1))
   
   DELETE FROM actividades WHERE plan_id IN
     (SELECT id FROM planes_estudio WHERE usuario_id=$1)
   
   DELETE FROM planes_estudio WHERE usuario_id=$1
   DELETE FROM horarios WHERE usuario_id=$1
   DELETE FROM historial_ia WHERE usuario_id=$1
   DELETE FROM estadisticas WHERE usuario_id=$1
   
   -- Elimina usuario
   DELETE FROM usuarios WHERE id=$1
   
   -- Elimina de auth.users (Supabase)
   supabase.auth.admin.deleteUser(usuario_id)
   
   COMMIT TRANSACTION
   
   Retorna:
   HTTP 200 OK
   {"mensaje": "Usuario eliminado"}

   D) VER ESTADÍSTICAS
   ────────────────────
   Admin click "Estadísticas":
   
   GET /api/admin/estadisticas
   
   Retorna datos globales:
   {
     "usuarios_totales": 250,
     "usuarios_activos": 180,
     "tareas_completadas_total": 5430,
     "horas_estudio_total": 12500,
     "plan_mas_popular": "Pomodoro",
     "promedio_racha": 4.5,
     "nuevos_usuarios_hoy": 12,
     "grafico_crecimiento": [...]
   }
   
   Frontend muestra dashboard con gráficos

6. Admin hace búsqueda:
   
   Ingresa en buscador: "sofia"
   GET /api/admin/usuarios?search=sofia&page=1
   
   Backend:
   SELECT * FROM usuarios 
   WHERE (nombre ILIKE '%sofia%' OR email ILIKE '%sofia%')
   LIMIT 10 OFFSET 0
   
   Retorna usuarios que coincidan

Errores Posibles:
-----------------
Si admin no tiene permisos:
  HTTP 403 Forbidden
  {"error": "No tienes permisos de administrador"}

Si usuario no existe:
  HTTP 404 Not Found
  {"error": "Usuario no encontrado"}

Si email ya existe (al editar):
  HTTP 400 Bad Request
  {"error": "Email ya registrado"}
```

---

## 🔄 CI/CD Pipeline (Recomendado)

```
GIT WORKFLOW
=============

1. Developer hace commit
   git commit -m "feat: agregar Feynman screen"
   git push origin feature/feynman

2. GitHub Actions se dispara (configurar .github/workflows)
   
   ├─ LINT & FORMAT
   │  ├─ npm run lint:backend
   │  ├─ flutter analyze
   │  └─ Verifica code style
   │
   ├─ TESTS (Opcional)
   │  ├─ npm run test:backend
   │  ├─ flutter test
   │  └─ Ejecuta suite de tests
   │
   ├─ BUILD
   │  ├─ Backend:
   │  │  ├─ npm install
   │  │  ├─ npm run build (tsc)
   │  │  └─ npm run test
   │  │
   │  └─ Frontend:
   │     ├─ flutter pub get
   │     ├─ flutter analyze
   │     └─ flutter build apk (Android)
   │
   └─ DEPLOY
      ├─ Staging (rama develop):
      │  ├─ Despliega backend a servidor staging
      │  ├─ Deploy frontend a Firebase Hosting staging
      │  └─ Ejecuta smoke tests
      │
      └─ Production (rama main):
         ├─ Requiere aprobación manual
         ├─ Despliega backend (Blue-Green Deployment)
         ├─ Despliega frontend a producción
         ├─ Ejecuta health checks
         └─ Notifica al equipo

PIPELINE RECOMENDADO
======================

.github/workflows/ci-cd.yml:

name: CI/CD Pipeline

on:
  push:
    branches: [main, develop, feature/*]
  pull_request:
    branches: [main, develop]

jobs:
  lint-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: cd backend && npm install
      - run: cd backend && npm run lint
      - run: cd backend && npx tsc --noEmit

  lint-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.11.5'
      - run: cd frontend && flutter pub get
      - run: cd frontend && flutter analyze

  test-backend:
    runs-on: ubuntu-latest
    needs: lint-backend
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: lumi_test
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: cd backend && npm install
      - run: cd backend && npm run test
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost/lumi_test

  build-backend:
    runs-on: ubuntu-latest
    needs: [lint-backend, test-backend]
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: cd backend && npm install && npm run build
      - uses: actions/upload-artifact@v3
        with:
          name: backend-dist
          path: backend/dist

  build-frontend:
    runs-on: ubuntu-latest
    needs: lint-frontend
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd frontend && flutter pub get
      - run: cd frontend && flutter build web
      - run: cd frontend && flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: frontend-builds
          path: |
            frontend/build/web
            frontend/build/app/outputs/apk/release

  deploy-staging:
    runs-on: ubuntu-latest
    needs: [build-backend, build-frontend]
    if: github.ref == 'refs/heads/develop'
    environment: staging
    steps:
      - uses: actions/download-artifact@v3
      - name: Deploy Backend to Staging
        run: |
          # Deploy backend (ej: Heroku, Railway, DigitalOcean)
          # ssh deploy@staging.server "cd /app && git pull && npm install && npm run build && pm2 restart app"
      - name: Deploy Frontend to Firebase Staging
        run: |
          # firebase deploy --project staging --only hosting

  deploy-production:
    runs-on: ubuntu-latest
    needs: [build-backend, build-frontend]
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://lumiia.app
    steps:
      - uses: actions/download-artifact@v3
      - name: Deploy Backend to Production
        run: |
          # Blue-Green deployment
          # ssh deploy@prod.server "..."
      - name: Deploy Frontend to Production
        run: |
          # firebase deploy --project production --only hosting
      - name: Notification
        run: |
          # Enviar notificación a Slack/Discord
          curl -X POST ${{ secrets.DISCORD_WEBHOOK }} \
            -d '{"content":"🚀 Deployment a producción exitoso"}'
```

---

## 📱 PLATAFORMAS Y BUILDS

```
PLATAFORMAS SOPORTADAS
========================

┌─────────────────────────────────────────────────────────────┐
│                    iOS (iPhone / iPad)                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Directorio: frontend/ios/                                 │
│                                                             │
│  Requisitos:                                                │
│  • Xcode 14+                                               │
│  • iOS Deployment Target: 11.0+                            │
│  • CocoaPods                                                │
│  • Apple Developer Account                                  │
│                                                             │
│  Build Command:                                             │
│  $ cd frontend                                              │
│  $ flutter build ios --release                              │
│                                                             │
│  Output:                                                    │
│  • build/ios/iphoneos/Runner.app                           │
│                                                             │
│  Configuración:                                             │
│  • Signing: Runner.xcodeproj > Build Settings              │
│  • Provisioning: Team ID, Bundle ID                        │
│  • Capabilities: Camera, Microphone, Biometric            │
│                                                             │
│  Distribución:                                              │
│  • Apple App Store (TestFlight, App Store)                │
│  • Ad Hoc (solo dispositivos registrados)                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│               ANDROID (Teléfonos / Tablets)                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Directorio: frontend/android/                             │
│                                                             │
│  Requisitos:                                                │
│  • Android SDK 21+                                         │
│  • Gradle 7.0+                                             │
│  • JDK 11+                                                 │
│  • Google Play Developer Account                           │
│                                                             │
│  Build Command:                                             │
│  $ cd frontend                                              │
│  $ flutter build apk --release                             │
│  $ flutter build app-bundle --release                      │
│                                                             │
│  Output:                                                    │
│  • build/app/outputs/apk/release/app-release.apk           │
│  • build/app/outputs/bundle/release/app-release.aab        │
│                                                             │
│  Configuración:                                             │
│  • android/app/build.gradle.kts                            │
│  • android/gradle.properties (versiones SDK)               │
│  • android/app/src/main/AndroidManifest.xml                │
│                                                             │
│  Permisos (AndroidManifest.xml):                            │
│  • android.permission.INTERNET                             │
│  • android.permission.CAMERA                               │
│  • android.permission.RECORD_AUDIO                         │
│  • android.permission.ACCESS_FINE_LOCATION                │
│  • android.permission.READ_EXTERNAL_STORAGE               │
│                                                             │
│  Signing:                                                   │
│  $ keytool -genkey -v -keystore ~/lumi-key.jks ...        │
│  • Alias: lumi_key                                         │
│  • Contraseña: (almacenar en .gitignore)                   │
│                                                             │
│  Distribución:                                              │
│  • Google Play Store (requiere AAB)                        │
│  • F-Droid (open source)                                  │
│  • APK directo (side-loading)                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              WEB (Navegadores Desktop/Mobile)              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Directorio: frontend/web/                                 │
│                                                             │
│  Requisitos:                                                │
│  • Chrome/Firefox/Safari actualizado                      │
│  • Web hosting (Firebase Hosting, Netlify, Vercel)        │
│                                                             │
│  Build Command:                                             │
│  $ cd frontend                                              │
│  $ flutter build web --release                             │
│                                                             │
│  Output:                                                    │
│  • build/web/ (HTML + JS + CSS + Assets)                   │
│                                                             │
│  Configuración:                                             │
│  • web/index.html (viewport, manifest)                     │
│  • web/manifest.json (PWA, ícono, nombre app)              │
│  • web/favicon.ico (ícono en pestaña)                      │
│                                                             │
│  Características PWA:                                       │
│  • Instalar en homescreen                                  │
│  • Offline mode (service worker)                           │
│  • Push notifications                                      │
│                                                             │
│  Hosting Recomendado:                                       │
│  • Firebase Hosting (integrado con Firebase)               │
│  • Netlify (auto-deploy desde GitHub)                      │
│  • Vercel (Next.js, pero soporta Flutter web)             │
│                                                             │
│  Deploy (Firebase):                                         │
│  $ firebase login                                           │
│  $ firebase init hosting                                    │
│  $ firebase deploy --only hosting                          │
│                                                             │
│  URL en vivo: https://lumiia-app.web.app                   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│            WINDOWS (Desktop - Escritorio)                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Directorio: frontend/windows/                             │
│                                                             │
│  Requisitos:                                                │
│  • Visual Studio 2019+ (C++ build tools)                   │
│  • Windows SDK 10.0.19041.0+                               │
│                                                             │
│  Build Command:                                             │
│  $ cd frontend                                              │
│  $ flutter build windows --release                         │
│                                                             │
│  Output:                                                    │
│  • build/windows/runner/Release/lumi.exe                   │
│                                                             │
│  Distribución:                                              │
│  • Microsoft Store (msix)                                  │
│  • Instalador directo (.exe)                               │
│                                                             │
│  Build MSIX:                                                │
│  $ flutter pub get                                          │
│  $ flutter pub run msix:create                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              LINUX (Desktop - Escritorio)                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Directorio: frontend/linux/                               │
│                                                             │
│  Requisitos:                                                │
│  • GCC 7.0+                                                │
│  • GTK 3.0+                                                │
│  • CMake                                                    │
│                                                             │
│  Build Command:                                             │
│  $ cd frontend                                              │
│  $ flutter build linux --release                           │
│                                                             │
│  Output:                                                    │
│  • build/linux/x64/release/bundle/lumi                     │
│                                                             │
│  Distribución:                                              │
│  • Snap (Ubuntu, etc.)                                     │
│  • AppImage (Linux universal)                              │
│  • .deb / .rpm (Debian/Red Hat)                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              macOS (Mac - Escritorio)                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Directorio: frontend/macos/                               │
│                                                             │
│  Requisitos:                                                │
│  • Xcode 13+                                               │
│  • macOS 10.13+                                            │
│                                                             │
│  Build Command:                                             │
│  $ cd frontend                                              │
│  $ flutter build macos --release                           │
│                                                             │
│  Output:                                                    │
│  • build/macos/Build/Products/Release/Lumi.app             │
│                                                             │
│  Distribución:                                              │
│  • Mac App Store                                           │
│  • Notarización de Apple                                   │
│  • Distribución directa (GitHub Releases)                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

MATRIZ DE SOPORTE
===================

Plataforma      │ Versión Mín │ Soporte │ Estado
────────────────┼─────────────┼─────────┼────────────
iOS             │ 11.0        │ ✅      │ Producción
Android         │ API 21 (5.0)│ ✅      │ Producción
Web             │ -           │ ✅      │ Producción
Windows         │ 10/11       │ ⚠️      │ Beta
Linux           │ -           │ ⚠️      │ Beta
macOS           │ 10.13       │ ⚠️      │ Beta

CONFIGURACIÓN DE BUILD VARIABLES
==================================

archivo: .env.build

PROD_BACKEND_URL=https://api.lumiia.app
PROD_SUPABASE_URL=https://lsbnizzypdmnvppatzxp.supabase.co
PROD_SUPABASE_ANON_KEY=sb_publishable_...

DEV_BACKEND_URL=http://localhost:3000
DEV_SUPABASE_URL=https://lsbnizzypdmnvppatzxp.supabase.co (staging)
DEV_SUPABASE_ANON_KEY=sb_publishable_staging_...

Usar en build:
flutter build apk --dart-define-from-file=.env.build --release
```

---

## 🗄️ DOCUMENTACIÓN BASE DE DATOS - LUMIIA

### 📋 ESQUEMA DE LA BASE DE DATOS

```sql
-- PostgreSQL Schema for LumiIa
-- Hosted on Supabase
-- Created: 2026-01-01

-- ============ TABLAS DE USUARIOS Y AUTENTICACIÓN ============

CREATE TABLE public.roles (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Datos iniciales
INSERT INTO public.roles (nombre, descripcion) VALUES
('ESTUDIANTE', 'Usuario que estudia y usa la plataforma'),
('ADMINISTRADOR', 'Gestor de usuarios y contenido'),
('MODERADOR', 'Moderador de comunidad (futuro)');

-- ============================================

CREATE TABLE public.usuarios (
  id UUID PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  apellido VARCHAR(255),
  email VARCHAR(255) UNIQUE NOT NULL,
  rol_id INTEGER REFERENCES public.roles(id),
  es_admin BOOLEAN DEFAULT false,
  foto_perfil TEXT,
  fecha_registro TIMESTAMP DEFAULT NOW(),
  ultima_conexion TIMESTAMP,
  estado VARCHAR(20) DEFAULT 'ACTIVO',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT usuarios_id_fkey 
    FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE
);

CREATE INDEX idx_usuarios_email ON public.usuarios(email);
CREATE INDEX idx_usuarios_rol ON public.usuarios(rol_id);

-- ============ TABLAS DE PERFIL DE ESTUDIANTE ============

CREATE TABLE public.perfiles_estudio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID UNIQUE NOT NULL,
  horas_disponibles INTEGER DEFAULT 2,
  objetivo TEXT,
  nivel_procrastinacion INTEGER CHECK (nivel_procrastinacion BETWEEN 1 AND 5) DEFAULT 3,
  foto_perfil TEXT,
  lenguaje_preferido VARCHAR(10) DEFAULT 'es',
  notificaciones_habilitadas BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT perfiles_estudio_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

-- ============ TABLAS DE PLANES DE ESTUDIO ============

CREATE TABLE public.metodos_estudio (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  duracion_recomendada INTEGER,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO public.metodos_estudio (nombre, descripcion, duracion_recomendada) VALUES
('Pomodoro', 'Ciclos de 25 min estudio + 5 min descanso', 25),
('Spaced Repetition', 'Repaso espaciado de conceptos', 50),
('Feynman Technique', 'Explicar conceptos con palabras simples', 60),
('Active Recall', 'Pruebas sin consultar material', 40);

-- ============================================

CREATE TABLE public.planes_estudio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  estado VARCHAR(50) DEFAULT 'ACTIVO',
  fecha_entrega DATE,
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_actualizacion TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT planes_estudio_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

CREATE INDEX idx_planes_usuario ON public.planes_estudio(usuario_id);
CREATE INDEX idx_planes_estado ON public.planes_estudio(estado);

-- ============================================

CREATE TABLE public.planes_ia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL UNIQUE,
  proveedor_ia VARCHAR(50) NOT NULL DEFAULT 'GEMINI',
  modelo_ia VARCHAR(50) NOT NULL,
  metodo_estudio TEXT NOT NULL,
  justificacion TEXT NOT NULL,
  tiempo_estimado_total INTEGER NOT NULL CHECK (tiempo_estimado_total > 0),
  consejos JSONB DEFAULT '[]'::jsonb,
  recursos JSONB DEFAULT '[]'::jsonb,
  resumen_final TEXT NOT NULL,
  version INTEGER DEFAULT 1,
  fecha_generacion TIMESTAMP DEFAULT NOW(),
  actualizado_en TIMESTAMP DEFAULT NOW(),
  dificultad VARCHAR(50) DEFAULT 'Media',
  enfoque_adicional TEXT,
  
  CONSTRAINT planes_ia_plan_id_fkey 
    FOREIGN KEY (plan_id) REFERENCES public.planes_estudio(id) ON DELETE CASCADE
);

-- ============ TABLAS DE ACTIVIDADES Y TAREAS ============

CREATE TABLE public.actividades (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL,
  titulo VARCHAR(255) NOT NULL,
  descripcion TEXT,
  fecha DATE,
  estado VARCHAR(50) DEFAULT 'PENDIENTE',
  orden INTEGER,
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT actividades_plan_id_fkey 
    FOREIGN KEY (plan_id) REFERENCES public.planes_estudio(id) ON DELETE CASCADE
);

CREATE INDEX idx_actividades_plan ON public.actividades(plan_id);

-- ============================================

CREATE TABLE public.tareas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actividad_id UUID,
  usuario_id UUID,
  titulo VARCHAR(255) NOT NULL,
  descripcion TEXT,
  completada BOOLEAN DEFAULT false,
  estado VARCHAR(50) DEFAULT 'PENDIENTE',
  fecha_entrega DATE,
  prioridad VARCHAR(20) DEFAULT 'NORMAL',
  fecha_creacion TIMESTAMP DEFAULT NOW(),
  fecha_completada TIMESTAMP,
  
  CONSTRAINT tareas_actividad_id_fkey 
    FOREIGN KEY (actividad_id) REFERENCES public.actividades(id) ON DELETE CASCADE,
  CONSTRAINT tareas_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

CREATE INDEX idx_tareas_actividad ON public.tareas(actividad_id);
CREATE INDEX idx_tareas_usuario ON public.tareas(usuario_id);
CREATE INDEX idx_tareas_estado ON public.tareas(estado);

-- ============ TABLA DE HORARIOS ============

CREATE TABLE public.horarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL,
  dia VARCHAR(20) NOT NULL,
  hora_inicio TIME NOT NULL,
  hora_fin TIME NOT NULL,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT horarios_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
  CONSTRAINT horarios_valid_time CHECK (hora_fin > hora_inicio)
);

CREATE INDEX idx_horarios_usuario ON public.horarios(usuario_id);

-- ============ TABLA DE HISTORIAL IA ============

CREATE TABLE public.historial_ia (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL,
  plan_id UUID,
  pregunta TEXT NOT NULL,
  respuesta TEXT NOT NULL,
  tokens_utilizados INTEGER,
  fecha TIMESTAMP DEFAULT NOW(),
  evaluacion_usuario INTEGER CHECK (evaluacion_usuario BETWEEN 1 AND 5),
  
  CONSTRAINT historial_ia_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
  CONSTRAINT historial_ia_plan_id_fkey 
    FOREIGN KEY (plan_id) REFERENCES public.planes_estudio(id) ON DELETE SET NULL
);

CREATE INDEX idx_historial_usuario ON public.historial_ia(usuario_id);
CREATE INDEX idx_historial_plan ON public.historial_ia(plan_id);
CREATE INDEX idx_historial_fecha ON public.historial_ia(fecha);

-- ============ TABLAS DE GAMIFICACIÓN ============

CREATE TABLE public.estadisticas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID UNIQUE NOT NULL,
  tareas_completadas INTEGER DEFAULT 0,
  horas_estudio NUMERIC(10,2) DEFAULT 0,
  racha INTEGER DEFAULT 0,
  fecha_ultima_racha DATE,
  puntos_totales INTEGER DEFAULT 0,
  nivel INTEGER DEFAULT 1,
  fecha_actualizacion TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT estadisticas_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

-- ============================================

CREATE TABLE public.recompensas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre VARCHAR(255) NOT NULL UNIQUE,
  descripcion TEXT,
  puntos INTEGER NOT NULL,
  icono_url TEXT,
  requisito TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO public.recompensas (nombre, descripcion, puntos, requisito) VALUES
('Primer Paso', 'Completa tu primera tarea', 10, 'tareas_completadas = 1'),
('Una Semana', '7 días de racha', 50, 'racha >= 7'),
('Un Mes', '30 días de racha', 200, 'racha >= 30'),
('Maestro', 'Completa 100 tareas', 500, 'tareas_completadas >= 100'),
('Erudito', 'Estudio 100 horas', 300, 'horas_estudio >= 100');

-- ============================================

CREATE TABLE public.usuario_recompensa (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL,
  recompensa_id UUID NOT NULL,
  fecha_obtenida TIMESTAMP DEFAULT NOW(),
  
  CONSTRAINT usuario_recompensa_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE,
  CONSTRAINT usuario_recompensa_recompensa_id_fkey 
    FOREIGN KEY (recompensa_id) REFERENCES public.recompensas(id) ON DELETE CASCADE,
  CONSTRAINT usuario_recompensa_unique UNIQUE (usuario_id, recompensa_id)
);

-- ============ TABLA DE NOTIFICACIONES ============

CREATE TABLE public.notificaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL,
  titulo VARCHAR(255),
  mensaje TEXT NOT NULL,
  tipo VARCHAR(50) DEFAULT 'INFO',
  leida BOOLEAN DEFAULT false,
  fecha TIMESTAMP DEFAULT NOW(),
  acciones JSONB,
  
  CONSTRAINT notificaciones_usuario_id_fkey 
    FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE CASCADE
);

CREATE INDEX idx_notificaciones_usuario ON public.notificaciones(usuario_id);
CREATE INDEX idx_notificaciones_leida ON public.notificaciones(leida);

-- ============ TABLA DE PLAN_METODO (Relación N:N) ============

CREATE TABLE public.plan_metodo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL,
  metodo_id INTEGER NOT NULL,
  
  CONSTRAINT plan_metodo_plan_id_fkey 
    FOREIGN KEY (plan_id) REFERENCES public.planes_estudio(id) ON DELETE CASCADE,
  CONSTRAINT plan_metodo_metodo_id_fkey 
    FOREIGN KEY (metodo_id) REFERENCES public.metodos_estudio(id) ON DELETE CASCADE,
  CONSTRAINT plan_metodo_unique UNIQUE (plan_id, metodo_id)
);

-- ============ VISTAS ÚTILES ============

CREATE VIEW public.usuario_estadisticas_view AS
SELECT 
  u.id,
  u.nombre,
  u.email,
  COUNT(DISTINCT t.id) as total_tareas,
  COUNT(DISTINCT CASE WHEN t.completada THEN t.id END) as tareas_completadas,
  e.racha,
  e.puntos_totales,
  e.nivel,
  ps.objetivo,
  ps.nivel_procrastinacion
FROM public.usuarios u
LEFT JOIN public.tareas t ON u.id = t.usuario_id
LEFT JOIN public.estadisticas e ON u.id = e.usuario_id
LEFT JOIN public.perfiles_estudio ps ON u.id = ps.usuario_id
GROUP BY u.id, u.nombre, u.email, e.racha, e.puntos_totales, e.nivel, ps.objetivo, ps.nivel_procrastinacion;

CREATE VIEW public.planes_activos_view AS
SELECT 
  p.id,
  p.nombre,
  p.usuario_id,
  u.nombre as usuario_nombre,
  p.estado,
  ia.metodo_estudio,
  COUNT(DISTINCT a.id) as total_actividades,
  COUNT(DISTINCT CASE WHEN t.completada THEN t.id END) as tareas_completadas
FROM public.planes_estudio p
JOIN public.usuarios u ON p.usuario_id = u.id
LEFT JOIN public.planes_ia ia ON p.id = ia.plan_id
LEFT JOIN public.actividades a ON p.id = a.plan_id
LEFT JOIN public.tareas t ON a.id = t.actividad_id
WHERE p.estado = 'ACTIVO'
GROUP BY p.id, p.nombre, p.usuario_id, u.nombre, p.estado, ia.metodo_estudio;

-- ============ FUNCIONES PL/pgSQL ============

-- Función para incrementar racha
CREATE OR REPLACE FUNCTION incrementar_racha(usuario_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.estadisticas
  SET 
    racha = racha + 1,
    fecha_ultima_racha = CURRENT_DATE,
    fecha_actualizacion = NOW()
  WHERE estadisticas.usuario_id = usuario_id;
END;
$$ LANGUAGE plpgsql;

-- Función para resetear racha (si usuario no estudia un día)
CREATE OR REPLACE FUNCTION resetear_racha(usuario_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.estadisticas
  SET 
    racha = 0,
    fecha_actualizacion = NOW()
  WHERE estadisticas.usuario_id = usuario_id
    AND fecha_ultima_racha < CURRENT_DATE - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar estadísticas al completar tarea
CREATE OR REPLACE FUNCTION actualizar_estadisticas_tarea()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.completada AND NOT OLD.completada THEN
    UPDATE public.estadisticas
    SET tareas_completadas = tareas_completadas + 1
    WHERE usuario_id = NEW.usuario_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_actualizar_estadisticas_tarea
AFTER UPDATE ON public.tareas
FOR EACH ROW
EXECUTE FUNCTION actualizar_estadisticas_tarea();

-- ============ POLÍTICAS DE SEGURIDAD (RLS) ============

-- Habilitar RLS en todas las tablas públicas
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfiles_estudio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tareas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.planes_estudio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estadisticas ENABLE ROW LEVEL SECURITY;

-- Política: Los usuarios solo ven sus propias tareas
CREATE POLICY usuarios_ver_propias_tareas ON public.tareas
FOR SELECT USING (usuario_id = auth.uid());

CREATE POLICY usuarios_crear_propias_tareas ON public.tareas
FOR INSERT WITH CHECK (usuario_id = auth.uid());

CREATE POLICY usuarios_editar_propias_tareas ON public.tareas
FOR UPDATE USING (usuario_id = auth.uid());

-- Política: Los usuarios solo ven sus propios planes
CREATE POLICY usuarios_ver_propios_planes ON public.planes_estudio
FOR SELECT USING (usuario_id = auth.uid());

-- Política: Admin puede ver todo
CREATE POLICY admin_ver_todo ON public.usuarios
FOR SELECT USING (
  auth.uid() IN (
    SELECT id FROM public.usuarios WHERE es_admin = true
  )
);
```

---

### 🔐 CONSIDERACIONES DE SEGURIDAD

```
SEGURIDAD EN BASE DE DATOS
=============================

1. ENCRIPTACIÓN
   ✓ PostgreSQL: SSL/TLS en tránsito
   ✓ Contraseñas: Hasheadas con Argon2 (Supabase Auth)
   ✓ Tokens: JWT firmados
   ✓ Datos sensibles: PGCrypto para encriptación en BD

   Implementar:
   CREATE EXTENSION pgcrypto;
   
   -- Para campos sensibles
   ALTER TABLE public.usuarios 
   ADD COLUMN telefono_encriptado bytea;
   
   UPDATE public.usuarios 
   SET telefono_encriptado = pgp_sym_encrypt(telefono, 'secret_key');

2. AUTENTICACIÓN
   ✓ OAuth2 / OIDC (Google, GitHub)
   ✓ JWT con refresh tokens
   ✓ MFA/2FA (futuro)
   ✓ Sesiones con timeout

3. AUTORIZACIÓN
   ✓ Row Level Security (RLS) habilitado
   ✓ Políticas por rol (ESTUDIANTE vs ADMIN)
   ✓ Validación en backend de permisos

   Verificación:
   -- Solo estudiantes ven sus datos
   SELECT * FROM public.usuarios 
   WHERE id = auth.uid();

4. INYECCIÓN SQL
   ✓ Prepared statements ($1, $2, etc.)
   ✓ Validación de entrada
   ✓ Sanitización en backend

   ❌ NUNCA:
   query = `SELECT * FROM usuarios WHERE email = '${email}'`
   
   ✅ SIEMPRE:
   query = `SELECT * FROM usuarios WHERE email = $1`
   await pool.query(query, [email])

5. AUDITORÍA
   ✓ Registrar cambios importantes (created_at, updated_at)
   ✓ Logs de acceso de admin
   ✓ Historial de cambios en tablas críticas

   Crear tabla de auditoría:
   CREATE TABLE public.audit_log (
     id BIGSERIAL PRIMARY KEY,
     tabla VARCHAR(100),
     operacion VARCHAR(10),
     usuario_id UUID,
     datos_antiguos JSONB,
     datos_nuevos JSONB,
     fecha TIMESTAMP DEFAULT NOW()
   );

6. BACKUPS
   ✓ Supabase realiza backups automáticos diarios
   ✓ Retención: 14 días
   ✓ Backup manual: pg_dump

   Manual backup:
   pg_dump postgresql://user:password@host/lumi > backup.sql

7. ACCESO A BD
   ✓ Solo backend puede conectar
   ✓ IP whitelist
   ✓ Credenciales en .env (NUNCA en git)

   .env:
   DATABASE_URL=postgresql://user:pass@host/db
   DATABASE_POOL_MIN=2
   DATABASE_POOL_MAX=20

   .gitignore:
   .env
   *.jks

8. RATE LIMITING
   ✓ Limitar intentos de login: 5/minuto por IP
   ✓ Limitar queries a IA: 100/hora por usuario
   ✓ Limitar uploads: 10MB/archivo, 100MB/usuario

9. VALIDACIONES
   ✓ Email válido (RFC 5322)
   ✓ Contraseña >= 8 caracteres
   ✓ UUID válido
   ✓ Fechas en formato correcto
   ✓ Limites de valores (procrastinación 1-5)

10. PERMISOS DE ARCHIVOS
    ✓ Solo usuarios autenticados pueden uploar
    ✓ Validar tipo MIME
    ✓ Almacenar en bucket privado (Supabase Storage)
    ✓ Generar URL con expiración
```

---

### 🔗 REFERENCIAS

```
Documentación
==============

PostgreSQL:
- https://www.postgresql.org/docs/
- https://www.postgresql.org/docs/current/sql-syntax.html

Supabase:
- https://supabase.com/docs
- https://supabase.com/docs/reference/auth/overview
- https://supabase.com/docs/reference/postgres/overview
- https://supabase.com/docs/guides/database/postgres/row-level-security

RLS (Row Level Security):
- https://supabase.com/docs/guides/auth/row-level-security
- https://www.postgresql.org/docs/current/sql-createpolicy.html

SQL Best Practices:
- https://use-the-index-luke.com/
- https://wiki.postgresql.org/wiki/Performance_Optimization
- https://www.postgresql.org/docs/current/sql-explain.html

Seguridad:
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- SQL Injection: https://owasp.org/www-community/attacks/SQL_Injection
- Authentication: https://owasp.org/www-community/attacks/Authentication_Cheat_Sheet

Hashing:
- Argon2: https://github.com/P-H-C/phc-winner-argon2
- bcrypt: https://en.wikipedia.org/wiki/Bcrypt
- OWASP Password Storage: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
```

---

# 📋 MAPA COMPLETO DEL PROYECTO LUMIIA

---

## 📂 ESTRUCTURA GENERAL DEL PROYECTO

```
LumiIa/
├── 📂 backend/                          # API REST Node.js/Express/TypeScript
│   ├── 📄 package.json                  # Dependencias NPM
│   ├── 📄 package-lock.json             # Lock de versiones
│   ├── 📄 tsconfig.json                 # Configuración TypeScript
│   ├── 📄 .env.example                  # Variables de entorno ejemplo
│   ├── 📂 src/                          # Código fuente TypeScript
│   │   ├── 📄 server.ts                 # Punto de entrada
│   │   ├── 📂 config/                   # Configuración
│   │   │   ├── 📄 db.ts                 # Pool PostgreSQL
│   │   │   └── 📂 ia/
│   │   │       └── 📄 gemini.config.ts  # API Gemini
│   │   ├── 📂 rutas/                    # Definición de endpoints
│   │   │   ├── 📄 authRoutes.ts
│   │   │   ├── 📄 tareas.routes.ts
│   │   │   ├── 📄 horarios.routes.js
│   │   │   ├── 📄 ia.routes.ts
│   │   │   ├── 📄 historial.routes.ts
│   │   │   └── 📄 adminRoutes.ts
│   │   ├── 📂 controllers/              # Lógica de negocio
│   │   │   ├── 📄 tareas.controller.ts
│   │   │   ├── 📄 horariosController.js
│   │   │   ├── 📄 ia.controller.ts
│   │   │   ├── 📄 historial.controller.ts
│   │   │   └── 📄 tareas.controller.test.ts
│   │   ├── 📂 services/                 # Lógica reutilizable
│   │   │   ├── 📄 gemini.service.ts
│   │   │   └── 📄 historial.service.ts
│   │   ├── 📂 prompts/                  # Templates de prompts
│   │   │   └── 📄 plan.prompt.ts
│   │   ├── 📂 types/                    # Tipos TypeScript
│   │   │   └── 📄 plan.types.ts
│   │   └── 📂 middleware/ (recomendado)
│   │       ├── 📄 auth.middleware.ts
│   │       └── 📄 errorHandler.ts
│   └── 📂 dist/ (generado)              # Código compilado
│
├── 📂 frontend/                         # Aplicación Flutter/Dart
│   ├── 📄 pubspec.yaml                  # Dependencias Flutter
│   ├── 📄 pubspec.lock                  # Lock de versiones
│   ├── 📄 analysis_options.yaml         # Linting
│   ├── 📄 devtools_options.yaml         # DevTools config
│   ├── 📄 README.md                     # Documentación
│   ├── 📄 .env.example                  # Ejemplo variables
│   ├── 📂 lib/                          # Código Dart/Flutter
│   │   ├── 📄 main.dart                 # Entry point
│   │   ├── 📂 models/                   # Modelos de datos
│   │   │   └── 📄 user.dart
│   │   ├── 📂 screens/                  # Pantallas (UI)
│   │   │   ├── 📄 splash_screen.dart
│   │   │   ├── 📄 login_screen.dart
│   │   │   ├── 📄 register_screen.dart
│   │   │   ├── 📄 olvidar_contraseña.dart
│   │   │   ├── 📄 dashboard_screen.dart
│   │   │   ├── 📄 calendar_screen.dart
│   │   │   ├── 📄 agregar_tarea_screen.dart
│   │   │   ├── 📄 profile_screen.dart (vacio)
│   │   │   ├── 📄 pomodoro_screen.dart
│   │   │   ├── 📄 feynman_screen.dart
│   │   │   ├── 📄 spaced_repetition_screen.dart
│   │   │   ├── 📄 active_recall_screen.dart
│   │   │   ├── 📄 progreso_screen.dart
│   │   │   ├── 📄 recompensas_screen.dart
│   │   │   ├── 📄 gamification_screen.dart
│   │   │   ├── 📄 historial_ia_screen.dart
│   │   │   ├── 📄 guia_detalle_screen.dart
│   │   │   ├── 📄 seleccionar_metodo_screen.dart
│   │   │   ├── 📄 configuracion_screen.dart
│   │   │   ├── 📄 admin_panel_screen.dart
│   │   │   ├── 📄 admin_user_list_screen.dart
│   │   │   └── 📄 admin_user_detail_screen.dart
│   │   ├── 📂 services/                 # Servicios lógica
│   │   │   ├── 📄 auth.service.dart
│   │   │   ├── 📄 api.service.dart
│   │   │   ├── 📄 supabase.service.dart
│   │   │   ├── 📄 tareas.service.dart
│   │   │   ├── 📄 planes.service.dart
│   │   │   └── 📄 historial.service.dart
│   │   ├── 📂 controllers/ (GetX)
│   │   │   ├── 📄 auth_controller.dart
│   │   │   ├── 📄 tareas_controller.dart
│   │   │   └── 📄 app_controller.dart
│   │   ├── 📂 widgets/                  # Componentes reutilizables
│   │   │   ├── 📄 custom_button.dart
│   │   │   ├── 📄 custom_textfield.dart
│   │   │   └── 📄 tarea_card.dart
│   │   ├── 📂 utils/                    # Utilidades
│   │   │   ├── 📄 constants.dart
│   │   │   ├── 📄 validators.dart
│   │   │   └── 📄 routes.dart
│   │   └── 📂 themes/
│   │       ├── 📄 app_colors.dart
│   │       └── 📄 app_theme.dart
│   ├── 📂 test/                         # Tests
│   │   ├── 📄 widget_test.dart
│   │   └── 📄 calendar_screen_test.dart
│   ├── 📂 build/ (generado)             # Código compilado
│   ├── 📂 android/                      # Configuración Android
│   ├── 📂 ios/                          # Configuración iOS
│   ├── 📂 web/                          # Configuración Web
│   ├── 📂 windows/                      # Configuración Windows
│   ├── 📂 linux/                        # Configuración Linux
│   ├── 📂 macos/                        # Configuración macOS
│   └── 📂 logo/                         # Assets (logos, imágenes)
│
├── 📂 basededatos/                      # Scripts BD
│   └── 📄 lumi.sql                      # Schema PostgreSQL
│
├── 📂 postman/                          # Colecciones Postman
│   └── 📂 globals/
│       └── 📄 workspace.globals.yaml
│
├── 📂 .github/ (recomendado)            # CI/CD
│   └── 📂 workflows/
│       └── 📄 ci-cd.yml
│
├── 📄 profile_screen.dart (suelto)      # Pantalla de perfil
├── 📄 README.md                         # Doc principal
├── 📄 READNE.md                         # Doc secundaria (TYPO)
├── 📄 PROJECT_MAP.md (creado)           # Mapa del proyecto
└── 📄 LUMIA_DETAILED_EXPLANATION.md (creado)  # Explicación detallada
```

---

## 🎯 RESUMEN EJECUTIVO

| Aspecto | Descripción |
|---------|------------|
| **Nombre** | LumiIa - Plataforma Educativa Inteligente |
| **Objetivo** | Ayudar a estudiantes a mejorar hábitos de estudio |
| **Tecnologías** | Flutter, Node.js, PostgreSQL, Google Gemini |
| **Usuarios** | Estudiantes, Administradores |
| **Funciones Principales** | Planes IA, Tareas, Técnicas, Gamificación |
| **Lenguajes** | Dart, TypeScript, SQL |
| **Plataformas** | iOS, Android, Web, Windows, Linux, macOS |
| **Estado** | En desarrollo (MVP) |
| **Base de Datos** | PostgreSQL en Supabase |
| **API IA** | Google Gemini (1.5 Pro) |
| **Autenticación** | Supabase Auth (JWT) |

---

## ⚙️ BACKEND - API (Node.js/TypeScript)

**Ubicación**: `/backend/`

### Estructura de Carpetas

```
backend/
├── src/
│   ├── server.ts                    # Express app, rutas, middleware
│   ├── config/db.ts                 # Pool PostgreSQL
│   ├── config/ia/gemini.config.ts   # Google Gemini setup
│   ├── rutas/                       # Endpoints
│   │   ├── authRoutes.ts            # Login, Register, Logout
│   │   ├── tareas.routes.ts         # CRUD tareas
│   │   ├── horarios.routes.js       # CRUD horarios
│   │   ├── ia.routes.ts             # Generar planes, preguntar
│   │   ├── historial.routes.ts      # Historial de IA
│   │   └── adminRoutes.ts           # Admin panel
│   ├── controllers/                 # Lógica
│   │   ├── tareas.controller.ts     # Validación, queries
│   │   ├── ia.controller.ts         # Coordinador de IA
│   │   ├── historial.controller.ts  # Historial
│   │   └── horariosController.js    # Horarios
│   ├── services/                    # Funciones reutilizables
│   │   ├── gemini.service.ts        # Llamadas a Gemini
│   │   └── historial.service.ts     # Operaciones historial
│   ├── prompts/                     # Templates
│   │   └── plan.prompt.ts           # Prompts para Gemini
│   └── types/                       # Tipos TS
│       └── plan.types.ts            # Interface PlanIA
└── dist/                            # Compilado (tsc)
```

### Dependencias Principales

| Dependencia | Versión | Propósito |
|-------------|---------|-----------|
| express | ^5.2.1 | Framework web |
| pg | ^8.16.0 | Driver PostgreSQL |
| @google/genai | ^2.10.0 | SDK Gemini |
| bcrypt | ^6.0.0 | Hash contraseñas |
| cors | ^2.8.6 | CORS middleware |
| dotenv | ^17.2.0 | Variables .env |
| typescript | ^5.9.3 | Compilador TS |
| tsx | ^4.20.3 | Ejecutor TS dev |

---

## 📱 FRONTEND - Aplicación Flutter

**Ubicación**: `/frontend/`

### Dependencias Principales

| Dependencia | Versión | Propósito |
|-------------|---------|-----------|
| flutter | SDK | Framework UI |
| supabase_flutter | ^2.12.4 | Auth + DB |
| google_fonts | ^8.1.0 | Tipografías |
| local_auth | ^3.0.1 | Biometría |
| http | ^1.6.0 | HTTP requests |
| intl | ^0.19.0 | i18n, fechas |
| image_picker | ^1.2.2 | Seleccionar fotos |
| table_calendar | ^3.1.3 | Calendario |

### Pantallas Implementadas (22 total)

1. **splash_screen.dart** - Pantalla de carga
2. **login_screen.dart** - Autenticación
3. **register_screen.dart** - Registro
4. **olvidar_contraseña.dart** - Recuperación
5. **dashboard_screen.dart** - Panel principal
6. **calendar_screen.dart** - Calendario interactivo
7. **agregar_tarea_screen.dart** - Crear tarea
8. **profile_screen.dart** - Perfil (vacío - TODO)
9. **pomodoro_screen.dart** - Timer Pomodoro
10. **feynman_screen.dart** - Técnica Feynman
11. **spaced_repetition_screen.dart** - Repaso espaciado
12. **active_recall_screen.dart** - Recuperación activa
13. **progreso_screen.dart** - Gráficos de progreso
14. **recompensas_screen.dart** - Logros
15. **gamification_screen.dart** - Puntos e insignias
16. **historial_ia_screen.dart** - Conversaciones IA
17. **guia_detalle_screen.dart** - Ver detalles plan
18. **seleccionar_metodo_screen.dart** - Elegir método
19. **configuracion_screen.dart** - Ajustes
20. **admin_panel_screen.dart** - Panel admin
21. **admin_user_list_screen.dart** - Listar usuarios
22. **admin_user_detail_screen.dart** - Detalles usuario

---

## 🗄️ BASE DE DATOS - PostgreSQL

**Ubicación**: `/basededatos/lumi.sql`

### Tablas Principales (13)

1. **usuarios** - Cuentas de usuario
2. **roles** - Tipos de roles (ESTUDIANTE, ADMIN)
3. **perfiles_estudio** - Preferencias por usuario
4. **planes_estudio** - Planes de estudio
5. **planes_ia** - Detalles IA de planes
6. **actividades** - Dentro de planes
7. **tareas** - Dentro de actividades
8. **horarios** - Disponibilidad de estudio
9. **historial_ia** - Conversaciones con Gemini
10. **estadisticas** - Métricas de usuario
11. **recompensas** - Logros disponibles
12. **usuario_recompensa** - Logros desbloqueados
13. **notificaciones** - Mensajes al usuario

---

## 🚀 PRÓXIMOS PASOS RECOMENDADOS

1. ✅ **Completar pantalla profile_screen.dart** (actualmente vacía)
2. ✅ **Estandarizar extensiones** (mezcla .ts y .js)
3. ✅ **Corregir typo**: READNE.md → README.md
4. ✅ **Implementar tests** (backend y frontend)
5. ✅ **Configurar CI/CD** (.github/workflows)
6. ✅ **Documentar APIs** (OpenAPI/Swagger)
7. ✅ **Agregar validaciones** (backend)
8. ✅ **Implementar autenticación** biométrica (frontend)
9. ✅ **Soporte offline** (Flutter con SQLite local)
10. ✅ **Notificaciones push** (Firebase Cloud Messaging)

---

**Documento generado**: 2026-09-01  
**Versión**: 1.0  
**Autor**: GitHub Copilot
