import test from "node:test";
import assert from "node:assert/strict";
import { normalizarTareaPayload, obtenerTareasPorUsuario } from "./tareas.controller.js";

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

test("rechaza un userId inválido antes de consultar la base de datos", async () => {
  const req: any = { params: { userId: "test" } };
  const res: any = {
    statusCode: 200,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(payload: any) {
      this.payload = payload;
      return this;
    },
  };

  await obtenerTareasPorUsuario(req, res);

  assert.equal(res.statusCode, 400);
  assert.equal(res.payload.mensaje, "Se requiere un usuario válido.");
});
