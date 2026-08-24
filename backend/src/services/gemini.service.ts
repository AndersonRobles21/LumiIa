// backend/src/services/gemini.service.ts
import { gemini, GEMINI_MODEL } from "../config/ia/gemini.config";
import { construirPromptPlan, PromptPlanInput } from "../prompts/plan.prompt";
import { PlanIA } from "../types/plan.types";

export async function generarPlanIA(
  datos: PromptPlanInput
): Promise<PlanIA> {

  const prompt = construirPromptPlan(datos);

  console.log("========== PROMPT ==========");
  console.log(prompt);
  console.log("============================");

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

  return JSON.parse(jsonLimpio);
}