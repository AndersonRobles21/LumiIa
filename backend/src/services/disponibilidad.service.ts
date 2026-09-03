export type EstadoDisponibilidad = "SUFICIENTE" | "AJUSTADO" | "INSUFICIENTE";

export interface HorarioDisponible {
  hora_inicio: string;
  hora_fin: string;
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
