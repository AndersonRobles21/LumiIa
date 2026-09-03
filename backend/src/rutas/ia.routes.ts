import { Router } from "express";
import { generarPlan, evaluarFeynman, regenerarMetodoPlan, eliminarPlan, reajustarPlanIA } from "../controllers/ia.controller";
import { getPlan, actualizarProgresoPlan } from "../controllers/historial.controller";

const router = Router();

// Generar un nuevo plan con Gemini
router.post("/generar", generarPlan);

// Obtener un plan específico (para abrirlo desde el historial)
router.get("/plan/:planId", getPlan);

// Guardar el progreso de los checkboxes (pasos/subpasos)
router.put("/plan/:planId/progreso", actualizarProgresoPlan);
router.put("/plan/:planId/reajustar-fecha", reajustarPlanIA);


// Evaluar Feynman con IA
router.post('/feynman/evaluar', evaluarFeynman);

// Regenerar el plan completo con el nuevo método seleccionado
router.put("/plan/:planId/metodo", regenerarMetodoPlan);

// Eliminar un plan específico
router.delete("/plan/:planId", eliminarPlan);

export default router;