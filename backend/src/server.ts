
import express from "express";
import dotenv from "dotenv";
import cors from "cors";



dotenv.config();

import { pool } from "./config/db";
import authRoutes from "./rutas/authRoutes";


const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);

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