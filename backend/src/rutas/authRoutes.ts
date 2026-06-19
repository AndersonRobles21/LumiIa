import { Router } from "express";
import { pool } from "../config/db";
import bcrypt from "bcrypt";

const router = Router();

/*
=================================
GET PROFILE
GET /api/auth/profile/:id
=================================
*/
router.get("/profile/:id", async (req, res) => {
  try {
    const { id } = req.params;

    const resultado = await pool.query(
      `
      SELECT
      id,
      nombre,
      apellido,
      correo,
      metodo_estudio
      FROM usuarios
      WHERE id = $1
      `,
      [id]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({
        mensaje: "Usuario no encontrado",
      });
    }

    res.status(200).json(resultado.rows[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({
      mensaje: "Error al obtener perfil",
    });
  }
});

/*
=================================
UPDATE PROFILE (Con validación de consistencia)
PUT /api/auth/profile/:id
=================================
*/
router.put("/profile/:id", async (req, res) => {
  const { id } = req.params;
  const { nombre, apellido, metodo_estudio } = req.body;

  // CAMBIO NECESARIO: Validar métodos permitidos igual que en el registro
  const metodosPermitidos = [
    "POMODORO",
    "FEYNMAN",
    "ACTIVE_RECALL",
    "MAPA_MENTAL",
    "SPACED_REPETITION"
  ];

  if (metodo_estudio && !metodosPermitidos.includes(metodo_estudio)) {
    return res.status(400).json({
      mensaje: "Método de estudio inválido",
    });
  }

  try {
    const resultado = await pool.query(
      `
      UPDATE usuarios 
      SET nombre = $1, 
          apellido = $2, 
          metodo_estudio = $3, 
          updated_at = NOW() 
      WHERE id = $4 
      RETURNING id, nombre, apellido, correo, metodo_estudio
      `,
      [nombre, apellido, metodo_estudio, id]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({ mensaje: "Usuario no encontrado" });
    }

    return res.status(200).json({
      mensaje: "Perfil actualizado con éxito",
      usuario: resultado.rows[0], // Este es el nodo que el frontend ahora leerá correctamente
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({
      mensaje: "Error interno al actualizar el perfil en la base de datos",
      error: error instanceof Error ? error.message : error,
    });
  }
});

/*
=================================
REGISTRO
POST /api/auth/register
=================================
*/
router.post("/register", async (req, res) => {
  try {
    const {
      nombre,
      apellido,
      correo,
      password,
      metodo_estudio,
    } = req.body;

    const metodosPermitidos = [
      "POMODORO",
      "FEYNMAN",
      "ACTIVE_RECALL",
      "MAPA_MENTAL",
      "SPACED_REPETITION"
    ];

    const metodoFinal = metodo_estudio || "POMODORO";

    if (!metodosPermitidos.includes(metodoFinal)) {
      return res.status(400).json({
        mensaje: "Método de estudio inválido",
      });
    }

    if (!nombre || !correo || !password) {
      return res.status(400).json({
        mensaje: "Faltan campos obligatorios",
      });
    }

    const usuarioExistente = await pool.query(
      "SELECT * FROM usuarios WHERE correo = $1",
      [correo]
    );

    if (usuarioExistente.rows.length > 0) {
      return res.status(400).json({
        mensaje: "El correo ya está registrado",
      });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const resultado = await pool.query(
      `
      INSERT INTO usuarios
      (
        nombre,
        apellido,
        correo,
        password_hash,
        metodo_estudio
      )
      VALUES
      (
        $1,
        $2,
        $3,
        $4,
        $5
      )
      RETURNING
      id,
      nombre,
      apellido,
      correo,
      metodo_estudio,
      created_at
      `,
      [
        nombre,
        apellido,
        correo,
        passwordHash,
        metodoFinal,
      ]
    );

    res.status(201).json({
      mensaje: "Usuario registrado correctamente",
      usuario: resultado.rows[0],
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      mensaje: "Error al registrar usuario",
    });
  }
});

/*
=================================
LOGIN
POST /api/auth/login
=================================
*/
router.post("/login", async (req, res) => {
  try {
    const { correo, password } = req.body;
    if (!correo || !password) {
      return res.status(400).json({
        mensaje: "Faltan credenciales"
      });
    }

    const resultado = await pool.query(
      `
      SELECT
      id,
      nombre,
      apellido,
      correo,
      metodo_estudio,
      password_hash
      FROM usuarios
      WHERE correo = $1
      `,
      [correo]
    );

    if (resultado.rows.length === 0) {
      return res.status(401).json({
        mensaje: "Correo o contraseña incorrectos",
      });
    }

    const usuario = resultado.rows[0];

    const passwordValida = await bcrypt.compare(
      password,
      usuario.password_hash
    );

    if (!passwordValida) {
      return res.status(401).json({
        mensaje: "Correo o contraseña incorrectos",
      });
    }

    res.status(200).json({
      mensaje: "Login exitoso",
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        apellido: usuario.apellido,
        correo: usuario.correo,
        metodo_estudio: usuario.metodo_estudio,
      },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      mensaje: "Error al iniciar sesión",
    });
  }
});

/*
=================================
REQUEST PASSWORD RESET
POST /api/auth/password/request
=================================
*/
router.post("/password/request", async (req, res) => {
  try {
    const { correo } = req.body;
    if (!correo) {
      return res.status(400).json({ mensaje: "El correo es obligatorio" });
    }

    // 1. Verificar si el usuario existe
    const usuario = await pool.query("SELECT id FROM usuarios WHERE correo = $1", [correo]);
    if (usuario.rows.length === 0) {
      return res.status(404).json({ mensaje: "No existe una cuenta con ese correo" });
    }

    // 2. Mock del código de verificación (Simulado para pruebas locales del Sprint 1)
    const codigoSimulado = "123456";
    console.log(`[TEST] Código enviado a ${correo}: ${codigoSimulado}`);

    // Nota: En producción, aquí guardarías el código con expiración en la BD y enviarías un email real.

    return res.status(200).json({ 
      mensaje: "Código de recuperación enviado con éxito",
      token: "TOKEN_PROVISIONAL_TEST" // Retorno plano para que api_service no de error
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ mensaje: "Error al solicitar recuperación" });
  }
});

/*
=================================
RESET PASSWORD
POST /api/auth/password/reset
=================================
*/
router.post("/password/reset", async (req, res) => {
  try {
    const { correo, password, code } = req.body;

    if (!correo || !password || !code) {
      return res.status(400).json({ mensaje: "Faltan campos obligatorios" });
    }

    // Validar el código simulado para pruebas locales
    if (code !== "123456") {
      return res.status(400).json({ mensaje: "Código de verificación inválido o expirado" });
    }

    // Encriptar nueva contraseña
    const nuevoPasswordHash = await bcrypt.hash(password, 10);

    // Actualizar en la base de datos
    const resultado = await pool.query(
      "UPDATE usuarios SET password_hash = $1 WHERE correo = $2",
      [nuevoPasswordHash, correo]
    );

    return res.status(200).json({ mensaje: "Contraseña actualizada correctamente" });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ mensaje: "Error al restablecer la contraseña" });
  }
});

export default router;