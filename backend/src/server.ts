import express from "express";
import dotenv from "dotenv";
dotenv.config();

import { pool } from "./config/db";
import authRoutes from "./rutas/authRoutes";

const app = express();

// Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rutas
app.use("/api/auth", authRoutes);

// Ruta de salud
app.get("/", async (req, res) => {
  const resultado = await pool.query("SELECT NOW()");
  res.json({
    mensaje: "LUMI Backend funcionando",
    fecha: resultado.rows[0],
  });
});

const PORT = process.env.PORT || 3000;
app.listen(Number(PORT), "0.0.0.0", () => {
  console.log(` Servidor LUMI corriendo en http://localhost:${PORT}`);
});