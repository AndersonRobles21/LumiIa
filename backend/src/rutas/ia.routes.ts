import { Router } from "express";
import { generarPlan } from "../controllers/ia.controller";

const router = Router();

router.post("/generar", generarPlan);

export default router;