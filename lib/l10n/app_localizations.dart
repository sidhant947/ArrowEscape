import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('de'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrow Escape'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Slide. Solve. Escape.'**
  String get appTagline;

  /// No description provided for @levelHeader.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {level}'**
  String levelHeader(int level);

  /// No description provided for @menuPlay.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get menuPlay;

  /// No description provided for @menuLevels.
  ///
  /// In en, this message translates to:
  /// **'LEVELS'**
  String get menuLevels;

  /// No description provided for @menuGameModes.
  ///
  /// In en, this message translates to:
  /// **'GAME MODES'**
  String get menuGameModes;

  /// No description provided for @menuRandom.
  ///
  /// In en, this message translates to:
  /// **'RANDOM'**
  String get menuRandom;

  /// No description provided for @menuHowToPlay.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get menuHowToPlay;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get menuSettings;

  /// No description provided for @randomPuzzleTitle.
  ///
  /// In en, this message translates to:
  /// **'Random Puzzle'**
  String get randomPuzzleTitle;

  /// No description provided for @randomPuzzleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a difficulty tier'**
  String get randomPuzzleSubtitle;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get difficultyMaster;

  /// No description provided for @difficultyExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get difficultyExpert;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @modesTitle.
  ///
  /// In en, this message translates to:
  /// **'MODES'**
  String get modesTitle;

  /// No description provided for @modeLevelsTitle.
  ///
  /// In en, this message translates to:
  /// **'LEVELS'**
  String get modeLevelsTitle;

  /// No description provided for @modeLevelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Select and replay any previously unlocked level.'**
  String get modeLevelsDesc;

  /// No description provided for @modeRandomTitle.
  ///
  /// In en, this message translates to:
  /// **'RANDOM'**
  String get modeRandomTitle;

  /// No description provided for @modeRandomDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate custom puzzles across 5 difficulty tiers.'**
  String get modeRandomDesc;

  /// No description provided for @modeZenTitle.
  ///
  /// In en, this message translates to:
  /// **'ZEN'**
  String get modeZenTitle;

  /// No description provided for @modeZenDesc.
  ///
  /// In en, this message translates to:
  /// **'No lives, no timers. Just pure relaxing puzzle solving.'**
  String get modeZenDesc;

  /// No description provided for @modeTimeAttackTitle.
  ///
  /// In en, this message translates to:
  /// **'TIME ATTACK'**
  String get modeTimeAttackTitle;

  /// No description provided for @modeTimeAttackDesc.
  ///
  /// In en, this message translates to:
  /// **'Race against the clock! Escape arrows to gain extra time.'**
  String get modeTimeAttackDesc;

  /// No description provided for @modeMultiplayerTitle.
  ///
  /// In en, this message translates to:
  /// **'MULTIPLAYER'**
  String get modeMultiplayerTitle;

  /// No description provided for @modeMultiplayerDesc.
  ///
  /// In en, this message translates to:
  /// **'Compete with friends on the exact same puzzle layout.'**
  String get modeMultiplayerDesc;

  /// No description provided for @levelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levelsTitle;

  /// No description provided for @multiplayerTitle.
  ///
  /// In en, this message translates to:
  /// **'MULTIPLAYER'**
  String get multiplayerTitle;

  /// No description provided for @hostRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'HOST ROOM'**
  String get hostRoomTitle;

  /// No description provided for @hostRoomDesc.
  ///
  /// In en, this message translates to:
  /// **'Share this room code with a friend to compete on the exact same puzzle layout!'**
  String get hostRoomDesc;

  /// No description provided for @tooltipNewCode.
  ///
  /// In en, this message translates to:
  /// **'New Code'**
  String get tooltipNewCode;

  /// No description provided for @tooltipCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get tooltipCopyCode;

  /// No description provided for @roomCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Room code {code} copied to clipboard!'**
  String roomCodeCopied(String code);

  /// No description provided for @startMatch.
  ///
  /// In en, this message translates to:
  /// **'START MATCH'**
  String get startMatch;

  /// No description provided for @joinRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'JOIN ROOM'**
  String get joinRoomTitle;

  /// No description provided for @joinRoomDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter or paste a room code to join the match.'**
  String get joinRoomDesc;

  /// No description provided for @joinRoomHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ROOM-849201'**
  String get joinRoomHint;

  /// No description provided for @joinRoomErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter a room code'**
  String get joinRoomErrorEmpty;

  /// No description provided for @joinMatch.
  ///
  /// In en, this message translates to:
  /// **'JOIN MATCH'**
  String get joinMatch;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @themeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'THEME & CUSTOM SKIN'**
  String get themeSectionTitle;

  /// No description provided for @preferencesSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferencesSectionTitle;

  /// No description provided for @prefHapticsTitle.
  ///
  /// In en, this message translates to:
  /// **'HAPTIC FEEDBACK'**
  String get prefHapticsTitle;

  /// No description provided for @prefHapticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on arrow taps, moves, and collisions'**
  String get prefHapticsDesc;

  /// No description provided for @prefInfiniteLivesTitle.
  ///
  /// In en, this message translates to:
  /// **'INFINITE LIVES'**
  String get prefInfiniteLivesTitle;

  /// No description provided for @prefInfiniteLivesDesc.
  ///
  /// In en, this message translates to:
  /// **'Play without losing hearts on blocked moves'**
  String get prefInfiniteLivesDesc;

  /// No description provided for @prefTapAssistTitle.
  ///
  /// In en, this message translates to:
  /// **'TAP ASSIST'**
  String get prefTapAssistTitle;

  /// No description provided for @prefTapAssistDesc.
  ///
  /// In en, this message translates to:
  /// **'Count taps on empty tiles near arrows as clicks'**
  String get prefTapAssistDesc;

  /// No description provided for @unlockThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Theme & Skins'**
  String get unlockThemeTitle;

  /// No description provided for @unlockThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock all custom themes and premium styling options.'**
  String get unlockThemeDesc;

  /// No description provided for @getUnlockCode.
  ///
  /// In en, this message translates to:
  /// **'Get Unlock Code'**
  String get getUnlockCode;

  /// No description provided for @enterUnlockCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter unlock code'**
  String get enterUnlockCodeHint;

  /// No description provided for @unlockSuccess.
  ///
  /// In en, this message translates to:
  /// **'All themes and skins unlocked!'**
  String get unlockSuccess;

  /// No description provided for @unlockErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid unlock code'**
  String get unlockErrorInvalid;

  /// No description provided for @unlockNow.
  ///
  /// In en, this message translates to:
  /// **'Unlock Now'**
  String get unlockNow;

  /// No description provided for @howToPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get howToPlayTitle;

  /// No description provided for @sectionTheBasics.
  ///
  /// In en, this message translates to:
  /// **'THE BASICS'**
  String get sectionTheBasics;

  /// No description provided for @guideCoreObjectiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Core Objective'**
  String get guideCoreObjectiveTitle;

  /// No description provided for @guideCoreObjectiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Your goal is to clear the entire puzzle grid by guiding every arrow off the board. When no arrows remain on the board, the level is complete.'**
  String get guideCoreObjectiveDesc;

  /// No description provided for @guideMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrow Movement'**
  String get guideMovementTitle;

  /// No description provided for @guideMovementDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap any arrow to launch it. Arrows slide forward in the exact direction their arrowhead points: Up, Down, Left, or Right. Even if an arrow has a bent or winding body, it always exits following its tip.'**
  String get guideMovementDesc;

  /// No description provided for @guideObstaclesTitle.
  ///
  /// In en, this message translates to:
  /// **'Obstacles & Collisions'**
  String get guideObstaclesTitle;

  /// No description provided for @guideObstaclesDesc.
  ///
  /// In en, this message translates to:
  /// **'An arrow can only escape if its entire exit path is completely clear. If another arrow stands in the way, the tapped arrow will shake and stay in place.'**
  String get guideObstaclesDesc;

  /// No description provided for @guideLivesTitle.
  ///
  /// In en, this message translates to:
  /// **'Lives & Health'**
  String get guideLivesTitle;

  /// No description provided for @guideLivesDesc.
  ///
  /// In en, this message translates to:
  /// **'In Classic mode, you start with 3 hearts. Tapping a blocked arrow costs 1 heart. If you deplete all 3 hearts, you must restart the level. You can toggle Infinite Lives in Settings anytime.'**
  String get guideLivesDesc;

  /// No description provided for @sectionBoardElements.
  ///
  /// In en, this message translates to:
  /// **'BOARD ELEMENTS'**
  String get sectionBoardElements;

  /// No description provided for @guideTurnDotsTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn Dots (Redirectors)'**
  String get guideTurnDotsTitle;

  /// No description provided for @guideTurnDotsDesc.
  ///
  /// In en, this message translates to:
  /// **'Look for circular dots on empty grid cells marked with small arrows. When a sliding arrow crosses a Turn Dot, it instantly pivots in the dot\'s direction and consumes it, opening unexpected exit routes.'**
  String get guideTurnDotsDesc;

  /// No description provided for @guideCombosTitle.
  ///
  /// In en, this message translates to:
  /// **'Combos & Streaks'**
  String get guideCombosTitle;

  /// No description provided for @guideCombosDesc.
  ///
  /// In en, this message translates to:
  /// **'Release arrows in quick succession (within 1.5 seconds) to trigger combos. Chaining consecutive escapes builds momentum and scores combo multipliers.'**
  String get guideCombosDesc;

  /// No description provided for @sectionGameModes.
  ///
  /// In en, this message translates to:
  /// **'GAME MODES'**
  String get sectionGameModes;

  /// No description provided for @guideClassicModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Classic Mode'**
  String get guideClassicModeTitle;

  /// No description provided for @guideClassicModeDesc.
  ///
  /// In en, this message translates to:
  /// **'The standard campaign progression. Advance through handcrafted and procedural stages of escalating size, shape masks, and path complexity with 3 hearts.'**
  String get guideClassicModeDesc;

  /// No description provided for @guideZenModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Zen Mode'**
  String get guideZenModeTitle;

  /// No description provided for @guideZenModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Pure relaxation with zero stress. No hearts to lose, no time limits, and no failure states. Ideal for unwinding and practicing complex boards.'**
  String get guideZenModeDesc;

  /// No description provided for @guideTimeAttackTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Attack'**
  String get guideTimeAttackTitle;

  /// No description provided for @guideTimeAttackDesc.
  ///
  /// In en, this message translates to:
  /// **'Fast-paced race against the clock! Every arrow you successfully escape awards precious bonus seconds back onto your countdown timer.'**
  String get guideTimeAttackDesc;

  /// No description provided for @guideMultiplayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Multiplayer Rooms'**
  String get guideMultiplayerTitle;

  /// No description provided for @guideMultiplayerDesc.
  ///
  /// In en, this message translates to:
  /// **'Host or join with room seed codes. Both players compete on the exact same randomized layout to see who can solve and escape the board fastest.'**
  String get guideMultiplayerDesc;

  /// No description provided for @guideRandomPuzzlesTitle.
  ///
  /// In en, this message translates to:
  /// **'Random Puzzles'**
  String get guideRandomPuzzlesTitle;

  /// No description provided for @guideRandomPuzzlesDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate infinite on-demand puzzles across Easy, Medium, Hard, Master, and Expert difficulties without affecting your campaign level progress.'**
  String get guideRandomPuzzlesDesc;

  /// No description provided for @sectionProStrategies.
  ///
  /// In en, this message translates to:
  /// **'PRO STRATEGIES'**
  String get sectionProStrategies;

  /// No description provided for @guideUnpeelTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpeel From the Perimeter'**
  String get guideUnpeelTitle;

  /// No description provided for @guideUnpeelDesc.
  ///
  /// In en, this message translates to:
  /// **'Start by scanning the outer borders. Arrows pointing straight outward into empty space can always escape immediately, freeing up critical lanes.'**
  String get guideUnpeelDesc;

  /// No description provided for @guideTraceBlockersTitle.
  ///
  /// In en, this message translates to:
  /// **'Trace Blockers in Reverse'**
  String get guideTraceBlockersTitle;

  /// No description provided for @guideTraceBlockersDesc.
  ///
  /// In en, this message translates to:
  /// **'When an arrow is blocked, find which arrow blocks it, then find what blocks that second arrow. Unlocking the final blocker in the chain frees everything behind it.'**
  String get guideTraceBlockersDesc;

  /// No description provided for @guideEnableTapAssistTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Tap Assist'**
  String get guideEnableTapAssistTitle;

  /// No description provided for @guideEnableTapAssistDesc.
  ///
  /// In en, this message translates to:
  /// **'If you play on smaller screens or tend to tap between tight arrow segments, turn on Tap Assist in Settings to automatically map nearby taps to the nearest arrow.'**
  String get guideEnableTapAssistDesc;

  /// No description provided for @leaveLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Level?'**
  String get leaveLevelTitle;

  /// No description provided for @leaveLevelDesc.
  ///
  /// In en, this message translates to:
  /// **'Your current level progress will be lost.'**
  String get leaveLevelDesc;

  /// No description provided for @dialogResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get dialogResume;

  /// No description provided for @dialogLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get dialogLeave;

  /// No description provided for @comboBanner.
  ///
  /// In en, this message translates to:
  /// **'{combo} x COMBO'**
  String comboBanner(int combo);

  /// No description provided for @bonusTimeBanner.
  ///
  /// In en, this message translates to:
  /// **'+15s'**
  String get bonusTimeBanner;

  /// No description provided for @scoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String scoreTitle(int score);

  /// No description provided for @randomModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Random Mode'**
  String get randomModeTitle;

  /// No description provided for @levelNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelNumberTitle(int level);

  /// No description provided for @levelCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Level Complete!'**
  String get levelCompleteTitle;

  /// No description provided for @gameFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'You Finished the Game!'**
  String get gameFinishedTitle;

  /// No description provided for @gameFinishedDesc.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve solved all 500 challenges. Stay tuned for more levels coming soon!'**
  String get gameFinishedDesc;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get nextLevel;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @buyMeACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy me a coffee'**
  String get buyMeACoffee;

  /// No description provided for @timesUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up!'**
  String get timesUp;

  /// No description provided for @outOfTime.
  ///
  /// In en, this message translates to:
  /// **'Out of Time!'**
  String get outOfTime;

  /// No description provided for @outOfLives.
  ///
  /// In en, this message translates to:
  /// **'Out of Lives!'**
  String get outOfLives;

  /// No description provided for @timeAttackStats.
  ///
  /// In en, this message translates to:
  /// **'Puzzles Cleared: {score}\nFinal Level: {level}'**
  String timeAttackStats(int score, int level);

  /// No description provided for @startNewRun.
  ///
  /// In en, this message translates to:
  /// **'Start New Run'**
  String get startNewRun;

  /// No description provided for @restartLevel.
  ///
  /// In en, this message translates to:
  /// **'Restart Level'**
  String get restartLevel;

  /// No description provided for @loadingLevel.
  ///
  /// In en, this message translates to:
  /// **'LOADING LEVEL...'**
  String get loadingLevel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
