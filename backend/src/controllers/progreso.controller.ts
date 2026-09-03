import { Request, Response } from "express";
import { pool } from "../config/db";

export async function obtenerProgreso(req: Request, res: Response): Promise<any> {
  try {
    const result = await pool.query(
      `SELECT tareas_completadas, horas_estudio, racha
       FROM estadisticas
       WHERE usuario_id = $1`,
      [req.params.userId],
    );

    return res.status(200).json(
      result.rows[0] ?? { tareas_completadas: 0, horas_estudio: 0, racha: 0 },
    );
  } catch (error) {
    console.error("Error obteniendo progreso:", error);
    return res.status(500).json({ mensaje: "Error al obtener progreso" });
  }
}

export async function registrarSesionEstudio(
  req: Request,
  res: Response,
): Promise<any> {
  const { usuario_id, duracion_minutos } = req.body;
  const minutos = Number(duracion_minutos);

  if (!usuario_id || !Number.isFinite(minutos) || minutos <= 0) {
    return res.status(400).json({ mensaje: "Datos de sesión inválidos" });
  }

  try {
    const result = await pool.query(
      `INSERT INTO estadisticas (usuario_id, horas_estudio)
       VALUES ($1, $2 / 60.0)
       ON CONFLICT (usuario_id)
       DO UPDATE SET horas_estudio = estadisticas.horas_estudio + ($2 / 60.0)
       RETURNING tareas_completadas, horas_estudio, racha`,
      [usuario_id, minutos],
    );

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error("Error registrando sesión de estudio:", error);
    return res.status(500).json({ mensaje: "Error al registrar sesión" });
  }
}
