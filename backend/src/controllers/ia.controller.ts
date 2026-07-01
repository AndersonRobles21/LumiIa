import { Request, Response } from "express";
import { pool } from "../config/db";
import { generarPlanIA } from "../services/gemini.service";
import { GEMINI_MODEL } from "../config/ia/gemini.config";

export async function generarPlan(req: Request, res: Response) {
    const client = await pool.connect();

    try {

        const usuario_id = req.body.usuario_id;
        const nombre = req.body.nombre;
        const descripcion = req.body.descripcion ?? "";
        const fecha_entrega = req.body.fecha_entrega;
        const mensajeUsuario = req.body.mensajeUsuario ?? "";
        console.log("========== BODY RECIBIDO ==========");
        console.log(req.body);
        console.log("===================================");

        if (!usuario_id || !nombre || !fecha_entrega) {
            return res.status(400).json({
                mensaje: "Faltan datos obligatorios.",
            });
        }

        const usuarioQuery = await client.query(
            `
      SELECT
        u.nombre,
        p.objetivo,
        p.horas_disponibles,
        p.nivel_procrastinacion
      FROM usuarios u
      LEFT JOIN perfiles_estudio p
        ON p.usuario_id = u.id
      WHERE u.id = $1
      `,
            [usuario_id]
        );

        if (usuarioQuery.rows.length === 0) {
            return res.status(404).json({
                mensaje: "Usuario no encontrado.",
            });
        }

        const usuario = usuarioQuery.rows[0];

        const planIA = await generarPlanIA({
            titulo: nombre,
            descripcion: descripcion ?? "",
            fechaEntrega: fecha_entrega,

            nombreUsuario: usuario.nombre,
            objetivo: usuario.objetivo ?? "",
            horasDisponibles: usuario.horas_disponibles ?? 2,
            nivelProcrastinacion: usuario.nivel_procrastinacion ?? 3,

            mensajeUsuario,
        });

        await client.query("BEGIN");

        const planResult = await client.query(
            `
      INSERT INTO planes_estudio
      (usuario_id, nombre, descripcion, estado)
      VALUES ($1,$2,$3,'ACTIVO')
      RETURNING id
      `,
            [usuario_id, nombre, descripcion ?? ""]
        );

        const planId = planResult.rows[0].id;

        await client.query(
            `
      INSERT INTO planes_ia
      (
        plan_id,
        proveedor_ia,
        modelo_ia,
        metodo_estudio,
        justificacion,
        tiempo_estimado_total,
        consejos,
        recursos,
        resumen_final
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      `,
            [
                planId,
                "Google",
                GEMINI_MODEL,
                planIA.metodo_estudio,
                planIA.justificacion,
                planIA.tiempo_estimado_total,
                JSON.stringify(planIA.consejos),
                JSON.stringify(planIA.recursos),
                planIA.resumen_final,
            ]
        );

        if (!Array.isArray(planIA.subtareas) || planIA.subtareas.length === 0) {
            throw new Error("La IA no devolvió subtareas.");
        }

        for (const sub of planIA.subtareas) {

    const actividad = await client.query(
        `
        INSERT INTO actividades
        (plan_id, titulo, descripcion, fecha, estado)
        VALUES ($1,$2,$3,$4,'PENDIENTE')
        RETURNING id
        `,
        [planId, sub.titulo, sub.descripcion, fecha_entrega]
    );

    const tarea = await client.query(
        `
        INSERT INTO tareas
        (actividad_id, titulo, descripcion, completada)
        VALUES ($1,$2,$3,false)
        RETURNING id, completada
        `,
        [
            actividad.rows[0].id,
            sub.titulo,
            `Duración: ${sub.duracion_minutos} min | Prioridad: ${sub.prioridad}`,
        ]
    );

    
    sub.id = tarea.rows[0].id;
    sub.completada = tarea.rows[0].completada;
}

        await client.query(
            `
      INSERT INTO historial_ia
      (usuario_id, plan_id, pregunta, respuesta)
      VALUES ($1,$2,$3,$4)
      `,
            [
                usuario_id,
                planId,
                JSON.stringify({ nombre, descripcion, fecha_entrega, mensajeUsuario }),
                JSON.stringify(planIA),
            ]
        );

        await client.query("COMMIT");

        return res.status(200).json({
            ok: true,
            plan: planIA,
            plan_id: planId,
        });
    } catch (error: any) {
        try {
            await client.query("ROLLBACK");
        } catch { }

        console.error(error);

        return res.status(500).json({
            ok: false,
            mensaje: error.message,
        });
    } finally {
        client.release();
    }
}