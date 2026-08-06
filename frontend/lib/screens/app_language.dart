import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLang { es, en }

class AppLanguage extends ChangeNotifier {
  AppLanguage._internal();
  static final AppLanguage instance = AppLanguage._internal();

  AppLang _current = AppLang.es;
  AppLang get current => _current;
  bool get isEnglish => _current == AppLang.en;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('app_language');
    if (saved == 'en') {
      _current = AppLang.en;
    } else {
      _current = AppLang.es;
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLang lang) async {
    if (_current == lang) return;
    _current = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang == AppLang.en ? 'en' : 'es');
    notifyListeners();
  }

  void toggle() => setLanguage(isEnglish ? AppLang.es : AppLang.en);

  /// Devuelve el texto traducido para un key q si falta la traducción, regresa la clave para que sea fácil detectar qué falta por traducir.
  String t(String key) {
    final entry = _strings[key];
    if (entry == null) return key;
    return entry[_current] ?? entry[AppLang.es] ?? key;
  }

  static final Map<String, Map<AppLang, String>> _strings = {
    //  Configuración 
    'config_title': {AppLang.es: 'Configuración', AppLang.en: 'Settings'},
    'login_title': {AppLang.es: 'Iniciar Sesión', AppLang.en: 'Sign in'},
    'login_password': {AppLang.es: 'Contraseña', AppLang.en: 'Password'},
    'login_use_biometric': {
      AppLang.es: 'Usar huella',
      AppLang.en: 'Use fingerprint',
    },
    'login_forgot_password': {
      AppLang.es: '¿Olvidaste tu contraseña?',
      AppLang.en: 'Forgot your password?',
    },
    'login_no_account': {
      AppLang.es: '¿No tienes una cuenta? ',
      AppLang.en: 'Don\'t have an account? ',
    },
    'login_register': {AppLang.es: 'Regístrate', AppLang.en: 'Sign up'},
    'login_verifying_biometric': {
      AppLang.es: 'Verificando huella...',
      AppLang.en: 'Verifying fingerprint...',
    },
    'login_use_password': {
      AppLang.es: 'Usar contraseña en su lugar',
      AppLang.en: 'Use password instead',
    },
    'section_notifications': {
      AppLang.es: 'Notificaciones',
      AppLang.en: 'Notifications',
    },
    'push_title': {
      AppLang.es: 'Notificaciones push',
      AppLang.en: 'Push notifications',
    },
    'push_subtitle': {
      AppLang.es: 'Avisos de actividades y tareas pendientes',
      AppLang.en: 'Alerts for activities and pending tasks',
    },
    'reminders_title': {
      AppLang.es: 'Recordatorios diarios',
      AppLang.en: 'Daily reminders',
    },
    'reminders_subtitle': {
      AppLang.es: 'Recibe un recordatorio de tu horario de estudio',
      AppLang.en: 'Get a reminder of your study schedule',
    },
    'section_security': {AppLang.es: 'Seguridad', AppLang.en: 'Security'},
    'biometric_title': {
      AppLang.es: 'Inicio con biometría',
      AppLang.en: 'Biometric login',
    },
    'biometric_subtitle': {
      AppLang.es: 'Usa huella o Face ID para entrar a Lumi',
      AppLang.en: 'Use fingerprint or Face ID to sign in to Lumi',
    },
    'biometric_unavailable': {
      AppLang.es: 'Este dispositivo no tiene biometría configurada.',
      AppLang.en: 'This device has no biometrics set up.',
    },
    'biometric_enabled_ok': {
      AppLang.es: 'Biometría activada correctamente.',
      AppLang.en: 'Biometric login turned on.',
    },
    'change_password': {
      AppLang.es: 'Cambiar contraseña',
      AppLang.en: 'Change password',
    },
    'privacy_data': {
      AppLang.es: 'Privacidad y datos',
      AppLang.en: 'Privacy & data',
    },
    'section_preferences': {
      AppLang.es: 'Preferencias',
      AppLang.en: 'Preferences',
    },
    'language': {AppLang.es: 'Idioma', AppLang.en: 'Language'},
    'study_methods': {
      AppLang.es: 'Métodos de estudio preferidos',
      AppLang.en: 'Preferred study methods',
    },
    'study_methods_msg': {
      AppLang.es:
          'Podrás elegir y guardar tus métodos de estudio favoritos (Pomodoro, mapas mentales, práctica activa, etc.) directamente desde aquí en una próxima actualización.',
      AppLang.en:
          'You\'ll be able to choose and save your favorite study methods (Pomodoro, mind maps, active recall, etc.) right from here in an upcoming update.',
    },
    'section_support': {AppLang.es: 'Soporte', AppLang.en: 'Support'},
    'help_center': {AppLang.es: 'Centro de ayuda', AppLang.en: 'Help center'},
    'about_lumi': {AppLang.es: 'Acerca de Lumi', AppLang.en: 'About Lumi'},
    'logout': {AppLang.es: 'Cerrar sesión', AppLang.en: 'Log out'},
    'logout_confirm_title': {
      AppLang.es: '¿Cerrar sesión?',
      AppLang.en: 'Log out?',
    },
    'logout_confirm_content': {
      AppLang.es:
          'Tendrás que volver a iniciar sesión para acceder a tu cuenta.',
      AppLang.en: 'You\'ll need to sign in again to access your account.',
    },
    'cancel': {AppLang.es: 'Cancelar', AppLang.en: 'Cancel'},
    'change_password_title': {
      AppLang.es: 'Cambiar contraseña',
      AppLang.en: 'Change password',
    },
    'change_password_no_email': {
      AppLang.es: 'No se encontró un correo asociado a tu cuenta.',
      AppLang.en: 'No email associated with your account was found.',
    },
    'change_password_send': {
      AppLang.es: 'Enviar correo',
      AppLang.en: 'Send email',
    },
    'change_password_sent': {
      AppLang.es: 'Te enviamos un correo a %s para cambiar tu contraseña.',
      AppLang.en: 'We sent an email to %s to reset your password.',
    },
    'change_password_error': {
      AppLang.es: 'No se pudo enviar el correo. Intenta de nuevo más tarde.',
      AppLang.en: 'Could not send the email. Please try again later.',
    },
    'select_language': {AppLang.es: 'Idioma', AppLang.en: 'Language'},
    'close': {AppLang.es: 'Cerrar', AppLang.en: 'Close'},
    'understood': {AppLang.es: 'Entendido', AppLang.en: 'Got it'},

    //  Historial IA 
    'history_title': {AppLang.es: 'Historial IA', AppLang.en: 'AI History'},
    'history_intro_1': {
      AppLang.es: 'Aquí verás tus planes de IA generados previamente.',
      AppLang.en: 'Here you\'ll see the AI plans you\'ve generated before.',
    },
    'history_intro_2': {
      AppLang.es: 'Selecciona uno para revisarlo en detalle.',
      AppLang.en: 'Select one to review it in detail.',
    },
    'history_empty': {
      AppLang.es: 'No hay planes de IA guardados aún.',
      AppLang.en: 'No AI plans saved yet.',
    },
    'history_plan_error': {
      AppLang.es: 'No se pudo cargar el plan seleccionado.',
      AppLang.en: 'Could not load the selected plan.',
    },
    'history_default_plan_name': {
      AppLang.es: 'Plan de estudio',
      AppLang.en: 'Study plan',
    },

    //  Barra de navegación 
    'nav_calendar_soon': {
      AppLang.es: '📅 Calendario: disponible próximamente.',
      AppLang.en: '📅 Calendar: coming soon.',
    },
  };
}


mixin AppLanguageListenerMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    AppLanguage.instance.addListener(_onAppLanguageChanged);
  }

  @override
  void dispose() {
    AppLanguage.instance.removeListener(_onAppLanguageChanged);
    super.dispose();
  }

  void _onAppLanguageChanged() {
    if (mounted) setState(() {});
  }

  /// Este es el q devuelve [es] o [en] según el idioma seleccionado
  String tr(String es, String en) =>
      AppLanguage.instance.isEnglish ? en : es;
}
