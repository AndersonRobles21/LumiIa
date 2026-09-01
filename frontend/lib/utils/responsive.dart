import 'package:flutter/material.dart';

/// Utilidades responsive para la app LUMI.
///
/// Provee funciones sencillas y estáticas para obtener dimensiones
/// y valores UI recomendados según el ancho de la pantalla.
class Responsive {
  // Breakpoints
  static const int _mobileMax = 599;
  static const int _tabletMin = 600;
  static const int _tabletMax = 1023;
  static const int _desktopMin = 1024;

  // Ancho / alto de la pantalla
  static double anchoPantalla(BuildContext context) => MediaQuery.of(context).size.width;
  static double altoPantalla(BuildContext context) => MediaQuery.of(context).size.height;

  // Tipo de dispositivo
  static bool esMovil(BuildContext context) => anchoPantalla(context) <= _mobileMax;
  static bool esTablet(BuildContext context) {
    final w = anchoPantalla(context);
    return w >= _tabletMin && w <= _tabletMax;
  }
  static bool esEscritorio(BuildContext context) => anchoPantalla(context) >= _desktopMin;

  // Padding horizontal recomendado según el dispositivo
  static double paddingHorizontalRecomendado(BuildContext context) {
    if (esMovil(context)) return 16.0;
    if (esTablet(context)) return 24.0;
    return 48.0;
  }

  // Ancho máximo de contenido (útil para centrar contenido en desktop)
  static double anchoMaximoContenido(BuildContext context) {
    if (esEscritorio(context)) return 1200.0;
    if (esTablet(context)) return 900.0;
    return anchoPantalla(context) - paddingHorizontalRecomendado(context) * 2;
  }

  // Tamaño de botones
  static double anchoBoton(BuildContext context) {
    if (esMovil(context)) return anchoPantalla(context) - paddingHorizontalRecomendado(context) * 2;
    if (esTablet(context)) return 320.0;
    return 220.0;
  }

  static double altoBoton(BuildContext context) => esMovil(context) ? 48.0 : 52.0;

  // Tipografías (valores recomendados)
  static double tamanioTitulo(BuildContext context) {
    if (esMovil(context)) return 20.0;
    if (esTablet(context)) return 24.0;
    return 28.0;
  }

  static double tamanioSubtitulo(BuildContext context) {
    if (esMovil(context)) return 16.0;
    if (esTablet(context)) return 18.0;
    return 20.0;
  }

  static double tamanioTexto(BuildContext context) {
    if (esMovil(context)) return 14.0;
    if (esTablet(context)) return 16.0;
    return 18.0;
  }

  // Espaciados y border radius
  static double espacio(BuildContext context) {
    if (esMovil(context)) return 8.0;
    if (esTablet(context)) return 12.0;
    return 16.0;
  }

  static double radioBorde(BuildContext context) {
    if (esMovil(context)) return 8.0;
    if (esTablet(context)) return 12.0;
    return 16.0;
  }
}
