import { Request, Response } from "express";
import { pool } from "../config/db";

export async function completarTarea(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { tareaId } = req.params;
    const { completada } = req.body;

    if (typeof completada !== "boolean") {
      return res.status(400).json({
        ok: false,
        mensaje: "El campo 'completada' debe ser boolean."
      });
    }

    const resultado = await pool.query(
      `
      UPDATE tareas
      SET completada = $1
      WHERE id = $2
      RETURNING *
      `,
      [completada, tareaId]
    );

    if (resultado.rowCount === 0) {
      return res.status(404).json({
        ok: false,
        mensaje: "Tarea no encontrada."
      });
    }

    return res.status(200).json({
      ok: true,
      mensaje: "Tarea actualizada correctamente.",
      tarea: resultado.rows[0]
    });

  } catch (error: any) {

    console.error("Error completarTarea:", error);

    return res.status(500).json({
      ok: false,
      mensaje: error.message
    });

  }
}