# LumiIa
``La procrastinación y la mala organización académica afectan directamente el rendimiento, la motivación y el proceso de aprendizaje de los aprendices. Muchos aprendices dejan tareas para último momento, generan estrés innecesario y disminuyen la calidad de sus trabajos. Solucionar esta problemática permitirá fortalecer la disciplina, mejorar la administración del
tiempo y fomentar el aprendizaje autónomo La aplicación y página web brindará beneficios a los aprendices al recibir planes de estudio
personalizados, recomendaciones inteligentes y herramientas de motivación mediante gamificación, ayudando a mejorar la organización del tiempo, el cumplimiento de actividades académicas y el desarrollo de hábitos de estudio más constantes y eficientes. Además, contribuirá a disminuir el estrés académico y fortalecer el autoaprendizaje en los programas de formación.
Desarrollar una aplicación móvil y página web con inteligencia artificial descriptiva para los aprendices de los programas de Análisis y Desarrollo de Software (ADSO), Biotecnología y
Agroindustria del CBA de Mosquera, con el fin de generar planes de estudio personalizados y fomentar hábitos eficientes que permitan combatir la procrastinación.``

```env id="n0d82k"
# =====================================================
# AUTH ENDPOINTS
# =====================================================

POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/auth/recovery

# =====================================================
# PROFILE ENDPOINTS
# =====================================================

GET    /api/profile
PUT    /api/profile

# =====================================================
# TASKS ENDPOINTS
# =====================================================

GET   /api/tasks
GET   /api/tasks/{id}
POST  /api/tasks
PUT   /api/tasks/{id}
DELETE /api/tasks/{id}

# =====================================================
# AI ENDPOINTS
# =====================================================

POST  /api/tasks/{id}/ai

# =====================================================
# STUDY METHODS ENDPOINTS
# =====================================================

GET   /api/methods
POST  /api/methods/select

# =====================================================
# GAMIFICATION ENDPOINTS
# =====================================================

GET   /api/streaks
GET   /api/rewards

# =====================================================
# STATS ENDPOINTS
# =====================================================

GET   /api/stats
GET   /api/stats/progress
GET   /api/stats/performance

# =====================================================
# ADMIN AUTH ENDPOINTS
# =====================================================

POST  /api/admin/login
POST  /api/admin/logout
POST  /api/admin/recovery

# =====================================================
# ADMIN USERS ENDPOINTS
# =====================================================

GET    /api/admin/users
POST   /api/admin/users
PUT    /api/admin/users/{id}
DELETE /api/admin/users/{id}

# =====================================================
# ADMIN ROLES ENDPOINTS
# =====================================================

POST   /api/admin/roles

# =====================================================
# ADMIN METHODS ENDPOINTS
# =====================================================

GET    /api/admin/methods
POST   /api/admin/methods
PUT    /api/admin/methods/{id}
DELETE /api/admin/methods/{id}

# =====================================================
# ADMIN STATS ENDPOINTS
# =====================================================

GET   /api/admin/stats
GET   /api/admin/stats/users
GET   /api/admin/stats/tasks
GET   /api/admin/stats/ai
```
