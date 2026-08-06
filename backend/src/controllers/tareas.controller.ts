import { Request, Response } from "express";
import { pool } from "../config/db";

function mapTareaRow(row: any) {
  return {
    id: row.id,
    nombre: row.nombre ?? row.titulo ?? "",
    descripcion: row.descripcion ?? "",
    estado: row.estado ?? (row.completada ? "COMPLETADA" : "PENDIENTE"),
    fecha_creacion: row.fecha_creacion ?? new Date().toISOString(),
    completada: row.completada ?? false,
  };
}

export function normalizarTareaPayload(payload: Record<string, any>) {
  const nombre = typeof payload.nombre === "string" ? payload.nombre.trim() : "";
  const titulo = typeof payload.titulo === "string" ? payload.titulo.trim() : nombre;

  if (!titulo) {
    return {
      error: "El campo 'nombre' es obligatorio.",
    };
  }

  let descripcion = payload.descripcion ?? "";
  if (descripcion !== null && typeof descripcion !== "string") {
    return {
      error: "El campo 'descripcion' debe ser texto.",
    };
  }

  let completada = payload.completada;
  if (completada !== undefined && typeof completada !== "boolean") {
    return {
      error: "El campo 'completada' debe ser booleano.",
    };
  }

  if (completada === undefined) {
    completada = false;
  }

  let estado = payload.estado ?? "";
  if (typeof estado !== "string") {
    return {
      error: "El campo 'estado' debe ser texto.",
    };
  }

  estado = estado.trim();
  if (!estado) {
    estado = completada ? "COMPLETADA" : "PENDIENTE";
  }

  const actividadId = payload.actividad_id ?? null;
  const usuarioId = typeof payload.usuario_id === "string" && payload.usuario_id.trim() !== ""
    ? payload.usuario_id.trim()
    : null;

  return {
    titulo,
    descripcion,
    estado,
    completada,
    actividad_id: actividadId,
    usuario_id: usuarioId,
  };
}

async function obtenerActividadParaTarea(
  usuarioId: string | null,
  actividadId: number | null,
  titulo: string,
  descripcion: string
) {
  if (actividadId) {
    return actividadId;
  }

  if (!usuarioId) {
    return null;
  }

  const planResultado = await pool.query(
    `
    SELECT id
    FROM planes_estudio
    WHERE usuario_id = $1
      AND estado = 'ACTIVO'
    ORDER BY fecha_creacion DESC
    LIMIT 1
    `,
    [usuarioId]
  );

  if (planResultado.rows.length === 0) {
    return null;
  }

  const actividadResultado = await pool.query(
    `
    INSERT INTO actividades
    (plan_id, titulo, descripcion, fecha, estado)
    VALUES ($1, $2, $3, CURRENT_DATE, 'PENDIENTE')
    RETURNING id
    `,
    [planResultado.rows[0].id, titulo, descripcion || "Tarea pendiente"]
  );

  return actividadResultado.rows[0].id;
}

export async function crearTarea(req: Request, res: Response): Promise<any> {
  try {
    const payload = normalizarTareaPayload(req.body);

    if ("error" in payload) {
      return res.status(400).json({
        ok: false,
        mensaje: payload.error,
      });
    }

    const usuarioId = typeof req.params.userId === "string" && req.params.userId.trim() !== ""
      ? req.params.userId.trim()
      : payload.usuario_id;

    if (!usuarioId) {
      return res.status(400).json({
        ok: false,
        mensaje: "Se requiere un usuario válido para crear la tarea.",
      });
    }

    const actividadId = await obtenerActividadParaTarea(
      usuarioId,
      payload.actividad_id,
      payload.titulo,
      payload.descripcion
    );

    const resultado = await pool.query(
      `
      INSERT INTO tareas
      (actividad_id, titulo, descripcion, completada)
      VALUES ($1, $2, $3, $4)
      RETURNING id, actividad_id, titulo, descripcion, completada
      `,
      [actividadId, payload.titulo, payload.descripcion, payload.completada]
    );

    const tarea = mapTareaRow({
      ...resultado.rows[0],
      estado: payload.estado,
      fecha_creacion: new Date().toISOString(),
    });

    return res.status(201).json({
      ok: true,
      mensaje: "Tarea creada correctamente.",
      tarea,
    });
  } catch (error: any) {
    console.error("❌ Error en crearTarea:", error);

    return res.status(500).json({
      ok: false,
      mensaje: error.message,
    });
  }
}

export async function obtenerTareasPorUsuario(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({
        ok: false,
        mensaje: "Se requiere un usuario válido.",
      });
    }

    const resultado = await pool.query(
      `
      SELECT
        t.id,
        t.titulo AS nombre,
        t.descripcion,
        CASE
          WHEN t.completada THEN 'COMPLETADA'
          ELSE 'PENDIENTE'
        END AS estado,
        NOW()::timestamp AS fecha_creacion,
        t.completada
      FROM tareas t
      LEFT JOIN actividades a ON a.id = t.actividad_id
      LEFT JOIN planes_estudio p ON p.id = a.plan_id
      WHERE p.usuario_id = $1 OR t.actividad_id IS NULL
      ORDER BY t.id DESC
      `,
      [userId]
    );

    return res.status(200).json({
      ok: true,
      tareas: resultado.rows.map(mapTareaRow),
    });
  } catch (error: any) {
    console.error("❌ Error en obtenerTareasPorUsuario:", error);

    return res.status(500).json({
      ok: false,
      mensaje: error.message,
    });
  }
}

export async function obtenerTareaPorId(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { tareaId } = req.params;

    const resultado = await pool.query(
      `
      SELECT
        id,
        titulo AS nombre,
        descripcion,
        CASE
          WHEN completada THEN 'COMPLETADA'
          ELSE 'PENDIENTE'
        END AS estado,
        NOW()::timestamp AS fecha_creacion,
        completada
      FROM tareas
      WHERE id = $1
      `,
      [tareaId]
    );

    if (resultado.rowCount === 0) {
      return res.status(404).json({
        ok: false,
        mensaje: "Tarea no encontrada.",
      });
    }

    return res.status(200).json({
      ok: true,
      tarea: mapTareaRow(resultado.rows[0]),
    });
  } catch (error: any) {
    console.error("❌ Error en obtenerTareaPorId:", error);

    return res.status(500).json({
      ok: false,
      mensaje: error.message,
    });
  }
}

export async function actualizarTarea(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { tareaId } = req.params;
    const payload = normalizarTareaPayload(req.body);

    if ("error" in payload) {
      return res.status(400).json({
        ok: false,
        mensaje: payload.error,
      });
    }

    const resultado = await pool.query(
      `
      UPDATE tareas
      SET
        titulo = $1,
        descripcion = $2,
        completada = $3
      WHERE id = $4
      RETURNING id, titulo, descripcion, completada
      `,
      [payload.titulo, payload.descripcion, payload.completada, tareaId]
    );

    if (resultado.rowCount === 0) {
      return res.status(404).json({
        ok: false,
        mensaje: "Tarea no encontrada.",
      });
    }

    return res.status(200).json({
      ok: true,
      mensaje: "Tarea actualizada correctamente.",
      tarea: mapTareaRow({
        ...resultado.rows[0],
        estado: payload.estado,
        fecha_creacion: new Date().toISOString(),
      }),
    });
  } catch (error: any) {
    console.error("❌ Error en actualizarTarea:", error);

    return res.status(500).json({
      ok: false,
      mensaje: error.message,
    });
  }
}

export async function eliminarTarea(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { tareaId } = req.params;

    const resultado = await pool.query(
      `
      DELETE FROM tareas
      WHERE id = $1
      RETURNING id
      `,
      [tareaId]
    );

    if (resultado.rowCount === 0) {
      return res.status(404).json({
        ok: false,
        mensaje: "Tarea no encontrada.",
      });
    }

    return res.status(200).json({
      ok: true,
      mensaje: "Tarea eliminada correctamente.",
    });
  } catch (error: any) {
    console.error("❌ Error en eliminarTarea:", error);

    return res.status(500).json({
      ok: false,
      mensaje: error.message,
    });
  }
}

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
        mensaje: "El campo 'completada' debe ser booleano.",
      });
    }

    const resultado = await pool.query(
      `
      UPDATE tareas
      SET completada = $1
      WHERE id = $2
      RETURNING id, titulo, descripcion, completada
      `,
      [completada, tareaId]
    );

    if (resultado.rowCount === 0) {
      return res.status(404).json({
        ok: false,
        mensaje: "Tarea no encontrada.",
      });
    }

    return res.status(200).json({
      ok: true,
      mensaje: "Tarea actualizada correctamente.",
      tarea: mapTareaRow({
        ...resultado.rows[0],
        estado: completada ? "COMPLETADA" : "PENDIENTE",
        fecha_creacion: new Date().toISOString(),
      }),
    });
  } catch (error: any) {
    console.error("❌ Error en completarTarea:", error);

    return res.status(500).json({
      ok: false,
      mensaje: error.message,
    });
  }
}