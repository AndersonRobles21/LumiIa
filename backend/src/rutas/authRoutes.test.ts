import assert from "node:assert/strict";
import test from "node:test";
import { pool } from "../config/db";
import authRoutes from "./authRoutes";

const userId = "00000000-0000-4000-8000-000000000001";

type RouteHandler = (req: any, res: any) => Promise<any>;

function getRouteHandler(path: string, method: string): RouteHandler {
  const layer = (authRoutes as any).stack.find(
    (entry: any) => entry.route?.path === path,
  );
  const routeLayer = layer?.route?.stack.find(
    (entry: any) => entry.method === method,
  );
  assert.ok(routeLayer, `route ${method.toUpperCase()} ${path} should exist`);
  return routeLayer.handle;
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

function todayAtLocalMidnight(): Date {
  const today = new Date();
  return new Date(today.getFullYear(), today.getMonth(), today.getDate());
}

test("devuelve un resumen de estadísticas sin insertar filas duplicadas", async (t) => {
  const calls: string[] = [];
  t.mock.method(pool as any, "query", async (sql: string) => {
    calls.push(sql);
    return {
      rows: [{ tareas_completadas: 2, horas_estudio: "1.5", racha: 3 }],
      rowCount: 1,
    };
  });

  const response = createResponse();
  await getRouteHandler("/estadisticas/:userId", "get")(
    { params: { userId } },
    response,
  );

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, {
    tareas_completadas: 2,
    horas_estudio: "1.5",
    racha: 3,
  });
  assert.match(calls[0], /MAX\(tareas_completadas\)/);
  assert.equal(calls.length, 1);
});

test("no vuelve a insertar estadísticas si la racha ya se marcó hoy", async (t) => {
  const calls: string[] = [];
  t.mock.method(pool as any, "query", async (sql: string) => {
    calls.push(sql);
    return {
      rows: [{ racha: 1, ultima_racha_fecha: todayAtLocalMidnight() }],
      rowCount: 1,
    };
  });

  const response = createResponse();
  await getRouteHandler("/estadisticas/:userId/racha", "post")(
    { params: { userId } },
    response,
  );

  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, { mensaje: "Ya marcaste hoy", racha: 1 });
  assert.equal(calls.length, 1);
  assert.match(calls[0], /MAX\(racha\)/);
});
