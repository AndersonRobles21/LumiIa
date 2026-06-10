import express from "express";
import dotenv from "dotenv";

dotenv.config();

import { pool } from "./config/db";

const app = express();

app.get("/", async (req, res) => {
  const resultado = await pool.query("SELECT NOW()");

  res.json({
    mensaje: "Conexión exitosa con Supabase",
    fecha: resultado.rows[0],
  });
});

app.listen(3000, "0.0.0.0", () => {
  console.log("Servidor funcionando en http://localhost:3000");
});