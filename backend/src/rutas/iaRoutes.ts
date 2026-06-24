import { Router, Request, Response } from "express";
import { pool } from "../config/db";

const router = Router();

// ==========================================
// FUNCIONALIDAD ACTIVA: GESTIÓN DE TAREAS
// ==========================================

// Guardar tarea sencilla en la base de datos
router.post("/guardar-tarea", async (req: Request, res: Response) => {
  const { usuario_id, titulo, descripcion, fecha } = req.body;
  try {
    const result = await pool.query(
      "INSERT INTO tareas (usuario_id, titulo, descripcion, fecha, completada) VALUES ($1, $2, $3, $4, false) RETURNING *",
      [usuario_id, titulo, descripcion, fecha]
    );
    res.status(201).json(result.rows[0]);
  } catch (e) {
    res.status(500).json({ error: "Error al guardar la tarea", detalle: e });
  }
});

// Listar tareas (para el Dashboard)
router.get("/tareas/:usuario_id", async (req: Request, res: Response) => {
  const { usuario_id } = req.params;
  try {
    const result = await pool.query(
      "SELECT * FROM tareas WHERE usuario_id = $1 ORDER BY fecha ASC", 
      [usuario_id]
    );
    res.json(result.rows);
  } catch (e) {
    res.status(500).json({ error: "Error al obtener tareas", detalle: e });
  }
});
export default router;
// ==========================================
// FUTURA FUNCIONALIDAD: LÓGICA DE IA (COMENTADA)
// ==========================================

/* // Esta ruta la reactivaremos cuando implementes la IA de nuevo.
// Mantenemos la estructura de Zod y el modelo para que no tengas que reescribirlo.

import { ChatGoogleGenerativeAI } from "@langchain/google-genai";
import { z } from "zod";

const esquemaPlan = z.object({
  metodo_sugerido_id: z.number(),
  actividades: z.array(z.object({
    titulo: z.string(),
    descripcion: z.string(),
    fecha: z.string()
  }))
});

router.post("/generar-plan-ia", async (req: Request, res: Response) => {
  // Aquí irá la lógica de Gemini 1.5 Flash cuando la quieras activar
  // ... lógica de LangChain ...
  export default router;

import * as dotenv from 'dotenv';
dotenv.config();

import { Router, Request, Response } from "express";
import { pool } from "../config/db";
import { ChatGoogleGenerativeAI } from "@langchain/google-genai";
import { z } from "zod";

const router = Router();

// 1. Esquema estricto para que la IA devuelva el JSON perfecto
const esquemaPlanEstudioIA = z.object({
  metodo_sugerido_id: z.number(),
  justificacion_metodo: z.string(),
  actividades: z.array(
    z.object({
      titulo: z.string(),
      descripcion: z.string(),
      fecha: z.string(), // Formato YYYY-MM-DD
      recursos_aprendizaje: z.array(z.string()),
      tareas_checklist: z.array(z.string())
    })
  )
});

router.post("/generar-plan", async (req: Request, res: Response): Promise<any> => {
  const { usuario_id, titulo_trabajo, descripcion_trabajo, fecha_entrega } = req.body;

  if (!usuario_id || !titulo_trabajo || !fecha_entrega) {
    return res.status(400).json({ mensaje: "Faltan parámetros obligatorios." });
  }

  const client = await pool.connect();

  try {
    // 2. Obtener datos del perfil y horarios
    const perfilRes = await client.query(
      "SELECT horas_disponibles, objetivo, nivel_procrastinacion FROM perfiles_estudio WHERE usuario_id = $1",
      [usuario_id]
    );
    const perfil = perfilRes.rows[0] || { horas_disponibles: 10, objetivo: "General", nivel_procrastinacion: 4 };

    const horariosRes = await client.query(
      "SELECT dia, hora_inicio, hora_fin FROM horarios WHERE usuario_id = $1",
      [usuario_id]
    );
    const horarios = horariosRes.rows;

    const metodosRes = await client.query("SELECT id, nombre FROM metodos_estudio");
    const metodosDisponibles = metodosRes.rows;

   const model = new ChatGoogleGenerativeAI({
  apiKey: process.env.GEMINI_API_KEY, 
  model: "gemini-1.5-flash", // <--- Prueba cambiar 'modelName' por 'model'
  maxOutputTokens: 2048,
});

    // Usamos 'any' para evitar problemas de tipos con withStructuredOutput en versiones nuevas
    const modelWithStructuredOutput = (model as any).withStructuredOutput(esquemaPlanEstudioIA);

    const prompt = `
      Eres LUMI, asistente de estudio. Tu misión es desglosar un trabajo en un plan de estudio.
      Trabajo: ${titulo_trabajo}
      Descripción: ${descripcion_trabajo}
      Fecha entrega: ${fecha_entrega}
      Disponibilidad: ${JSON.stringify(horarios)}
      Métodos: ${JSON.stringify(metodosDisponibles)}
      
      Genera el cronograma respetando las fechas y rangos.
    `;

    const respuestaIA = await modelWithStructuredOutput.invoke(prompt);

    // 4. Transacción en Base de Datos
    await client.query("BEGIN");

    const planResult = await client.query(
      "INSERT INTO planes_estudio (usuario_id, nombre, descripcion, estado, fecha_creacion) VALUES ($1, $2, $3, 'ACTIVO', NOW()) RETURNING id",
      [usuario_id, titulo_trabajo, respuestaIA.justificacion_metodo]
    );
    const planId = planResult.rows[0].id;

    await client.query("INSERT INTO plan_metodo (plan_id, metodo_id) VALUES ($1, $2)", [planId, respuestaIA.metodo_sugerido_id]);

    for (const act of respuestaIA.actividades) {
      const actResult = await client.query(
        "INSERT INTO actividades (plan_id, titulo, descripcion, fecha, estado) VALUES ($1, $2, $3, $4, 'PENDIENTE') RETURNING id",
        [planId, act.titulo, `${act.descripcion}\nRecursos: ${act.recursos_aprendizaje.join(", ")}`, act.fecha]
      );
      const actividadId = actResult.rows[0].id;

      for (const tareaTitulo of act.tareas_checklist) {
        await client.query("INSERT INTO tareas (actividad_id, titulo, completada) VALUES ($1, $2, false)", [actividadId, tareaTitulo]);
      }
    }

    await client.query("COMMIT");

    return res.status(201).json({
      mensaje: "Plan generado con éxito",
      datos_plan: respuestaIA
    });

  } catch (error: any) {
    await client.query("ROLLBACK");
    console.error("❌ Error en backend:", error);
    return res.status(500).json({ mensaje: "Error al procesar con IA", detalle: error.message });
  } finally {
    client.release();
  }
});

export default router;
});
*/

