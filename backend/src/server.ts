import express from "express";
import dotenv from "dotenv";
import cors from "cors";

dotenv.config();

import { pool } from "./config/db";

import authRoutes from "./rutas/authRoutes";
import horarios from "./rutas/horarios";
import tareas from "./rutas/tareas.routes";
import iaRoutes from "./rutas/ia.routes";
import historialRoutes from "./rutas/historial.routes";
import adminRoutes from "./rutas/admin.routes";
import progresoRoutes from "./rutas/progreso.routes";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/horarios", horarios);
app.use("/api/tareas", tareas);
app.use("/api/ia", iaRoutes);
app.use("/api/ia/historial", historialRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/progreso", progresoRoutes);

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