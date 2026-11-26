// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Arrow Escape';

  @override
  String get appTagline => 'Verschieben. Lösen. Entkommen.';

  @override
  String levelHeader(int level) {
    return 'LEVEL $level';
  }

  @override
  String get menuPlay => 'SPIELEN';

  @override
  String get menuLevels => 'LEVELS';

  @override
  String get menuGameModes => 'SPIELMODI';

  @override
  String get menuRandom => 'ZUFALL';

  @override
  String get menuHowToPlay => 'SPIELANLEITUNG';

  @override
  String get menuSettings => 'EINSTELLUNGEN';

  @override
  String get randomPuzzleTitle => 'Zufälliges Rätsel';

  @override
  String get randomPuzzleSubtitle => 'Schwierigkeitsgrad wählen';

  @override
  String get difficultyEasy => 'Einfach';

  @override
  String get difficultyMedium => 'Mittel';

  @override
  String get difficultyHard => 'Schwer';

  @override
  String get difficultyMaster => 'Meister';

  @override
  String get difficultyExpert => 'Experte';

  @override
  String get dialogCancel => 'Abbrechen';

  @override
  String get modesTitle => 'MODI';

  @override
  String get modeLevelsTitle => 'LEVELS';

  @override
  String get modeLevelsDesc =>
      'Wähle ein bereits freigeschaltetes Level aus und spiele es erneut.';

  @override
  String get modeRandomTitle => 'ZUFALL';

  @override
  String get modeRandomDesc =>
      'Generiere benutzerdefinierte Rätsel in 5 Schwierigkeitsstufen.';

  @override
  String get modeZenTitle => 'ZEN';

  @override
  String get modeZenDesc =>
      'Keine Leben, keine Timer. Einfach nur entspanntes Rätsellösen.';

  @override
  String get modeTimeAttackTitle => 'ZEITRENNEN';

  @override
  String get modeTimeAttackDesc =>
      'Wetteifere gegen die Zeit! Befreie Pfeile, um Bonuszeit zu erhalten.';

  @override
  String get modeMultiplayerTitle => 'MEHRSPIELER';

  @override
  String get modeMultiplayerDesc =>
      'Tritt mit Freunden auf exakt demselben Rätsel-Spielfeld an.';

  @override
  String get levelsTitle => 'Levels';

  @override
  String get multiplayerTitle => 'MEHRSPIELER';

  @override
  String get hostRoomTitle => 'RAUM ERSTELLEN';

  @override
  String get hostRoomDesc =>
      'Teile diesen Raumcode mit einem Freund, um auf exakt demselben Rätsel-Spielfeld anzutreten!';

  @override
  String get tooltipNewCode => 'Neuer Code';

  @override
  String get tooltipCopyCode => 'Code kopieren';

  @override
  String roomCodeCopied(String code) {
    return 'Raumcode $code in die Zwischenablage kopiert!';
  }

  @override
  String get startMatch => 'SPIEL STARTEN';

  @override
  String get joinRoomTitle => 'RAUM BEITRETEN';

  @override
  String get joinRoomDesc =>
      'Gib einen Raumcode ein oder füge ihn ein, um dem Spiel beizutreten.';

  @override
  String get joinRoomHint => 'z. B. ROOM-849201';

  @override
  String get joinRoomErrorEmpty => 'Bitte gib einen Raumcode ein';

  @override
  String get joinMatch => 'SPIEL BEITRETEN';

  @override
  String get settingsTitle => 'EINSTELLUNGEN';

  @override
  String get themeSectionTitle => 'DESIGN & BENUTZERDEFINIERTER SKIN';

  @override
  String get preferencesSectionTitle => 'EINSTELLUNGEN';

  @override
  String get prefHapticsTitle => 'HAPTISCHES FEEDBACK';

  @override
  String get prefHapticsDesc =>
      'Vibration bei Pfeiltipps, Zügen und Kollisionen';

  @override
  String get prefInfiniteLivesTitle => 'UNENDLICHE LEBEN';

  @override
  String get prefInfiniteLivesDesc =>
      'Spielen ohne Herzverlust bei ungültigen Zügen';

  @override
  String get prefTapAssistTitle => 'TIPP-UNTERSTÜTZUNG';

  @override
  String get prefTapAssistDesc =>
      'Tippen auf leere Felder nahe Pfeilen als Klicks werten';

  @override
  String get unlockThemeTitle => 'Designs & Skins freischalten';

  @override
  String get unlockThemeDesc =>
      'Schalte alle benutzerdefinierten Designs und Premium-Stile frei.';

  @override
  String get getUnlockCode => 'Freischaltcode anfordern';

  @override
  String get enterUnlockCodeHint => 'Freischaltcode eingeben';

  @override
  String get unlockSuccess => 'Alle Designs und Skins freigeschaltet!';

  @override
  String get unlockErrorInvalid => 'Ungültiger Freischaltcode';

  @override
  String get unlockNow => 'Jetzt freischalten';

  @override
  String get howToPlayTitle => 'SPIELANLEITUNG';

  @override
  String get sectionTheBasics => 'DIE GRUNDLAGEN';

  @override
  String get guideCoreObjectiveTitle => 'Hauptziel';

  @override
  String get guideCoreObjectiveDesc =>
      'Dein Ziel ist es, das gesamte Spielfeld zu räumen, indem du jeden Pfeil vom Brett lenkst. Wenn sich keine Pfeile mehr auf dem Brett befinden, ist das Level abgeschlossen.';

  @override
  String get guideMovementTitle => 'Pfeilbewegung';

  @override
  String get guideMovementDesc =>
      'Tippe auf einen beliebigen Pfeil, um ihn zu starten. Pfeile gleiten exakt in die Richtung vorwärts, in die ihre Spitze zeigt: Oben, Unten, Links oder Rechts. Selbst wenn ein Pfeil einen gebogenen oder gewundenen Körper hat, verlässt er das Feld immer in Richtung seiner Spitze.';

  @override
  String get guideObstaclesTitle => 'Hindernisse & Kollisionen';

  @override
  String get guideObstaclesDesc =>
      'Ein Pfeil kann nur entkommen, wenn sein kompletter Austrittspfad völlig frei ist. Steht ein anderer Pfeil im Weg, wackelt der angetippte Pfeil und bleibt an Ort und Stelle.';

  @override
  String get guideLivesTitle => 'Leben & Gesundheit';

  @override
  String get guideLivesDesc =>
      'Im Klassik-Modus startest du mit 3 Herzen. Das Antippen eines blockierten Pfeils kostet 1 Herz. Wenn alle 3 Herzen aufgebraucht sind, musst du das Level neu starten. Du kannst unendliche Leben jederzeit in den Einstellungen aktivieren.';

  @override
  String get sectionBoardElements => 'SPIELBRETT-ELEMENTE';

  @override
  String get guideTurnDotsTitle => 'Drehpunkte (Umlenker)';

  @override
  String get guideTurnDotsDesc =>
      'Halte Ausschau nach kreisrundem Punkten auf leeren Feldern, die mit kleinen Pfeilen markiert sind. Wenn ein gleitender Pfeil einen Drehpunkt kreuzt, schwenkt er sofort in die Richtung des Punktes, verschlingt diesen und eröffnet so unerwartete Fluchtwege.';

  @override
  String get guideCombosTitle => 'Kombos & Serien';

  @override
  String get guideCombosDesc =>
      'Löse Pfeile in schneller Folge (innerhalb von 1,5 Sekunden) aus, um Kombos auszulösen. Das Aneinanderreihen aufeinanderfolgender Manöver erzeugt Schwung und bringt Kombo-Multiplikatoren.';

  @override
  String get sectionGameModes => 'SPIELMODI';

  @override
  String get guideClassicModeTitle => 'Klassik-Modus';

  @override
  String get guideClassicModeDesc =>
      'Der klassische Kampagnenfortschritt. Spiele dich durch handgemachte und prozedurale Level mit steigender Größe, Formmasken und Pfadkomplexität – mit 3 Herzen.';

  @override
  String get guideZenModeTitle => 'Zen-Modus';

  @override
  String get guideZenModeDesc =>
      'Purer Genuss ohne Stress. Keine Herzen verlieren, kein Zeitlimit und keine Niederlagen. Ideal zum Abschalten und Üben komplexer Spielfelder.';

  @override
  String get guideTimeAttackTitle => 'Zeitrennen';

  @override
  String get guideTimeAttackDesc =>
      'Rasanter Wettlauf gegen die Zeit! Jeder erfolgreich befreite Pfeil bringt dir wertvolle Bonussekunden für deinen Countdown zurück.';

  @override
  String get guideMultiplayerTitle => 'Mehrspieler-Räume';

  @override
  String get guideMultiplayerDesc =>
      'Erstelle oder trete über Raumcodes bei. Beide Spieler treten auf exakt demselben zufälligen Spielfeld an, um zu sehen, wer das Brett am schnellsten löst.';

  @override
  String get guideRandomPuzzlesTitle => 'Zufällige Rätsel';

  @override
  String get guideRandomPuzzlesDesc =>
      'Generiere unendlich viele Rätsel auf Abruf in den Schwierigkeiten Einfach, Mittel, Schwer, Meister und Experte, ohne deinen Kampagnenfortschritt zu beeinflussen.';

  @override
  String get sectionProStrategies => 'PROFI-STRATEGIEN';

  @override
  String get guideUnpeelTitle => 'Von außen nach innen abtragen';

  @override
  String get guideUnpeelDesc =>
      'Beginne damit, die Ränder abzusuchen. Pfeile, die direkt nach außen in den leeren Raum zeigen, können immer sofort entkommen und schaffen wichtige Spuren frei.';

  @override
  String get guideTraceBlockersTitle => 'Blockierer rückwärts verfolgen';

  @override
  String get guideTraceBlockersDesc =>
      'Wenn ein Pfeil blockiert ist, ermittle, welcher Pfeil ihn blockiert, und dann, was wiederum diesen zweiten Pfeil blockiert. Das Entfernen des letzten Pfeil in der Kette befreit alles dahinter.';

  @override
  String get guideEnableTapAssistTitle => 'Tipp-Unterstützung aktivieren';

  @override
  String get guideEnableTapAssistDesc =>
      'Wenn du auf kleineren Bildschirmen spielst oder dazu neigst, zwischen engen Pfeilsegmenten zu tippen, aktiviere die Tipp-Unterstützung in den Einstellungen, um Berührungen automatisch dem nächstgelegenen Pfeil zuzuordnen.';

  @override
  String get leaveLevelTitle => 'Level verlassen?';

  @override
  String get leaveLevelDesc => 'Dein aktueller Levelfortschritt geht verloren.';

  @override
  String get dialogResume => 'Fortsetzen';

  @override
  String get dialogLeave => 'Verlassen';

  @override
  String comboBanner(int combo) {
    return '$combo x KOMBO';
  }

  @override
  String get bonusTimeBanner => '+15s';

  @override
  String scoreTitle(int score) {
    return 'Punktzahl: $score';
  }

  @override
  String get randomModeTitle => 'Zufallsmodus';

  @override
  String levelNumberTitle(int level) {
    return 'Level $level';
  }

  @override
  String get levelCompleteTitle => 'Level geschafft!';

  @override
  String get gameFinishedTitle => 'Du hast das Spiel durchgespielt!';

  @override
  String get gameFinishedDesc =>
      'Herzlichen Glückwunsch! Du hast alle 500 Herausforderungen gelöst. Freue dich auf bald kommende Level!';

  @override
  String get nextLevel => 'Nächstes Level';

  @override
  String get home => 'Hauptmenü';

  @override
  String get buyMeACoffee => 'Spendiere mir einen Kaffee';

  @override
  String get timesUp => 'Die Zeit ist um!';

  @override
  String get outOfTime => 'Zeit abgelaufen!';

  @override
  String get outOfLives => 'Keine Leben mehr!';

  @override
  String timeAttackStats(int score, int level) {
    return 'Gelöste Rätsel: $score\nLetztes Level: $level';
  }

  @override
  String get startNewRun => 'Neuen Spieldurchlauf starten';

  @override
  String get restartLevel => 'Level neu starten';

  @override
  String get loadingLevel => 'LEVEL WIRD GELADEN...';
}
