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
UPDATE PROFILE
PUT /api/auth/profile/:id
=================================
*/

router.put("/profile/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre } = req.body;

    const resultado = await pool.query(
      `
      UPDATE usuarios
      SET
      nombre = $1,
      updated_at = NOW()
      WHERE id = $2
      RETURNING
      id,
      nombre,
      apellido,
      correo,
      metodo_estudio
      `,
      [nombre, id]
    );

    if (resultado.rows.length === 0) {
      return res.status(404).json({
        mensaje: "Usuario no encontrado",
      });
    }

    res.status(200).json({
      mensaje: "Perfil actualizado",
      usuario: resultado.rows[0],
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      mensaje: "Error al actualizar perfil",
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

export default router;