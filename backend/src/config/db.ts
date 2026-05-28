import { Pool } from "pg";
import dotenv from "dotenv";

dotenv.config();

if (!process.env.DB_HOST) {
  throw new Error("❌ Falta DB_HOST en .env");
}

console.log("🌐 Conectando a:", process.env.DB_HOST);

export const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,

  ssl: {
    rejectUnauthorized: false,
  },
});