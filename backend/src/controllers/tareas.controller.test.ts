import test from "node:test";
import assert from "node:assert/strict";
import { pool } from "../config/db.js";
import {
  completarTarea,
  normalizarTareaPayload,
  obtenerTareasPorUsuario,
} from "./tareas.controller.js";

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

test("actualiza estadísticas duplicadas al completar una tarea", async (t) => {
  const userId = "00000000-0000-4000-8000-000000000001";
  const calls: Array<{ sql: string; params?: unknown[] }> = [];
  const results = [
    { rows: [{ id: "00000000-0000-4000-8000-000000000002", titulo: "Repasar", descripcion: "", completada: true }], rowCount: 1 },
    { rows: [{ usuario_id: userId }], rowCount: 1 },
    { rows: [{ total_tareas: "4", tareas_completadas: "2" }], rowCount: 1 },
    { rows: [], rowCount: 6 },
  ];

  t.mock.method(pool as any, "query", async (sql: string, params?: unknown[]) => {
    calls.push({ sql, params });
    const result = results.shift();
    assert.ok(result, "unexpected database query");
    return result;
  });

  const response: any = {
    statusCode: 200,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(payload: unknown) {
      this.payload = payload;
      return this;
    },
  };

  await completarTarea(
    { params: { tareaId: "00000000-0000-4000-8000-000000000002" }, body: { completada: true } } as any,
    response,
  );

  assert.equal(response.statusCode, 200);
  assert.match(calls[3].sql, /UPDATE estadisticas/);
  assert.doesNotMatch(calls[3].sql, /ON CONFLICT/);
  assert.deepEqual(calls[3].params, [userId, 2]);
  assert.equal(calls.length, 4);
});
