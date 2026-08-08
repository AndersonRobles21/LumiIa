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