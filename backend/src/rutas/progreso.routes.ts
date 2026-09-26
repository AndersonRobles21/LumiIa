import { Router } from "express";
import {
  obtenerProgreso,
  registrarSesionEstudio,
  obtenerHorasSemana,
} from "../controllers/progreso.controller";

const router = Router();

router.get("/:userId/semana", obtenerHorasSemana);
router.get("/:userId", obtenerProgreso);
router.post("/sesion", registrarSesionEstudio);

export default router;