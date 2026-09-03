import { Router } from "express";
import {
  obtenerProgreso,
  registrarSesionEstudio,
} from "../controllers/progreso.controller";

const router = Router();

router.get("/:userId", obtenerProgreso);
router.post("/sesion", registrarSesionEstudio);

export default router;