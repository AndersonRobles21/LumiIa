// backend/src/services/gemini.service.ts
import { gemini, GEMINI_MODEL } from "../config/ia/gemini.config";
import { construirPromptPlan, PromptPlanInput } from "../prompts/plan.prompt";
import { PlanIA } from "../types/plan.types";

// Modelo de respaldo en caso de que el principal sufra saturación (503)
const GEMINI_FALLBACK_MODEL = "gemini-1.5-flash";

/**
 * Función auxiliar para ejecutar peticiones a Gemini con Exponential Backoff
 * y cambio a modelo secundario si el principal devuelve 503 o 429.
 */
async function ejecutarConRetryYFallback<T>(
  fn: (modelToUse: string) => Promise<T>,
  intentos = 3,
  esperaMs = 1000,
  modeloActual = GEMINI_MODEL
): Promise<T> {
  try {
    return await fn(modeloActual);
  } catch (error: any) {
    const esErrorTemporal = error?.status === 503 || error?.status === 429;

    if (intentos > 1 && esErrorTemporal) {
      // Si falla en los primeros intentos, cambiamos al modelo fallback
      const siguienteModelo =
        modeloActual === GEMINI_MODEL ? GEMINI_FALLBACK_MODEL : GEMINI_MODEL;

      console.warn(
        `⚠️ Gemini (${modeloActual}) ocupado (Status ${error?.status}). Reintentando en ${esperaMs}ms usando modelo: ${siguienteModelo}...`
      );

      await new Promise((resolve) => setTimeout(resolve, esperaMs));

      return ejecutarConRetryYFallback(
        fn,
        intentos - 1,
        esperaMs * 2, // Incremento exponencial del tiempo de espera
        siguienteModelo
      );
    }

    throw error;
  }
}

export async function generarPlanIA(
  datos: PromptPlanInput
): Promise<PlanIA> {
  const prompt = construirPromptPlan(datos);

  console.log("========== PROMPT ==========");
  console.log(prompt);
  console.log("============================");

  return ejecutarConRetryYFallback(async (modelo) => {
    const response = await gemini.models.generateContent({
      model: modelo,
      contents: prompt,
      config: {
        temperature: 0.2,
        responseMimeType: "application/json",
      },
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
  });
}

export async function evaluarExplicacionFeynmanIA(
  concepto: string,
  explicacion: string
): Promise<{ aprobado: boolean; mensaje: string }> {
  const prompt = `Actúa como Lumi, una tutora virtual amigable pero estricta. El estudiante debe explicar el concepto "${concepto}" usando la técnica Feynman. 
La explicación del estudiante es: "${explicacion}".

Analiza detalladamente si la explicación es seria, coherente y demuestra que entendió el núcleo del tema. 
Si el estudiante escribió una broma, una grosería, palabras repetidas sin sentido, o texto absurdo (como decir tonterías o cosas sin relación), debes rechazarlo (aprobado: false).

Devuelve la respuesta strictly en un objeto JSON con esta estructura exacta y sin texto adicional:
{
  "aprobado": true o false,
  "mensaje": "Un mensaje corto de Lumi felicitándolo si está bien o corrigiéndolo con cariño si está mal o es broma."
}`;

  return ejecutarConRetryYFallback(async (modelo) => {
    const response = await gemini.models.generateContent({
      model: modelo,
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

    return JSON.parse(jsonLimpio);
  });
}