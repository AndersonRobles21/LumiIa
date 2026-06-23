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

    // Inicializa preventivamente el perfil de estudio con valores vacíos
    await pool.query(
      "INSERT INTO perfiles_estudio (usuario_id, horas_disponibles, objetivo, nivel_procrastinacion) VALUES ($1, 0, '', 1) ON CONFLICT DO NOTHING",
      [id]
    );

    // Inicializa estadísticas para la gamificación
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
GET PROFILE (Conectado estrictamente a perfiles_estudio)
GET /api/auth/profile/:id
============================================================
*/
// Actualiza el GET /profile/:id en tu archivo de Node para incluir foto_perfil:
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

// Actualiza el PUT /profile/:id en tu archivo de Node:
router.put("/profile/:id", async (req: Request, res: Response): Promise<any> => {
  const { id } = req.params;
  const { nombre, apellido, horas_disponibles, objetivo, nivel_procrastinacion, foto_perfil, horario } = req.body;
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    
    // 1. Actualiza tabla de usuarios
    await client.query("UPDATE usuarios SET nombre = $1, apellido = $2 WHERE id = $3", [nombre.trim(), apellido || null, id]);

    // 2. Hace UPSERT en perfiles_estudio leyendo los datos exactos del body
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

    // 3. Sincroniza horarios
    if (horario && Array.isArray(horario)) {
      await client.query("DELETE FROM horarios WHERE usuario_id = $1", [id]);
      for (const b of horario) {
        await client.query("INSERT INTO horarios (usuario_id, dia, hora_inicio, hora_fin) VALUES ($1, $2, $3, $4)", [id, b.dia.trim(), b.hora_inicio.trim(), b.hora_fin.trim()]);
      }
    }
    
    await client.query("COMMIT");
    return res.status(200).json({ mensaje: "Perfil de LUMI guardado exitosamente" });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error(error);
    return res.status(500).json({ mensaje: "Error al guardar perfil" });
  } finally { client.release(); }
});
export default router;