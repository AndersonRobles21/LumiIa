import { Request, Response } from "express";
import { pool } from "../config/db";
import { generarPlanIA } from "../services/gemini.service";
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

    let horasDisponibles = 0;
    horariosQuery.rows.forEach((h: any) => {
      const inicio = Number(h.hora_inicio.split(":")[0]);
      const fin = Number(h.hora_fin.split(":")[0]);
      horasDisponibles += fin - inicio;
    });

    if (horasDisponibles <= 0) horasDisponibles = 2;

    const hoy = new Date();
    const entrega = new Date(fecha_entrega);
    const diasRestantes = Math.max(1, Math.ceil((entrega.getTime() - hoy.getTime()) / (1000 * 60 * 60 * 24)));
    const minutosDisponibles = diasRestantes * horasDisponibles * 60;


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
    });

  } catch (error: any) {
    try { await client.query("ROLLBACK"); } catch { }
    console.error(error);
    return res.status(500).json({ ok: false, mensaje: error.message });
  } finally {
    client.release();
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

// 📌 ENDPOINT PARA REGENERAR EL PLAN Y SUS PASOS CON EL NUEVO MÉTODO SELECCIONADO
export async function regenerarMetodoPlan(req: Request, res: Response) {
  const { planId } = req.params;
  let { metodo_estudio, usuario_id, nombre, descripcion, fecha_entrega, dificultad } = req.body;

  try {
    console.log(`🔄 [REGENERAR] Plan ID: ${planId} | Nuevo método: ${metodo_estudio}`);

    const client = await pool.connect();
    let objetivoUsuario = "";
    let procrastinacion = 3;
    let nombreUsuario = "Estudiante";

    try {
      // 1. Si Flutter no mandó el nombre o la descripción, los buscamos directamente de la BD usando el planId
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
        fecha_entrega = fecha_entrega || new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString();
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

    // 3. Llamada obligatoria a la IA con el nuevo método forzado
    const planIA = await generarPlanIA({
      titulo: nombre,
      descripcion: descripcion,
      fechaEntrega: fecha_entrega,
      metodoEstudio: metodo_estudio, // 👈 Aquí va explícitamente el nuevo método cambiado
      dificultad: dificultad,
      enfoqueAdicional: `ATENCIÓN CRÍTICA: El estudiante ha cambiado explícitamente el método de estudio de esta tarea al método "${metodo_estudio}". DEBES generar una estructura de pasos, subpasos, conceptos clave y preguntas de recall diseñadas EXCLUSIVAMENTE para la técnica "${metodo_estudio}". No repitas el método anterior.`,
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

    // 4. Actualizar en la base de datos el método y los nuevos pasos generados por la IA
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

const planActualizado = {
      id: planId,
      nombre: nombre,
      descripcion: descripcion,
      ...planIA,
      metodo_estudio: metodo_estudio,
    };

    console.log(`✅ [EXITO] Plan ${planId} actualizado correctamente al método: ${metodo_estudio}`);
    return res.status(200).json(planActualizado);

  } catch (error: any) {
    console.error("❌ Error crítico en regenerarMetodoPlan:", error.message || error);
    return res.status(500).json({ ok: false, mensaje: error.message || "Error interno al regenerar el método." });
  }
}