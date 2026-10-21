// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class AppLocalizationsFil extends AppLocalizations {
  AppLocalizationsFil([String locale = 'fil']) : super(locale);

  @override
  String get appTitle => 'Centauri — AI UI/UX Canvas';

  @override
  String get languageTooltip => 'Wika';

  @override
  String get languageDialogTitle => 'Wika';

  @override
  String get commonAdd => 'Magdagdag';

  @override
  String get commonRetry => 'Subukan muli';

  @override
  String get commonEdit => 'I-edit';

  @override
  String get commonDelete => 'Tanggalin';

  @override
  String get commonCancel => 'Kanselahin';

  @override
  String get commonSave => 'I-save';

  @override
  String get commonClose => 'Isara';

  @override
  String get commonActive => 'Aktibo';

  @override
  String get commonSetActive => 'Gawing aktibo';

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
      'Naka-imbak at naka-encrypt ang lahat ng data sa device mo.';

  @override
  String get providerListLoadFailed => 'Hindi ma-load ang mga Provider.';

  @override
  String get providerListEmptyTitle => 'Wala pang Provider';

  @override
  String get providerListEmptyBody =>
      'Magdagdag ng Provider para simulan ang Centauri.';

  @override
  String get providerListAddProvider => 'Magdagdag ng Provider';

  @override
  String get providerDeleted => 'Tinanggal ang Provider';

  @override
  String get providerDetailPickProvider => 'Pumili muna ng Provider.';

  @override
  String get providerDetailPickModel => 'Pumili muna ng Model.';

  @override
  String providerDetailSaveFailed(String error) {
    return 'Hindi ma-save: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'Hindi maalis ang API Key: $error';
  }

  @override
  String get providerDetailUpdated => 'Na-update ang Provider';

  @override
  String get providerDetailAdded => 'Naidagdag ang Provider';

  @override
  String get providerDetailTestOk => 'Gumagana ang koneksyon.';

  @override
  String get providerDetailTitleEdit => 'I-edit ang Provider';

  @override
  String get providerDetailTitleNew => 'Magdagdag ng Provider';

  @override
  String get providerDetailDeleteTooltip => 'Tanggalin ang Provider';

  @override
  String get providerDetailFieldName => 'Pangalan';

  @override
  String get providerDetailNameHint => 'hal. \"OpenAI Pro\"';

  @override
  String get providerDetailNameRequired => 'Kailangan ang pangalan.';

  @override
  String get providerDetailPickProviderLabel => 'Pumili ng Provider';

  @override
  String get providerDetailFieldProviderName => 'Pangalan ng Provider';

  @override
  String get providerDetailProviderNameHint => 'hal. \"OpenAI\"';

  @override
  String get providerDetailProviderNameRequired =>
      'Kailangan ang pangalan ng Provider.';

  @override
  String get providerDetailPickModelLabel => 'Pumili ng Model';

  @override
  String get providerDetailPickProviderFirst => 'Pumili muna ng Provider';

  @override
  String get providerDetailTestAction => 'Subukan';

  @override
  String get providerDetailBaseUrlRequired => 'Kailangan ang Base URL.';

  @override
  String get providerDetailBaseUrlInvalid =>
      'Maglagay ng valid na URL (halimbawa: https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'Mula sa Provider';

  @override
  String get providerDetailApiKeyStored =>
      'Naka-save ang API Key. I-reset para palitan.';

  @override
  String get providerDetailApiKeyCleared =>
      'Maaalis ang API Key kapag nag-save.';

  @override
  String get providerDetailApiKeyOptional =>
      'Iwanang blangko para sa lokal na serbisyo na walang auth.';

  @override
  String get providerDetailReset => 'I-reset';

  @override
  String get providerDeleteTargetFallback => 'Provider na ito';

  @override
  String get providerDeleteTitle => 'Tanggalin ang Provider na ito?';

  @override
  String providerDeleteBody(String target) {
    return 'Permanenteng tatanggalin ang $target at ang mga naka-save na data.';
  }

  @override
  String get modelCardDeleteTooltip => 'Tanggalin ang Model';

  @override
  String get modelCardCopyIdTooltip => 'Kopyahin ang ID ng Model';

  @override
  String modelCardCopied(String model) {
    return 'Nakopya: $model';
  }

  @override
  String get modelPickerTitle => 'Pumili ng Model';

  @override
  String get modelPickerCustom => 'Custom na Model';

  @override
  String get modelPickerAddModel => 'Magdagdag ng Model';

  @override
  String get modelPickerIdHint => 'hal. \"gpt-4o\"';

  @override
  String get providerPickerTitle => 'Pumili ng Provider';

  @override
  String get commonAllPages => 'Lahat ng page';

  @override
  String get canvasUntitledProject => 'Bagong prototype';

  @override
  String get canvasHideHistory => 'Itago ang history';

  @override
  String get canvasShowHistory => 'Ipakita ang history';

  @override
  String get canvasHideChat => 'Itago ang chat';

  @override
  String get canvasShowChat => 'Ipakita ang chat';

  @override
  String get canvasHidePreview => 'Itago ang preview';

  @override
  String get canvasShowPreview => 'Ipakita ang preview';

  @override
  String get canvasUndoTooltip => 'I-undo (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'I-redo (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na screen',
      one: '1 screen',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'Design';

  @override
  String get canvasModeCode => 'Code';

  @override
  String get canvasShowCode => 'Ipakita ang code';

  @override
  String get canvasHideCode => 'Itago ang code';

  @override
  String get canvasServiceSettings => 'Mga setting ng serbisyo';

  @override
  String get canvasSelectionOff => 'Itigil ang pagpili ng elemento';

  @override
  String get canvasSelectionOn => 'Pumili ng elemento sa canvas';

  @override
  String get canvasBreadcrumbFallback => 'canvas';

  @override
  String get canvasStopGenerating => 'Itigil ang paggawa';

  @override
  String get canvasStopAction => 'Itigil';

  @override
  String get canvasEmptyTitle => 'Wala pang UI';

  @override
  String get canvasEmptyBody => 'Mag-type ng mensahe para magsimula.';

  @override
  String get canvasPrototypeTitle => 'Prototype';

  @override
  String get canvasChatPanelTooltip => 'Panel ng chat at history';

  @override
  String get storageFailedTitle => 'Hindi mabuksan ang lokal na storage. ';

  @override
  String get storageFailedBody =>
      'Isara ang isa pang Centauri window at subukan muli.';

  @override
  String get previewGenericError => 'May error sa preview.';

  @override
  String previewLinkInvalid(String href) {
    return 'Invalid na link: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'Hindi mabuksan: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'Hindi mahanap ang page: $href';
  }

  @override
  String get previewDeleteFailed =>
      'Hindi matanggal ang component. Subukan muli.';

  @override
  String get previewLoading => 'Naglo-load…';

  @override
  String get previewNoPagesTitle => 'Wala pang page';

  @override
  String get previewNoPagesBody => 'Mag-type ng mensahe para gumawa ng page.';

  @override
  String get previewLoadFailedTitle => 'Hindi ma-load ang preview';

  @override
  String get previewWebView2Hint =>
      'Kung paulit-ulit, i-install ang Microsoft Edge WebView2 Runtime.';

  @override
  String get exportNoPages => 'Wala pang page na mai-export.';

  @override
  String exportSaved(String path) {
    return 'Nai-save: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Nakopya ang Figma data ($count elemento).';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Nai-save ang Figma data ($count elemento): $path';
  }

  @override
  String get exportFailed => 'Nabigo ang pag-export. Subukan muli.';

  @override
  String get exportPageTooltip => 'I-export ang page';

  @override
  String get exportPageTooltipCompact =>
      'I-export ang page (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (larawan)';

  @override
  String get exportSvg => 'SVG (vector)';

  @override
  String get exportPdf => 'PDF (dokumento)';

  @override
  String get exportAction => 'I-export';

  @override
  String get codePanelCopied => 'Nakopya ang HTML.';

  @override
  String get codePanelCopyTooltip => 'Kopyahin ang HTML';

  @override
  String get codePanelSaveTooltip => 'I-save bilang .html';

  @override
  String get codePanelEmpty => 'Wala pang code.\nGumawa muna ng UI.';

  @override
  String get promptAnalyzeImage => 'Suriin ang larawang ito.';

  @override
  String promptUnsupportedFormat(String name) {
    return 'Hindi suportado ang format na \"$name\".';
  }

  @override
  String promptReadFailed(String name) {
    return 'Hindi mabasa ang \"$name\".';
  }

  @override
  String get promptPlaceholder => 'Mag-type ng mensahe…';

  @override
  String get promptAttachTooltip => 'Mag-attach ng file';

  @override
  String get promptStopTooltip => 'Itigil ang paggawa';

  @override
  String get promptMentionPagesTooltip => 'Banggitin ang page';

  @override
  String get attachmentImageFailed => 'Hindi maipakita ang larawan.';

  @override
  String get attachmentRemoveTooltip => 'Alisin ang attachment';

  @override
  String get chatWelcomeTitle => 'Magsimula sa isang mensahe';

  @override
  String get chatWelcomeBody => 'Magtanong ng design advice, o ipagawa agad.';

  @override
  String get chatTabChat => 'Chat';

  @override
  String get chatTabHistory => 'History';

  @override
  String get pageRenameTitle => 'Palitan ang pangalan ng page';

  @override
  String get pageRenameHint => 'Pangalan ng page';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(i-double-click para palitan ang pangalan)';
  }

  @override
  String get markdownEmpty => '(walang laman)';

  @override
  String get windowMinimize => 'I-minimize';

  @override
  String get windowMaximize => 'I-maximize';

  @override
  String get windowRestore => 'I-restore';

  @override
  String get windowClose => 'Isara';

  @override
  String get historyRenameTitle => 'Palitan ang pangalan';

  @override
  String get historyRenameHint => 'Pangalan ng chat';

  @override
  String get historyNewChat => 'Bagong chat';

  @override
  String get historySearchHint => 'Maghanap ng chat';

  @override
  String get historyRecent => 'Kamakailan';

  @override
  String get historyRenameTooltip => 'Palitan ang pangalan';

  @override
  String get historyEmptySearch => 'Walang chat na tugma.';

  @override
  String get historyEmptyList => 'Wala pang naka-save na chat.';

  @override
  String get codeExportTitle => 'I-export ang code';

  @override
  String codeExportCopied(String format) {
    return 'Nakopya ang $format code.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na character',
      one: '1 character',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'Kopyahin';

  @override
  String get codeExportDownload => 'I-download';

  @override
  String get codeExportNoticeHtml =>
      'Isang self-contained na HTML file: kasama ang CSS at JS, gumagana offline.';

  @override
  String get codeExportNoticeReact =>
      'Tinatayang conversion. Ilipat ang laman ng <style> sa CSS file at suriin bago gamitin.';

  @override
  String get codeExportNoticeFlutter =>
      'Tinatayang conversion. Inline styles lang ang isinasalin; hindi kasama ang CSS sa <style>. Suriin bago gamitin.';

  @override
  String get codeExportNoticeTailwind =>
      'Tinatayang conversion. Kailangan ng Tailwind v3.2+; ilipat ang laman ng <style> sa CSS file. Suriin bago gamitin.';

  @override
  String get codeExportTransformErrorTitle => 'Hindi na-convert ang code';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Hindi ma-convert ang Alpha code sa $format.';
  }

  @override
  String get codeExportUseHtml => 'Gamitin ang HTML';

  @override
  String get codeExportEmptyTitle => 'Wala pang UI na mai-export';

  @override
  String get codeExportEmptyBody => 'Gumawa muna ng UI.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'Sa Desktop lang tumatakbo ang MCP.';

  @override
  String get mcpRunning => 'Tumatakbo';

  @override
  String get mcpStopped => 'Nakasara';

  @override
  String get mcpDescription =>
      'Tulay para sa AI agents (Claude Code, Cursor) para makita at ma-edit ang design nang live.';

  @override
  String get mcpStarting => 'Nagsisimula…';

  @override
  String get mcpStart => 'Simulan';

  @override
  String get mcpAutoStartNote =>
      'Awtomatikong nagsisimula ang server kapag binuksan ang app.';

  @override
  String get mcpCopyAddress => 'Kopyahin';

  @override
  String get mcpAddressCopied => 'Nakopya ang address.';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get chatProcessing => 'Pinoproseso…';

  @override
  String get chatUiReady => 'Handa na ang UI';

  @override
  String get chatViewCode => 'Tingnan ang code';

  @override
  String get chatHideCode => 'Itago';

  @override
  String get chatNoMessagesTitle => 'Wala pang usapan';

  @override
  String get chatNoMessagesBody => 'Mag-type ng mensahe para magsimula.';

  @override
  String get commonGenericError => 'May nangyaring mali. Subukan muli.';

  @override
  String get canvasMentionElementFallback => 'Napiling elemento';

  @override
  String get canvasNoProvider =>
      'Walang aktibong Provider. Magdagdag para magsimula.';

  @override
  String get canvasUntitledPage => 'Walang pamagat';

  @override
  String get canvasGenerationStopped => 'Itinigil ang paggawa.';

  @override
  String get promptAttachmentLimit => 'Hanggang 6 na attachment bawat mensahe.';

  @override
  String get providerNotFound => 'Hindi mahanap ang Provider.';

  @override
  String get errorCancelled => 'Kinansela.';

  @override
  String get errorApiTimeout =>
      'Nag-time out ang koneksyon. Suriin ang address o ang network.';

  @override
  String get errorApiUnreachable => 'Hindi makakonekta. Suriin ang address.';

  @override
  String get errorApiUnauthorized =>
      'Hindi valid ang access key o walang pahintulot.';

  @override
  String get errorApiRateLimited =>
      'Nililimitahan ng serbisyo ang mga request. Subukan muli maya-maya.';

  @override
  String get errorApiNotFound =>
      'Hindi mahanap ang address o Model. Suriin ang dalawa.';

  @override
  String get errorApiRejected => 'Tinanggihan ng serbisyo ang request.';

  @override
  String get errorApiCertificate =>
      'Hindi valid ang certificate ng server. Suriin ang address.';

  @override
  String get errorApiSendFailed =>
      'Hindi maipadala ang request. Suriin ang koneksyon at address.';

  @override
  String get errorApiBadResponse =>
      'Hindi tugma ang format ng sagot. Dapat magtapos sa /v1 ang address.';

  @override
  String get errorApiNoChatEndpoint =>
      'Wala pang chat address ang serbisyong ito.';

  @override
  String get errorApiModelUnavailable =>
      'Hindi available dito ang Model na ito. Pumili ng iba.';

  @override
  String get errorApiConnectionBroken => 'Naputol ang koneksyon. Subukan muli.';

  @override
  String errorApiProviderReported(String detail) {
    return 'Mensahe mula sa serbisyo: $detail';
  }

  @override
  String get errorGenerationTimeout =>
      'Huminto ang paggawa: masyadong matagal. Subukan muli.';

  @override
  String get errorExportNotReady =>
      'Hindi pa handa ang page. Maghintay sandali.';

  @override
  String get errorExportTimeout => 'Nag-time out ang export. Subukan muli.';

  @override
  String get errorExportNoElements => 'Wala pang ma-export.';

  @override
  String get errorExportEmptyResult =>
      'Walang laman ang resulta. Subukan muli.';

  @override
  String get errorExportWriteFailed =>
      'Hindi ma-save ang file. Pumili ng ibang lokasyon.';

  @override
  String get errorImportInvalidFile =>
      'Hindi valid na JSON ang file na ito. Pumili ng Centauri .mydesign file.';

  @override
  String get errorImportNotProject => 'Hindi ito Centauri project file.';

  @override
  String errorImportNewerVersion(String version) {
    return 'Kailangan ng file na ito ng mas bagong Centauri version ($version). I-update muna ang app.';
  }

  @override
  String get errorImportEmpty => 'Walang laman ang project file na ito.';

  @override
  String errorImportEmptyFile(String name) {
    return 'Walang laman ang file na $name.';
  }

  @override
  String get errorImportUnusable =>
      'Hindi mabasa ang file. Pumili ng ibang file.';

  @override
  String errorImportUnusableFile(String name) {
    return 'Hindi mabasa ang file na $name. Pumili ng ibang file.';
  }

  @override
  String get errorAttachmentEmpty => 'Walang laman ang file.';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'Walang laman ang file na $name.';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'Masyadong malaki ang file (max $maxMb MB).';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'Hindi sinusuportahan ang format na iyon. Gamitin ang $formats.';
  }

  @override
  String get errorStorageFailed => 'Hindi ma-access ang key sa device na ito.';

  @override
  String get errorTransformNoCode => 'Wala pang code ang page na ito.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get exportFigmaPlugin => 'Figma (plug-in)';

  @override
  String exportFigmaCopiedWidth(int width) {
    return 'Nakopya sa $width px. I-paste sa Figma.';
  }

  @override
  String get catalogSectionFreeTier => 'Libreng tier';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => 'Itsura';

  @override
  String get appearanceTitle => 'Itsura';

  @override
  String get appearanceModeLabel => 'Mode';

  @override
  String get appearanceModeSystem => 'Sistema';

  @override
  String get appearanceModeLight => 'Maliwanag';

  @override
  String get appearanceModeDark => 'Madilim';

  @override
  String get appearancePrimaryLabel => 'Pangunahing kulay';

  @override
  String get appearanceReset => 'I-reset';

  @override
  String get commonDone => 'Tapos na';

  @override
  String get colorBlue => 'Asul';

  @override
  String get colorIndigo => 'Indigo';

  @override
  String get colorViolet => 'Lila';

  @override
  String get colorTeal => 'Teal';

  @override
  String get colorGreen => 'Berde';

  @override
  String get colorAmber => 'Amber';

  @override
  String get colorRose => 'Rosas';

  @override
  String get colorSlate => 'Abuhin';
}
