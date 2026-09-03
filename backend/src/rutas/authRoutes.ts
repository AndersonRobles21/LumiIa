//authRoutes.ts
  import { Router, Request, Response } from "express";
  import { pool } from "../config/db";

  const router = Router();

  function contarLogros(tareas: number, racha: number, planes: number, horas: number) {
    let count = 0;
    if (tareas >= 1) count++;
    if (tareas >= 5) count++;
    if (planes >= 1) count += 2;
    if (tareas >= 1 || horas >= 1) count++;
    if (racha >= 3) count++;
    if (racha >= 10) count++;
    if (racha >= 30) count++;
    if (tareas >= 2 || horas >= 1) count++;
    if (horas >= 1 || tareas >= 2) count++;
    if (tareas >= 8) count++;
    if (tareas >= 10) count++;
    if (tareas >= 15) count++;
    if (planes >= 2) count++;
    if (tareas >= 20) count++;
    if (count >= 10) count++;
    return count;
  }

  router.get("/personajes/:userId", async (req: Request, res: Response): Promise<any> => {
    try {
      const result = await pool.query(
        "SELECT personaje, costo_xp, fecha_compra FROM personajes_usuario WHERE usuario_id = $1 ORDER BY personaje",
        [req.params.userId],
      );
      return res.status(200).json({ personajes: result.rows });
    } catch (error) {
      console.error("Error obteniendo personajes:", error);
      return res.status(500).json({ mensaje: "Error al obtener personajes" });
    }
  });

  router.post("/personajes/:userId/comprar", async (req: Request, res: Response): Promise<any> => {
    const client = await pool.connect();
    try {
      const userId = req.params.userId;
      const personaje = Number(req.body.personaje);
      if (!Number.isInteger(personaje) || personaje < 1 || personaje > 18) {
        return res.status(400).json({ mensaje: "Personaje inválido" });
      }

      const costo = personaje * 25;
      await client.query("BEGIN");
      const statsResult = await client.query(
        "SELECT tareas_completadas, racha, horas_estudio FROM estadisticas WHERE usuario_id = $1 FOR UPDATE",
        [userId],
      );
      const stats = statsResult.rows[0] || {};
      const tasks = Number(stats.tareas_completadas) || 0;
      const streak = Number(stats.racha) || 0;
      const hours = Number(stats.horas_estudio) || 0;
      const plansResult = await client.query(
        "SELECT COUNT(*)::int AS total FROM historial_ia WHERE usuario_id = $1",
        [userId],
      );
      const plans = Number(plansResult.rows[0]?.total) || 0;
      const xpGanado = tasks * 20 + streak * 15 + plans * 25 +
        contarLogros(tasks, streak, plans, hours) * 35;
      const purchasedResult = await client.query(
        "SELECT personaje, costo_xp FROM personajes_usuario WHERE usuario_id = $1 FOR UPDATE",
        [userId],
      );
      const alreadyOwned = purchasedResult.rows.some((row) => Number(row.personaje) === personaje);
      const spent = purchasedResult.rows.reduce((sum, row) => sum + Number(row.costo_xp), 0);

      if (alreadyOwned) {
        await client.query("COMMIT");
        return res.status(200).json({ ok: true, comprado: true, xp_disponible: xpGanado - spent });
      }
      if (xpGanado - spent < costo) {
        await client.query("ROLLBACK");
        return res.status(409).json({ mensaje: "No tienes XP suficiente", xp_disponible: xpGanado - spent });
      }

      await client.query(
        "INSERT INTO personajes_usuario (usuario_id, personaje, costo_xp) VALUES ($1, $2, $3)",
        [userId, personaje, costo],
      );
      await client.query(
        "UPDATE perfiles_estudio SET foto_perfil = $1 WHERE usuario_id = $2",
        [`asset:logo/personajes/personaje${personaje}.png`, userId],
      );
      await client.query("COMMIT");
      return res.status(201).json({
        ok: true,
        comprado: true,
        xp_disponible: xpGanado - spent - costo,
      });
    } catch (error) {
      await client.query("ROLLBACK");
      console.error("Error comprando personaje:", error);
      return res.status(500).json({ mensaje: "Error al comprar personaje" });
    } finally {
      client.release();
    }
  });
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
      "SELECT racha, ultima_racha_fecha FROM estadisticas WHERE usuario_id = $1",
      [userId]
    );

    const stats = resultado.rows[0];

    const formatearFechaLocal = (fecha: Date) => {
      const year = fecha.getFullYear();
      const month = String(fecha.getMonth() + 1).padStart(2, "0");
      const day = String(fecha.getDate()).padStart(2, "0");
      return `${year}-${month}-${day}`;
    };

    const hoy = new Date();
    const hoyFecha = formatearFechaLocal(hoy);

    if (stats.ultima_racha_fecha) {
      const ultimaFecha = formatearFechaLocal(new Date(stats.ultima_racha_fecha));

      if (ultimaFecha === hoyFecha) {
        return res.status(200).json({
          mensaje: "Ya marcaste hoy",
          racha: Number(stats.racha) || 0,
        });
      }
    }

    let nuevaRacha = 1;

    if (stats.ultima_racha_fecha) {
      const ultimaFecha = formatearFechaLocal(new Date(stats.ultima_racha_fecha));

      const ayer = new Date(hoy);
      ayer.setDate(hoy.getDate() - 1);
      const ayerFecha = formatearFechaLocal(ayer);

      nuevaRacha =
        ultimaFecha === ayerFecha
          ? (Number(stats.racha) || 0) + 1
          : 1;
    }

    await pool.query(
      "UPDATE estadisticas SET racha = $1, ultima_racha_fecha = $2 WHERE usuario_id = $3",
      [nuevaRacha, hoyFecha, userId]
    );

    return res.status(200).json({
      mensaje: "Racha actualizada",
      racha: nuevaRacha,
    });
  } catch (error: any) {
    console.error("❌ Error en POST /estadisticas/racha:", error);
    return res.status(500).json({
      mensaje: "Error al actualizar racha",
    });
  }
});

  export default router;