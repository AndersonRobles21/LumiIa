import { Router, Request, Response } from "express";
import { pool } from "../config/db";

const router = Router();

/*
============================================================
GET PLANES DE ESTUDIO (TAREAS PENDIENTES) DE UN USUARIO
GET /api/tareas/:userId

Trae los planes_estudio del usuario con estado ACTIVO.
El dashboard los muestra como "Trabajos pendientes".
============================================================
*/
router.get("/:userId", async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId } = req.params;

    const resultado = await pool.query(
      `SELECT id, nombre, descripcion, estado, fecha_creacion
       FROM planes_estudio
       WHERE usuario_id = $1
         AND estado = 'ACTIVO'
       ORDER BY fecha_creacion DESC`,
      [userId]
    );

    return res.status(200).json({ tareas: resultado.rows });
  } catch (error: any) {
    console.error("❌ Error en GET /api/tareas/:userId:", error);
    return res.status(500).json({
      mensaje: "Error interno al obtener los planes de estudio",
      detalle: error.message || String(error),
    });
  }
});

/*
============================================================
CREAR PLAN DE ESTUDIO + ACTIVIDAD + TAREA (desde el formulario de IA)
POST /api/tareas/generar

Inserta en: planes_estudio → actividades → tareas
============================================================
*/
router.post("/generar", async (req: Request, res: Response): Promise<any> => {
  const client = await pool.connect();
  try {
    const { usuario_id, nombre, descripcion, fecha_entrega } = req.body;

    if (!usuario_id || !nombre) {
      return res.status(400).json({
        mensaje: "Faltan campos obligatorios: usuario_id o nombre.",
      });
    }

    await client.query("BEGIN");

    // 1. Crear el plan de estudio
    const planResult = await client.query(
      `INSERT INTO planes_estudio (usuario_id, nombre, descripcion, estado)
       VALUES ($1, $2, $3, 'ACTIVO')
       RETURNING id, nombre, descripcion, estado, fecha_creacion`,
      [usuario_id, nombre.trim(), descripcion || ""]
    );
    const plan = planResult.rows[0];

    // 2. Crear la actividad vinculada al plan
    const actividadResult = await client.query(
      `INSERT INTO actividades (plan_id, titulo, descripcion, fecha, estado)
       VALUES ($1, $2, $3, $4, 'PENDIENTE')
       RETURNING id, titulo, descripcion, fecha, estado`,
      [
        plan.id,
        nombre.trim(),
        descripcion || "Sin descripción adicional.",
        fecha_entrega || null,
      ]
    );
    const actividad = actividadResult.rows[0];

    // 3. Crear tareas del checklist vinculadas a la actividad
    const checklistBase = [
      "Revisar los requisitos del trabajo",
      "Dividir el trabajo en partes pequeñas",
      "Entregar antes de la fecha límite",
    ];

    for (const item of checklistBase) {
      await client.query(
        `INSERT INTO tareas (actividad_id, titulo, descripcion, completada)
         VALUES ($1, $2, $3, false)`,
        [actividad.id, item, ""]
      );
    }

    await client.query("COMMIT");

    // Estructura de respuesta para la pantalla GuiaDetalleScreen
    const datosPlan = {
      justificacion_metodo: `Plan creado para "${plan.nombre}". Organiza tu tiempo antes del ${fecha_entrega ?? "la fecha límite"}.`,
      actividades: [
        {
          titulo: actividad.titulo,
          descripcion: actividad.descripcion,
          tareas_checklist: checklistBase,
        },
      ],
    };

    return res.status(201).json({
      mensaje: "Plan de estudio creado correctamente",
      plan,
      datos_plan: datosPlan,
    });
  } catch (error: any) {
    await client.query("ROLLBACK");
    console.error("❌ Error en POST /api/tareas/generar:", error);
    return res.status(500).json({
      mensaje: "Error interno al crear el plan de estudio",
      detalle: error.message || String(error),
    });
  } finally {
    client.release();
  }
});

export default router;
