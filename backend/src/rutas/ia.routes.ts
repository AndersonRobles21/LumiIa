import { Router } from "express";
import { generarPlan } from "../controllers/ia.controller";
import { getPlan } from "../controllers/historial.controller";

const router = Router();

router.post("/generar", generarPlan);
router.get("/plan/:planId", getPlan);

export default router;