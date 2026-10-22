// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Centauri — AI UI/UX Canvas';

  @override
  String get languageTooltip => 'Language';

  @override
  String get languageDialogTitle => 'Language';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonActive => 'Active';

  @override
  String get commonSetActive => 'Set active';

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
      'All data is stored and encrypted on your device.';

  @override
  String get providerListLoadFailed => 'Couldn\'t load providers.';

  @override
  String get providerListEmptyTitle => 'No providers yet';

  @override
  String get providerListEmptyBody => 'Add a provider to start using Centauri.';

  @override
  String get providerListAddProvider => 'Add provider';

  @override
  String get providerDeleted => 'Provider deleted';

  @override
  String get providerDetailPickProvider => 'Choose a provider first.';

  @override
  String get providerDetailPickModel => 'Choose a model first.';

  @override
  String providerDetailSaveFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'Couldn\'t remove the API key: $error';
  }

  @override
  String get providerDetailUpdated => 'Provider updated';

  @override
  String get providerDetailAdded => 'Provider added';

  @override
  String get providerDetailTestOk => 'Connection works.';

  @override
  String get providerDetailTitleEdit => 'Edit provider';

  @override
  String get providerDetailTitleNew => 'Add provider';

  @override
  String get providerDetailDeleteTooltip => 'Delete provider';

  @override
  String get providerDetailFieldName => 'Name';

  @override
  String get providerDetailNameHint => 'e.g. \"OpenAI Pro\"';

  @override
  String get providerDetailNameRequired => 'Name is required.';

  @override
  String get providerDetailPickProviderLabel => 'Choose a provider';

  @override
  String get providerDetailFieldProviderName => 'Provider name';

  @override
  String get providerDetailProviderNameHint => 'e.g. \"OpenAI\"';

  @override
  String get providerDetailProviderNameRequired => 'Provider name is required.';

  @override
  String get providerDetailPickModelLabel => 'Choose a model';

  @override
  String get providerDetailPickProviderFirst => 'Choose a provider first';

  @override
  String get providerDetailTestAction => 'Test';

  @override
  String get providerDetailBaseUrlRequired => 'Base URL is required.';

  @override
  String get providerDetailBaseUrlInvalid =>
      'Enter a valid URL (example: https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'From the provider';

  @override
  String get providerDetailApiKeyStored =>
      'API key saved. Reset to replace it.';

  @override
  String get providerDetailApiKeyCleared =>
      'API key will be removed when you save.';

  @override
  String get providerDetailApiKeyOptional =>
      'Leave empty for a local service without authentication.';

  @override
  String get providerDetailReset => 'Reset';

  @override
  String get providerDeleteTargetFallback => 'this provider';

  @override
  String get providerDeleteTitle => 'Delete this provider?';

  @override
  String providerDeleteBody(String target) {
    return '$target and its saved data will be deleted permanently.';
  }

  @override
  String get modelCardDeleteTooltip => 'Delete model';

  @override
  String get modelCardCopyIdTooltip => 'Copy model id';

  @override
  String modelCardCopied(String model) {
    return 'Copied: $model';
  }

  @override
  String get modelPickerTitle => 'Choose a model';

  @override
  String get modelPickerCustom => 'Custom model';

  @override
  String get modelPickerAddModel => 'Add model';

  @override
  String get modelPickerIdHint => 'e.g. \"gpt-4o\"';

  @override
  String get providerPickerTitle => 'Choose a provider';

  @override
  String get commonAllPages => 'All pages';

  @override
  String get canvasUntitledProject => 'New prototype';

  @override
  String get canvasHideHistory => 'Hide history';

  @override
  String get canvasShowHistory => 'Show history';

  @override
  String get canvasHideChat => 'Hide chat';

  @override
  String get canvasShowChat => 'Show chat';

  @override
  String get canvasHidePreview => 'Hide preview';

  @override
  String get canvasShowPreview => 'Show preview';

  @override
  String get canvasUndoTooltip => 'Undo (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'Redo (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count screens',
      one: '1 screen',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'Design';

  @override
  String get canvasModeCode => 'Code';

  @override
  String get canvasShowCode => 'Show code';

  @override
  String get canvasHideCode => 'Hide code';

  @override
  String get canvasServiceSettings => 'Service settings';

  @override
  String get canvasSelectionOff => 'Stop selecting elements';

  @override
  String get canvasSelectionOn => 'Select an element on the canvas';

  @override
  String get canvasBreadcrumbFallback => 'canvas';

  @override
  String get canvasStopGenerating => 'Stop generating';

  @override
  String get canvasStopAction => 'Stop';

  @override
  String get canvasEmptyTitle => 'No UI yet';

  @override
  String get canvasEmptyBody => 'Type a message to start.';

  @override
  String get canvasPrototypeTitle => 'Prototype';

  @override
  String get canvasChatPanelTooltip => 'Chat and history panel';

  @override
  String get storageFailedTitle => 'Local storage couldn\'t be opened. ';

  @override
  String get storageFailedBody =>
      'Close the other Centauri window and try again.';

  @override
  String get previewGenericError => 'Something went wrong in the preview.';

  @override
  String previewLinkInvalid(String href) {
    return 'Invalid link: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'Couldn\'t open: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'Page not found: $href';
  }

  @override
  String get previewDeleteFailed =>
      'Couldn\'t delete the component. Try again.';

  @override
  String get previewEditText => 'Edit text';

  @override
  String get previewEditWithAi => 'Edit with AI';

  @override
  String get previewTextEditFailed => 'Couldn\'t save the text. Try again.';

  @override
  String get previewComponentDeleted => 'Component deleted';

  @override
  String get previewLoading => 'Loading.';

  @override
  String get previewNoPagesTitle => 'No pages yet';

  @override
  String get previewNoPagesBody => 'Type a message to create a page.';

  @override
  String get previewLoadFailedTitle => 'Preview failed to load';

  @override
  String get previewWebView2Hint =>
      'If it keeps failing, install the Microsoft Edge WebView2 Runtime.';

  @override
  String get exportNoPages => 'No pages to export yet.';

  @override
  String exportSaved(String path) {
    return 'Saved: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Figma data ($count elements) copied.';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Figma data ($count elements) saved: $path';
  }

  @override
  String get exportFailed => 'Export failed. Try again.';

  @override
  String get exportPageTooltip => 'Export page';

  @override
  String get exportPageTooltipCompact => 'Export page (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (image)';

  @override
  String get exportSvg => 'SVG (vector)';

  @override
  String get exportPdf => 'PDF (document)';

  @override
  String get exportAction => 'Export';

  @override
  String get codePanelCopied => 'HTML copied.';

  @override
  String get codePanelCopyTooltip => 'Copy HTML';

  @override
  String get codePanelSaveTooltip => 'Save as .html';

  @override
  String get codePanelEmpty => 'No code yet.\nCreate a UI first.';

  @override
  String get promptAnalyzeImage => 'Analyze this image.';

  @override
  String promptUnsupportedFormat(String name) {
    return 'Unsupported format: \"$name\".';
  }

  @override
  String promptReadFailed(String name) {
    return 'Couldn\'t read \"$name\".';
  }

  @override
  String get promptPlaceholder => 'Type a message.';

  @override
  String get promptAttachTooltip => 'Attach a file';

  @override
  String get promptStopTooltip => 'Stop generating';

  @override
  String get promptMentionPagesTooltip => 'Mention a page';

  @override
  String get attachmentImageFailed => 'Couldn\'t display the image.';

  @override
  String get attachmentRemoveTooltip => 'Remove attachment';

  @override
  String get chatWelcomeTitle => 'Start with a message';

  @override
  String get chatWelcomeBody =>
      'Ask anything for design advice, or ask for it to be built.';

  @override
  String get chatTabChat => 'Chat';

  @override
  String get chatTabHistory => 'History';

  @override
  String get pageRenameTitle => 'Rename page';

  @override
  String get pageRenameHint => 'Page name';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(double-click to rename)';
  }

  @override
  String get markdownEmpty => '(empty)';

  @override
  String get windowMinimize => 'Minimize';

  @override
  String get windowMaximize => 'Maximize';

  @override
  String get windowRestore => 'Restore';

  @override
  String get windowClose => 'Close';

  @override
  String get historyRenameTitle => 'Rename';

  @override
  String get historyRenameHint => 'Chat name';

  @override
  String get historyNewChat => 'New chat';

  @override
  String get historySearchHint => 'Search chats';

  @override
  String get historyRecent => 'Recent';

  @override
  String get historyRenameTooltip => 'Rename';

  @override
  String get historyEmptySearch => 'No matching chats.';

  @override
  String get historyEmptyList => 'No saved chats yet.';

  @override
  String get codeExportTitle => 'Export code';

  @override
  String codeExportCopied(String format) {
    return '$format code copied.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count characters',
      one: '1 character',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'Copy';

  @override
  String get codeExportDownload => 'Download';

  @override
  String get codeExportNoticeHtml =>
      'Single self-contained HTML file: bundled CSS and JS, works offline.';

  @override
  String get codeExportNoticeReact =>
      'Approximate conversion. Move <style> contents to a CSS file and inspect before use.';

  @override
  String get codeExportNoticeFlutter =>
      'Approximate conversion. Translates inline styles only; <style> CSS is excluded. Inspect before use.';

  @override
  String get codeExportNoticeTailwind =>
      'Approximate conversion. Requires Tailwind v3.2+; move <style> contents to a CSS file. Inspect before use.';

  @override
  String get codeExportTransformErrorTitle => 'Code conversion failed';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Alpha code could not be transformed into $format.';
  }

  @override
  String get codeExportUseHtml => 'Use HTML';

  @override
  String get codeExportEmptyTitle => 'No UI to export yet';

  @override
  String get codeExportEmptyBody => 'Create a UI first.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP only runs on Desktop.';

  @override
  String get mcpRunning => 'Running';

  @override
  String get mcpStopped => 'Stopped';

  @override
  String get mcpDescription =>
      'Bridge for AI agents (Claude Code, Cursor) to inspect and edit designs live.';

  @override
  String get mcpStarting => 'Starting…';

  @override
  String get mcpStart => 'Start';

  @override
  String get mcpAutoStartNote =>
      'Server starts automatically when opening the app.';

  @override
  String get mcpCopyAddress => 'Copy';

  @override
  String get mcpAddressCopied => 'Address copied.';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get mcpGuideOpen => 'Guide';

  @override
  String get mcpGuideTitle => 'MCP guide';

  @override
  String get mcpGuideSubtitle => 'Connect an AI agent to this app.';

  @override
  String get mcpGuideStepStart => 'Start the server';

  @override
  String get mcpGuideStepStartDesc =>
      'Runs while the app is open. No sign-in needed.';

  @override
  String get mcpGuideEndpoint => 'Address';

  @override
  String get mcpGuideStepConnect => 'Connect your agent';

  @override
  String get mcpGuideStepConnectDesc =>
      'Pick your agent, then copy the snippet.';

  @override
  String mcpGuideWhere(String path) {
    return 'File: $path';
  }

  @override
  String get mcpGuideCopy => 'Copy snippet';

  @override
  String get mcpGuideCopied => 'Snippet copied.';

  @override
  String get mcpGuideStepTest => 'Check the connection';

  @override
  String get mcpGuideStepTestDesc =>
      'Send this request, then look for your sessions.';

  @override
  String get mcpGuideStepTools => 'What the agent can do';

  @override
  String get mcpGuideStepToolsDesc => 'Six tools: list first, detail later.';

  @override
  String get mcpGuideTipTitle => 'If it won\'t connect';

  @override
  String get mcpGuideTipAppClosed =>
      'Keep the app open; closing it stops the server.';

  @override
  String get mcpGuideTipPort => 'If 8765 is taken, the app moves to 8766–8774.';

  @override
  String get mcpGuideTipLocal => 'Local only. Never share this port.';

  @override
  String get mcpToolListSessions => 'Lists conversations with counts.';

  @override
  String get mcpToolGetSession => 'Reads one conversation and its pages.';

  @override
  String get mcpToolGetPageHtml => 'Returns one page\'s full HTML.';

  @override
  String get mcpToolWritePage => 'Creates or replaces a page.';

  @override
  String get mcpToolDeletePage => 'Deletes a page.';

  @override
  String get mcpToolPostToChat => 'Writes a reply into the chat.';

  @override
  String get chatProcessing => 'Processing…';

  @override
  String get chatUiReady => 'UI ready';

  @override
  String get chatViewCode => 'View code';

  @override
  String get chatHideCode => 'Hide';

  @override
  String get chatNoMessagesTitle => 'No conversations yet';

  @override
  String get chatNoMessagesBody => 'Type a message to get started.';

  @override
  String get commonGenericError => 'Something went wrong. Try again.';

  @override
  String get canvasMentionElementFallback => 'Selected element';

  @override
  String get canvasNoProvider => 'No active provider. Add one to start.';

  @override
  String get canvasPagesTrimmed =>
      'Extra pages were removed to match the number you asked for.';

  @override
  String get canvasUntitledPage => 'Untitled';

  @override
  String get canvasGenerationStopped => 'Generation stopped.';

  @override
  String get promptAttachmentLimit => 'Up to 6 attachments per message.';

  @override
  String get providerNotFound => 'Provider not found.';

  @override
  String get errorCancelled => 'Cancelled.';

  @override
  String get errorApiTimeout =>
      'Connection timed out. Check the address or your network.';

  @override
  String get errorApiUnreachable => 'Couldn\'t connect. Check the address.';

  @override
  String get errorApiUnauthorized =>
      'The access key is invalid or has no access.';

  @override
  String get errorApiRateLimited =>
      'The service is limiting requests. Try again shortly.';

  @override
  String get errorApiNotFound => 'Address or model not found. Check both.';

  @override
  String get errorApiRejected => 'The service rejected the request.';

  @override
  String get errorApiCertificate =>
      'The server certificate isn\'t valid. Check the address.';

  @override
  String get errorApiSendFailed =>
      'Couldn\'t send the request. Check your connection and the address.';

  @override
  String get errorApiBadResponse =>
      'The reply wasn\'t in the expected format. The address should end with /v1.';

  @override
  String get errorApiNoChatEndpoint => 'This service has no chat address yet.';

  @override
  String get errorApiModelUnavailable =>
      'This model isn\'t available here. Pick another.';

  @override
  String get errorApiConnectionBroken => 'The connection dropped. Try again.';

  @override
  String errorApiProviderReported(String detail) {
    return 'Service message: $detail';
  }

  @override
  String get errorGenerationTimeout =>
      'Generation stopped: it took too long. Try again.';

  @override
  String get errorExportNotReady => 'The page isn\'t ready yet. Wait a moment.';

  @override
  String get errorExportTimeout => 'Export timed out. Try again.';

  @override
  String get errorExportNoElements => 'Nothing to export yet.';

  @override
  String get errorExportEmptyResult => 'The result came back empty. Try again.';

  @override
  String get errorExportWriteFailed =>
      'Couldn\'t save the file. Try another location.';

  @override
  String get errorImportInvalidFile =>
      'This file isn\'t valid JSON. Pick a Centauri .mydesign file.';

  @override
  String get errorImportNotProject => 'This isn\'t a Centauri project file.';

  @override
  String errorImportNewerVersion(String version) {
    return 'This file needs a newer Centauri version ($version). Update the app first.';
  }

  @override
  String get errorImportEmpty => 'This project file is empty.';

  @override
  String errorImportEmptyFile(String name) {
    return 'The file $name is empty.';
  }

  @override
  String get errorImportUnusable =>
      'The file can\'t be read. Try another file.';

  @override
  String errorImportUnusableFile(String name) {
    return 'The file $name can\'t be read. Try another file.';
  }

  @override
  String get errorAttachmentEmpty => 'The file is empty.';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'The file $name is empty.';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'The file is too large (max $maxMb MB).';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'That format isn\'t supported. Use $formats.';
  }

  @override
  String get errorStorageFailed => 'Couldn\'t access the key on this device.';

  @override
  String get errorTransformNoCode => 'This page has no code yet.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get exportFigmaPlugin => 'Figma (plugin)';

  @override
  String exportFigmaCopiedWidth(int width) {
    return 'Copied at $width px. Paste into Figma.';
  }

  @override
  String get catalogSectionFreeTier => 'Free Tier';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => 'Appearance';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceModeLabel => 'Mode';

  @override
  String get appearanceModeSystem => 'System';

  @override
  String get appearanceModeLight => 'Light';

  @override
  String get appearanceModeDark => 'Dark';

  @override
  String get appearancePrimaryLabel => 'Primary color';

  @override
  String get appearanceReset => 'Reset';

  @override
  String get commonDone => 'Done';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorViolet => 'Violet';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorRose => 'Rose';

  @override
  String get colorSlate => 'Slate';

  @override
  String get generationStepPreparing => 'Reading your message';

  @override
  String get generationStepWaiting => 'Waiting for the service';

  @override
  String get generationStepWriting => 'Writing the design';

  @override
  String get generationStepBuilding => 'Building pages';

  @override
  String get generationCanvasBuilding => 'Building…';

  @override
  String generationPageProgress(int index, int total) {
    return 'Page $index of $total';
  }

  @override
  String generationPageProgressUnknown(int index) {
    return 'Page $index';
  }

  @override
  String get generationTitle => 'Building your design';
}
