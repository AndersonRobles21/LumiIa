import { Router, Request, Response } from "express";
import { pool } from "../config/db";

const router = Router();

async function columnExists(table: string, column: string) {
  const q = `SELECT COUNT(*) as c FROM information_schema.columns WHERE table_name = $1 AND column_name = $2`;
  const r = await pool.query(q, [table, column]);
  return Number(r.rows[0].c) > 0;
}

async function checkAdmin(req: Request, res: Response, next: any) {
  try {
    const requesterId = (req.headers["x-user-id"] || req.query.requesterId) as string | undefined;
    if (!requesterId) return res.status(401).json({ mensaje: "Usuario no autenticado (falta x-user-id)" });

    const resultado = await pool.query("SELECT es_admin FROM usuarios WHERE id = $1", [requesterId]);
    if (resultado.rows.length === 0) return res.status(403).json({ mensaje: "Acceso denegado" });
    const esAdmin = resultado.rows[0].es_admin;
    if (!esAdmin) return res.status(403).json({ mensaje: "Acceso denegado" });

    (req as any).requesterId = requesterId;
    next();
  } catch (error: any) {
    console.error("Error checkAdmin:", error?.message || error);
    return res.status(500).json({ mensaje: "Error validando administrador" });
  }
}

router.get("/check", checkAdmin, async (req: Request, res: Response) => {
  return res.status(200).json({ admin: true });
});

router.get("/overview", checkAdmin, async (req: Request, res: Response) => {
  try {
    const totalUsersRes = await pool.query("SELECT COUNT(*) as total FROM usuarios");
    const activeUsersRes = await pool.query("SELECT COUNT(*) as active FROM usuarios WHERE fecha_registro > NOW() - INTERVAL '30 days'");
    const totalTasksRes = await pool.query("SELECT COUNT(*) as total FROM tareas");
    const tasksCompletedRes = await pool.query("SELECT COUNT(*) as completed FROM tareas WHERE completada = true");
    const avgStreakRes = await pool.query("SELECT AVG(racha) as avg_racha FROM estadisticas");

    return res.status(200).json({
      total_users: Number(totalUsersRes.rows[0].total) || 0,
      users_active_30d: Number(activeUsersRes.rows[0].active) || 0,
      total_tareas: Number(totalTasksRes.rows[0].total) || 0,
      tareas_completadas: Number(tasksCompletedRes.rows[0].completed) || 0,
      promedio_rachas: Number(avgStreakRes.rows[0].avg_racha) || 0,
    });
  } catch (error: any) {
    console.error("Error admin overview:", error?.message || error);
    return res.status(500).json({ mensaje: "Error al obtener overview" });
  }
});

router.get("/users", checkAdmin, async (req: Request, res: Response) => {
  try {
    const search = (req.query.search as string) || "";
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(200, Number(req.query.limit) || 25);
    const offset = (page - 1) * limit;

    const hasCorreo = await columnExists("usuarios", "correo");
    const hasUltimoAcceso = await columnExists("usuarios", "ultimo_acceso");

    const selectCols = [
      "u.id",
      "u.nombre",
      "u.apellido",
      "u.rol_id",
      "u.fecha_registro",
      "p.objetivo",
      "p.foto_perfil",
      "coalesce(s.racha,0) as racha",
      `(SELECT COUNT(*) FROM tareas t JOIN actividades a ON a.id = t.actividad_id JOIN planes_estudio pe ON pe.id = a.plan_id WHERE pe.usuario_id = u.id) as tareas_count`,
    ];

    if (hasCorreo) selectCols.push("u.correo");
    if (hasUltimoAcceso) selectCols.push("u.ultimo_acceso");

    let filterSql = "";
    const params: any[] = [];
    if (search && search.trim() !== "") {
      const s = `%${search.trim()}%`;
      params.push(s);
      if (hasCorreo) {
        filterSql = `WHERE (u.nombre || ' ' || u.apellido ILIKE $1 OR u.correo ILIKE $1)`;
      } else {
        filterSql = `WHERE (u.nombre || ' ' || u.apellido ILIKE $1)`;
      }
    }

    const baseQuery = `SELECT ${selectCols.join(", ")} FROM usuarios u
      LEFT JOIN LATERAL (
        SELECT objetivo, foto_perfil FROM perfiles_estudio WHERE usuario_id = u.id ORDER BY id DESC LIMIT 1
      ) p ON true
      LEFT JOIN LATERAL (
        SELECT racha FROM estadisticas WHERE usuario_id = u.id ORDER BY id DESC LIMIT 1
      ) s ON true
      ${filterSql}
      ORDER BY u.fecha_registro DESC
      LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const listaRes = await pool.query(baseQuery, params);
    const countQuery = `SELECT COUNT(*) as total FROM usuarios u ${filterSql}`;
    const countRes = await pool.query(countQuery, params.slice(0, params.length - 2));

    return res.status(200).json({
      total: Number(countRes.rows[0].total) || 0,
      page,
      limit,
      usuarios: listaRes.rows,
    });
  } catch (error: any) {
    console.error("Error admin users:", error?.message || error);
    return res.status(500).json({ mensaje: "Error al listar usuarios" });
  }
});

router.get("/users/:id", checkAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const hasCorreo = await columnExists("usuarios", "correo");
    const usuarioSelect = hasCorreo
      ? "SELECT id, nombre, apellido, correo, rol_id, fecha_registro FROM usuarios WHERE id = $1"
      : "SELECT id, nombre, apellido, rol_id, fecha_registro FROM usuarios WHERE id = $1";
    const usuarioRes = await pool.query(usuarioSelect, [id]);
    if (usuarioRes.rows.length === 0) return res.status(404).json({ mensaje: "Usuario no encontrado" });
    const perfilRes = await pool.query("SELECT id, horas_disponibles, objetivo, nivel_procrastinacion, foto_perfil FROM perfiles_estudio WHERE usuario_id = $1", [id]);
    const estadRes = await pool.query("SELECT tareas_completadas, horas_estudio, racha FROM estadisticas WHERE usuario_id = $1", [id]);
    const tareasRes = await pool.query(
      `SELECT t.id, t.titulo as nombre, t.descripcion, t.completada
       FROM tareas t
       JOIN actividades a ON a.id = t.actividad_id
       JOIN planes_estudio p ON p.id = a.plan_id
       WHERE p.usuario_id = $1
       ORDER BY t.id DESC`,
      [id]
    );

    const historialRes = await pool.query(
      "SELECT id, usuario_id, prompt, respuesta, fecha_creacion FROM historial_ia WHERE usuario_id = $1 ORDER BY fecha_creacion DESC LIMIT 50",
      [id]
    ).catch(() => ({ rows: [] }));

    const horariosRes = await pool.query("SELECT id, dia, hora_inicio, hora_fin FROM horarios WHERE usuario_id = $1 ORDER BY id", [id]).catch(() => ({ rows: [] }));

    const planesRes = await pool.query("SELECT id, nombre, descripcion, estado, fecha_creacion FROM planes_estudio WHERE usuario_id = $1 ORDER BY fecha_creacion DESC", [id]).catch(() => ({ rows: [] }));

    const actividadesRes = await pool.query("SELECT a.id, a.plan_id, a.titulo, a.descripcion, a.fecha, a.estado FROM actividades a JOIN planes_estudio p ON p.id = a.plan_id WHERE p.usuario_id = $1 ORDER BY a.fecha DESC", [id]).catch(() => ({ rows: [] }));

    const tareas = tareasRes.rows || [];
    const pendientes = tareas.filter((t: any) => t.completada === false || t.completada === null);

    return res.status(200).json({
      usuario: usuarioRes.rows[0],
      perfil_estudio: perfilRes.rows[0] || null,
      estadisticas: estadRes.rows[0] || { tareas_completadas: 0, horas_estudio: 0, racha: 0 },
      tareas,
      tareas_pendientes: pendientes,
      historial: historialRes.rows || [],
      horarios: horariosRes.rows || [],
      planes_estudio: planesRes.rows || [],
      actividades: actividadesRes.rows || [],
    });
  } catch (error: any) {
    console.error("Error admin user detail:", error?.message || error);
    return res.status(500).json({ mensaje: "Error al obtener detalle de usuario" });
  }
});

router.put("/users/:id", checkAdmin, async (req: Request, res: Response) => {
  const { id } = req.params;
  const { nombre, apellido, objetivo, horas_disponibles, nivel_procrastinacion, foto_perfil, rol_id } = req.body;
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    if (nombre || apellido) {
      await client.query("UPDATE usuarios SET nombre = $1, apellido = $2 WHERE id = $3", [nombre || null, apellido || null, id]);
    }
    const perfilQuery = `INSERT INTO perfiles_estudio (usuario_id, horas_disponibles, objetivo, nivel_procrastinacion, foto_perfil) VALUES ($1, $2, $3, $4, $5) ON CONFLICT (usuario_id) DO UPDATE SET horas_disponibles = EXCLUDED.horas_disponibles, objetivo = EXCLUDED.objetivo, nivel_procrastinacion = EXCLUDED.nivel_procrastinacion, foto_perfil = EXCLUDED.foto_perfil`;
    await client.query(perfilQuery, [id, horas_disponibles || 0, objetivo || '', nivel_procrastinacion || 1, foto_perfil || null]);

    if (typeof rol_id !== 'undefined') {
      await client.query("UPDATE usuarios SET rol_id = $1 WHERE id = $2", [rol_id, id]);
    }

    await client.query("COMMIT");
    return res.status(200).json({ mensaje: "Usuario actualizado" });
  } catch (error: any) {
    await client.query("ROLLBACK");
    console.error("Error admin update user:", error?.message || error);
    return res.status(500).json({ mensaje: "Error al actualizar usuario" });
  } finally {
    client.release();
  }
});

router.post("/users/:id/disable", checkAdmin, async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { disable } = req.body; // boolean
    const hasActivo = await columnExists("usuarios", "activo");
    if (!hasActivo) return res.status(400).json({ mensaje: "No es posible desactivar: falta columna 'activo' en la tabla usuarios" });
    await pool.query("UPDATE usuarios SET activo = $1 WHERE id = $2", [disable === true, id]);
    return res.status(200).json({ mensaje: "Usuario actualizado" });
  } catch (error: any) {
    console.error("Error admin disable user:", error?.message || error);
    return res.status(500).json({ mensaje: "Error al desactivar usuario" });
  }
});

router.delete("/users/:id", checkAdmin, async (req: Request, res: Response) => {
  const { id } = req.params;
  const requesterId = (req as any).requesterId as string | undefined;
  if (requesterId === id) return res.status(403).json({ mensaje: "No puedes eliminar el perfil con el que estás ingresado" });

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query("DELETE FROM tareas WHERE actividad_id IN (SELECT a.id FROM actividades a JOIN planes_estudio p ON p.id = a.plan_id WHERE p.usuario_id = $1)", [id]);
    await client.query("DELETE FROM actividades WHERE plan_id IN (SELECT id FROM planes_estudio WHERE usuario_id = $1)", [id]);
    await client.query("DELETE FROM planes_estudio WHERE usuario_id = $1", [id]);
    await client.query("DELETE FROM horarios WHERE usuario_id = $1", [id]);
    await client.query("DELETE FROM perfiles_estudio WHERE usuario_id = $1", [id]);
    await client.query("DELETE FROM estadisticas WHERE usuario_id = $1", [id]);
    await client.query("DELETE FROM usuarios WHERE id = $1", [id]);
    await client.query("COMMIT");
    return res.status(200).json({ mensaje: "Usuario eliminado" });
  } catch (error: any) {
    await client.query("ROLLBACK");
    console.error("Error admin delete user:", error?.message || error);
    return res.status(500).json({ mensaje: "Error al eliminar usuario" });
  } finally {
    client.release();
  }
});

export default router;
