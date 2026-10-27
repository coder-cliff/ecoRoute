import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('en', 'English'),
  lugbara('lug', 'Lugbara'),
  swahili('sw', 'Kiswahili');

  const AppLanguage(this.code, this.label);
  final String code;
  final String label;
}

class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final LanguageService instance = LanguageService._();

  static const String _prefKey = 'ecoroute_app_language_v1';
  AppLanguage _currentLanguage = AppLanguage.english;
  SharedPreferences? _prefs;

  AppLanguage get currentLanguage => _currentLanguage;

  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null) {
      _currentLanguage = AppLanguage.values.firstWhere(
        (l) => l.code == savedCode,
        orElse: () => AppLanguage.english,
      );
      notifyListeners();
    }
  }

  Future<void> setLanguage(AppLanguage language, [SharedPreferences? prefs]) async {
    _currentLanguage = language;
    notifyListeners();
    try {
      final p = prefs ?? _prefs ?? await SharedPreferences.getInstance();
      await p.setString(_prefKey, language.code);
    } catch (_) {
      // Non-critical persistence failure in restricted environments
    }
  }

  String translate(String key) {
    final langMap = _translations[_currentLanguage] ?? _translations[AppLanguage.english]!;
    return langMap[key] ?? _translations[AppLanguage.english]![key] ?? key;
  }

  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.english: {
      'app_title': 'EcoRoute',
      'welcome': 'Arua waste pickup',
      'service_area': 'Service area: within 12 km of the Arua centre.',
      'report_issue': 'Report an issue',
      'schedule_pickup': 'Schedule pickup',
      'service_overview': 'Service overview',
      'account_role': 'Account & role',
      'rider_title': 'Rider dispatch board',
      'admin_title': 'Operations control center',
      'resident_title': 'Resident service overview',
      'stops_to_collect': 'Stops to collect',
      'collected': 'Collected',
      'completed': 'Completed',
      'all_requests': 'Requests',
      'approvals': 'Approvals to review',
      'paid': 'Verified & paid',
      'collection_schedule': 'Arua collection schedule',
      'north_zone': 'North zone',
      'south_zone': 'South zone',
      'east_zone': 'East zone',
      'west_zone': 'West zone',
      'move_closer': 'Move closer to the rubbish...',
      'auto_mode': 'Automatic Capture',
      'manual_mode': 'Manual Capture',
      'detecting_waste': 'Analyzing rubbish profile...',
      'optimal_distance': 'Optimal distance detected! Capturing...',
      'tap_to_capture': 'Tap shutter to capture waste photo',
      'momo_pay': 'Pay with Mobile Money',
      'receipt': 'Collection Receipt',
      'language': 'Language',
    },
    AppLanguage.lugbara: {
      'app_title': 'EcoRoute',
      'welcome': 'Arua liru ebi',
      'service_area': 'Arua kilimita 12 vutia liru omba ku.',
      'report_issue': 'Azita nze / Adri embilu',
      'schedule_pickup': 'Liru omba',
      'service_overview': 'Azita ebi',
      'account_role': 'Akawunti & Ru',
      'rider_title': 'Rider azita kabilo',
      'admin_title': 'Kansulu adrisi kabilo',
      'resident_title': 'Oco adri liru ebi',
      'stops_to_collect': 'Liru ndo ebi',
      'collected': 'Ebi kpo',
      'completed': 'Kpo pari dri',
      'all_requests': 'Liru omba dria',
      'approvals': 'Nze lero',
      'paid': 'Kpii / Ma fesi',
      'collection_schedule': 'Arua liru ebi cici',
      'north_zone': 'North zoni',
      'south_zone': 'South zoni',
      'east_zone': 'East zoni',
      'west_zone': 'West zoni',
      'move_closer': 'Mi tu aza liru ci ru...',
      'auto_mode': 'Otomatiki foto ebi',
      'manual_mode': 'Mi foto ebi dri si',
      'detecting_waste': 'Liru lero nze...',
      'optimal_distance': 'Aza sawa leleta! Foto ebi...',
      'tap_to_capture': 'Mi buti ni kpa foto ebi tu',
      'momo_pay': 'Momo fesi fesi',
      'receipt': 'Risiti liru ebi niri',
      'language': 'Ti ti',
    },
    AppLanguage.swahili: {
      'app_title': 'EcoRoute',
      'welcome': 'Mkusanyiko wa taka Arua',
      'service_area': 'Eneo la huduma: ndani ya km 12 ya kituo cha Arua.',
      'report_issue': 'Toa taarifa ya tatizo',
      'schedule_pickup': 'Panga mkusanyiko',
      'service_overview': 'Muhtasari wa huduma',
      'account_role': 'Akaunti na jukumu',
      'rider_title': 'Ubao wa dereva wa njia',
      'admin_title': 'Kituo cha uendeshaji',
      'resident_title': 'Muhtasari wa mkazi',
      'stops_to_collect': 'Vituo vya kukusanya',
      'collected': 'Zimekusanywa',
      'completed': 'Zimekamilika',
      'all_requests': 'Maombi yote',
      'approvals': 'Uidhinishaji',
      'paid': 'Imelipwa na kuthibitishwa',
      'collection_schedule': 'Ratiba ya ukusanyaji Arua',
      'north_zone': 'Eneo la Kaskazini',
      'south_zone': 'Eneo la Kusini',
      'east_zone': 'Eneo la Mashariki',
      'west_zone': 'Eneo la Magharibi',
      'move_closer': 'Sogea karibu na taka...',
      'auto_mode': 'Picha ya Kiotomatiki',
      'manual_mode': 'Picha ya Mwongozo',
      'detecting_waste': 'Inachambua aina ya taka...',
      'optimal_distance': 'Umbali sahihi umepatikana! Inapiga picha...',
      'tap_to_capture': 'Gonga kitufe kupiga picha ya taka',
      'momo_pay': 'Lipa kwa Pesa ya Simu',
      'receipt': 'Stakabadhi ya Malipo',
      'language': 'Lugha',
    },
  };
}
