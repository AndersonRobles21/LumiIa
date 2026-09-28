import { pool } from "../config/db";

function numeroNoNegativo(valor: unknown): number {
  const numero = typeof valor === "number" ? valor : Number(valor);
  return Number.isFinite(numero) && numero >= 0 ? numero : 0;
}

export function contarPasosPrincipales(
  planes: Array<{ pasos: unknown }>,
): { total: number; completados: number } {
  let total = 0;
  let completados = 0;

  for (const plan of planes) {
    let pasos: unknown = plan.pasos;
    if (typeof pasos === "string") {
      try {
        pasos = JSON.parse(pasos);
      } catch {
        continue;
      }
    }
    if (!Array.isArray(pasos)) continue;

    for (const paso of pasos) {
      if (!paso || typeof paso !== "object") continue;
      total++;

      const subpasos = Array.isArray((paso as Record<string, unknown>).subpasos)
        ? (paso as Record<string, unknown>).subpasos as unknown[]
        : [];
      const pasoCompletado = (paso as Record<string, unknown>).completado === true;
      const subpasosCompletos = subpasos.length > 0 && subpasos.every(
        (subpaso) =>
          subpaso != null &&
          typeof subpaso === "object" &&
          (subpaso as Record<string, unknown>).completado === true,
      );

      if (pasoCompletado || subpasosCompletos) completados++;
    }
  }

  return { total, completados };
}

export async function obtenerResumenEstadisticas(usuarioId: string) {
  const [estadisticasResult, planesResult] = await Promise.all([
    pool.query(
      `SELECT
                 COALESCE(
                   (SELECT MAX(tareas_completadas)
                    FROM estadisticas
                    WHERE usuario_id = $1),
                   0
                 )::int AS tareas_completadas,
       COALESCE(
         (SELECT SUM(duracion_minutos)::numeric / 60.0
          FROM sesiones_estudio
          WHERE usuario_id = $1),
         0
       ) AS horas_estudio,
       COALESCE(
         (SELECT MAX(racha) FROM estadisticas WHERE usuario_id = $1),
         0
       )::int AS racha
       `,
      [usuarioId],
    ),
    pool.query(
      `SELECT pi.pasos
       FROM planes_estudio p
       JOIN planes_ia pi ON pi.plan_id = p.id
       WHERE p.usuario_id = $1`,
      [usuarioId],
    ),
  ]);

  const fila = estadisticasResult.rows[0] ?? {};
  const pasosPrincipales = contarPasosPrincipales(planesResult.rows);
  return {
    pasos_principales_totales: pasosPrincipales.total,
    pasos_principales_completados: pasosPrincipales.completados,
    tareas_completadas: Math.trunc(numeroNoNegativo(fila.tareas_completadas)),
    horas_estudio: numeroNoNegativo(fila.horas_estudio),
    racha: Math.trunc(numeroNoNegativo(fila.racha)),
  };
}