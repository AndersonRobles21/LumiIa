export interface SubtareaIA {
  titulo: string;
  descripcion: string;
  duracion_minutos: number;
  prioridad: "ALTA" | "MEDIA" | "BAJA";
}

export interface RecursoIA {
  tipo: string;
  nombre: string;
  descripcion: string;
}

export interface PlanIA {
  metodo_estudio: string;
  justificacion: string;
  tiempo_estimado_total: number;
  consejos: string[];
  recursos: RecursoIA[];
  subtareas: SubtareaIA[];
  resumen_final: string;
}