import { pool } from "../config/db";

function numeroNoNegativo(valor: unknown): number {
  const numero = typeof valor === "number" ? valor : Number(valor);
  return Number.isFinite(numero) && numero >= 0 ? numero : 0;
}

export function contarPlanesPrincipales(
  planes: Array<{ pasos: unknown; completado_en?: unknown }>,
): { total: number; completados: number; faltantes: number } {
  let total = 0;
  let completados = 0;

  for (const plan of planes) {
    total++;

    let pasos: unknown = plan.pasos;
    if (typeof pasos === "string") {
      try {
        pasos = JSON.parse(pasos);
      } catch {
        pasos = [];
      }
    }
    const fases = Array.isArray(pasos) ? pasos : [];
    const planCompletado = plan.completado_en != null || (
      fases.length > 0 && fases.every((paso) => {
        if (!paso || typeof paso !== "object") return false;
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

        return pasoCompletado || subpasosCompletos;
      })
    );

    if (planCompletado) completados++;
  }

  return { total, completados, faltantes: total - completados };
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
      `SELECT p.completado_en, pi.pasos
       FROM planes_estudio p
       LEFT JOIN planes_ia pi ON pi.plan_id = p.id
       WHERE p.usuario_id = $1`,
      [usuarioId],
    ),
  ]);

  const fila = estadisticasResult.rows[0] ?? {};
  const planesPrincipales = contarPlanesPrincipales(planesResult.rows);
  return {
    planes_principales_totales: planesPrincipales.total,
    planes_principales_completados: planesPrincipales.completados,
    tareas_faltantes: planesPrincipales.faltantes,
    tareas_completadas: Math.trunc(numeroNoNegativo(fila.tareas_completadas)),
    horas_estudio: numeroNoNegativo(fila.horas_estudio),
    racha: Math.trunc(numeroNoNegativo(fila.racha)),
  };
}