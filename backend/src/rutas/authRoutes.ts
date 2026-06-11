import { Router, Request, Response } from "express";
import bcrypt from "bcrypt";
import { pool } from "../config/db";

const router = Router();

router.post("/register", async (req: Request, res: Response) => {
  const { email, password } = req.body;

  // Validación básica
  if (!email || !password) {
    return res.status(400).json({ error: "Email y contraseña son requeridos" });
  }

  if (password.length < 6) {
    return res.status(400).json({ error: "La contraseña debe tener mínimo 6 caracteres" });
  }

  try {
    // Verificar si el correo ya existe
    const existe = await pool.query(
      "SELECT id FROM usuarios WHERE correo = $1",
      [email]
    );

    if (existe.rows.length > 0) {
      return res.status(409).json({ error: "Este correo ya está registrado" });
    }

    // Hashear contraseña
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Insertar usuario (nombre temporal para la demo)
    const resultado = await pool.query(
      `INSERT INTO usuarios (nombre, correo, password_hash)
       VALUES ($1, $2, $3)
       RETURNING id, nombre, correo, created_at`,
      ["Usuario Flutter", email, passwordHash]
    );

    const usuario = resultado.rows[0];

    return res.status(201).json({
      mensaje: "Usuario registrado exitosamente",
      usuario: {
        id: usuario.id,
        nombre: usuario.nombre,
        correo: usuario.correo,
        creado: usuario.created_at,
      },
    });
  } catch (error) {
    console.error("Error en registro:", error);
    return res.status(500).json({ error: "Error interno del servidor" });
  }
});

export default router;