// backend/src/services/gemini.service.ts
import { gemini, GEMINI_MODEL } from "../config/ia/gemini.config";
import { construirPromptPlan, PromptPlanInput } from "../prompts/plan.prompt";
import { PlanIA } from "../types/plan.types";

// Función auxiliar para esperar unos segundos entre reintentos
const esperar = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// Función genérica para manejar llamadas a Gemini con reintentos automáticos en caso de error 503
async function intentarConReintentos(fn: () => Promise<any>, maxIntentos = 3, esperaMs = 3000) {
  let intentos = maxIntentos;
  while (intentos > 0) {
    try {
      return await fn();
    } catch (error: any) {
      // Si es un error 503 (Servicio no disponible / alta demanda) y quedan intentos
      if (error?.status === 503 && intentos > 1) {
        console.warn(`[Gemini] Servidores saturados (503). Reintentando en ${esperaMs / 1000}s... (Intentos restantes: ${intentos - 1})`);
        await esperar(esperaMs);
        intentos--;
      } else {
        throw error;
      }
    }
  }
}

export async function generarPlanIA(
  datos: PromptPlanInput
): Promise<PlanIA> {
  const prompt = construirPromptPlan(datos);

  console.log("========== PROMPT ==========");
  console.log(prompt);
  console.log("============================");

  // Llamada envuelta con reintentos automáticos
  const response = await intentarConReintentos(async () => {
    return await gemini.models.generateContent({
      model: GEMINI_MODEL,
      contents: prompt,
      config: {
        temperature: 0.2,
        responseMimeType: "application/json",
      },
    });
  });

  const texto = response.text;

  if (!texto) {
    throw new Error("Gemini no devolvió respuesta.");
  }

  const jsonLimpio = texto
    .replace(/```json/g, "")
    .replace(/```/g, "")
    .trim();

  try {
    const plan: PlanIA = JSON.parse(jsonLimpio);

    console.log("========== RESPUESTA JSON DE GEMINI ==========");
    console.log(JSON.stringify(plan, null, 2));
    console.log("==============================================");

    return plan;
  } catch (error) {
    console.error("Respuesta completa de Gemini:");
    console.error(texto);
    throw new Error("Gemini devolvió un JSON inválido.");
  }
}

export async function evaluarExplicacionFeynmanIA(
  concepto: string,
  explicacion: string
): Promise<{ aprobado: boolean; mensaje: string }> {
  const prompt = `Actúa como Lumi, una tutora virtual amigable pero estricta. El estudiante debe explicar el concepto "${concepto}" usando la técnica Feynman. 
La explicación del estudiante es: "${explicacion}".

Analiza detalladamente si la explicación es seria, coherente y demuestra que entendió el núcleo del tema. 
Si el estudiante escribió una broma, una grosería, palabras repetidas sin sentido, o texto absurdo (como decir tonterías o cosas sin relación), debes rechazarlo (aprobado: false).

Devuelve la respuesta estrictamente en un objeto JSON con esta estructura exacta y sin texto adicional:
{
  "aprobado": true o false,
  "mensaje": "Un mensaje corto de Lumi felicitándolo si está bien o corrigiéndolo con cariño si está mal o es broma."
}`;

  // Llamada envuelta con reintentos automáticos
  const response = await intentarConReintentos(async () => {
    return await gemini.models.generateContent({
      model: GEMINI_MODEL,
      contents: prompt,
      config: {
        temperature: 0.2,
        responseMimeType: "application/json",
      },
    });
  });

  const texto = response.text;
  if (!texto) {
    throw new Error("Gemini no devolvió respuesta para la evaluación.");
  }

  const jsonLimpio = texto
    .replace(/```json/g, "")
    .replace(/```/g, "")
    .trim();

  return JSON.parse(jsonLimpio);
}