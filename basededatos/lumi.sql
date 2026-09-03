-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.roles (
  id integer NOT NULL DEFAULT nextval('roles_id_seq'::regclass),
  nombre character varying NOT NULL UNIQUE,
  CONSTRAINT roles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.usuarios (
  id uuid NOT NULL,
  nombre character varying NOT NULL,
  apellido character varying,
  rol_id integer,
  fecha_registro timestamp without time zone DEFAULT now(),
  es_admin boolean DEFAULT false,
  CONSTRAINT usuarios_pkey PRIMARY KEY (id),
  CONSTRAINT usuarios_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id),
  CONSTRAINT usuarios_rol_id_fkey FOREIGN KEY (rol_id) REFERENCES public.roles(id)
);
CREATE TABLE public.perfiles_estudio (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid UNIQUE,
  horas_disponibles integer,
  objetivo text,
  nivel_procrastinacion integer,
  foto_perfil text,
  CONSTRAINT perfiles_estudio_pkey PRIMARY KEY (id),
  CONSTRAINT perfiles_estudio_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.metodos_estudio (
  id integer NOT NULL DEFAULT nextval('metodos_estudio_id_seq'::regclass),
  nombre character varying NOT NULL,
  descripcion text,
  CONSTRAINT metodos_estudio_pkey PRIMARY KEY (id)
);
CREATE TABLE public.planes_estudio (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  nombre character varying NOT NULL,
  descripcion text,
  estado character varying DEFAULT 'ACTIVO'::character varying,
  fecha_creacion timestamp without time zone DEFAULT now(),
  CONSTRAINT planes_estudio_pkey PRIMARY KEY (id),
  CONSTRAINT planes_estudio_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
ALTER TABLE public.planes_estudio
  ADD COLUMN IF NOT EXISTS completado_en timestamp without time zone;
CREATE TABLE public.plan_metodo (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  plan_id uuid,
  metodo_id integer,
  CONSTRAINT plan_metodo_pkey PRIMARY KEY (id),
  CONSTRAINT plan_metodo_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.planes_estudio(id),
  CONSTRAINT plan_metodo_metodo_id_fkey FOREIGN KEY (metodo_id) REFERENCES public.metodos_estudio(id)
);
CREATE TABLE public.actividades (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  plan_id uuid,
  titulo character varying,
  descripcion text,
  fecha date,
  estado character varying DEFAULT 'PENDIENTE'::character varying,
  CONSTRAINT actividades_pkey PRIMARY KEY (id),
  CONSTRAINT actividades_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.planes_estudio(id)
);
CREATE TABLE public.tareas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  actividad_id uuid,
  titulo character varying,
  descripcion text,
  completada boolean DEFAULT false,
  CONSTRAINT tareas_pkey PRIMARY KEY (id),
  CONSTRAINT tareas_actividad_id_fkey FOREIGN KEY (actividad_id) REFERENCES public.actividades(id)
);
CREATE TABLE public.horarios (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  dia character varying,
  hora_inicio time without time zone,
  hora_fin time without time zone,
  CONSTRAINT horarios_pkey PRIMARY KEY (id),
  CONSTRAINT horarios_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.historial_ia (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  pregunta text,
  respuesta text,
  fecha timestamp without time zone DEFAULT now(),
  plan_id uuid,
  CONSTRAINT historial_ia_pkey PRIMARY KEY (id),
  CONSTRAINT historial_ia_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT historial_ia_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.planes_estudio(id)
);
CREATE TABLE public.estadisticas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  tareas_completadas integer DEFAULT 0,
  horas_estudio numeric DEFAULT 0,
  racha integer DEFAULT 0,
  CONSTRAINT estadisticas_pkey PRIMARY KEY (id),
  CONSTRAINT estadisticas_usuario_id_unico UNIQUE (usuario_id),
  CONSTRAINT estadisticas_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
ALTER TABLE public.estadisticas
  ADD COLUMN IF NOT EXISTS ultima_racha_fecha date;
CREATE TABLE public.personajes_usuario (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid NOT NULL,
  personaje integer NOT NULL CHECK (personaje BETWEEN 1 AND 18),
  costo_xp integer NOT NULL CHECK (costo_xp > 0),
  fecha_compra timestamp without time zone DEFAULT now(),
  CONSTRAINT personajes_usuario_pkey PRIMARY KEY (id),
  CONSTRAINT personajes_usuario_unico UNIQUE (usuario_id, personaje),
  CONSTRAINT personajes_usuario_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.recompensas (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  nombre character varying,
  descripcion text,
  puntos integer,
  CONSTRAINT recompensas_pkey PRIMARY KEY (id)
);
CREATE TABLE public.usuario_recompensa (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  recompensa_id uuid,
  CONSTRAINT usuario_recompensa_pkey PRIMARY KEY (id),
  CONSTRAINT usuario_recompensa_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id),
  CONSTRAINT usuario_recompensa_recompensa_id_fkey FOREIGN KEY (recompensa_id) REFERENCES public.recompensas(id)
);
CREATE TABLE public.notificaciones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  usuario_id uuid,
  mensaje text,
  leida boolean DEFAULT false,
  fecha timestamp without time zone DEFAULT now(),
  CONSTRAINT notificaciones_pkey PRIMARY KEY (id),
  CONSTRAINT notificaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id)
);
CREATE TABLE public.planes_ia (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL UNIQUE,
  proveedor_ia character varying NOT NULL,
  modelo_ia character varying NOT NULL,
  metodo_estudio text NOT NULL,
  justificacion text NOT NULL,
  tiempo_estimado_total integer NOT NULL CHECK (tiempo_estimado_total > 0),
  consejos jsonb NOT NULL DEFAULT '[]'::jsonb,
  recursos jsonb NOT NULL DEFAULT '[]'::jsonb,
  resumen_final text NOT NULL,
  version integer NOT NULL DEFAULT 1,
  fecha_generacion timestamp without time zone DEFAULT now(),
  actualizado_en timestamp without time zone DEFAULT now(),
  dificultad character varying DEFAULT 'Media'::character varying,
  enfoque_adicional text,
  CONSTRAINT planes_ia_pkey PRIMARY KEY (id),
  CONSTRAINT planes_ia_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.planes_estudio(id)
);