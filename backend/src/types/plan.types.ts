export interface Subpaso {
  id: string;
  texto: string;
  completado: boolean;
}

export interface PasoPrincipal {
  numero: number;
  titulo: string;
  descripcion: string;
  subpasos: Subpaso[];
}

export interface PreguntaRecall {
  pregunta: string;
  respuesta: string;
}

export interface SubtareaIA {
  titulo: string;
  descripcion: string;
  duracion_minutos: number;
  prioridad: "ALTA" | "MEDIA" | "BAJA";
}

export interface RecursoIA {
  tipo: string;
  nombre: string;
  url?: string;
  descripcion: string;
}

export interface PlanIA {
  metodo_estudio: string;
  justificacion: string;
  tiempo_estimado_total: number;
  consejos: string[];
  recursos: RecursoIA[];
  subtareas?: SubtareaIA[];
  conceptos_clave: string[];
  preguntas_recall: PreguntaRecall[];
  pasos: PasoPrincipal[];
  resumen_final: string;
}