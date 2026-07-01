import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";

dotenv.config();

if (!process.env.GEMINI_API_KEY) {
  throw new Error("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxzYm5penp5cGRtbnZwcGF0enhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExOTE1MTEsImV4cCI6MjA5Njc2NzUxMX0.BSPlhX0JOwUWTYoSmzcse3MAIANgu5UniSNxm6Qjr0U");
}

export const GEMINI_MODEL =
  process.env.GEMINI_MODEL || "gemini-2.5-flash";

export const GEMINI_TEMPERATURE = Number(
  process.env.GEMINI_TEMPERATURE ?? 0.6
);

export const GEMINI_MAX_OUTPUT_TOKENS = Number(
  process.env.GEMINI_MAX_OUTPUT_TOKENS ?? 8192
);

export const gemini = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});