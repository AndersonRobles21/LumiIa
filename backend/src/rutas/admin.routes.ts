import { Router, Request, Response, NextFunction } from "express";
import { pool } from "../config/db";

const router = Router();

async function esAdministrador(userId: string): Promise<boolean> {
  const usuarioRes = await pool.query(
    `SELECT es_admin
     FROM usuarios
     WHERE id = $1`,
    [userId]
  );

  if (usuarioRes.rows.length === 0) return false;

  return Boolean(usuarioRes.rows[0]?.es_admin === true);
}

async function requireAdmin(req: Request, res: Response, next: NextFunction) {
  const adminUserId = req.params.userId ?? req.body?.userId ?? req.query?.userId;

  if (!adminUserId || typeof adminUserId !== "string") {
    return res.status(400).json({ ok: false, mensaje: "Falta el identificador del administrador." });
  }

  const ok = await esAdministrador(adminUserId);
  if (!ok) {
    return res.status(403).json({ ok: false, mensaje: "Acceso denegado. El usuario no tiene permisos de administrador." });
  }

  return next();
}

router.get("/summary/:userId", requireAdmin, async (req: Request, res: Response): Promise<any> => {
  try {
    const totalUsuariosRes = await pool.query(`SELECT COUNT(*)::int AS total FROM usuarios`);
    const estudiantesRes = await pool.query(`SELECT COUNT(*)::int AS total FROM usuarios WHERE COALESCE(es_admin, false) = false`);
    const administradoresRes = await pool.query(`SELECT COUNT(*)::int AS total FROM usuarios WHERE COALESCE(es_admin, false) = true`);
    const planesRes = await pool.query(`SELECT COUNT(*)::int AS total FROM planes_estudio`);
    const tareasRes = await pool.query(`SELECT COUNT(*)::int AS total FROM tareas`);
    const tareasCompletadasRes = await pool.query(`SELECT COUNT(*)::int AS total FROM tareas WHERE completada = true`);
    const planesPorDiaRes = await pool.query(`
      SELECT DATE(fecha_creacion) AS fecha, COUNT(*)::int AS total
      FROM planes_estudio
      GROUP BY DATE(fecha_creacion)
      ORDER BY fecha DESC
      LIMIT 30
    `);
    const tareasPorDiaRes = await pool.query(`
      SELECT DATE(a.fecha) AS fecha, COUNT(*)::int AS total
      FROM tareas t
      JOIN actividades a ON a.id = t.actividad_id
      GROUP BY DATE(a.fecha)
      ORDER BY fecha DESC
      LIMIT 30
    `);
    const tareasCompletadasPorDiaRes = await pool.query(`
      SELECT DATE(a.fecha) AS fecha, COUNT(*)::int AS total
      FROM tareas t
      JOIN actividades a ON a.id = t.actividad_id
      WHERE t.completada = true
      GROUP BY DATE(a.fecha)
      ORDER BY fecha DESC
      LIMIT 30
    `);

    return res.status(200).json({
      ok: true,
      totalUsuarios: Number(totalUsuariosRes.rows[0]?.total ?? 0),
      estudiantes: Number(estudiantesRes.rows[0]?.total ?? 0),
      administradores: Number(administradoresRes.rows[0]?.total ?? 0),
      totalPlanes: Number(planesRes.rows[0]?.total ?? 0),
      totalTareas: Number(tareasRes.rows[0]?.total ?? 0),
      tareasCompletadas: Number(tareasCompletadasRes.rows[0]?.total ?? 0),
      planesPorDia: planesPorDiaRes.rows,
      tareasPorDia: tareasPorDiaRes.rows,
      tareasCompletadasPorDia: tareasCompletadasPorDiaRes.rows,
    });
  } catch (error: any) {
    console.error("❌ Error en /admin/summary:", error);
    return res.status(500).json({ ok: false, mensaje: "Error al obtener el resumen administrativo." });
  }
});

router.get("/usuarios/:userId", requireAdmin, async (req: Request, res: Response): Promise<any> => {
  try {
    // Selección de usuarios estudiantes. Usamos subqueries laterales para
    // evitar multiplicar filas si existen múltiples entradas relacionadas
    // en tablas como `estadisticas`.
    // Soportamos ordenamiento via query param `order=az|recent`.
    const order = (req.query.order ?? 'recent') as string;
    let orderClause = 'u.fecha_registro DESC';
    if (order === 'az') {
      orderClause = `LOWER(u.nombre) ASC, LOWER(u.apellido) ASC`;
    } else {
      orderClause = 'u.fecha_registro DESC';
    }

    const query = `
      SELECT
        u.id,
        u.nombre,
        u.apellido,
        u.fecha_registro,
        u.es_admin,
        pe.foto_perfil,
        pe.objetivo,
        est.racha,
        est.tareas_completadas,
        est.horas_estudio
      FROM usuarios u
      LEFT JOIN perfiles_estudio pe ON pe.usuario_id = u.id
      LEFT JOIN LATERAL (
        SELECT racha, tareas_completadas, horas_estudio
        FROM estadisticas
        WHERE usuario_id = u.id
        ORDER BY id DESC
        LIMIT 1
      ) est ON true
      WHERE COALESCE(u.es_admin, false) = false
      ORDER BY ${orderClause}
    `;

    const result = await pool.query(query);

    return res.status(200).json({ ok: true, usuarios: result.rows });
  } catch (error: any) {
    console.error("❌ Error en /admin/usuarios:", error);
    return res.status(500).json({ ok: false, mensaje: "Error al cargar los usuarios estudiantes." });
  }
});

router.get("/administradores/:userId", requireAdmin, async (req: Request, res: Response): Promise<any> => {
  try {
    const order = (req.query.order ?? 'recent') as string;
    let orderClause = 'u.fecha_registro DESC';
    if (order === 'az') {
      orderClause = `LOWER(u.nombre) ASC, LOWER(u.apellido) ASC`;
    }

    const query = `
      SELECT
        u.id,
        u.nombre,
        u.apellido,
        u.fecha_registro,
        u.es_admin,
        pe.foto_perfil,
        pe.objetivo,
        est.racha,
        est.tareas_completadas,
        est.horas_estudio
      FROM usuarios u
      LEFT JOIN perfiles_estudio pe ON pe.usuario_id = u.id
      LEFT JOIN LATERAL (
        SELECT racha, tareas_completadas, horas_estudio
        FROM estadisticas
        WHERE usuario_id = u.id
        ORDER BY id DESC
        LIMIT 1
      ) est ON true
      WHERE COALESCE(u.es_admin, false) = true
      ORDER BY ${orderClause}
    `;

    const result = await pool.query(query);

    return res.status(200).json({ ok: true, usuarios: result.rows });
  } catch (error: any) {
    console.error("❌ Error en /admin/administradores:", error);
    return res.status(500).json({ ok: false, mensaje: "Error al cargar los administradores." });
  }
});

router.get("/usuarios/:userId/:targetUserId", requireAdmin, async (req: Request, res: Response): Promise<any> => {
  try {
    const { targetUserId } = req.params;

    const usuarioRes = await pool.query(`
      SELECT
        u.id,
        u.nombre,
        u.apellido,
        u.fecha_registro,
        u.es_admin,
        pe.objetivo,
        pe.horas_disponibles,
        pe.nivel_procrastinacion,
        pe.foto_perfil,
        est.racha,
        est.tareas_completadas,
        est.horas_estudio
      FROM usuarios u
      LEFT JOIN perfiles_estudio pe ON pe.usuario_id = u.id
      LEFT JOIN LATERAL (
        SELECT racha, tareas_completadas, horas_estudio
        FROM estadisticas
        WHERE usuario_id = u.id
        ORDER BY id DESC
        LIMIT 1
      ) est ON true
      WHERE u.id = $1
    `, [targetUserId]);

    if (usuarioRes.rows.length === 0) {
      return res.status(404).json({ ok: false, mensaje: "Usuario no encontrado." });
    }

    const planesRes = await pool.query(`
      SELECT id, nombre, descripcion, estado, fecha_creacion
      FROM planes_estudio
      WHERE usuario_id = $1
      ORDER BY fecha_creacion DESC
    `, [targetUserId]);

    const tareasRes = await pool.query(`
      SELECT t.id, t.titulo, t.descripcion, t.completada, a.fecha AS fecha_entrega
      FROM tareas t
      LEFT JOIN actividades a ON a.id = t.actividad_id
      LEFT JOIN planes_estudio pe ON pe.id = a.plan_id
      WHERE pe.usuario_id = $1
      ORDER BY a.fecha DESC, t.id DESC
    `, [targetUserId]);

    const medallasRes = await pool.query(`
      SELECT r.id, r.nombre, r.descripcion, r.puntos
      FROM usuario_recompensa ur
      JOIN recompensas r ON r.id = ur.recompensa_id
      WHERE ur.usuario_id = $1
      ORDER BY r.nombre ASC
    `, [targetUserId]);

    const horariosRes = await pool.query(`
      SELECT id, dia, hora_inicio, hora_fin
      FROM horarios
      WHERE usuario_id = $1
      ORDER BY dia ASC
    `, [targetUserId]);

    return res.status(200).json({
      ok: true,
      usuario: usuarioRes.rows[0],
      planes: planesRes.rows,
      tareas: tareasRes.rows,
      medallas: medallasRes.rows,
      horarios: horariosRes.rows,
    });
  } catch (error: any) {
    console.error("❌ Error en /admin/usuarios/:id:", error);
    return res.status(500).json({ ok: false, mensaje: "Error al cargar el detalle del usuario." });
  }
});

router.put("/usuarios/:userId/:targetUserId/nombre", requireAdmin, async (req: Request, res: Response): Promise<any> => {
  try {
    const { targetUserId } = req.params;
    const { nombre, apellido } = req.body ?? {};

    if (typeof nombre !== "string" || nombre.trim() === "") {
      return res.status(400).json({ ok: false, mensaje: "El nombre es obligatorio." });
    }

    if (typeof apellido !== "string" && apellido !== null && apellido !== undefined) {
      return res.status(400).json({ ok: false, mensaje: "El apellido tiene un formato inválido." });
    }

    const result = await pool.query(
      `UPDATE usuarios
       SET nombre = $1,
           apellido = $2
       WHERE id = $3
       RETURNING id, nombre, apellido`,
      [nombre.trim(), apellido ?? null, targetUserId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ ok: false, mensaje: "No se encontró el usuario para actualizar." });
    }

    return res.status(200).json({ ok: true, mensaje: "Nombre y apellido actualizados correctamente.", usuario: result.rows[0] });
  } catch (error: any) {
    console.error("❌ Error actualizando nombre/apellido:", error);
    return res.status(500).json({ ok: false, mensaje: "Error al actualizar los datos del usuario." });
  }
});

router.delete("/usuarios/:userId/:targetUserId", requireAdmin, async (req: Request, res: Response): Promise<any> => {
  const client = await pool.connect();

  try {
    const { targetUserId } = req.params;
    await client.query("BEGIN");

    await client.query(`DELETE FROM historial_ia WHERE usuario_id = $1`, [targetUserId]);
    await client.query(`DELETE FROM planes_ia WHERE plan_id IN (SELECT id FROM planes_estudio WHERE usuario_id = $1)`, [targetUserId]);
    await client.query(`DELETE FROM tareas WHERE actividad_id IN (SELECT a.id FROM actividades a JOIN planes_estudio p ON p.id = a.plan_id WHERE p.usuario_id = $1)`, [targetUserId]);
    await client.query(`DELETE FROM actividades WHERE plan_id IN (SELECT id FROM planes_estudio WHERE usuario_id = $1)`, [targetUserId]);
    await client.query(`DELETE FROM planes_estudio WHERE usuario_id = $1`, [targetUserId]);
    await client.query(`DELETE FROM horarios WHERE usuario_id = $1`, [targetUserId]);
    await client.query(`DELETE FROM perfiles_estudio WHERE usuario_id = $1`, [targetUserId]);
    await client.query(`DELETE FROM estadisticas WHERE usuario_id = $1`, [targetUserId]);
    await client.query(`DELETE FROM usuario_recompensa WHERE usuario_id = $1`, [targetUserId]);
    await client.query(`DELETE FROM notificaciones WHERE usuario_id = $1`, [targetUserId]);

    const deleted = await client.query(`DELETE FROM usuarios WHERE id = $1 RETURNING id`, [targetUserId]);

    await client.query("COMMIT");

    if (deleted.rowCount === 0) {
      return res.status(404).json({ ok: false, mensaje: "No se encontró el usuario a eliminar." });
    }

    return res.status(200).json({ ok: true, mensaje: "Usuario eliminado correctamente." });
  } catch (error: any) {
    await client.query("ROLLBACK");
    console.error("❌ Error eliminando usuario:", error);
    return res.status(500).json({ ok: false, mensaje: "Error al eliminar el usuario. Revisa las dependencias reales del sistema." });
  } finally {
    client.release();
  }
});

// Promover usuario a administrador
router.put("/usuarios/:userId/:targetUserId/promover", requireAdmin, async (req: Request, res: Response): Promise<any> => {
  try {
    const { targetUserId } = req.params;

    const result = await pool.query(
      `UPDATE usuarios SET es_admin = true WHERE id = $1 RETURNING id, es_admin`,
      [targetUserId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ ok: false, mensaje: 'Usuario no encontrado.' });
    }

    return res.status(200).json({ ok: true, mensaje: 'Usuario promovido a administrador.', usuario: result.rows[0] });
  } catch (error: any) {
    console.error('❌ Error promoviendo usuario:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error al promover usuario a administrador.' });
  }
});

// Delegar administrador a estudiante sin modificar sus datos de estudiante.
router.put("/usuarios/:userId/:targetUserId/delegar", requireAdmin, async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId, targetUserId } = req.params;

    if (userId === targetUserId) {
      return res.status(400).json({ ok: false, mensaje: "No puedes delegarte a ti mismo." });
    }

    const result = await pool.query(
      `UPDATE usuarios SET es_admin = false WHERE id = $1 AND es_admin = true RETURNING id, es_admin`,
      [targetUserId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ ok: false, mensaje: "El administrador no fue encontrado." });
    }

    return res.status(200).json({ ok: true, mensaje: "Administrador delegado a estudiante.", usuario: result.rows[0] });
  } catch (error: any) {
    console.error('❌ Error delegando administrador:', error);
    return res.status(500).json({ ok: false, mensaje: 'Error al delegar administrador a estudiante.' });
  }
});

export default router;
