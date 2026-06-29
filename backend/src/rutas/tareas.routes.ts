import { Router, Request, Response } from "express";
import { pool } from "../config/db";

const router = Router();

/*
============================================================
NOTA IMPORTANTE:
Esta ruta asume una tabla "tareas" con, al menos, estas columnas:

  CREATE TABLE tareas (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES usuarios(id),
    nombre TEXT NOT NULL,
    descripcion TEXT,
    fecha_entrega DATE,
    completada BOOLEAN DEFAULT FALSE,
    fecha_creacion TIMESTAMP DEFAULT NOW()
  );

Si esa tabla no existe todavía en Supabase/PostgreSQL, hay que
crearla antes de probar estos endpoints.
============================================================
*/

/*
============================================================
GET TAREAS DE UN USUARIO
GET /api/tareas/:userId
============================================================
*/
router.get("/:userId", async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId } = req.params;

    const resultado = await pool.query(
      `SELECT id, usuario_id, nombre, descripcion, fecha_entrega, completada
       FROM tareas
       WHERE usuario_id = $1
       ORDER BY fecha_entrega ASC`,
      [userId]
    );

    return res.status(200).json({ tareas: resultado.rows });
  } catch (error: any) {
    console.error("❌ Error en GET /api/tareas/:userId:", error);
    return res.status(500).json({
      mensaje: "Error interno al obtener las tareas",
      detalle: error.message || String(error),
    });
  }
});

/*
============================================================
GENERAR / CREAR UNA TAREA (PLAN DE ESTUDIO)
POST /api/tareas/generar
============================================================
*/
router.post("/generar", async (req: Request, res: Response): Promise<any> => {
  try {
    const { usuario_id, nombre, descripcion, fecha_entrega } = req.body;

    if (!usuario_id || !nombre) {
      return res.status(400).json({
        mensaje: "Faltan campos obligatorios: usuario_id o nombre.",
      });
    }

    const insertQuery = `
      INSERT INTO tareas (usuario_id, nombre, descripcion, fecha_entrega)
      VALUES ($1, $2, $3, $4)
      RETURNING id, usuario_id, nombre, descripcion, fecha_entrega, completada;
    `;
    const result = await pool.query(insertQuery, [
      usuario_id,
      nombre.trim(),
      descripcion || "",
      fecha_entrega || null,
    ]);

    const tarea = result.rows[0];

    // Estructura básica para alimentar la pantalla de guía mientras no
    // exista un motor de IA real conectado. Reemplazar esta sección
    // cuando se integre el servicio de IA que genera el plan detallado.
    const datosPlan = {
      justificacion_metodo: `Plan generado para "${tarea.nombre}". Organiza tu tiempo antes del ${tarea.fecha_entrega ?? "la fecha límite"}.`,
      actividades: [
        {
          titulo: tarea.nombre,
          descripcion: tarea.descripcion || "Sin descripción adicional.",
          tareas_checklist: [
            "Revisar los requisitos del trabajo",
            "Dividir el trabajo en partes pequeñas",
            "Entregar antes de la fecha límite",
          ],
        },
      ],
    };

    return res.status(201).json({
      mensaje: "Tarea creada correctamente",
      tarea,
      datos_plan: datosPlan,
    });
  } catch (error: any) {
    console.error("❌ Error en POST /api/tareas/generar:", error);
    return res.status(500).json({
      mensaje: "Error interno al crear la tarea",
      detalle: error.message || String(error),
    });
  }
});

export default router;