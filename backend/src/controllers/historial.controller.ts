import { Request, Response } from "express";
import { obtenerHistorialIA, obtenerPlanIA } from "../services/historial.service";
import { pool } from "../config/db";

export async function getHistorial(req: Request, res: Response) {
  try {
    const usuarioId = Array.isArray(req.params.usuarioId)
      ? req.params.usuarioId[0]
      : req.params.usuarioId;
    const historial = await obtenerHistorialIA(usuarioId ?? "");

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
    const planId = Array.isArray(req.params.planId)
      ? req.params.planId[0]
      : req.params.planId;
    const plan = await obtenerPlanIA(planId ?? "");

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

export async function actualizarProgresoPlan(req: Request, res: Response) {
  try {
    const { planId } = req.params;
    const { pasos } = req.body;

    if (!pasos || !Array.isArray(pasos)) {
      return res.status(400).json({
        ok: false,
        mensaje: "Se requiere un array de pasos válido.",
      });
    }

    await pool.query(
      `UPDATE planes_ia 
       SET pasos = $1, actualizado_en = NOW() 
       WHERE plan_id = $2`,
      [JSON.stringify(pasos), planId]
    );

    return res.status(200).json({
      ok: true,
      mensaje: "Progreso de pasos actualizado correctamente.",
    });
  } catch (error: any) {
    console.error("Error en PUT /api/ia/plan/:planId/progreso:", error);
    return res.status(500).json({
      ok: false,
      mensaje: "Error al guardar el progreso en la base de datos.",
      detalle: error.message,
    });
  }
}