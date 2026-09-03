import { Request, Response } from "express";
import { pool } from "../config/db";
import { generarPlanIA } from "../services/gemini.service";
import { calcularCapacidadPlan } from "../services/disponibilidad.service";
import { GEMINI_MODEL, gemini } from "../config/ia/gemini.config";

export async function generarPlan(req: Request, res: Response) {
  const client = await pool.connect();

  try {
    const usuario_id = req.body.usuario_id;
    const nombre = req.body.nombre;
    const descripcion = req.body.descripcion ?? "";
    const fecha_entrega = req.body.fecha_entrega;
    const metodo_estudio = req.body.metodo_estudio ?? "Pomodoro";
    const dificultad = req.body.dificultad ?? "Media";
    const enfoque_adicional = req.body.enfoque_adicional ?? "";
    const mensajeUsuario = req.body.mensajeUsuario ?? "";

    if (!usuario_id || !nombre || !fecha_entrega) {
      return res.status(400).json({ mensaje: "Faltan datos obligatorios." });
    }

    const fechaEntrega = new Date(`${fecha_entrega}T00:00:00`);
    const hoyNormalizado = new Date();
    hoyNormalizado.setHours(0, 0, 0, 0);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(fecha_entrega) ||
        Number.isNaN(fechaEntrega.getTime()) || fechaEntrega < hoyNormalizado) {
      return res.status(400).json({ mensaje: "La fecha de entrega debe ser válida y no puede estar en el pasado." });
    }

    const usuarioQuery = await client.query(
      `SELECT u.nombre, p.objetivo, p.nivel_procrastinacion 
       FROM usuarios u 
       LEFT JOIN perfiles_estudio p ON p.usuario_id = u.id 
       WHERE u.id = $1`,
      [usuario_id]
    );

    if (usuarioQuery.rows.length === 0) {
      return res.status(404).json({ mensaje: "Usuario no encontrado." });
    }

    const usuario = usuarioQuery.rows[0];

    // Consulta de horarios y días restantes
    const horariosQuery = await client.query(
      `SELECT dia, hora_inicio, hora_fin FROM horarios WHERE usuario_id = $1`,
      [usuario_id]
    );

    const capacidadInicial = calcularCapacidadPlan(fecha_entrega, horariosQuery.rows);
    const { horasPorDia: horasDisponibles, diasRestantes, minutosDisponibles } = capacidadInicial;


    // Generar Plan con IA
    const planIA = await generarPlanIA({
      titulo: nombre,
      descripcion,
      fechaEntrega: fecha_entrega,
      metodoEstudio: metodo_estudio,
      dificultad,
      enfoqueAdicional: enfoque_adicional,
      nombreUsuario: usuario.nombre,
      objetivo: usuario.objetivo ?? "",
      horasDisponibles,
      nivelProcrastinacion: usuario.nivel_procrastinacion ?? 3,
      diasRestantes,
      minutosDisponibles,
      mensajeUsuario,
    });

    const tiempoEstimado = Number(planIA.tiempo_estimado_total ?? 0);
    const estadoDisponibilidad = calcularCapacidadPlan(
      fecha_entrega,
      horariosQuery.rows,
      tiempoEstimado
    ).estado;
    const tiempoInsuficiente = estadoDisponibilidad !== "SUFICIENTE";

    await client.query("BEGIN");

    // 1. Insertar en planes_estudio
    const planResult = await client.query(
      `INSERT INTO planes_estudio (usuario_id, nombre, descripcion, estado)
       VALUES ($1, $2, $3, 'ACTIVO') RETURNING id`,
      [usuario_id, nombre, descripcion]
    );

    const planId = planResult.rows[0].id;

    // 2. Insertar en planes_ia guardando pasos, conceptos y preguntas en jsonb
    await client.query(
      `INSERT INTO planes_ia 
       (plan_id, proveedor_ia, modelo_ia, metodo_estudio, justificacion, 
        tiempo_estimado_total, consejos, recursos, resumen_final, pasos, conceptos_clave, preguntas_recall)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
      [
        planId,
        "Google",
        GEMINI_MODEL,
        planIA.metodo_estudio || metodo_estudio,
        planIA.justificacion,
        planIA.tiempo_estimado_total,
        JSON.stringify(planIA.consejos ?? []),
        JSON.stringify(planIA.recursos ?? []),
        planIA.resumen_final,
        JSON.stringify(planIA.pasos ?? []),
        JSON.stringify(planIA.conceptos_clave ?? []),
        JSON.stringify(planIA.preguntas_recall ?? []),
      ]
    );

    // 3. Insertar en historial_ia
    await client.query(
      `INSERT INTO historial_ia (usuario_id, plan_id, pregunta, respuesta)
       VALUES ($1, $2, $3, $4)`,
      [
        usuario_id,
        planId,
        JSON.stringify({ nombre, descripcion, fecha_entrega, metodo_estudio, dificultad, enfoque_adicional }),
        JSON.stringify(planIA),
      ]
    );

    await client.query("COMMIT");

    // Inyectamos el ID del plan generado en el JSON retornado a Flutter
    const respuestaFinal = {
      id: planId,
      nombre: nombre,
      descripcion: descripcion,
      ...planIA,
    };

    return res.status(200).json({
      ok: true,
      plan: respuestaFinal,
      plan_id: planId,
      recomendacion_tiempo: tiempoInsuficiente
        ? estadoDisponibilidad === "AJUSTADO"
          ? "Tienes poco margen para completar esta tarea. El plan requerirá aprovechar casi todo tu tiempo disponible."
          : "El tiempo disponible parece ser insuficiente para completar todo el contenido antes de la fecha de entrega. Te recomendamos aumentarlo si es posible."
        : null,
      estado_disponibilidad: estadoDisponibilidad,
      minutos_disponibles: minutosDisponibles,
    });

  } catch (error: any) {
    try { await client.query("ROLLBACK"); } catch { }
    console.error(error);
    return res.status(500).json({ ok: false, mensaje: error.message });
  } finally {
    client.release();
  }
}

// 📌 ENDPOINT PARA OBTENER EL DETALLE DE UN PLAN Y SU VALIDACIÓN DE TIEMPO
export async function obtenerPlanPorId(req: Request, res: Response) {
  const { planId } = req.params;

  try {
    const client = await pool.connect();
    
    const planRes = await client.query(
      `SELECT pe.id, pe.usuario_id, pe.nombre, pe.descripcion, pe.estado, pe.creado_en AS created_at,
              pi.proveedor_ia, pi.modelo_ia, pi.metodo_estudio, pi.justificacion, 
              pi.tiempo_estimado_total, pi.consejos, pi.recursos, pi.resumen_final, 
              pi.pasos, pi.conceptos_clave, pi.preguntas_recall
       FROM planes_estudio pe
       LEFT JOIN planes_ia pi ON pi.plan_id = pe.id
       WHERE pe.id = $1`,
      [planId]
    );

    if (planRes.rows.length === 0) {
      client.release();
      return res.status(404).json({ ok: false, mensaje: "Plan no encontrado." });
    }

    const planData = planRes.rows[0];
    const usuario_id = planData.usuario_id;

    // Rescatar la última fecha de entrega guardada en el historial
    const historialRes = await client.query(
      `SELECT (h.pregunta::json)->>'fecha_entrega' AS fecha_entrega 
       FROM historial_ia h WHERE h.plan_id = $1 ORDER BY h.fecha DESC LIMIT 1`,
      [planId]
    );

    let fechaEntrega = historialRes.rows.length > 0 ? historialRes.rows[0].fecha_entrega : null;
    
    // Si no hay fecha en el historial, usamos una por defecto o la actual + 5 días
    if (!fechaEntrega) {
      fechaEntrega = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    }

    // Consultar horarios del usuario para recalcular capacidad
    const horariosQuery = await client.query(
      `SELECT dia, hora_inicio, hora_fin FROM horarios WHERE usuario_id = $1`,
      [usuario_id]
    );

    client.release();

    const tiempoEstimado = Number(planData.tiempo_estimado_total ?? 0);
    const estadoDisponibilidad = calcularCapacidadPlan(
      fechaEntrega,
      horariosQuery.rows,
      tiempoEstimado
    ).estado;
    const tiempoInsuficiente = estadoDisponibilidad !== "SUFICIENTE";

    return res.status(200).json({
      ok: true,
      ...planData,
      fecha_entrega: fechaEntrega,
      recomendacion_tiempo: tiempoInsuficiente
        ? estadoDisponibilidad === "AJUSTADO"
          ? "Tienes poco margen para completar esta tarea. El plan requerirá aprovechar casi todo tu tiempo disponible."
          : "El tiempo disponible parece ser insuficiente para completar todo el contenido antes de la fecha de entrega. Te recomendamos aumentarlo si es posible."
        : null,
      estado_disponibilidad: estadoDisponibilidad,
    });

  } catch (error: any) {
    console.error("❌ Error en obtenerPlanPorId:", error);
    return res.status(500).json({ ok: false, mensaje: error.message });
  }
}

// 📌 ENDPOINT PARA GUARDAR EL ESTADO DE LOS CHECKBOXES (PROGRESO)
export async function actualizarProgreso(req: Request, res: Response) {
  const { planId } = req.params;
  const { pasos } = req.body;

  try {
    await pool.query(
      `UPDATE planes_ia SET pasos = $1, actualizado_en = NOW() WHERE plan_id = $2`,
      [JSON.stringify(pasos), planId]
    );

    return res.status(200).json({ ok: true, mensaje: "Progreso actualizado" });
  } catch (error: any) {
    return res.status(500).json({ ok: false, mensaje: error.message });
  }
}

// eliminar un plan específico
export async function eliminarPlan(req: Request, res: Response) {
  const client = await pool.connect();
  
  try {
    const { planId } = req.params;

    await client.query('BEGIN');

    // 1. Eliminar de historial_ia
    await client.query('DELETE FROM historial_ia WHERE plan_id = $1', [planId]);

    // 2. Eliminar de planes_ia
    await client.query('DELETE FROM planes_ia WHERE plan_id = $1', [planId]);

    // 3. Eliminar actividades y tareas asociadas
    await client.query(`
      DELETE FROM tareas 
      WHERE actividad_id IN (
        SELECT id FROM actividades WHERE plan_id = $1
      )
    `, [planId]);

    await client.query('DELETE FROM actividades WHERE plan_id = $1', [planId]);

    // 4. Finalmente eliminar el plan principal
    const result = await client.query('DELETE FROM planes_estudio WHERE id = $1 RETURNING id', [planId]);

    await client.query('COMMIT');

    if (result.rowCount === 0) {
      return res.status(404).json({
        ok: false,
        mensaje: 'Plan no encontrado',
      });
    }

    return res.status(200).json({
      ok: true,
      mensaje: 'Plan eliminado correctamente',
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    console.error('Error eliminando plan:', error);
    return res.status(500).json({
      ok: false,
      mensaje: 'Error al eliminar el plan',
      detalle: error.message,
    });
  } finally {
    client.release();
  }
}

// 📌 ENDPOINT PARA EVALUAR LA TÉCNICA FEYNMAN CON IA
export async function evaluarFeynman(req: Request, res: Response) {
  try {
    const { concepto, explicacion } = req.body;

    if (!concepto || !explicacion) {
      return res.status(400).json({ 
        aprobado: false, 
        mensaje: "Faltan datos obligatorios para evaluar." 
      });
    }

    const prompt = `Actúa como Lumi, una tutora virtual amigable pero estricta. El estudiante debe explicar el concepto "${concepto}" usando la técnica Feynman. 
La explicación del estudiante es: "${explicacion}".

Analiza detalladamente si la explicación es seria, coherente y demuestra que entendió el núcleo del tema. 
Si el estudiante escribió una broma, una grosería, palabras repetidas sin sentido, o texto absurdo (como decir tonterías, insultos o cosas sin relación lógica con el concepto), debes rechazarlo (aprobado: false).

Devuelve la respuesta estrictamente en un objeto JSON con esta estructura exacta y sin texto adicional por fuera del JSON:
{
  "aprobado": true o false,
  "mensaje": "Un mensaje corto de Lumi felicitándolo con energía si está bien, o corrigiéndolo con cariño y firmeza si está mal o es broma."
}`;

    const response = await gemini.models.generateContent({
      model: GEMINI_MODEL,
      contents: prompt,
      config: {
        temperature: 0.2,
        responseMimeType: "application/json",
      },
    });

    const texto = response.text;
    if (!texto) {
      throw new Error("Gemini no devolvió respuesta para la evaluación.");
    }

    const jsonLimpio = texto
      .replace(/```json/g, "")
      .replace(/```/g, "")
      .trim();

    const resultadoIA = JSON.parse(jsonLimpio);

    return res.status(200).json(resultadoIA);

  } catch (error: any) {
    console.error("Error al evaluar Feynman con IA:", error);
    return res.status(500).json({ 
      aprobado: false, 
      mensaje: "Error interno del servidor al evaluar con IA." 
    });
  }
}

// 📌 ENDPOINT PARA REGENERAR EL PLAN Y SUS PASOS CON EL NUEVO MÉTODO SELECCIONADO Y NUEVA FECHA
export async function regenerarMetodoPlan(req: Request, res: Response) {
  const { planId } = req.params;
  let { metodo_estudio, usuario_id, nombre, descripcion, fecha_entrega, dificultad } = req.body;

  try {
    console.log(`🔄 [REGENERAR] Plan ID: ${planId} | Nuevo método: ${metodo_estudio} | Nueva fecha: ${fecha_entrega}`);

    const client = await pool.connect();
    let objetivoUsuario = "";
    let procrastinacion = 3;
    let nombreUsuario = "Estudiante";

    try {
      // 1. Buscamos los datos actuales de la base de datos
      const planDbRes = await client.query(
        `SELECT pe.nombre, pe.descripcion, pe.usuario_id, pi.dificultad, pi.fecha_generacion 
         FROM planes_estudio pe 
         LEFT JOIN planes_ia pi ON pi.plan_id = pe.id 
         WHERE pe.id = $1`,
        [planId]
      );

      if (planDbRes.rows.length > 0) {
        const planData = planDbRes.rows[0];
        nombre = nombre || planData.nombre || "Estudio";
        descripcion = descripcion || planData.descripcion || "";
        usuario_id = usuario_id || planData.usuario_id;
        dificultad = dificultad || planData.dificultad || "Media";
        
        // Si no mandaron fecha nueva, intentamos rescatar la última fecha registrada en el historial
        if (!fecha_entrega) {
          const historialRes = await client.query(
            `SELECT (h.pregunta::json)->>'fecha_entrega' AS fecha_antigua 
             FROM historial_ia h WHERE h.plan_id = $1 ORDER BY h.fecha DESC LIMIT 1`,
            [planId]
          );
          if (historialRes.rows.length > 0 && historialRes.rows[0].fecha_antigua) {
            fecha_entrega = historialRes.rows[0].fecha_antigua;
          } else {
            fecha_entrega = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
          }
        }
      }

      // 2. Buscar datos del usuario y su perfil
      if (usuario_id) {
        const userRes = await client.query(
          `SELECT u.nombre, p.objetivo, p.nivel_procrastinacion 
           FROM usuarios u 
           LEFT JOIN perfiles_estudio p ON p.usuario_id = u.id 
           WHERE u.id = $1`,
          [usuario_id]
        );
        if (userRes.rows.length > 0) {
          nombreUsuario = userRes.rows[0].nombre || "Estudiante";
          objetivoUsuario = userRes.rows[0].objetivo || "";
          procrastinacion = userRes.rows[0].nivel_procrastinacion || 3;
        }
      }
    } finally {
      client.release();
    }

    if (!metodo_estudio) {
      return res.status(400).json({ ok: false, mensaje: "El método de estudio es obligatorio." });
    }

    // 3. Llamada obligatoria a la IA con los datos actualizados
    const planIA = await generarPlanIA({
      titulo: nombre,
      descripcion: descripcion,
      fechaEntrega: fecha_entrega,
      metodoEstudio: metodo_estudio,
      dificultad: dificultad,
      enfoqueAdicional: `ATENCIÓN CRÍTICA: El estudiante ha cambiado explícitamente el método de estudio de esta tarea al método "${metodo_estudio}" y su nueva fecha límite es ${fecha_entrega}. DEBES generar una estructura de pasos ajustada a este tiempo.`,
      nombreUsuario: nombreUsuario,
      objetivo: objetivoUsuario,
      horasDisponibles: 4,
      nivelProcrastinacion: procrastinacion,
      diasRestantes: 5,
      minutosDisponibles: 1200,
      mensajeUsuario: "",
    });

    if (!planIA) {
      throw new Error("El servicio de Gemini no devolvió datos para la regeneración.");
    }

    // 4. Actualizar en la base de datos el método y los pasos
    await pool.query(
      `UPDATE planes_ia 
       SET metodo_estudio = $1, 
           justificacion = $2, 
           tiempo_estimado_total = $3, 
           consejos = $4, 
           recursos = $5, 
           resumen_final = $6, 
           pasos = $7, 
           conceptos_clave = $8, 
           preguntas_recall = $9, 
           actualizado_en = NOW() 
       WHERE plan_id = $10`,
      [
        metodo_estudio,
        planIA.justificacion ?? "",
        planIA.tiempo_estimado_total ?? 30,
        JSON.stringify(planIA.consejos ?? []),
        JSON.stringify(planIA.recursos ?? []),
        planIA.resumen_final ?? "",
        JSON.stringify(planIA.pasos ?? []),
        JSON.stringify(planIA.conceptos_clave ?? []),
        JSON.stringify(planIA.preguntas_recall ?? []),
        planId,
      ]
    );

    // 5. 🔑 IMPORTANTE: Insertamos un nuevo registro en historial_ia para que la nueva fecha quede guardada y el calendario la lea
    await pool.query(
      `INSERT INTO historial_ia (usuario_id, plan_id, pregunta, respuesta)
       VALUES ($1, $2, $3, $4)`,
      [
        usuario_id,
        planId,
        JSON.stringify({ nombre, descripcion, fecha_entrega, metodo_estudio, dificultad }),
        JSON.stringify(planIA),
      ]
    );

    const planActualizado = {
      id: planId,
      nombre: nombre,
      descripcion: descripcion,
      fecha_entrega: fecha_entrega,
      ...planIA,
      metodo_estudio: metodo_estudio,
    };

    console.log(`✅ [EXITO] Plan ${planId} actualizado al método ${metodo_estudio} y fecha ${fecha_entrega}`);
    return res.status(200).json(planActualizado);

  } catch (error: any) {
    console.error("❌ Error crítico en regenerarMetodoPlan:", error.message || error);
    return res.status(500).json({ ok: false, mensaje: error.message || "Error interno al regenerar el método." });
  }
}

// 📌 ENDPOINT PARA REAJUSTAR SOLAMENTE LA FECHA DE ENTREGA DEL PLAN (MATEMÁTICAMENTE SIN USAR IA)
export async function reajustarPlanIA(req: Request, res: Response) {
  const { planId } = req.params;
  const { fecha_entrega } = req.body;

  try {
    if (!fecha_entrega) {
      return res.status(400).json({ ok: false, mensaje: "La nueva fecha de entrega es obligatoria." });
    }

    console.log(`📅 [REAJUSTAR FECHA MATEMÁTICO] Plan ID: ${planId} | Nueva fecha: ${fecha_entrega}`);

    const client = await pool.connect();

    try {
      // 1. Buscamos los datos actuales del plan y sus pasos en la base de datos
      const planDbRes = await client.query(
        `SELECT pe.nombre, pe.descripcion, pe.usuario_id, pi.pasos 
         FROM planes_estudio pe 
         LEFT JOIN planes_ia pi ON pi.plan_id = pe.id 
         WHERE pe.id = $1`,
        [planId]
      );

      if (planDbRes.rows.length === 0) {
        client.release();
        return res.status(404).json({ ok: false, mensaje: "Plan no encontrado." });
      }

      const planData = planDbRes.rows[0];
      const usuario_id = planData.usuario_id;
      const nombre = planData.nombre || "Estudio";
      const descripcion = planData.descripcion || "";
      let pasos = planData.pasos || [];

      // 2. Rescatar la última fecha de entrega anterior registrada en el historial para calcular la diferencia
      const historialRes = await client.query(
        `SELECT (h.pregunta::json)->>'fecha_entrega' AS fecha_antigua 
         FROM historial_ia h WHERE h.plan_id = $1 ORDER BY h.fecha DESC LIMIT 1`,
        [planId]
      );

      const fechaAntiguaStr = historialRes.rows.length > 0 ? historialRes.rows[0].fecha_antigua : null;

      // 3. Desplazar las fechas de los pasos de forma matemática si existen fechas previas
      if (fechaAntiguaStr && Array.isArray(pasos) && pasos.length > 0) {
        const fechaAntigua = new Date(`${fechaAntiguaStr}T00:00:00`);
        const fechaNueva = new Date(`${fecha_entrega}T00:00:00`);
        
        const diferenciaDias = Math.round((fechaNueva.getTime() - fechaAntigua.getTime()) / (1000 * 60 * 60 * 24));

        pasos = pasos.map((paso: any) => {
          if (paso.fecha) {
            const fPaso = new Date(`${paso.fecha}T00:00:00`);
            fPaso.setDate(fPaso.getDate() + diferenciaDias);
            paso.fecha = fPaso.toISOString().split('T')[0];
          }
          return paso;
        });
      }

      // 4. Actualizamos los pasos reajustados en planes_ia
      await client.query(
        `UPDATE planes_ia 
         SET pasos = $1, actualizado_en = NOW() 
         WHERE plan_id = $2`,
        [JSON.stringify(pasos), planId]
      );

      // 5. Insertamos el registro en historial_ia para que el calendario detecte la nueva fecha al refrescar
      await client.query(
        `INSERT INTO historial_ia (usuario_id, plan_id, pregunta, respuesta)
         VALUES ($1, $2, $3, $4)`,
        [
          usuario_id,
          planId,
          JSON.stringify({ nombre, descripcion, fecha_entrega }),
          JSON.stringify({ mensaje: "Reajustado sin IA", pasos })
        ]
      );

      client.release();

      console.log(`✅ [EXITO] Fecha del plan ${planId} reajustada matemáticamente al ${fecha_entrega}`);
      
      return res.status(200).json({ 
        ok: true, 
        mensaje: "Fecha actualizada con éxito",
        pasos: pasos
      });

    } catch (innerError: any) {
      client.release();
      throw innerError;
    }

  } catch (error: any) {
    console.error("❌ Error crítico en reajustarPlanIA:", error.message || error);
    return res.status(500).json({ ok: false, mensaje: error.message || "Error al reajustar la fecha." });
  }
}