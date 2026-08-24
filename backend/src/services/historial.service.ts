import { pool } from "../config/db";

export async function obtenerHistorialIA(usuarioId: string) {
  const resultado = await pool.query(
    `
    SELECT
      pe.id,
      pe.nombre,
      pe.descripcion,
      pe.estado,
      pe.fecha_creacion,
      pi.metodo_estudio,
      pi.tiempo_estimado_total,
      pi.resumen_final
    FROM planes_estudio pe
    LEFT JOIN planes_ia pi
      ON pi.plan_id = pe.id
    WHERE pe.usuario_id = $1
    ORDER BY pe.fecha_creacion DESC
    `,
    [usuarioId]
  );

  return resultado.rows;
}

export async function obtenerPlanIA(planId: string) {
  const result = await pool.query(
    `SELECT 
        p.id,
        p.nombre,
        p.descripcion,
        p.fecha_creacion,
        pia.metodo_estudio,
        pia.justificacion,
        pia.tiempo_estimado_total,
        pia.consejos,
        pia.recursos,
        pia.resumen_final,
        pia.pasos,
        pia.conceptos_clave,
        pia.preguntas_recall
     FROM planes_estudio p
     INNER JOIN planes_ia pia ON pia.plan_id = p.id
     WHERE p.id = $1`,
    [planId]
  );

  if (result.rows.length === 0) return null;

  const row = result.rows[0];
  return {
    id: row.id,
    nombre: row.nombre,
    descripcion: row.descripcion,
    metodo_estudio: row.metodo_estudio,
    justificacion: row.justificacion,
    tiempo_estimado_total: row.tiempo_estimado_total,
    consejos: typeof row.consejos === 'string' ? JSON.parse(row.consejos) : row.consejos,
    recursos: typeof row.recursos === 'string' ? JSON.parse(row.recursos) : row.recursos,
    resumen_final: row.resumen_final,
    pasos: typeof row.pasos === 'string' ? JSON.parse(row.pasos) : row.pasos,
    conceptos_clave: typeof row.conceptos_clave === 'string' ? JSON.parse(row.conceptos_clave) : row.conceptos_clave,
    preguntas_recall: typeof row.preguntas_recall === 'string' ? JSON.parse(row.preguntas_recall) : row.preguntas_recall,
  };
}