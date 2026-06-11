import { Router } from "express";
import { pool } from "../config/db";

const router = Router();

router.post("/register", async (req, res) => {
  try {
    const { email, password } = req.body;

    const resultado = await pool.query(
      `
      INSERT INTO usuario (correo, password)
      VALUES ($1, $2)
      RETURNING *
      `,
      [email, password]
    );

    res.status(201).json({
      mensaje: "Usuario registrado",
      usuario: resultado.rows[0],
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      mensaje: "Error al registrar usuario",
    });
  }
});

export default router;