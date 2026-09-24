export type EstadoDisponibilidad = "SUFICIENTE" | "AJUSTADO" | "INSUFICIENTE";

export interface HorarioDisponible {
  hora_inicio: string;
  hora_fin: string;
}

export interface HorarioSemanal extends HorarioDisponible {
  dia: string;
}

export interface FranjaDisponible {
  fecha: string;
  dia: string;
  hora_inicio: string;
  hora_fin: string;
  minutos: number;
}

export interface UnidadPlanificable {
  clave: string;
  duracionMinutos: number;
}

export interface SegmentoPlanificado extends UnidadPlanificable {
  fecha: string;
  minutosAsignados: number;
  segmento: number;
  totalSegmentos: number;
}

export interface CapacidadPlan {
  horasPorDia: number;
  diasRestantes: number;
  minutosDisponibles: number;
  estado: EstadoDisponibilidad;
}

function minutosDesdeMedianoche(valor: string): number {
  const partes = String(valor).slice(0, 5).split(":");
  return Number(partes[0]) * 60 + Number(partes[1] ?? 0);
}

const DIAS_CANONICOS = ["domingo", "lunes", "martes", "miercoles", "jueves", "viernes", "sabado"];
const ALIAS_DIAS: Record<string, string> = {
  dom: "domingo", domingo: "domingo",
  lun: "lunes", lunes: "lunes",
  mar: "martes", martes: "martes",
  mie: "miercoles", miercoles: "miercoles",
  jue: "jueves", jueves: "jueves",
  vie: "viernes", viernes: "viernes",
  sab: "sabado", sabado: "sabado",
};

function diaCanonico(valor: string): string {
  const dia = String(valor).trim().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
  const resultado = ALIAS_DIAS[dia];
  if (!resultado) throw new Error(`Día de horario inválido: ${valor}`);
  return resultado;
}

function fechaUTC(valor: string | Date): Date {
  if (valor instanceof Date) {
    return new Date(Date.UTC(valor.getUTCFullYear(), valor.getUTCMonth(), valor.getUTCDate()));
  }
  const [year, month, day] = String(valor).slice(0, 10).split("-").map(Number);
  const fecha = new Date(Date.UTC(year, month - 1, day));
  if (Number.isNaN(fecha.getTime())) throw new Error(`Fecha inválida: ${valor}`);
  return fecha;
}

function fechaISO(fecha: Date): string {
  return fecha.toISOString().slice(0, 10);
}

function sumarDias(fecha: Date, dias: number): Date {
  const resultado = new Date(fecha);
  resultado.setUTCDate(resultado.getUTCDate() + dias);
  return resultado;
}

function minutosHorarioSeguro(valor: string): number {
  const minutos = minutosDesdeMedianoche(valor);
  if (!/^\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?$/.test(String(valor).trim())) {
    throw new Error(`Hora de horario inválida: ${valor}`);
  }
  const [hora, minuto] = String(valor).slice(0, 5).split(":").map(Number);
  if (hora > 23 || minuto > 59 || minutos < 0) throw new Error(`Hora de horario inválida: ${valor}`);
  return minutos;
}

export function minutosDisponiblesPorDia(horarios: HorarioSemanal[]): Record<string, number> {
  const resultado: Record<string, number> = Object.fromEntries(
    DIAS_CANONICOS.map((dia) => [dia, 0])
  );
  for (const horario of horarios) {
    const dia = diaCanonico(horario.dia);
    const inicio = minutosHorarioSeguro(horario.hora_inicio);
    const fin = minutosHorarioSeguro(horario.hora_fin);
    if (fin <= inicio) throw new Error(`La hora fin debe ser mayor que inicio en ${dia}`);
    resultado[dia] += fin - inicio;
  }
  return resultado;
}

export function franjasDisponiblesEntreFechas(
  horarios: HorarioSemanal[],
  fechaInicio: string | Date,
  fechaFin: string | Date
): FranjaDisponible[] {
  const inicio = fechaUTC(fechaInicio);
  const fin = fechaUTC(fechaFin);
  if (inicio > fin) return [];

  const normalizados = horarios.map((horario) => {
    const dia = diaCanonico(horario.dia);
    const inicioMinutos = minutosHorarioSeguro(horario.hora_inicio);
    const finMinutos = minutosHorarioSeguro(horario.hora_fin);
    if (finMinutos <= inicioMinutos) throw new Error(`La hora fin debe ser mayor que inicio en ${dia}`);
    return { ...horario, dia, inicioMinutos, finMinutos };
  });
  const resultado: FranjaDisponible[] = [];

  for (let fecha = inicio; fecha <= fin; fecha = sumarDias(fecha, 1)) {
    const dia = DIAS_CANONICOS[fecha.getUTCDay()];
    for (const horario of normalizados) {
      if (horario.dia !== dia) continue;
      resultado.push({
        fecha: fechaISO(fecha),
        dia,
        hora_inicio: horario.hora_inicio,
        hora_fin: horario.hora_fin,
        minutos: horario.finMinutos - horario.inicioMinutos,
      });
    }
  }

  return resultado.sort((a, b) => `${a.fecha}${a.hora_inicio}`.localeCompare(`${b.fecha}${b.hora_inicio}`));
}

export function minutosDisponiblesEntreFechas(
  horarios: HorarioSemanal[],
  fechaInicio: string | Date,
  fechaFin: string | Date
): number {
  return franjasDisponiblesEntreFechas(horarios, fechaInicio, fechaFin)
    .reduce((total, franja) => total + franja.minutos, 0);
}

export function distribuirUnidadesEnFranjas(
  unidades: UnidadPlanificable[],
  franjas: FranjaDisponible[]
): SegmentoPlanificado[] {
  const capacidadPorFecha = new Map<string, number>();
  for (const franja of franjas) {
    capacidadPorFecha.set(franja.fecha, (capacidadPorFecha.get(franja.fecha) ?? 0) + franja.minutos);
  }

  const resultado: SegmentoPlanificado[] = [];
  for (const unidad of unidades) {
    const duracion = Math.max(1, Math.round(Number(unidad.duracionMinutos)));
    let pendiente = duracion;
    let segmento = 0;
    const segmentosUnidad: SegmentoPlanificado[] = [];
    const posibles = [...capacidadPorFecha.entries()].filter(([, capacidad]) => capacidad > 0);
    for (const [fecha, capacidadInicial] of posibles) {
      if (pendiente <= 0) break;
      const asignado = Math.min(pendiente, capacidadInicial);
      if (asignado <= 0) continue;
      segmento++;
      segmentosUnidad.push({
        ...unidad,
        fecha,
        minutosAsignados: asignado,
        segmento,
        totalSegmentos: 0,
      });
      pendiente -= asignado;
      capacidadPorFecha.set(fecha, capacidadInicial - asignado);
    }
    if (pendiente > 0) {
      throw new Error(`No hay disponibilidad suficiente para planificar ${unidad.clave}.`);
    }
    resultado.push(...segmentosUnidad.map((segmentoPlanificado) => ({
      ...segmentoPlanificado,
      totalSegmentos: segmentosUnidad.length,
    })));
  }
  return resultado;
}

export function minutosPorDiaDesdeHorarios(horarios: HorarioDisponible[]): number {
  return horarios.reduce((total, horario) => {
    const inicio = minutosDesdeMedianoche(horario.hora_inicio);
    const fin = minutosDesdeMedianoche(horario.hora_fin);
    return total + Math.max(0, fin - inicio);
  }, 0);
}

export function calcularCapacidadPlan(
  fechaEntrega: string | Date,
  horarios: HorarioDisponible[],
  tiempoEstimadoMinutos?: number
): CapacidadPlan {
  const minutosPorDia = minutosPorDiaDesdeHorarios(horarios);
  const horasPorDia = minutosPorDia > 0 ? minutosPorDia / 60 : 2;
  const entrega = new Date(
    typeof fechaEntrega === "string" && /^\d{4}-\d{2}-\d{2}$/.test(fechaEntrega)
      ? `${fechaEntrega}T23:59:59`
      : fechaEntrega
  );
  const diasRestantes = Math.max(1, Math.ceil((entrega.getTime() - Date.now()) / 86400000));
  const minutosDisponibles = Math.max(15, Math.floor(diasRestantes * horasPorDia * 60));

  let estado: EstadoDisponibilidad = "SUFICIENTE";
  if (tiempoEstimadoMinutos != null) {
    if (minutosDisponibles < tiempoEstimadoMinutos) {
      estado = "INSUFICIENTE";
    } else if (minutosDisponibles < tiempoEstimadoMinutos * 1.2) {
      // Ajustado: queda menos de un 20% de margen sobre el tiempo estimado.
      estado = "AJUSTADO";
    }
  }

  return { horasPorDia, diasRestantes, minutosDisponibles, estado };
}
