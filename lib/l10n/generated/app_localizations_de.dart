// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Centauri — KI-Canvas für UI/UX';

  @override
  String get languageTooltip => 'Sprache';

  @override
  String get languageDialogTitle => 'Sprache';

  @override
  String get commonAdd => 'Hinzufügen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonEdit => 'Bearbeiten';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonUndo => 'Rückgängig';

  @override
  String get commonActive => 'Aktiv';

  @override
  String get commonSetActive => 'Aktivieren';

  @override
  String get commonProvider => 'Provider';

  @override
  String get commonBaseUrl => 'Base URL';

  @override
  String get commonApiKey => 'API Key';

  @override
  String get commonModel => 'Model';

  @override
  String get providerListHeading => 'Bring Your Own Key (BYOK)';

  @override
  String get providerListSubtitle =>
      'Alle Daten werden verschlüsselt auf Ihrem Gerät gespeichert.';

  @override
  String get providerListLoadFailed => 'Provider konnten nicht geladen werden.';

  @override
  String get providerListEmptyTitle => 'Noch keine Provider';

  @override
  String get providerListEmptyBody =>
      'Fügen Sie einen Provider hinzu, um Centauri zu nutzen.';

  @override
  String get providerListAddProvider => 'Provider hinzufügen';

  @override
  String get providerDeleted => 'Provider gelöscht';

  @override
  String get providerDetailPickProvider => 'Wählen Sie zuerst einen Provider.';

  @override
  String get providerDetailPickModel => 'Wählen Sie zuerst ein Model.';

  @override
  String providerDetailSaveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'API Key konnte nicht entfernt werden: $error';
  }

  @override
  String get providerDetailUpdated => 'Provider aktualisiert';

  @override
  String get providerDetailAdded => 'Provider hinzugefügt';

  @override
  String get providerDetailTestOk => 'Verbindung funktioniert.';

  @override
  String get providerDetailTitleEdit => 'Provider bearbeiten';

  @override
  String get providerDetailTitleNew => 'Provider hinzufügen';

  @override
  String get providerDetailDeleteTooltip => 'Provider löschen';

  @override
  String get providerDetailFieldName => 'Name';

  @override
  String get providerDetailNameHint => 'z. B. „OpenAI Pro“';

  @override
  String get providerDetailNameRequired => 'Name ist erforderlich.';

  @override
  String get providerDetailPickProviderLabel => 'Provider wählen';

  @override
  String get providerDetailFieldProviderName => 'Provider-Name';

  @override
  String get providerDetailProviderNameHint => 'z. B. „OpenAI“';

  @override
  String get providerDetailProviderNameRequired =>
      'Provider-Name ist erforderlich.';

  @override
  String get providerDetailPickModelLabel => 'Model wählen';

  @override
  String get providerDetailPickProviderFirst => 'Zuerst Provider wählen';

  @override
  String get providerDetailTestAction => 'Testen';

  @override
  String get providerDetailBaseUrlRequired => 'Base URL ist erforderlich.';

  @override
  String get providerDetailBaseUrlInvalid =>
      'Gültige URL eingeben (Beispiel: https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'Vom Provider';

  @override
  String get providerDetailApiKeyStored =>
      'API Key gespeichert. Zum Ersetzen zurücksetzen.';

  @override
  String get providerDetailApiKeyCleared =>
      'API Key wird beim Speichern entfernt.';

  @override
  String get providerDetailApiKeyOptional =>
      'Für einen lokalen Dienst ohne Anmeldung leer lassen.';

  @override
  String get providerDetailReset => 'Zurücksetzen';

  @override
  String get providerDeleteTargetFallback => 'diesen Provider';

  @override
  String get providerDeleteTitle => 'Diesen Provider löschen?';

  @override
  String providerDeleteBody(String target) {
    return '$target und die gespeicherten Daten werden endgültig gelöscht.';
  }

  @override
  String get modelCardDeleteTooltip => 'Model löschen';

  @override
  String get modelCardCopyIdTooltip => 'Model-ID kopieren';

  @override
  String modelCardCopied(String model) {
    return 'Kopiert: $model';
  }

  @override
  String get modelPickerTitle => 'Model wählen';

  @override
  String get modelPickerCustom => 'Eigenes Model';

  @override
  String get modelPickerAddModel => 'Model hinzufügen';

  @override
  String get modelPickerIdHint => 'z. B. „gpt-4o“';

  @override
  String get providerPickerTitle => 'Provider wählen';

  @override
  String get commonAllPages => 'Alle Seiten';

  @override
  String get canvasUntitledProject => 'Neuer Prototyp';

  @override
  String get canvasHideHistory => 'Verlauf ausblenden';

  @override
  String get canvasShowHistory => 'Verlauf anzeigen';

  @override
  String get canvasHideChat => 'Chat ausblenden';

  @override
  String get canvasShowChat => 'Chat anzeigen';

  @override
  String get canvasHidePreview => 'Vorschau ausblenden';

  @override
  String get canvasShowPreview => 'Vorschau anzeigen';

  @override
  String get canvasUndoTooltip => 'Rückgängig (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'Wiederholen (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Screens',
      one: '1 Screen',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'Design';

  @override
  String get canvasModeCode => 'Code';

  @override
  String get canvasShowCode => 'Code anzeigen';

  @override
  String get canvasHideCode => 'Code ausblenden';

  @override
  String get canvasLayoutDesktop => 'Desktop';

  @override
  String get canvasLayoutMobile => 'Mobil';

  @override
  String get canvasServiceSettings => 'Diensteinstellungen';

  @override
  String get canvasSelectionOff => 'Elementauswahl beenden';

  @override
  String get canvasSelectionOn => 'Element auf der Canvas wählen';

  @override
  String get canvasBreadcrumbFallback => 'Canvas';

  @override
  String get canvasStopGenerating => 'Generierung stoppen';

  @override
  String get canvasStopAction => 'Stoppen';

  @override
  String get canvasEmptyTitle => 'Noch keine UI';

  @override
  String get canvasEmptyBody => 'Nachricht eingeben, um zu starten.';

  @override
  String get canvasPrototypeTitle => 'Prototyp';

  @override
  String get canvasChatPanelTooltip => 'Chat- und Verlaufsbereich';

  @override
  String get storageFailedTitle =>
      'Lokaler Speicher konnte nicht geöffnet werden. ';

  @override
  String get storageFailedBody =>
      'Schließen Sie das andere Centauri-Fenster und versuchen Sie es erneut.';

  @override
  String get previewGenericError =>
      'In der Vorschau ist ein Fehler aufgetreten.';

  @override
  String previewLinkInvalid(String href) {
    return 'Ungültiger Link: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'Konnte nicht geöffnet werden: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'Seite nicht gefunden: $href';
  }

  @override
  String get previewDeleteFailed =>
      'Komponente konnte nicht gelöscht werden. Erneut versuchen.';

  @override
  String get previewEditText => 'Text bearbeiten';

  @override
  String get previewEditWithAi => 'Mit KI bearbeiten';

  @override
  String get previewTextEditFailed =>
      'Text konnte nicht gespeichert werden. Erneut versuchen.';

  @override
  String get previewComponentDeleted => 'Komponente gelöscht';

  @override
  String get previewLoading => 'Wird geladen…';

  @override
  String get previewNoPagesTitle => 'Noch keine Seiten';

  @override
  String get previewNoPagesBody =>
      'Nachricht eingeben, um eine Seite zu erstellen.';

  @override
  String get previewLoadFailedTitle => 'Vorschau konnte nicht geladen werden';

  @override
  String get previewWebView2Hint =>
      'Wenn es weiter fehlschlägt, installieren Sie die Microsoft Edge WebView2 Runtime.';

  @override
  String get exportNoPages => 'Noch keine Seiten zum Exportieren.';

  @override
  String exportSaved(String path) {
    return 'Gespeichert: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Figma-Daten ($count Elemente) kopiert.';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Figma-Daten ($count Elemente) gespeichert: $path';
  }

  @override
  String get exportFailed => 'Export fehlgeschlagen. Erneut versuchen.';

  @override
  String get exportPageTooltip => 'Seite exportieren';

  @override
  String get exportPageTooltipCompact =>
      'Seite exportieren (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (Bild)';

  @override
  String get exportSvg => 'SVG (Vektor)';

  @override
  String get exportPdf => 'PDF (Dokument)';

  @override
  String get exportAction => 'Exportieren';

  @override
  String get codePanelCopied => 'HTML kopiert.';

  @override
  String get codePanelCopyTooltip => 'HTML kopieren';

  @override
  String get codePanelSaveTooltip => 'Als .html speichern';

  @override
  String get codePanelEmpty => 'Noch kein Code.\nErstellen Sie zuerst eine UI.';

  @override
  String get promptAnalyzeImage => 'Dieses Bild analysieren.';

  @override
  String promptUnsupportedFormat(String name) {
    return 'Format „$name“ wird nicht unterstützt.';
  }

  @override
  String promptReadFailed(String name) {
    return '„$name“ konnte nicht gelesen werden.';
  }

  @override
  String get promptPlaceholder => 'Nachricht eingeben…';

  @override
  String get promptAttachTooltip => 'Datei anhängen';

  @override
  String get promptStopTooltip => 'Generierung stoppen';

  @override
  String get promptMentionPagesTooltip => 'Seite erwähnen';

  @override
  String get attachmentImageFailed => 'Bild konnte nicht angezeigt werden.';

  @override
  String get attachmentRemoveTooltip => 'Anhang entfernen';

  @override
  String get chatWelcomeTitle => 'Mit einer Nachricht starten';

  @override
  String get chatWelcomeBody =>
      'Fragen Sie nach Design-Tipps oder lassen Sie direkt etwas bauen.';

  @override
  String get chatTabChat => 'Chat';

  @override
  String get chatTabHistory => 'Verlauf';

  @override
  String get pageRenameTitle => 'Seite umbenennen';

  @override
  String get pageRenameHint => 'Seitenname';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(Doppelklick zum Umbenennen)';
  }

  @override
  String get markdownEmpty => '(leer)';

  @override
  String get windowMinimize => 'Minimieren';

  @override
  String get windowMaximize => 'Maximieren';

  @override
  String get windowRestore => 'Wiederherstellen';

  @override
  String get windowClose => 'Schließen';

  @override
  String get historyRenameTitle => 'Umbenennen';

  @override
  String get historyRenameHint => 'Chat-Name';

  @override
  String get historyNewChat => 'Neuer Chat';

  @override
  String get historySearchHint => 'Chats durchsuchen';

  @override
  String get historyRecent => 'Zuletzt';

  @override
  String get historyRenameTooltip => 'Umbenennen';

  @override
  String get historyEmptySearch => 'Keine passenden Chats.';

  @override
  String get historyEmptyList => 'Noch keine gespeicherten Chats.';

  @override
  String get codeExportTitle => 'Code exportieren';

  @override
  String codeExportCopied(String format) {
    return '$format-Code kopiert.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeichen',
      one: '1 Zeichen',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'Kopieren';

  @override
  String get codeExportDownload => 'Herunterladen';

  @override
  String get codeExportNoticeHtml =>
      'Eine eigenständige HTML-Datei: CSS und JS enthalten, funktioniert offline.';

  @override
  String get codeExportNoticeReact =>
      'Ungefähre Umwandlung. <style>-Inhalt in eine CSS-Datei verschieben und vor der Nutzung prüfen.';

  @override
  String get codeExportNoticeFlutter =>
      'Ungefähre Umwandlung. Nur Inline-Styles werden übernommen; CSS aus <style> fehlt. Vor der Nutzung prüfen.';

  @override
  String get codeExportNoticeTailwind =>
      'Ungefähre Umwandlung. Tailwind v3.2+ nötig; <style>-Inhalt in eine CSS-Datei verschieben. Vor der Nutzung prüfen.';

  @override
  String get codeExportTransformErrorTitle => 'Code-Umwandlung fehlgeschlagen';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Alpha-Code konnte nicht in $format umgewandelt werden.';
  }

  @override
  String get codeExportUseHtml => 'HTML verwenden';

  @override
  String get codeExportEmptyTitle => 'Noch keine UI zum Exportieren';

  @override
  String get codeExportEmptyBody => 'Erstellen Sie zuerst eine UI.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP läuft nur auf dem Desktop.';

  @override
  String get mcpRunning => 'Läuft';

  @override
  String get mcpStopped => 'Gestoppt';

  @override
  String get mcpDescription =>
      'Schnittstelle für KI-Agenten (Claude Code, Cursor) zum Live-Ansehen und Bearbeiten von Designs.';

  @override
  String get mcpStarting => 'Startet…';

  @override
  String get mcpStart => 'Starten';

  @override
  String get mcpAutoStartNote =>
      'Der Server startet automatisch beim Öffnen der App.';

  @override
  String get mcpCopyAddress => 'Kopieren';

  @override
  String get mcpAddressCopied => 'Adresse kopiert.';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get mcpGuideOpen => 'Anleitung';

  @override
  String get mcpGuideTitle => 'MCP-Anleitung';

  @override
  String get mcpGuideSubtitle => 'Verbinde einen KI-Agenten mit dieser App.';

  @override
  String get mcpGuideStepStart => 'Server starten';

  @override
  String get mcpGuideStepStartDesc => 'Läuft, solange die App offen ist.';

  @override
  String get mcpGuideEndpoint => 'Adresse';

  @override
  String get mcpGuideStepConnect => 'Agent verbinden';

  @override
  String get mcpGuideStepConnectDesc => 'Agent wählen, dann Code kopieren.';

  @override
  String mcpGuideWhere(String path) {
    return 'Datei: $path';
  }

  @override
  String get mcpGuideCopy => 'Code kopieren';

  @override
  String get mcpGuideCopied => 'Code kopiert.';

  @override
  String get mcpGuideStepTest => 'Verbindung prüfen';

  @override
  String get mcpGuideStepTestDesc =>
      'Sende diese Anfrage und sieh dir die Liste an.';

  @override
  String get mcpGuideStepTools => 'Was der Agent kann';

  @override
  String get mcpGuideStepToolsDesc =>
      'Sechs Werkzeuge: erst Liste, dann Details.';

  @override
  String get mcpGuideTipTitle => 'Wenn keine Verbindung entsteht';

  @override
  String get mcpGuideTipAppClosed =>
      'App offen lassen; beim Schließen stoppt der Server.';

  @override
  String get mcpGuideTipPort =>
      'Ist 8765 belegt, wechselt die App auf 8766–8774.';

  @override
  String get mcpGuideTipLocal =>
      'Nur lokal. Diesen Port nicht ins Netz freigeben.';

  @override
  String get mcpToolListSessions => 'Listet Unterhaltungen mit Anzahl.';

  @override
  String get mcpToolGetSession => 'Liest eine Unterhaltung und ihre Seiten.';

  @override
  String get mcpToolGetPageHtml =>
      'Gibt das vollständige HTML einer Seite zurück.';

  @override
  String get mcpToolWritePage => 'Erstellt oder ersetzt eine Seite.';

  @override
  String get mcpToolDeletePage => 'Löscht eine Seite.';

  @override
  String get mcpToolPostToChat => 'Schreibt eine Antwort in den Chat.';

  @override
  String get chatProcessing => 'Wird verarbeitet…';

  @override
  String get chatUiReady => 'UI bereit';

  @override
  String get chatViewCode => 'Code ansehen';

  @override
  String get chatHideCode => 'Ausblenden';

  @override
  String get chatNoMessagesTitle => 'Noch keine Unterhaltungen';

  @override
  String get chatNoMessagesBody => 'Nachricht eingeben, um zu starten.';

  @override
  String chatStreamPage(int page) {
    return 'Seite $page wird geschrieben…';
  }

  @override
  String chatStreamPageOf(int page, int total) {
    return 'Seite $page von $total wird geschrieben…';
  }

  @override
  String get chatStreamFinishing => 'Seiten werden vorbereitet…';

  @override
  String get commonGenericError =>
      'Etwas ist schiefgelaufen. Erneut versuchen.';

  @override
  String get canvasMentionElementFallback => 'Ausgewähltes Element';

  @override
  String get canvasNoProvider =>
      'Kein aktiver Provider. Fügen Sie einen hinzu, um zu starten.';

  @override
  String get canvasPagesTrimmed =>
      'Zusätzliche Seiten wurden entfernt, um der gewünschten Anzahl zu entsprechen.';

  @override
  String get canvasUntitledPage => 'Ohne Titel';

  @override
  String get canvasGenerationStopped => 'Generierung gestoppt.';

  @override
  String get promptAttachmentLimit => 'Bis zu 6 Anhänge pro Nachricht.';

  @override
  String get providerNotFound => 'Provider nicht gefunden.';

  @override
  String get errorCancelled => 'Abgebrochen.';

  @override
  String get errorApiTimeout =>
      'Zeitüberschreitung bei der Verbindung. Prüfen Sie die Adresse oder Ihr Netzwerk.';

  @override
  String get errorApiUnreachable =>
      'Verbindung fehlgeschlagen. Prüfen Sie die Adresse.';

  @override
  String get errorApiUnauthorized =>
      'Der Zugriffsschlüssel ist ungültig oder hat keine Berechtigung.';

  @override
  String get errorApiRateLimited =>
      'Der Dienst begrenzt Anfragen. Versuchen Sie es gleich noch einmal.';

  @override
  String get errorApiInsufficientCredits =>
      'Das Guthaben des Kontos ist aufgebraucht. Lade es auf und versuche es erneut.';

  @override
  String get errorApiNotFound =>
      'Adresse oder Model nicht gefunden. Prüfen Sie beides.';

  @override
  String get errorApiRejected => 'Der Dienst hat die Anfrage abgelehnt.';

  @override
  String get errorApiCertificate =>
      'Das Serverzertifikat ist ungültig. Prüfen Sie die Adresse.';

  @override
  String get errorApiSendFailed =>
      'Anfrage konnte nicht gesendet werden. Prüfen Sie Verbindung und Adresse.';

  @override
  String get errorApiBadResponse =>
      'Die Antwort hatte ein unerwartetes Format. Die Adresse sollte auf /v1 enden.';

  @override
  String get errorApiNoChatEndpoint =>
      'Dieser Dienst hat noch keine Chat-Adresse.';

  @override
  String get errorApiModelUnavailable =>
      'Dieses Model ist hier nicht verfügbar. Wählen Sie ein anderes.';

  @override
  String get errorApiConnectionBroken =>
      'Die Verbindung wurde unterbrochen. Versuchen Sie es noch einmal.';

  @override
  String errorApiProviderReported(String detail) {
    return 'Meldung des Dienstes: $detail';
  }

  @override
  String get errorGenerationTimeout =>
      'Generierung gestoppt: Sie hat zu lange gedauert. Versuchen Sie es noch einmal.';

  @override
  String get errorExportNotReady =>
      'Die Seite ist noch nicht bereit. Warten Sie einen Moment.';

  @override
  String get errorExportTimeout =>
      'Zeitüberschreitung beim Export. Versuchen Sie es noch einmal.';

  @override
  String get errorExportNoElements => 'Noch nichts zum Exportieren.';

  @override
  String get errorExportEmptyResult =>
      'Das Ergebnis war leer. Versuchen Sie es noch einmal.';

  @override
  String get errorExportWriteFailed =>
      'Datei konnte nicht gespeichert werden. Wählen Sie einen anderen Ort.';

  @override
  String get errorImportInvalidFile =>
      'Diese Datei ist kein gültiges JSON. Wählen Sie eine Centauri-.mydesign-Datei.';

  @override
  String get errorImportNotProject => 'Das ist keine Centauri-Projektdatei.';

  @override
  String errorImportNewerVersion(String version) {
    return 'Diese Datei braucht eine neuere Centauri-Version ($version). Aktualisieren Sie zuerst die App.';
  }

  @override
  String get errorImportEmpty => 'Diese Projektdatei ist leer.';

  @override
  String errorImportEmptyFile(String name) {
    return 'Die Datei $name ist leer.';
  }

  @override
  String get errorImportUnusable =>
      'Die Datei kann nicht gelesen werden. Wählen Sie eine andere Datei.';

  @override
  String errorImportUnusableFile(String name) {
    return 'Die Datei $name kann nicht gelesen werden. Wählen Sie eine andere Datei.';
  }

  @override
  String get errorAttachmentEmpty => 'Die Datei ist leer.';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'Die Datei $name ist leer.';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'Die Datei ist zu groß (max. $maxMb MB).';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'Dieses Format wird nicht unterstützt. Verwenden Sie $formats.';
  }

  @override
  String get errorStorageFailed =>
      'Der Schlüssel auf diesem Gerät ist nicht verfügbar.';

  @override
  String get errorTransformNoCode => 'Diese Seite hat noch keinen Code.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get exportFigmaPlugin => 'Figma (Plugin)';

  @override
  String exportFigmaCopiedWidth(int width) {
    return 'Kopiert bei $width px. In Figma einfügen.';
  }

  @override
  String get catalogSectionFreeTier => 'Kostenlos';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => 'Darstellung';

  @override
  String get appearanceTitle => 'Darstellung';

  @override
  String get appearanceModeLabel => 'Modus';

  @override
  String get appearanceModeSystem => 'System';

  @override
  String get appearanceModeLight => 'Hell';

  @override
  String get appearanceModeDark => 'Dunkel';

  @override
  String get appearancePrimaryLabel => 'Primärfarbe';

  @override
  String get appearanceReset => 'Zurücksetzen';

  @override
  String get commonDone => 'Fertig';

  @override
  String get colorBlue => 'Blau';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorViolet => 'Violett';

  @override
  String get colorTeal => 'Türkis';

  @override
  String get colorGreen => 'Grün';

  @override
  String get colorAmber => 'Bernstein';

  @override
  String get colorRose => 'Rosé';

  @override
  String get colorSlate => 'Schiefer';

  @override
  String get generationStepPreparing => 'Nachricht wird gelesen';

  @override
  String get generationStepWaiting => 'Warte auf den Dienst';

  @override
  String get generationStepWriting => 'Design wird erstellt';

  @override
  String get generationStepBuilding => 'Seiten werden aufgebaut';

  @override
  String get generationCanvasBuilding => 'Wird aufgebaut…';

  @override
  String generationPageProgress(int index, int total) {
    return 'Seite $index von $total';
  }

  @override
  String generationPageProgressUnknown(int index) {
    return 'Seite $index';
  }

  @override
  String get oauthConnect => 'Verbinden';

  @override
  String get oauthConnecting => 'Verbinden…';

  @override
  String oauthConnectedAs(String account) {
    return 'Angemeldet als $account';
  }

  @override
  String oauthBalance(String amount) {
    return 'Guthaben $amount';
  }

  @override
  String get oauthDisconnect => 'Abmelden';

  @override
  String get oauthLoginRequired => 'Zum Fortfahren zuerst anmelden.';

  @override
  String get providerSubtitleOpencode => 'Kostenlose Coding-Modelle';

  @override
  String get providerSubtitleOpenrouter => 'Viele Modelle, ein Schlüssel';

  @override
  String get providerSubtitleNvidia => 'Kostenloses Entwicklerkonto';

  @override
  String get providerSubtitleOllamaCloud => 'Läuft in der Cloud';

  @override
  String get providerSubtitleGemini => 'Schlüssel aus Google AI Studio';

  @override
  String get providerSubtitleCline => 'Mit Konto anmelden';

  @override
  String get providerSubtitleCommandCode => 'Kostenpflichtiger Plan';

  @override
  String get providerSubtitleGroq => 'Schnelle Antworten';

  @override
  String get providerSubtitleMinimax => 'MiniMax-Modelle';

  @override
  String get providerSubtitleMistral => 'Mistral-Modelle';

  @override
  String get providerSubtitleZai => 'GLM-Modelle';

  @override
  String get providerSubtitleKiro => 'Lokaler Proxy nötig';

  @override
  String get providerSubtitleCustom => 'Eigener Dienst';

  @override
  String get clineLoginTitle => 'Mit Cline-Konto anmelden';

  @override
  String get clineLoginBody =>
      'Melde dich im Browser an. Dieses Fenster aktualisiert sich selbst.';

  @override
  String get clinePasteBody =>
      'Kommt der Browser nicht zurück, füge den angezeigten Link ein.';

  @override
  String get clineFieldLink => 'Anmeldelink';

  @override
  String get clineFieldLinkHint => 'Link aus Cline einfügen';

  @override
  String get clineLinkInvalid =>
      'Der Link passt nicht. Kopiere ihn erneut aus Cline.';

  @override
  String get providerDetailTestAccount => 'Konto testen';

  @override
  String get generationTitle => 'Design wird generiert';
}
