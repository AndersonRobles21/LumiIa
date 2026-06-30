import { Router, Request, Response } from "express";
import { pool } from "../config/db";
import { completarTarea } from "../controllers/tareas.controller";

const router = Router();

/*
============================================================
GET PLANES DE ESTUDIO (TAREAS PENDIENTES) DE UN USUARIO
GET /api/tareas/:userId
============================================================
*/
router.get("/:userId", async (req: Request, res: Response): Promise<any> => {
  try {

    const { userId } = req.params;

    const resultado = await pool.query(
      `
      SELECT
        id,
        nombre,
        descripcion,
        estado,
        fecha_creacion
      FROM planes_estudio
      WHERE usuario_id = $1
        AND estado = 'ACTIVO'
      ORDER BY fecha_creacion DESC
      `,
      [userId]
    );

    return res.status(200).json({
      tareas: resultado.rows,
    });

  } catch (error: any) {

    console.error("❌ Error en GET /api/tareas/:userId:", error);

    return res.status(500).json({
      mensaje: "Error interno al obtener los planes de estudio.",
      detalle: error.message,
    });

  }
});

/*
============================================================
CHECKLIST
PUT /api/tareas/:tareaId/completar
============================================================
*/
router.put("/:tareaId/completar", completarTarea);

export default router;