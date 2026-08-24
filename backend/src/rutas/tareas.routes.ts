// tareas.routes.ts
import { Router } from "express";
import {
  actualizarTarea,
  completarTarea,
  crearTarea,
  eliminarTarea,
  obtenerTareaPorId,
  obtenerTareasPorUsuario,
} from "../controllers/tareas.controller";

const router = Router();

/*
============================================================
CREAR TAREA
POST /api/tareas
POST /api/tareas/:userId
============================================================
*/
router.post("/", crearTarea);
router.post("/:userId", crearTarea);

/*
============================================================
GET TAREAS DE UN USUARIO
GET /api/tareas/:userId
============================================================
*/
router.get("/:userId", obtenerTareasPorUsuario);

/*
============================================================
GET TAREA POR ID
GET /api/tareas/detalle/:tareaId
============================================================
*/
router.get("/detalle/:tareaId", obtenerTareaPorId);

/*
============================================================
ACTUALIZAR TAREA
PUT /api/tareas/:tareaId
============================================================
*/
router.put("/:tareaId", actualizarTarea);

/*
============================================================
ELIMINAR TAREA
DELETE /api/tareas/:tareaId
============================================================
*/
router.delete("/:tareaId", eliminarTarea);

/*
============================================================
CHECKLIST
PUT /api/tareas/:tareaId/completar
============================================================
*/
router.put("/:tareaId/completar", completarTarea);

export default router;