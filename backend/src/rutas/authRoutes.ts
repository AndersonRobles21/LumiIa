import { Router, Request, Response } from "express";
import { pool } from "../config/db";

const router = Router();

/*
============================================================
REGISTRO
POST /api/auth/register
============================================================
*/
router.post("/register", async (req: Request, res: Response): Promise<any> => {
  try {
    const { id, nombre, apellido, rol_id } = req.body;

    if (!id || !nombre) {
      return res.status(400).json({
        mensaje: "Faltan campos obligatorios en el cuerpo: id o nombre.",
      });
    }

    const queryText = `
      INSERT INTO usuarios (id, nombre, apellido, rol_id)
      VALUES ($1, $2, $3, $4)
      RETURNING id, nombre, apellido, rol_id, fecha_registro;
    `;
    const values = [
      id,
      nombre.trim(),
      apellido && apellido.trim() !== "" ? apellido.trim() : null,
      rol_id || null
    ];
    
    const result = await pool.query(queryText, values);

    await pool.query(
      "INSERT INTO perfiles_estudio (usuario_id, horas_disponibles, objetivo, nivel_procrastinacion) VALUES ($1, 0, '', 1) ON CONFLICT DO NOTHING",
      [id]
    );

    await pool.query(
      "INSERT INTO estadisticas (usuario_id) VALUES ($1) ON CONFLICT DO NOTHING",
      [id]
    );

    return res.status(201).json({
      mensaje: "Usuario registrado correctamente en LUMI",
      usuario: result.rows[0],
    });
  } catch (error: any) {
    console.error("❌ Error en POST /register:", error);
    return res.status(500).json({
      mensaje: "Error interno al insertar el perfil en PostgreSQL",
      detalle: error.message || String(error)
    });
  }
});

/*
============================================================
LOGIN
POST /api/auth/login
============================================================
*/
router.post("/login", async (req: Request, res: Response): Promise<any> => {
  try {
    const { id } = req.body;

    if (!id) {
      return res.status(400).json({
        mensaje: "El campo id (UUID) es requerido para validar el login.",
      });
    }

    const resultado = await pool.query(
      "SELECT id, nombre, apellido, rol_id, fecha_registro FROM usuarios WHERE id = $1",
      [id]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({
        mensaje: "El usuario no tiene un perfil creado en PostgreSQL. Regístrate primero.",
      });
    }

    return res.status(200).json({
      mensaje: "Inicio de sesión verificado correctamente en PostgreSQL",
      usuario: resultado.rows[0],
    });
  } catch (error: any) {
    console.error("❌ Error en POST /login:", error);
    return res.status(500).json({ mensaje: "Error interno en el servidor local durante el login" });
  }
});

/*
============================================================
GET PROFILE
GET /api/auth/profile/:id
============================================================
*/
router.get("/profile/:id", async (req: Request, res: Response): Promise<any> => {
  try {
    const { id } = req.params;
    const usuarioRes = await pool.query("SELECT id, nombre, apellido, rol_id FROM usuarios WHERE id = $1", [id]);
    if (usuarioRes.rows.length === 0) return res.status(404).json({ mensaje: "Usuario no encontrado" });
    const usuario = usuarioRes.rows[0];

    const perfilEstudioRes = await pool.query(
      "SELECT id, horas_disponibles, objetivo, nivel_procrastinacion, foto_perfil FROM perfiles_estudio WHERE usuario_id = $1",
      [id]
    );
    const horariosRes = await pool.query("SELECT id, dia, hora_inicio, hora_fin FROM horarios WHERE usuario_id = $1", [id]);

    return res.status(200).json({
      id: usuario.id,
      nombre: usuario.nombre,
      apellido: usuario.apellido,
      rol_id: usuario.rol_id,
      perfil_estudio: perfilEstudioRes.rows[0] || { horas_disponibles: 0, objetivo: "", nivel_procrastinacion: 1, foto_perfil: null },
      horarios: horariosRes.rows,
    });
  } catch (error) {
    return res.status(500).json({ mensaje: "Error al obtener perfil" });
  }
});

/*
============================================================
UPDATE PROFILE
PUT /api/auth/profile/:id
============================================================
*/
router.put("/profile/:id", async (req: Request, res: Response): Promise<any> => {
  const { id } = req.params;
  const { nombre, apellido, horas_disponibles, objetivo, nivel_procrastinacion, foto_perfil, horario } = req.body;
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    await client.query("UPDATE usuarios SET nombre = $1, apellido = $2 WHERE id = $3", [nombre.trim(), apellido || null, id]);

    const perfilQuery = `
      INSERT INTO perfiles_estudio (usuario_id, horas_disponibles, objetivo, nivel_procrastinacion, foto_perfil)
      VALUES ($1, $2, $3, $4, $5)
      ON CONFLICT (usuario_id) 
      DO UPDATE SET 
        horas_disponibles = EXCLUDED.horas_disponibles,
        objetivo = EXCLUDED.objetivo,
        nivel_procrastinacion = EXCLUDED.nivel_procrastinacion,
        foto_perfil = EXCLUDED.foto_perfil;
    `;
    await client.query(perfilQuery, [
      id,
      horas_disponibles || 0,
      objetivo || '',
      nivel_procrastinacion || 1,
      foto_perfil || null
    ]);

    if (horario && Array.isArray(horario)) {
      await client.query("DELETE FROM horarios WHERE usuario_id = $1", [id]);
      for (const b of horario) {
        await client.query(
          "INSERT INTO horarios (usuario_id, dia, hora_inicio, hora_fin) VALUES ($1, $2, $3, $4)",
          [id, b.dia.trim(), b.hora_inicio.trim(), b.hora_fin.trim()]
        );
      }
    }

    await client.query("COMMIT");
    return res.status(200).json({ mensaje: "Perfil de LUMI guardado exitosamente" });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error(error);
    return res.status(500).json({ mensaje: "Error al guardar perfil" });
  } finally {
    client.release();
  }
});

/*
============================================================
GET ESTADÍSTICAS
GET /api/auth/estadisticas/:userId
============================================================
*/
router.get("/estadisticas/:userId", async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId } = req.params;
    const resultado = await pool.query(
      "SELECT tareas_completadas, horas_estudio, racha FROM estadisticas WHERE usuario_id = $1",
      [userId]
    );
    if (resultado.rows.length === 0) {
      await pool.query(
        "INSERT INTO estadisticas (usuario_id) VALUES ($1) ON CONFLICT DO NOTHING",
        [userId]
      );
      return res.status(200).json({ tareas_completadas: 0, horas_estudio: 0, racha: 0 });
    }
    return res.status(200).json(resultado.rows[0]);
  } catch (error: any) {
    console.error("❌ Error en GET /estadisticas:", error);
    return res.status(500).json({ mensaje: "Error al obtener estadísticas" });
  }
});

router.post("/estadisticas/:userId/tareas", async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId } = req.params;

    const resultado = await pool.query(
      `
      SELECT
        COUNT(*) AS total_tareas,
        COUNT(*) FILTER (WHERE t.completada = true) AS tareas_completadas
      FROM tareas t
      JOIN actividades a ON a.id = t.actividad_id
      JOIN planes_estudio p ON p.id = a.plan_id
      WHERE p.usuario_id = $1
      `,
      [userId]
    );

    const totalTareas = Number(resultado.rows[0]?.total_tareas ?? 0);
    const tareasCompletadas = Number(resultado.rows[0]?.tareas_completadas ?? 0);

    await pool.query(
      `
      INSERT INTO estadisticas (usuario_id, tareas_completadas, racha, horas_estudio)
      VALUES ($1, $2, 0, 0)
      ON CONFLICT (usuario_id) DO UPDATE SET tareas_completadas = EXCLUDED.tareas_completadas
      `,
      [userId, tareasCompletadas]
    );

    return res.status(200).json({
      ok: true,
      total_tareas: totalTareas,
      tareas_completadas: tareasCompletadas,
      tareas_pendientes: Math.max(totalTareas - tareasCompletadas, 0),
    });
  } catch (error: any) {
    console.error("❌ Error en POST /estadisticas/:userId/tareas:", error);
    return res.status(500).json({ mensaje: "Error al sincronizar estadísticas de tareas" });
  }
});

/*
============================================================
REGISTRAR RACHA HOY
POST /api/auth/estadisticas/:userId/racha

Incrementa la racha solo si el usuario no ha marcado hoy todavía.
Usa horas_estudio para guardar el número de día del año del último marcado.
============================================================
*/
router.post("/estadisticas/:userId/racha", async (req: Request, res: Response): Promise<any> => {
  try {
    const { userId } = req.params;

    await pool.query(
      "INSERT INTO estadisticas (usuario_id, racha, tareas_completadas, horas_estudio) VALUES ($1, 0, 0, 0) ON CONFLICT DO NOTHING",
      [userId]
    );

    const resultado = await pool.query(
      "SELECT racha, horas_estudio FROM estadisticas WHERE usuario_id = $1",
      [userId]
    );
    const stats = resultado.rows[0];

    const hoy = new Date();
    const diaDelAnio = Math.floor(
      (hoy.getTime() - new Date(hoy.getFullYear(), 0, 0).getTime()) / 86400000
    );
    const ultimoDiaMarcado = Number(stats.horas_estudio) || 0;

    if (ultimoDiaMarcado === diaDelAnio) {
      return res.status(200).json({ mensaje: "Ya marcaste hoy", racha: stats.racha });
    }

    const nuevaRacha = ultimoDiaMarcado === diaDelAnio - 1
      ? Number(stats.racha) + 1
      : 1;

    await pool.query(
      "UPDATE estadisticas SET racha = $1, horas_estudio = $2 WHERE usuario_id = $3",
      [nuevaRacha, diaDelAnio, userId]
    );

    return res.status(200).json({ mensaje: "Racha actualizada", racha: nuevaRacha });
  } catch (error: any) {
    console.error("❌ Error en POST /estadisticas/racha:", error);
    return res.status(500).json({ mensaje: "Error al actualizar racha" });
  }
});

export default router;