import { Request, Response } from "express";
import { obtenerHistorialIA, obtenerPlanIA } from "../services/historial.service";

export async function getHistorial(req: Request, res: Response) {
  try {
    const { usuarioId } = req.params;
    const historial = await obtenerHistorialIA(usuarioId);

    return res.status(200).json(historial);
  } catch (error: any) {
    console.error("Error en GET /api/ia/historial/:usuarioId:", error);
    return res.status(500).json({
      ok: false,
      mensaje: "Error interno al obtener el historial de IA.",
      detalle: error.message,
    });
  }
}

export async function getPlan(req: Request, res: Response) {
  try {
    const { planId } = req.params;
    const plan = await obtenerPlanIA(planId);

    if (!plan) {
      return res.status(404).json({
        ok: false,
        mensaje: "Plan no encontrado.",
      });
    }

    return res.status(200).json(plan);
  } catch (error: any) {
    console.error("Error en GET /api/ia/plan/:planId:", error);
    return res.status(500).json({
      ok: false,
      mensaje: "Error interno al obtener el plan de IA.",
      detalle: error.message,
    });
  }
}
