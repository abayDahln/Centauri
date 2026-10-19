// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Centauri — Canvas UI/UX par IA';

  @override
  String get languageTooltip => 'Langue';

  @override
  String get languageDialogTitle => 'Langue';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonActive => 'Actif';

  @override
  String get commonSetActive => 'Activer';

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
      'Toutes les données sont stockées et chiffrées sur votre appareil.';

  @override
  String get providerListLoadFailed => 'Impossible de charger les Provider.';

  @override
  String get providerListEmptyTitle => 'Aucun Provider pour l\'instant';

  @override
  String get providerListEmptyBody =>
      'Ajoutez un Provider pour commencer avec Centauri.';

  @override
  String get providerListAddProvider => 'Ajouter un Provider';

  @override
  String get providerDeleted => 'Provider supprimé';

  @override
  String get providerDetailPickProvider => 'Choisissez d\'abord un Provider.';

  @override
  String get providerDetailPickModel => 'Choisissez d\'abord un Model.';

  @override
  String providerDetailSaveFailed(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'Impossible de supprimer l\'API Key : $error';
  }

  @override
  String get providerDetailUpdated => 'Provider mis à jour';

  @override
  String get providerDetailAdded => 'Provider ajouté';

  @override
  String get providerDetailTestOk => 'La connexion fonctionne.';

  @override
  String get providerDetailTitleEdit => 'Modifier le Provider';

  @override
  String get providerDetailTitleNew => 'Ajouter un Provider';

  @override
  String get providerDetailDeleteTooltip => 'Supprimer le Provider';

  @override
  String get providerDetailFieldName => 'Nom';

  @override
  String get providerDetailNameHint => 'ex. « OpenAI Pro »';

  @override
  String get providerDetailNameRequired => 'Le nom est requis.';

  @override
  String get providerDetailPickProviderLabel => 'Choisir un Provider';

  @override
  String get providerDetailFieldProviderName => 'Nom du Provider';

  @override
  String get providerDetailProviderNameHint => 'ex. « OpenAI »';

  @override
  String get providerDetailProviderNameRequired =>
      'Le nom du Provider est requis.';

  @override
  String get providerDetailPickModelLabel => 'Choisir un Model';

  @override
  String get providerDetailPickProviderFirst =>
      'Choisissez d\'abord un Provider';

  @override
  String get providerDetailTestAction => 'Tester';

  @override
  String get providerDetailBaseUrlRequired => 'Le Base URL est requis.';

  @override
  String get providerDetailBaseUrlInvalid =>
      'Saisissez une URL valide (exemple : https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'Depuis le Provider';

  @override
  String get providerDetailApiKeyStored =>
      'API Key enregistrée. Réinitialisez pour la remplacer.';

  @override
  String get providerDetailApiKeyCleared =>
      'L\'API Key sera supprimée à l\'enregistrement.';

  @override
  String get providerDetailApiKeyOptional =>
      'Laissez vide pour un service local sans authentification.';

  @override
  String get providerDetailReset => 'Réinitialiser';

  @override
  String get providerDeleteTargetFallback => 'ce Provider';

  @override
  String get providerDeleteTitle => 'Supprimer ce Provider ?';

  @override
  String providerDeleteBody(String target) {
    return '$target et ses données enregistrées seront supprimés définitivement.';
  }

  @override
  String get modelCardDeleteTooltip => 'Supprimer le Model';

  @override
  String get modelCardCopyIdTooltip => 'Copier l\'ID du Model';

  @override
  String modelCardCopied(String model) {
    return 'Copié : $model';
  }

  @override
  String get modelPickerTitle => 'Choisir un Model';

  @override
  String get modelPickerCustom => 'Model personnalisé';

  @override
  String get modelPickerAddModel => 'Ajouter un Model';

  @override
  String get modelPickerIdHint => 'ex. « gpt-4o »';

  @override
  String get providerPickerTitle => 'Choisir un Provider';

  @override
  String get commonAllPages => 'Toutes les pages';

  @override
  String get canvasUntitledProject => 'Nouveau prototype';

  @override
  String get canvasHideHistory => 'Masquer l\'historique';

  @override
  String get canvasShowHistory => 'Afficher l\'historique';

  @override
  String get canvasHidePreview => 'Masquer l\'aperçu';

  @override
  String get canvasShowPreview => 'Afficher l\'aperçu';

  @override
  String get canvasUndoTooltip => 'Annuler (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'Rétablir (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écrans',
      one: '1 écran',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'Design';

  @override
  String get canvasModeCode => 'Code';

  @override
  String get canvasServiceSettings => 'Réglages du service';

  @override
  String get canvasSelectionOff => 'Désactiver la sélection';

  @override
  String get canvasSelectionOn => 'Sélectionnez un élément sur le canvas';

  @override
  String get canvasBreadcrumbFallback => 'canvas';

  @override
  String get canvasStopGenerating => 'Arrêter la génération';

  @override
  String get canvasStopAction => 'Arrêter';

  @override
  String get canvasEmptyTitle => 'Pas encore d\'UI';

  @override
  String get canvasEmptyBody => 'Écrivez un message pour commencer.';

  @override
  String get canvasPrototypeTitle => 'Prototype';

  @override
  String get canvasChatPanelTooltip => 'Panneau chat et historique';

  @override
  String get storageFailedTitle => 'Impossible d\'ouvrir le stockage local. ';

  @override
  String get storageFailedBody =>
      'Fermez l\'autre fenêtre Centauri et réessayez.';

  @override
  String get previewGenericError => 'Une erreur est survenue dans l\'aperçu.';

  @override
  String previewLinkInvalid(String href) {
    return 'Lien invalide : $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'Impossible d\'ouvrir : $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'Page introuvable : $href';
  }

  @override
  String get previewDeleteFailed =>
      'Impossible de supprimer le composant. Réessayez.';

  @override
  String get previewLoading => 'Chargement…';

  @override
  String get previewNoPagesTitle => 'Aucune page pour l\'instant';

  @override
  String get previewNoPagesBody => 'Écrivez un message pour créer une page.';

  @override
  String get previewLoadFailedTitle => 'Impossible de charger l\'aperçu';

  @override
  String get previewWebView2Hint =>
      'Si l\'erreur persiste, installez Microsoft Edge WebView2 Runtime.';

  @override
  String get exportNoPages => 'Aucune page à exporter pour l\'instant.';

  @override
  String exportSaved(String path) {
    return 'Enregistré : $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Données Figma ($count éléments) copiées.';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Données Figma ($count éléments) enregistrées : $path';
  }

  @override
  String get exportFailed => 'Échec de l\'export. Réessayez.';

  @override
  String get exportPageTooltip => 'Exporter la page';

  @override
  String get exportPageTooltipCompact => 'Exporter la page (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (image)';

  @override
  String get exportSvg => 'SVG (vectoriel)';

  @override
  String get exportPdf => 'PDF (document)';

  @override
  String get exportAction => 'Exporter';

  @override
  String get codePanelCopied => 'HTML copié.';

  @override
  String get codePanelCopyTooltip => 'Copier le HTML';

  @override
  String get codePanelSaveTooltip => 'Enregistrer en .html';

  @override
  String get codePanelEmpty => 'Pas encore de code.\nCréez d\'abord une UI.';

  @override
  String get promptAnalyzeImage => 'Analysez cette image.';

  @override
  String promptUnsupportedFormat(String name) {
    return 'Format non pris en charge : « $name ».';
  }

  @override
  String promptReadFailed(String name) {
    return 'Impossible de lire « $name ».';
  }

  @override
  String get promptPlaceholder => 'Écrivez un message…';

  @override
  String get promptAttachTooltip => 'Joindre un fichier';

  @override
  String get promptStopTooltip => 'Arrêter la génération';

  @override
  String get promptMentionPagesTooltip => 'Mentionner une page';

  @override
  String get attachmentImageFailed => 'Impossible d\'afficher l\'image.';

  @override
  String get attachmentRemoveTooltip => 'Retirer la pièce jointe';

  @override
  String get chatWelcomeTitle => 'Commencez par un message';

  @override
  String get chatWelcomeBody =>
      'Demandez un conseil design ou faites créer l\'interface.';

  @override
  String get chatTabChat => 'Chat';

  @override
  String get chatTabHistory => 'Historique';

  @override
  String get pageRenameTitle => 'Renommer la page';

  @override
  String get pageRenameHint => 'Nom de la page';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(double-clic pour renommer)';
  }

  @override
  String get markdownEmpty => '(vide)';

  @override
  String get windowMinimize => 'Réduire';

  @override
  String get windowMaximize => 'Agrandir';

  @override
  String get windowRestore => 'Restaurer';

  @override
  String get windowClose => 'Fermer';

  @override
  String get historyRenameTitle => 'Renommer';

  @override
  String get historyRenameHint => 'Nom du chat';

  @override
  String get historyNewChat => 'Nouveau chat';

  @override
  String get historySearchHint => 'Rechercher un chat';

  @override
  String get historyRecent => 'Récent';

  @override
  String get historyRenameTooltip => 'Renommer';

  @override
  String get historyEmptySearch => 'Aucun chat correspondant.';

  @override
  String get historyEmptyList => 'Aucun chat enregistré pour l\'instant.';

  @override
  String get codeExportTitle => 'Exporter le code';

  @override
  String codeExportCopied(String format) {
    return 'Code $format copié.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caractères',
      one: '1 caractère',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'Copier';

  @override
  String get codeExportDownload => 'Télécharger';

  @override
  String get codeExportNoticeHtml =>
      'Un seul fichier HTML autonome : CSS et JS intégrés, fonctionne hors ligne.';

  @override
  String get codeExportNoticeReact =>
      'Conversion approximative. Déplacez le contenu de <style> dans un fichier CSS et vérifiez avant usage.';

  @override
  String get codeExportNoticeFlutter =>
      'Conversion approximative. Seuls les styles en ligne sont traduits ; le CSS de <style> est exclu. Vérifiez avant usage.';

  @override
  String get codeExportNoticeTailwind =>
      'Conversion approximative. Nécessite Tailwind v3.2+ ; déplacez le contenu de <style> dans un fichier CSS. Vérifiez avant usage.';

  @override
  String get codeExportTransformErrorTitle => 'Impossible de convertir le code';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Le code Alpha n\'a pas pu être converti en $format.';
  }

  @override
  String get codeExportUseHtml => 'Utiliser HTML';

  @override
  String get codeExportEmptyTitle => 'Aucune UI à exporter pour l\'instant';

  @override
  String get codeExportEmptyBody => 'Créez d\'abord une UI.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP fonctionne uniquement sur Desktop.';

  @override
  String get mcpRunning => 'En cours';

  @override
  String get mcpStopped => 'Arrêté';

  @override
  String get mcpDescription =>
      'Passerelle pour les agents IA (Claude Code, Cursor) afin de voir et modifier les designs en direct.';

  @override
  String get mcpStarting => 'Démarrage…';

  @override
  String get mcpStart => 'Démarrer';

  @override
  String get mcpAutoStartNote =>
      'Le serveur démarre automatiquement à l\'ouverture de l\'app.';

  @override
  String get mcpCopyAddress => 'Copier';

  @override
  String get mcpAddressCopied => 'Adresse copiée.';

  @override
  String get chatProcessing => 'Traitement…';

  @override
  String get chatUiReady => 'UI prête';

  @override
  String get chatViewCode => 'Voir le code';

  @override
  String get chatHideCode => 'Masquer';

  @override
  String get chatNoMessagesTitle => 'Aucune conversation pour l\'instant';

  @override
  String get chatNoMessagesBody => 'Écrivez un message pour commencer.';

  @override
  String get commonGenericError => 'Une erreur est survenue. Réessayez.';

  @override
  String get canvasMentionElementFallback => 'Élément sélectionné';

  @override
  String get canvasNoProvider =>
      'Aucun Provider actif. Ajoutez-en un pour commencer.';

  @override
  String get canvasUntitledPage => 'Sans titre';

  @override
  String get canvasGenerationStopped => 'Génération arrêtée.';

  @override
  String get promptAttachmentLimit => 'Jusqu\'à 6 pièces jointes par message.';

  @override
  String get providerNotFound => 'Provider introuvable.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get catalogSectionFreeTier => 'Offre gratuite';

  @override
  String get catalogSectionApiKey => 'API Key';
}
