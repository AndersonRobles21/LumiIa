// ia.routes.ts
import { Router } from "express";
import { generarPlan, evaluarFeynman, regenerarMetodoPlan } from "../controllers/ia.controller"; // <--- Aquí importamos los tres controladores necesarios
import { getPlan, actualizarProgresoPlan } from "../controllers/historial.controller";

const router = Router();

// Generar un nuevo plan con Gemini
router.post("/generar", generarPlan);

// Obtener un plan específico (para abrirlo desde el historial)
router.get("/plan/:planId", getPlan);

// Guardar el progreso de los checkboxes (pasos/subpasos)
router.put("/plan/:planId/progreso", actualizarProgresoPlan);

// 📌 RUTA NUEVA: Evaluar Feynman con IA
router.post('/feynman/evaluar', evaluarFeynman);

// 📌 RUTA NUEVA: Regenerar el plan completo con el nuevo método seleccionado
router.put("/plan/:planId/metodo", regenerarMetodoPlan);

export default router;