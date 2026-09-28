import { Request, Response } from "express";
import { pool } from "../config/db";
import { obtenerResumenEstadisticas } from "../services/estadisticas.service";

export async function obtenerProgreso(req: Request, res: Response): Promise<any> {
  try {
    const userId = Array.isArray(req.params.userId)
      ? req.params.userId[0] ?? ""
      : req.params.userId;
    return res.status(200).json(await obtenerResumenEstadisticas(userId));
  } catch (error) {
    console.error("Error obteniendo progreso:", error);
    return res.status(500).json({ mensaje: "Error al obtener progreso" });
  }
}

export async function registrarSesionEstudio(
  req: Request,
  res: Response,
): Promise<any> {
  const {
    usuario_id,
    duracion_minutos,
    tipo_origen,
    origen_id,
    categoria,
    inicio,
    fin,
  } = req.body;
  const minutos = Number(duracion_minutos);

  if (!usuario_id || !Number.isSafeInteger(minutos) || minutos <= 0) {
    return res.status(400).json({ mensaje: "Datos de sesión inválidos" });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    await client.query(
      `INSERT INTO sesiones_estudio
         (usuario_id, tipo_origen, origen_id, categoria, duracion_minutos, inicio, fin)
       VALUES ($1, $2, $3, $4, $5, $6, COALESCE($7, now()))`,
      [
        usuario_id,
        tipo_origen ?? "manual",
        origen_id ?? null,
        categoria ?? null,
        minutos,
        inicio ?? null,
        fin ?? null,
      ],
    );

    const statsResult = await client.query(
      `UPDATE estadisticas
       SET horas_estudio = COALESCE(horas_estudio, 0) + ($2 / 60.0)
       WHERE usuario_id = $1
       RETURNING tareas_completadas, horas_estudio, racha`,
      [usuario_id, minutos],
    );

    const stats = statsResult.rows[0] ?? (await client.query(
      `INSERT INTO estadisticas (usuario_id, horas_estudio)
       VALUES ($1, $2 / 60.0)
       RETURNING tareas_completadas, horas_estudio, racha`,
      [usuario_id, minutos],
    )).rows[0];

    await client.query("COMMIT");
    return res.status(201).json(stats);
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Error registrando sesión de estudio:", error);
    return res.status(500).json({ mensaje: "Error al registrar sesión" });
  } finally {
    client.release();
  }
}

export async function obtenerHorasSemana(req: Request, res: Response): Promise<any> {
  try {
    const { userId } = req.params;

    const result = await pool.query(
      `SELECT EXTRACT(ISODOW FROM fin)::int AS dia_iso,
              SUM(duracion_minutos)::int AS minutos
       FROM sesiones_estudio
       WHERE usuario_id = $1
         AND fin >= date_trunc('week', CURRENT_DATE)
         AND fin < date_trunc('week', CURRENT_DATE) + interval '7 days'
       GROUP BY dia_iso`,
      [userId],
    );

    const horasPorDia = Array(7).fill(0);
    for (const fila of result.rows) {
      const idx = Number(fila.dia_iso) - 1;
      const minutos = Number(fila.minutos);
      if (idx >= 0 && idx < 7 && Number.isFinite(minutos) && minutos >= 0) {
        horasPorDia[idx] = minutos / 60;
      }
    }

    return res.status(200).json({ horas_por_dia: horasPorDia });
  } catch (error) {
    console.error("Error obteniendo horas de la semana:", error);
    return res.status(500).json({ mensaje: "Error al obtener horas de la semana" });
  }
}