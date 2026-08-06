import test from "node:test";
import assert from "node:assert/strict";
import { normalizarTareaPayload } from "./tareas.controller.js";

test("normaliza datos de tarea desde alias de nombre y estado", () => {
  const payload = normalizarTareaPayload({
    nombre: "Estudiar",
    descripcion: "Repasar tema",
    estado: "PENDIENTE",
    completada: false,
  });

  assert.equal(payload.titulo, "Estudiar");
  assert.equal(payload.descripcion, "Repasar tema");
  assert.equal(payload.completada, false);
});

test("rechaza un payload con completada inválida", () => {
  const payload = normalizarTareaPayload({
    nombre: "Tarea",
    completada: "si",
  });

  assert.equal(payload.error, "El campo 'completada' debe ser booleano.");
});
