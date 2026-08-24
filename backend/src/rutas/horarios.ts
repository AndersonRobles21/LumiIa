// horarios.ts
import { Router } from "express";
import { pool } from "../config/db";

const router = Router();

router.post("/:planId", async (req, res) => {
  try {
    const { planId } = req.params;
    const { dia, hora_inicio, hora_fin } = req.body;

    if (!dia || !hora_inicio || !hora_fin) {
      return res.status(400).json({
        error: "Faltan datos"
      });
    }

    if (hora_inicio >= hora_fin) {
      return res.status(400).json({
        error: "La hora de inicio debe ser menor que la hora fin"
      });
    }

    const horarios = await pool.query(
      `
      SELECT *
      FROM horarios_estudio
      WHERE plan_id = $1
      AND dia = $2
      `,
      [planId, dia]
    );

    const hayCruce = horarios.rows.some((h) =>
      hora_inicio < h.hora_fin &&
      hora_fin > h.hora_inicio
    );

    if (hayCruce) {
      return res.status(400).json({
        error: "El horario se cruza con otro bloque existente"
      });
    }

    const resultado = await pool.query(
      `
      INSERT INTO horarios_estudio
      (plan_id, dia, hora_inicio, hora_fin)
      VALUES ($1, $2, $3, $4)
      RETURNING *
      `,
      [planId, dia, hora_inicio, hora_fin]
    );

    res.status(201).json(resultado.rows[0]);

  } catch (error) {
    console.error(error);

    res.status(500).json({
      error: "Error interno del servidor"
    });
  }
});

export default router;