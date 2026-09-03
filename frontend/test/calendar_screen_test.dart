import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/calendar_screen.dart';

void main() {
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
}
