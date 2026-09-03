//authRoutes.ts
  import { Router, Request, Response } from "express";
  import { pool } from "../config/db";
  import { generarPlanIA } from "../services/gemini.service";
  import { calcularCapacidadPlan, HorarioDisponible } from "../services/disponibilidad.service";

  const router = Router();

  function normalizarHorarios(horarios: any[]): HorarioDisponible[] {
    return horarios
      .filter((horario) => horario && horario.hora_inicio && horario.hora_fin)
      .map((horario) => ({
        hora_inicio: String(horario.hora_inicio),
        hora_fin: String(horario.hora_fin),
      }));
  }

  async function reajustarPlanesPorHorario(
    usuarioId: string,
    horariosAnteriores: HorarioDisponible[],
    horariosNuevos: HorarioDisponible[]
  ): Promise<void> {
    const tareasResult = await pool.query(
      `
      SELECT t.id AS tarea_id, t.completada, a.fecha, p.id AS plan_id,
             p.nombre, p.descripcion, p.usuario_id,
             u.nombre AS nombre_usuario, pe.objetivo,
             pe.nivel_procrastinacion, pia.metodo_estudio,
             pia.dificultad, pia.tiempo_estimado_total, pia.pasos
      FROM tareas t
      JOIN actividades a ON a.id = t.actividad_id
      JOIN planes_estudio p ON p.id = a.plan_id
      JOIN usuarios u ON u.id = p.usuario_id
      LEFT JOIN perfiles_estudio pe ON pe.usuario_id = p.usuario_id
      JOIN planes_ia pia ON pia.plan_id = p.id
      WHERE p.usuario_id = $1
        AND t.completada = false
        AND a.fecha IS NOT NULL
        AND a.fecha >= CURRENT_DATE
      `,
      [usuarioId]
    );

    let revisadas = 0;
    let actualizadas = 0;
    let fallidas = 0;

    for (const tarea of tareasResult.rows) {
      const capacidadAnterior = calcularCapacidadPlan(
        tarea.fecha,
        horariosAnteriores,
        Number(tarea.tiempo_estimado_total)
      );
      const capacidadNueva = calcularCapacidadPlan(
        tarea.fecha,
        horariosNuevos,
        Number(tarea.tiempo_estimado_total)
      );

      if (capacidadAnterior.minutosDisponibles === capacidadNueva.minutosDisponibles) continue;
      revisadas++;

      try {
        const pasosAnteriores = typeof tarea.pasos === "string"
          ? JSON.parse(tarea.pasos)
          : (tarea.pasos ?? []);
        const planNuevo = await generarPlanIA({
          titulo: tarea.nombre,
          descripcion: tarea.descripcion ?? "",
          fechaEntrega: new Date(tarea.fecha).toISOString().slice(0, 10),
          metodoEstudio: tarea.metodo_estudio,
          dificultad: tarea.dificultad ?? "Media",
          enfoqueAdicional: "Reorganiza la planificación porque cambió la disponibilidad semanal del estudiante. Conserva el método de estudio y reutiliza los pasos que sigan siendo válidos.",
          nombreUsuario: tarea.nombre_usuario,
          objetivo: tarea.objetivo ?? "",
          horasDisponibles: capacidadNueva.horasPorDia,
          nivelProcrastinacion: tarea.nivel_procrastinacion ?? 3,
          diasRestantes: capacidadNueva.diasRestantes,
          minutosDisponibles: capacidadNueva.minutosDisponibles,
          mensajeUsuario: "",
        });

        const progresoPorId = new Map<string, boolean>();
        for (const paso of Array.isArray(pasosAnteriores) ? pasosAnteriores : []) {
          for (const subpaso of paso?.subpasos ?? []) {
            if (subpaso?.id != null) progresoPorId.set(String(subpaso.id), subpaso.completado === true);
          }
        }
        for (const paso of Array.isArray(planNuevo.pasos) ? planNuevo.pasos : []) {
          for (const subpaso of paso?.subpasos ?? []) {
            if (progresoPorId.has(String(subpaso.id))) {
              subpaso.completado = progresoPorId.get(String(subpaso.id)) ?? false;
            }
          }
        }

        const client = await pool.connect();
        try {
          await client.query("BEGIN");
          await client.query(
            `UPDATE planes_ia SET justificacion = $1, tiempo_estimado_total = $2,
             consejos = $3, recursos = $4, resumen_final = $5, pasos = $6,
             conceptos_clave = $7, preguntas_recall = $8, actualizado_en = NOW()
             WHERE plan_id = $9`,
            [planNuevo.justificacion ?? "", planNuevo.tiempo_estimado_total,
              JSON.stringify(planNuevo.consejos ?? []), JSON.stringify(planNuevo.recursos ?? []),
              planNuevo.resumen_final ?? "", JSON.stringify(planNuevo.pasos ?? []),
              JSON.stringify(planNuevo.conceptos_clave ?? []), JSON.stringify(planNuevo.preguntas_recall ?? []),
              tarea.plan_id]
          );
          await client.query(
            `INSERT INTO historial_ia (usuario_id, plan_id, pregunta, respuesta)
             VALUES ($1, $2, $3, $4)`,
            [usuarioId, tarea.plan_id, JSON.stringify({
              nombre: tarea.nombre,
              descripcion: tarea.descripcion,
              fecha_entrega: new Date(tarea.fecha).toISOString().slice(0, 10),
              metodo_estudio: tarea.metodo_estudio,
              motivo: "cambio_de_horario",
            }), JSON.stringify(planNuevo)]
          );
          await client.query("COMMIT");
          actualizadas++;
        } catch (error) {
          await client.query("ROLLBACK");
          throw error;
        } finally {
          client.release();
        }
      } catch (error) {
        fallidas++;
        console.error(`No se pudo reajustar la tarea ${tarea.tarea_id} tras cambiar horarios:`, error);
      }
    }

    if (revisadas > 0) {
      const mensaje = fallidas > 0
        ? `Tu horario se actualizó. Se ajustaron ${actualizadas} planes, pero ${fallidas} no pudieron reorganizarse. Puedes intentarlo nuevamente.`
        : `Tu disponibilidad fue actualizada. Se revisaron ${revisadas} tareas y se ajustaron ${actualizadas} planes.`;
      await pool.query(
        "INSERT INTO notificaciones (usuario_id, mensaje) VALUES ($1, $2)",
        [usuarioId, mensaje]
      );
    }
  }
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
        "SELECT id, nombre, apellido, rol_id, es_admin, fecha_registro FROM usuarios WHERE id = $1",
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
        es_admin: Boolean(resultado.rows[0]?.es_admin ?? false),
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
      const usuarioRes = await pool.query("SELECT id, nombre, apellido, rol_id, es_admin FROM usuarios WHERE id = $1", [id]);
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
        es_admin: Boolean(usuario.es_admin ?? false),
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
    const usuarioId = Array.isArray(id) ? id[0] ?? "" : id;
    const client = await pool.connect();
    try {
      const horarioAnteriorResult = await client.query(
        "SELECT hora_inicio, hora_fin FROM horarios WHERE usuario_id = $1",
        [id]
      );
      const horariosAnteriores = normalizarHorarios(horarioAnteriorResult.rows);
      const horariosNuevos = horario && Array.isArray(horario)
        ? normalizarHorarios(horario)
        : horariosAnteriores;
      const cambioHorario = horario && Array.isArray(horario) &&
        JSON.stringify(horariosAnteriores) !== JSON.stringify(horariosNuevos);

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
      if (cambioHorario) {
        void reajustarPlanesPorHorario(usuarioId, horariosAnteriores, horariosNuevos)
          .catch((error) => console.error("Error general reajustando planes por cambio de horario:", error));
      }
      return res.status(200).json({
        mensaje: cambioHorario
          ? "Perfil de LUMI guardado. Se están revisando tus planes según tu nuevo horario."
          : "Perfil de LUMI guardado exitosamente",
        reajuste_en_proceso: Boolean(cambioHorario),
      });
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