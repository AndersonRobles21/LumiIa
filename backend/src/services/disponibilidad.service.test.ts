import test from "node:test";
import assert from "node:assert/strict";
import {
  calcularCapacidadPlan,
  minutosPorDiaDesdeHorarios,
} from "./disponibilidad.service.js";

test("suma intervalos reales incluyendo minutos", () => {
  assert.equal(
    minutosPorDiaDesdeHorarios([
      { hora_inicio: "14:30", hora_fin: "16:00" },
      { hora_inicio: "18:00", hora_fin: "19:15" },
    ]),
    165,
  );
});

test("clasifica como ajustado con el tiempo exacto porque no deja margen", () => {
  const capacidad = calcularCapacidadPlan(
    new Date(Date.now() + 24 * 60 * 60 * 1000),
    [{ hora_inicio: "09:00", hora_fin: "10:00" }],
    60,
  );

  assert.equal(capacidad.estado, "AJUSTADO");
});

test("clasifica como ajustado cuando queda menos de 20% de margen", () => {
  const capacidad = calcularCapacidadPlan(
    new Date(Date.now() + 24 * 60 * 60 * 1000),
    [{ hora_inicio: "09:00", hora_fin: "10:00" }],
    55,
  );

  assert.equal(capacidad.estado, "AJUSTADO");
});

test("clasifica como insuficiente cuando falta capacidad", () => {
  const capacidad = calcularCapacidadPlan(
    new Date(Date.now() + 24 * 60 * 60 * 1000),
    [{ hora_inicio: "09:00", hora_fin: "10:00" }],
    61,
  );

  assert.equal(capacidad.estado, "INSUFICIENTE");
});
