import assert from "node:assert/strict";
import test from "node:test";
import { pool } from "../config/db";
import { obtenerHorasSemana, registrarSesionEstudio } from "./progreso.controller";

type QueryCall = { sql: string; params?: unknown[] };
type FakeClient = {
  query: (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>;
  release: () => void;
};

function createRequest(body: Record<string, unknown>): any {
  return { body };
}

function createResponse(): any {
  return {
    statusCode: 200,
    body: null,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(body: unknown) {
      this.body = body;
      return this;
    },
  };
}

function fakeClient(
  handleQuery: (sql: string, params?: unknown[]) => Promise<{ rows: any[] }>,
  calls: QueryCall[],
): FakeClient {
  return {
    async query(sql, params) {
      calls.push({ sql, params });
      return handleQuery(sql, params);
    },
    release() {},
  };
}

function stubPoolConnection(t: test.TestContext, client: FakeClient): void {
  t.mock.method(pool as any, "connect", async () => client as any);
}

const validBody = {
  usuario_id: "00000000-0000-4000-8000-000000000001",
  duracion_minutos: 1,
  tipo_origen: "pomodoro",
  categoria: "Prueba",
};

test("registra una sesión y actualiza todas las filas duplicadas de estadísticas", async (t) => {
  const calls: QueryCall[] = [];
  const client = fakeClient(async (sql) => {
    if (sql.startsWith("UPDATE estadisticas")) {
      return {
        rows: Array.from({ length: 6 }, (_, index) => ({
          tareas_completadas: 0,
          horas_estudio: (index + 1) / 60,
          racha: 0,
        })),
      };
    }
    return { rows: [] };
  }, calls);
  stubPoolConnection(t, client);
  const response = createResponse();

  await registrarSesionEstudio(createRequest(validBody), response);

  assert.equal(response.statusCode, 201);
  assert.equal(calls[0].sql, "BEGIN");
  assert.match(calls[1].sql, /INSERT INTO sesiones_estudio/);
  assert.match(calls[2].sql, /UPDATE estadisticas/);
  assert.doesNotMatch(calls[2].sql, /ON CONFLICT/);
  assert.equal(calls[calls.length - 1]?.sql, "COMMIT");
});

test("crea estadísticas si aún no existen para el usuario", async (t) => {
  const calls: QueryCall[] = [];
  const client = fakeClient(async (sql) => {
    if (sql.startsWith("UPDATE estadisticas")) return { rows: [] };
    if (sql.startsWith("INSERT INTO estadisticas")) {
      return { rows: [{ tareas_completadas: 0, horas_estudio: 1 / 60, racha: 0 }] };
    }
    return { rows: [] };
  }, calls);
  stubPoolConnection(t, client);
  const response = createResponse();

  await registrarSesionEstudio(createRequest(validBody), response);

  assert.equal(response.statusCode, 201);
  assert.ok(calls.some(({ sql }) => sql.startsWith("INSERT INTO estadisticas")));
  assert.equal(calls[calls.length - 1]?.sql, "COMMIT");
});

test("revierte la transacción si falla el registro de la sesión", async (t) => {
  const calls: QueryCall[] = [];
  const client = fakeClient(async (sql) => {
    if (sql.startsWith("INSERT INTO sesiones_estudio")) {
      throw new Error("session insert failed");
    }
    return { rows: [] };
  }, calls);
  stubPoolConnection(t, client);
  const response = createResponse();

  await registrarSesionEstudio(createRequest(validBody), response);

  assert.equal(response.statusCode, 500);
  assert.equal((response.body as any).mensaje, "Error al registrar sesión");
  assert.ok(calls.some(({ sql }) => sql === "ROLLBACK"));
  assert.equal(calls.some(({ sql }) => sql === "COMMIT"), false);
});

test("devuelve las horas semanales en orden de lunes a domingo", async (t) => {
  const calls: QueryCall[] = [];
  t.mock.method(pool as any, "query", async (sql: string, params?: unknown[]) => {
    calls.push({ sql, params });
    return {
      rows: [
        { dia_iso: 1, minutos: 90 },
        { dia_iso: 7, minutos: 30 },
      ],
    };
  });
  const response = createResponse();

  await obtenerHorasSemana({ params: { userId: validBody.usuario_id } } as any, response);

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, {
    horas_por_dia: [1.5, 0, 0, 0, 0, 0, 0.5],
  });
  assert.match(calls[0].sql, /EXTRACT\(ISODOW FROM fin\)/);
  assert.deepEqual(calls[0].params, [validBody.usuario_id]);
});
