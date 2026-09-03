import { Request, Response } from "express";
import { pool } from "../config/db";
import { generarPlanIA } from "../services/gemini.service";
import { calcularCapacidadPlan } from "../services/disponibilidad.service";

const UUID_REGEX = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$/;

function esUuidValido(valor: string | undefined | null): boolean {
  if (typeof valor !== "string") return false;
  return UUID_REGEX.test(valor.trim());
}

function obtenerParametroUnico(valor: string | string[] | undefined): string {
  if (Array.isArray(valor)) {
    return valor[0] ?? "";
  }
  return valor ?? "";
}

function mapTareaRow(row: any) {
  return {
    id: row.id,
    actividad_id: row.actividad_id ?? null,
    nombre: row.nombre ?? row.titulo ?? "",
    descripcion: row.descripcion ?? "",
    estado: row.estado ?? (row.completada ? "COMPLETADA" : "PENDIENTE"),
    fecha_creacion: row.fecha_creacion ?? new Date().toISOString(),
    fecha_entrega: row.fecha_entrega ?? row.fecha ?? null,
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
  const fechaEntrega = payload.fecha_entrega == null
    ? null
    : typeof payload.fecha_entrega === "string" && /^\d{4}-\d{2}-\d{2}$/.test(payload.fecha_entrega)
      ? payload.fecha_entrega
      : undefined;

  if (fechaEntrega === undefined) {
    return { error: "El campo 'fecha_entrega' debe tener formato YYYY-MM-DD." };
  }

  return {
    titulo,
    descripcion,
    estado,
    completada,
    actividad_id: actividadId,
    usuario_id: usuarioId,
    fecha_entrega: fechaEntrega,
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

    if (payload.fecha_entrega) {
      const fechaEntrega = new Date(`${payload.fecha_entrega}T00:00:00`);
      const hoy = new Date();
      hoy.setHours(0, 0, 0, 0);
      if (Number.isNaN(fechaEntrega.getTime()) || fechaEntrega < hoy) {
        return res.status(400).json({
          ok: false,
          mensaje: "La fecha de entrega debe ser válida y no puede estar en el pasado.",
        });
      }
    }

    const usuarioIdParam = typeof req.params.userId === "string" ? req.params.userId.trim() : "";
    const usuarioId = usuarioIdParam !== ""
      ? usuarioIdParam
      : payload.usuario_id;

    if (!usuarioId) {
      return res.status(400).json({
        ok: false,
        mensaje: "Se requiere un usuario válido para crear la tarea.",
      });
    }

    if (usuarioIdParam !== "" && !esUuidValido(usuarioIdParam)) {
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
    const userId = obtenerParametroUnico(req.params.userId);

    if (!esUuidValido(userId)) {
      return res.status(400).json({
        ok: false,
        mensaje: "Se requiere un usuario válido.",
      });
    }

    const resultado = await pool.query(
      `
      SELECT
        t.id,
        t.actividad_id,
        t.titulo AS nombre,
        t.descripcion,
        CASE
          WHEN t.completada THEN 'COMPLETADA'
          ELSE 'PENDIENTE'
        END AS estado,
        NOW()::timestamp AS fecha_creacion,
        a.fecha AS fecha_entrega,
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
    const tareaId = obtenerParametroUnico(req.params.tareaId);

    if (!esUuidValido(tareaId)) {
      return res.status(400).json({
        ok: false,
        mensaje: "Identificador de tarea inválido.",
      });
    }

    const resultado = await pool.query(
      `
      SELECT
        t.id,
        t.actividad_id,
        t.titulo AS nombre,
        t.descripcion,
        CASE
          WHEN t.completada THEN 'COMPLETADA'
          ELSE 'PENDIENTE'
        END AS estado,
        NOW()::timestamp AS fecha_creacion,
        a.fecha AS fecha_entrega,
        t.completada
      FROM tareas t
      LEFT JOIN actividades a ON a.id = t.actividad_id
      WHERE t.id = $1
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
    const tareaId = obtenerParametroUnico(req.params.tareaId);

    if (!esUuidValido(tareaId)) {
      return res.status(400).json({
        ok: false,
        mensaje: "Identificador de tarea inválido.",
      });
    }

    const payload = normalizarTareaPayload(req.body);

    if ("error" in payload) {
      return res.status(400).json({
        ok: false,
        mensaje: payload.error,
      });
    }

    const contexto = await pool.query(
      `
      SELECT t.id, t.actividad_id, a.plan_id, a.fecha,
             p.usuario_id, p.nombre, p.descripcion,
             u.nombre AS nombre_usuario, pe.objetivo, pe.nivel_procrastinacion,
             pia.metodo_estudio, pia.dificultad, pia.pasos,
             pia.enfoque_adicional
      FROM tareas t
      LEFT JOIN actividades a ON a.id = t.actividad_id
      LEFT JOIN planes_estudio p ON p.id = a.plan_id
      LEFT JOIN usuarios u ON u.id = p.usuario_id
      LEFT JOIN perfiles_estudio pe ON pe.usuario_id = p.usuario_id
      LEFT JOIN planes_ia pia ON pia.plan_id = p.id
      WHERE t.id = $1
      `,
      [tareaId]
    );

    if (contexto.rowCount === 0) {
      return res.status(404).json({ ok: false, mensaje: "Tarea no encontrada." });
    }

    const actual = contexto.rows[0];
    if (payload.fecha_entrega && payload.usuario_id !== actual.usuario_id) {
      return res.status(403).json({
        ok: false,
        mensaje: "No tienes permiso para modificar esta tarea.",
      });
    }
    let planRegenerado: any = null;

    if (payload.fecha_entrega && actual.plan_id && actual.usuario_id) {
      const horarios = await pool.query(
        `SELECT hora_inicio, hora_fin FROM horarios WHERE usuario_id = $1`,
        [actual.usuario_id]
      );
      const capacidad = calcularCapacidadPlan(payload.fecha_entrega, horarios.rows);
      const { horasPorDia: horasDisponibles, diasRestantes, minutosDisponibles } = capacidad;
      const pasosAnteriores = typeof actual.pasos === "string"
        ? JSON.parse(actual.pasos)
        : (actual.pasos ?? []);

      planRegenerado = await generarPlanIA({
        titulo: actual.nombre,
        descripcion: actual.descripcion ?? "",
        fechaEntrega: payload.fecha_entrega,
        metodoEstudio: actual.metodo_estudio ?? "Auto",
        dificultad: actual.dificultad ?? "Media",
        enfoqueAdicional: "Reorganiza la planificación para la nueva fecha de entrega, manteniendo el método de estudio seleccionado.",
        nombreUsuario: actual.nombre_usuario ?? "Estudiante",
        objetivo: actual.objetivo ?? "",
        horasDisponibles,
        nivelProcrastinacion: actual.nivel_procrastinacion ?? 3,
        diasRestantes,
        minutosDisponibles,
        mensajeUsuario: "",
      });

      const progresoPorId = new Map<string, boolean>();
      for (const paso of Array.isArray(pasosAnteriores) ? pasosAnteriores : []) {
        for (const subpaso of paso?.subpasos ?? []) {
          if (subpaso?.id != null) progresoPorId.set(String(subpaso.id), subpaso.completado === true);
        }
      }
      for (const paso of Array.isArray(planRegenerado.pasos) ? planRegenerado.pasos : []) {
        for (const subpaso of paso?.subpasos ?? []) {
          if (progresoPorId.has(String(subpaso.id))) {
            subpaso.completado = progresoPorId.get(String(subpaso.id));
          }
        }
      }
    }

    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      if (payload.fecha_entrega && actual.actividad_id) {
        await client.query("UPDATE actividades SET fecha = $1 WHERE id = $2", [payload.fecha_entrega, actual.actividad_id]);
      }
      if (planRegenerado && actual.plan_id) {
        await client.query(
          `UPDATE planes_ia SET metodo_estudio = $1, justificacion = $2,
             tiempo_estimado_total = $3, consejos = $4, recursos = $5,
             resumen_final = $6, pasos = $7, conceptos_clave = $8,
             preguntas_recall = $9, actualizado_en = NOW() WHERE plan_id = $10`,
          [actual.metodo_estudio ?? planRegenerado.metodo_estudio, planRegenerado.justificacion ?? "",
            planRegenerado.tiempo_estimado_total, JSON.stringify(planRegenerado.consejos ?? []),
            JSON.stringify(planRegenerado.recursos ?? []), planRegenerado.resumen_final ?? "",
            JSON.stringify(planRegenerado.pasos ?? []), JSON.stringify(planRegenerado.conceptos_clave ?? []),
            JSON.stringify(planRegenerado.preguntas_recall ?? []), actual.plan_id]
        );
        await client.query(
          `INSERT INTO historial_ia (usuario_id, plan_id, pregunta, respuesta)
           VALUES ($1, $2, $3, $4)`,
          [actual.usuario_id, actual.plan_id, JSON.stringify({ nombre: actual.nombre, descripcion: actual.descripcion, fecha_entrega: payload.fecha_entrega, metodo_estudio: actual.metodo_estudio }), JSON.stringify(planRegenerado)]
        );
      }

      const resultado = await client.query(
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

      await client.query("COMMIT");

      return res.status(200).json({
        ok: true,
        mensaje: planRegenerado ? "Tarea y planificación reorganizadas correctamente." : "Tarea actualizada correctamente.",
        tarea: mapTareaRow({ ...resultado.rows[0], actividad_id: actual.actividad_id, fecha_entrega: payload.fecha_entrega ?? actual.fecha }),
      });
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    } finally {
      client.release();
    }
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
    const tareaId = obtenerParametroUnico(req.params.tareaId);

    if (!esUuidValido(tareaId)) {
      return res.status(400).json({
        ok: false,
        mensaje: "Identificador de tarea inválido.",
      });
    }

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
    const tareaId = obtenerParametroUnico(req.params.tareaId);

    if (!esUuidValido(tareaId)) {
      return res.status(400).json({
        ok: false,
        mensaje: "Identificador de tarea inválido.",
      });
    }

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

    const userResult = await pool.query(
      `
      SELECT p.usuario_id
      FROM tareas t
      JOIN actividades a ON a.id = t.actividad_id
      JOIN planes_estudio p ON p.id = a.plan_id
      WHERE t.id = $1
      LIMIT 1
      `,
      [tareaId]
    );

    const userId = userResult.rows[0]?.usuario_id;
    if (userId) {
      const statsResult = await pool.query(
        `
        SELECT
          COUNT(*) AS total_tareas,
          COUNT(*) FILTER (WHERE t.completada = true) AS tareas_completadas
        FROM tareas t
        JOIN actividades a ON a.id = t.actividad_id
        JOIN planes_estudio p ON p.id = a.plan_id
        WHERE p.usuario_id = $1
        `,
        [userId]
      );

      const totalTareas = Number(statsResult.rows[0]?.total_tareas ?? 0);
      const tareasCompletadas = Number(statsResult.rows[0]?.tareas_completadas ?? 0);

      await pool.query(
        `
        INSERT INTO estadisticas (usuario_id, tareas_completadas, racha, horas_estudio)
        VALUES ($1, $2, 0, 0)
        ON CONFLICT (usuario_id) DO UPDATE SET tareas_completadas = EXCLUDED.tareas_completadas
        `,
        [userId, tareasCompletadas]
      );

      if (totalTareas === 0) {
        await pool.query(
          `UPDATE estadisticas SET tareas_completadas = 0 WHERE usuario_id = $1`,
          [userId]
        );
      }
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