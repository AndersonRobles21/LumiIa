import { Router } from "express";
import { getHistorial } from "../controllers/historial.controller";

const router = Router();

router.get("/:usuarioId", getHistorial);

export default router;