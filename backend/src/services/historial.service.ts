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
  const resultado = await pool.query(
    `
    SELECT respuesta
    FROM historial_ia
    WHERE plan_id = $1
    ORDER BY id DESC
    LIMIT 1
    `,
    [planId]
  );

  if (resultado.rows.length === 0) {
    return null;
  }

  const respuesta = resultado.rows[0].respuesta;
  if (typeof respuesta === "string") {
    return JSON.parse(respuesta);
  }

  return respuesta;
}
