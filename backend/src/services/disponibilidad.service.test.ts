import test from "node:test";
import assert from "node:assert/strict";
import {
  calcularCapacidadPlan,
  distribuirUnidadesEnFranjas,
  franjasDisponiblesEntreFechas,
  minutosDisponiblesPorDia,
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

test("separa la disponibilidad semanal por día", () => {
  assert.deepEqual(
    minutosDisponiblesPorDia([
      { dia: "lunes", hora_inicio: "16:00", hora_fin: "18:00" },
      { dia: "miercoles", hora_inicio: "14:00", hora_fin: "17:00" },
      { dia: "viernes", hora_inicio: "15:00", hora_fin: "18:00" },
    ]),
    {
      lunes: 120,
      martes: 0,
      miercoles: 180,
      jueves: 0,
      viernes: 180,
      sabado: 0,
      domingo: 0,
    },
  );
});

test("convierte horarios semanales en fechas concretas sin mezclar días", () => {
  const franjas = franjasDisponiblesEntreFechas(
    [
      { dia: "lunes", hora_inicio: "16:00", hora_fin: "18:00" },
      { dia: "miercoles", hora_inicio: "14:00", hora_fin: "17:00" },
      { dia: "viernes", hora_inicio: "15:00", hora_fin: "18:00" },
    ],
    "2026-09-28",
    "2026-10-04",
  );

  assert.deepEqual(franjas.map((franja) => [franja.fecha, franja.minutos]), [
    ["2026-09-28", 120],
    ["2026-09-30", 180],
    ["2026-10-02", 180],
  ]);
});

test("divide una actividad larga entre fechas disponibles sin exceder su capacidad", () => {
  const franjas = franjasDisponiblesEntreFechas(
    [
      { dia: "lunes", hora_inicio: "16:00", hora_fin: "18:00" },
      { dia: "miércoles", hora_inicio: "16:00", hora_fin: "18:00" },
    ],
    "2026-09-28",
    "2026-09-30",
  );
  const segmentos = distribuirUnidadesEnFranjas(
    [{ clave: "fase-1", duracionMinutos: 180 }],
    franjas,
  );

  assert.deepEqual(segmentos.map((segmento) => [segmento.fecha, segmento.minutosAsignados]), [
    ["2026-09-28", 120],
    ["2026-09-30", 60],
  ]);
});
