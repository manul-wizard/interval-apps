import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'kit_localizations_en.dart';
import 'kit_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of KitLocalizations
/// returned by `KitLocalizations.of(context)`.
///
/// Applications need to include `KitLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/kit_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: KitLocalizations.localizationsDelegates,
///   supportedLocales: KitLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the KitLocalizations.supportedLocales
/// property.
abstract class KitLocalizations {
  KitLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static KitLocalizations of(BuildContext context) {
    return Localizations.of<KitLocalizations>(context, KitLocalizations)!;
  }

  static const LocalizationsDelegate<KitLocalizations> delegate =
      _KitLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// Starts the workout from its beginning.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Pauses the running workout.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Continues the paused workout.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Returns the workout to its beginning.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Status shown while the workout is paused.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get paused;

  /// Title of the settings screen and its button.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label of the language setting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Screen-reader label of a minus button.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// Screen-reader label of a plus button.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// Tooltip of the button that turns the dark theme on.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// Tooltip of the button that turns the light theme on.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;
}

class _KitLocalizationsDelegate
    extends LocalizationsDelegate<KitLocalizations> {
  const _KitLocalizationsDelegate();

  @override
  Future<KitLocalizations> load(Locale locale) {
    return SynchronousFuture<KitLocalizations>(lookupKitLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_KitLocalizationsDelegate old) => false;
}

KitLocalizations lookupKitLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return KitLocalizationsEn();
    case 'ru':
      return KitLocalizationsRu();
  }

  throw FlutterError(
    'KitLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
