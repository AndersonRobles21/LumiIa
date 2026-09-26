import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/calendar_screen.dart';

void main() {
  test('normaliza todas las actividades de un plan como un solo evento padre', () {
    final eventos = normalizarEventosCalendario(
      planes: [
        {
          'id': 'plan-1',
          'nombre': 'Proyecto general',
          'descripcion': 'Descripción principal',
          'fecha_entrega': '2026-10-10',
        },
      ],
      tareas: [
        {
          'id': 'tarea-1',
          'plan_id': 'plan-1',
          'nombre': 'Paso 1',
          'fecha_entrega': '2026-10-03',
        },
        {
          'id': 'tarea-2',
          'plan_id': 'plan-1',
          'nombre': 'Paso 2',
          'fecha_entrega': '2026-10-06',
        },
      ],
    );

    expect(eventos, hasLength(1));
    expect(eventos.single['nombre'], 'Proyecto general');
    expect(eventos.single['descripcion'], 'Descripción principal');
    expect(eventos.single['fecha_entrega'], '2026-10-10');
  });

  test('agrupa el fallback de actividades por plan y conserva tareas sueltas', () {
    final eventos = normalizarEventosCalendario(
      tareas: [
        {
          'id': 'tarea-1',
          'plan_id': 'plan-1',
          'plan_nombre': 'Plan padre',
          'plan_descripcion': 'Descripción padre',
          'plan_fecha_entrega': '2026-10-10',
          'nombre': 'Paso 1',
        },
        {
          'id': 'tarea-2',
          'plan_id': 'plan-1',
          'plan_nombre': 'Plan padre',
          'plan_fecha_entrega': '2026-10-10',
          'nombre': 'Paso 2',
        },
        {'id': 'manual-1', 'nombre': 'Tarea independiente'},
      ],
    );

    expect(eventos, hasLength(2));
    expect(eventos.first['nombre'], 'Plan padre');
    expect(eventos.last['nombre'], 'Tarea independiente');
  });

  test('marca el plan cada día desde su creación hasta la fecha de entrega', () {
    final fechas = fechasEventoCalendario(
      DateTime.utc(2026, 9, 26),
      DateTime.utc(2026, 9, 29),
    );

    expect(fechas, [
      DateTime.utc(2026, 9, 26),
      DateTime.utc(2026, 9, 27),
      DateTime.utc(2026, 9, 28),
      DateTime.utc(2026, 9, 29),
    ]);
  });

  testWidgets('CalendarScreen muestra eventos tras cargar sus datos', (WidgetTester tester) async {
    final hoy = DateTime.now();
    final tasks = [
      {
        'id': '123',
        'nombre': 'Entrega de proyecto',
        'descripcion': 'Subir la versión final del proyecto.',
        'fecha_entrega': DateTime(hoy.year, hoy.month, hoy.day).toIso8601String(),
        'estado': 'PENDIENTE',
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(userId: 'user-1', tasks: tasks),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Calendario'), findsOneWidget);
    expect(find.text('Entrega de proyecto'), findsOneWidget);
  });

  testWidgets('CalendarScreen muestra una sola tarjeta por plan', (WidgetTester tester) async {
    final hoy = DateTime.now();
    final fechaEntrega = DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).toIso8601String();

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(
          userId: 'user-1',
          tasks: [
            {
              'id': 'task-1',
              'plan_id': 'plan-1',
              'plan_nombre': 'Plan de matemáticas',
              'plan_descripcion': 'Descripción general del plan',
              'plan_fecha_entrega': fechaEntrega,
              'nombre': 'Paso uno',
            },
            {
              'id': 'task-2',
              'plan_id': 'plan-1',
              'plan_nombre': 'Plan de matemáticas',
              'plan_descripcion': 'Descripción general del plan',
              'plan_fecha_entrega': fechaEntrega,
              'nombre': 'Paso dos',
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Plan de matemáticas'), findsOneWidget);
    expect(find.text('Paso uno'), findsNothing);
    expect(find.text('Paso dos'), findsNothing);
  });
}
