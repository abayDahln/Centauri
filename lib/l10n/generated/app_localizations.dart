import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('fil'),
    Locale('fr'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Centauri — AI UI/UX Canvas'**
  String get appTitle;

  /// No description provided for @languageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTooltip;

  /// No description provided for @languageDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageDialogTitle;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonSetActive.
  ///
  /// In en, this message translates to:
  /// **'Set active'**
  String get commonSetActive;

  /// No description provided for @commonProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get commonProvider;

  /// No description provided for @commonBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get commonBaseUrl;

  /// No description provided for @commonApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get commonApiKey;

  /// No description provided for @commonModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get commonModel;

  /// No description provided for @providerListHeading.
  ///
  /// In en, this message translates to:
  /// **'Bring Your Own Key (BYOK)'**
  String get providerListHeading;

  /// No description provided for @providerListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All data is stored and encrypted on your device.'**
  String get providerListSubtitle;

  /// No description provided for @providerListLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load providers.'**
  String get providerListLoadFailed;

  /// No description provided for @providerListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No providers yet'**
  String get providerListEmptyTitle;

  /// No description provided for @providerListEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a provider to start using Centauri.'**
  String get providerListEmptyBody;

  /// No description provided for @providerListAddProvider.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get providerListAddProvider;

  /// No description provided for @providerDeleted.
  ///
  /// In en, this message translates to:
  /// **'Provider deleted'**
  String get providerDeleted;

  /// No description provided for @providerDetailPickProvider.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider first.'**
  String get providerDetailPickProvider;

  /// No description provided for @providerDetailPickModel.
  ///
  /// In en, this message translates to:
  /// **'Choose a model first.'**
  String get providerDetailPickModel;

  /// No description provided for @providerDetailSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {error}'**
  String providerDetailSaveFailed(String error);

  /// No description provided for @providerDetailClearKeyFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the API key: {error}'**
  String providerDetailClearKeyFailed(String error);

  /// No description provided for @providerDetailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Provider updated'**
  String get providerDetailUpdated;

  /// No description provided for @providerDetailAdded.
  ///
  /// In en, this message translates to:
  /// **'Provider added'**
  String get providerDetailAdded;

  /// No description provided for @providerDetailTestOk.
  ///
  /// In en, this message translates to:
  /// **'Connection works.'**
  String get providerDetailTestOk;

  /// No description provided for @providerDetailTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit provider'**
  String get providerDetailTitleEdit;

  /// No description provided for @providerDetailTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get providerDetailTitleNew;

  /// No description provided for @providerDetailDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete provider'**
  String get providerDetailDeleteTooltip;

  /// No description provided for @providerDetailFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get providerDetailFieldName;

  /// No description provided for @providerDetailNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"OpenAI Pro\"'**
  String get providerDetailNameHint;

  /// No description provided for @providerDetailNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get providerDetailNameRequired;

  /// No description provided for @providerDetailPickProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider'**
  String get providerDetailPickProviderLabel;

  /// No description provided for @providerDetailFieldProviderName.
  ///
  /// In en, this message translates to:
  /// **'Provider name'**
  String get providerDetailFieldProviderName;

  /// No description provided for @providerDetailProviderNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"OpenAI\"'**
  String get providerDetailProviderNameHint;

  /// No description provided for @providerDetailProviderNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Provider name is required.'**
  String get providerDetailProviderNameRequired;

  /// No description provided for @providerDetailPickModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get providerDetailPickModelLabel;

  /// No description provided for @providerDetailPickProviderFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider first'**
  String get providerDetailPickProviderFirst;

  /// No description provided for @providerDetailTestAction.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get providerDetailTestAction;

  /// No description provided for @providerDetailBaseUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Base URL is required.'**
  String get providerDetailBaseUrlRequired;

  /// No description provided for @providerDetailBaseUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL (example: https://...).'**
  String get providerDetailBaseUrlInvalid;

  /// No description provided for @providerDetailApiKeyFromProvider.
  ///
  /// In en, this message translates to:
  /// **'From the provider'**
  String get providerDetailApiKeyFromProvider;

  /// No description provided for @providerDetailApiKeyStored.
  ///
  /// In en, this message translates to:
  /// **'API key saved. Reset to replace it.'**
  String get providerDetailApiKeyStored;

  /// No description provided for @providerDetailApiKeyCleared.
  ///
  /// In en, this message translates to:
  /// **'API key will be removed when you save.'**
  String get providerDetailApiKeyCleared;

  /// No description provided for @providerDetailApiKeyOptional.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for a local service without authentication.'**
  String get providerDetailApiKeyOptional;

  /// No description provided for @providerDetailReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get providerDetailReset;

  /// No description provided for @providerDeleteTargetFallback.
  ///
  /// In en, this message translates to:
  /// **'this provider'**
  String get providerDeleteTargetFallback;

  /// No description provided for @providerDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this provider?'**
  String get providerDeleteTitle;

  /// No description provided for @providerDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{target} and its saved data will be deleted permanently.'**
  String providerDeleteBody(String target);

  /// No description provided for @modelCardDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete model'**
  String get modelCardDeleteTooltip;

  /// No description provided for @modelCardCopyIdTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy model id'**
  String get modelCardCopyIdTooltip;

  /// No description provided for @modelCardCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied: {model}'**
  String modelCardCopied(String model);

  /// No description provided for @modelPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a model'**
  String get modelPickerTitle;

  /// No description provided for @modelPickerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom model'**
  String get modelPickerCustom;

  /// No description provided for @modelPickerAddModel.
  ///
  /// In en, this message translates to:
  /// **'Add model'**
  String get modelPickerAddModel;

  /// No description provided for @modelPickerIdHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. \"gpt-4o\"'**
  String get modelPickerIdHint;

  /// No description provided for @providerPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a provider'**
  String get providerPickerTitle;

  /// No description provided for @commonAllPages.
  ///
  /// In en, this message translates to:
  /// **'All pages'**
  String get commonAllPages;

  /// No description provided for @canvasUntitledProject.
  ///
  /// In en, this message translates to:
  /// **'New prototype'**
  String get canvasUntitledProject;

  /// No description provided for @canvasHideHistory.
  ///
  /// In en, this message translates to:
  /// **'Hide history'**
  String get canvasHideHistory;

  /// No description provided for @canvasShowHistory.
  ///
  /// In en, this message translates to:
  /// **'Show history'**
  String get canvasShowHistory;

  /// No description provided for @canvasHideChat.
  ///
  /// In en, this message translates to:
  /// **'Hide chat'**
  String get canvasHideChat;

  /// No description provided for @canvasShowChat.
  ///
  /// In en, this message translates to:
  /// **'Show chat'**
  String get canvasShowChat;

  /// No description provided for @canvasHidePreview.
  ///
  /// In en, this message translates to:
  /// **'Hide preview'**
  String get canvasHidePreview;

  /// No description provided for @canvasShowPreview.
  ///
  /// In en, this message translates to:
  /// **'Show preview'**
  String get canvasShowPreview;

  /// No description provided for @canvasUndoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Undo (Ctrl+Z)'**
  String get canvasUndoTooltip;

  /// No description provided for @canvasRedoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Redo (Ctrl+Y)'**
  String get canvasRedoTooltip;

  /// No description provided for @canvasPageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 screen} other{{count} screens}}'**
  String canvasPageCount(int count);

  /// No description provided for @canvasModeDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get canvasModeDesign;

  /// No description provided for @canvasModeCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get canvasModeCode;

  /// No description provided for @canvasShowCode.
  ///
  /// In en, this message translates to:
  /// **'Show code'**
  String get canvasShowCode;

  /// No description provided for @canvasHideCode.
  ///
  /// In en, this message translates to:
  /// **'Hide code'**
  String get canvasHideCode;

  /// No description provided for @canvasServiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Service settings'**
  String get canvasServiceSettings;

  /// No description provided for @canvasSelectionOff.
  ///
  /// In en, this message translates to:
  /// **'Stop selecting elements'**
  String get canvasSelectionOff;

  /// No description provided for @canvasSelectionOn.
  ///
  /// In en, this message translates to:
  /// **'Select an element on the canvas'**
  String get canvasSelectionOn;

  /// No description provided for @canvasBreadcrumbFallback.
  ///
  /// In en, this message translates to:
  /// **'canvas'**
  String get canvasBreadcrumbFallback;

  /// No description provided for @canvasStopGenerating.
  ///
  /// In en, this message translates to:
  /// **'Stop generating'**
  String get canvasStopGenerating;

  /// No description provided for @canvasStopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get canvasStopAction;

  /// No description provided for @canvasEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No UI yet'**
  String get canvasEmptyTitle;

  /// No description provided for @canvasEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Type a message to start.'**
  String get canvasEmptyBody;

  /// No description provided for @canvasPrototypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Prototype'**
  String get canvasPrototypeTitle;

  /// No description provided for @canvasChatPanelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Chat and history panel'**
  String get canvasChatPanelTooltip;

  /// No description provided for @storageFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Local storage couldn\'t be opened. '**
  String get storageFailedTitle;

  /// No description provided for @storageFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Close the other Centauri window and try again.'**
  String get storageFailedBody;

  /// No description provided for @previewGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong in the preview.'**
  String get previewGenericError;

  /// No description provided for @previewLinkInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid link: {href}'**
  String previewLinkInvalid(String href);

  /// No description provided for @previewLinkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open: {href}'**
  String previewLinkOpenFailed(String href);

  /// No description provided for @previewPageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found: {href}'**
  String previewPageNotFound(String href);

  /// No description provided for @previewDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the component. Try again.'**
  String get previewDeleteFailed;

  /// No description provided for @previewEditText.
  ///
  /// In en, this message translates to:
  /// **'Edit text'**
  String get previewEditText;

  /// No description provided for @previewEditWithAi.
  ///
  /// In en, this message translates to:
  /// **'Edit with AI'**
  String get previewEditWithAi;

  /// No description provided for @previewTextEditFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the text. Try again.'**
  String get previewTextEditFailed;

  /// No description provided for @previewComponentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Component deleted'**
  String get previewComponentDeleted;

  /// No description provided for @previewLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading.'**
  String get previewLoading;

  /// No description provided for @previewNoPagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No pages yet'**
  String get previewNoPagesTitle;

  /// No description provided for @previewNoPagesBody.
  ///
  /// In en, this message translates to:
  /// **'Type a message to create a page.'**
  String get previewNoPagesBody;

  /// No description provided for @previewLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview failed to load'**
  String get previewLoadFailedTitle;

  /// No description provided for @previewWebView2Hint.
  ///
  /// In en, this message translates to:
  /// **'If it keeps failing, install the Microsoft Edge WebView2 Runtime.'**
  String get previewWebView2Hint;

  /// No description provided for @exportNoPages.
  ///
  /// In en, this message translates to:
  /// **'No pages to export yet.'**
  String get exportNoPages;

  /// No description provided for @exportSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String exportSaved(String path);

  /// No description provided for @exportFigmaCopied.
  ///
  /// In en, this message translates to:
  /// **'Figma data ({count} elements) copied.'**
  String exportFigmaCopied(int count);

  /// No description provided for @exportFigmaSaved.
  ///
  /// In en, this message translates to:
  /// **'Figma data ({count} elements) saved: {path}'**
  String exportFigmaSaved(int count, String path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Try again.'**
  String get exportFailed;

  /// No description provided for @exportPageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export page'**
  String get exportPageTooltip;

  /// No description provided for @exportPageTooltipCompact.
  ///
  /// In en, this message translates to:
  /// **'Export page (PNG/SVG/PDF/Figma)'**
  String get exportPageTooltipCompact;

  /// No description provided for @exportPng.
  ///
  /// In en, this message translates to:
  /// **'PNG (image)'**
  String get exportPng;

  /// No description provided for @exportSvg.
  ///
  /// In en, this message translates to:
  /// **'SVG (vector)'**
  String get exportSvg;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF (document)'**
  String get exportPdf;

  /// No description provided for @exportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportAction;

  /// No description provided for @codePanelCopied.
  ///
  /// In en, this message translates to:
  /// **'HTML copied.'**
  String get codePanelCopied;

  /// No description provided for @codePanelCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy HTML'**
  String get codePanelCopyTooltip;

  /// No description provided for @codePanelSaveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save as .html'**
  String get codePanelSaveTooltip;

  /// No description provided for @codePanelEmpty.
  ///
  /// In en, this message translates to:
  /// **'No code yet.\nCreate a UI first.'**
  String get codePanelEmpty;

  /// No description provided for @promptAnalyzeImage.
  ///
  /// In en, this message translates to:
  /// **'Analyze this image.'**
  String get promptAnalyzeImage;

  /// No description provided for @promptUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Unsupported format: \"{name}\".'**
  String promptUnsupportedFormat(String name);

  /// No description provided for @promptReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read \"{name}\".'**
  String promptReadFailed(String name);

  /// No description provided for @promptPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message.'**
  String get promptPlaceholder;

  /// No description provided for @promptAttachTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get promptAttachTooltip;

  /// No description provided for @promptStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop generating'**
  String get promptStopTooltip;

  /// No description provided for @promptMentionPagesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mention a page'**
  String get promptMentionPagesTooltip;

  /// No description provided for @attachmentImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t display the image.'**
  String get attachmentImageFailed;

  /// No description provided for @attachmentRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get attachmentRemoveTooltip;

  /// No description provided for @chatWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with a message'**
  String get chatWelcomeTitle;

  /// No description provided for @chatWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Ask anything for design advice, or ask for it to be built.'**
  String get chatWelcomeBody;

  /// No description provided for @chatTabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTabChat;

  /// No description provided for @chatTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get chatTabHistory;

  /// No description provided for @pageRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename page'**
  String get pageRenameTitle;

  /// No description provided for @pageRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Page name'**
  String get pageRenameHint;

  /// No description provided for @pageSlugTooltip.
  ///
  /// In en, this message translates to:
  /// **'{slug}\n(double-click to rename)'**
  String pageSlugTooltip(String slug);

  /// No description provided for @markdownEmpty.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get markdownEmpty;

  /// No description provided for @windowMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowMinimize;

  /// No description provided for @windowMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get windowMaximize;

  /// No description provided for @windowRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get windowRestore;

  /// No description provided for @windowClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get windowClose;

  /// No description provided for @historyRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get historyRenameTitle;

  /// No description provided for @historyRenameHint.
  ///
  /// In en, this message translates to:
  /// **'Chat name'**
  String get historyRenameHint;

  /// No description provided for @historyNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get historyNewChat;

  /// No description provided for @historySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get historySearchHint;

  /// No description provided for @historyRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get historyRecent;

  /// No description provided for @historyRenameTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get historyRenameTooltip;

  /// No description provided for @historyEmptySearch.
  ///
  /// In en, this message translates to:
  /// **'No matching chats.'**
  String get historyEmptySearch;

  /// No description provided for @historyEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No saved chats yet.'**
  String get historyEmptyList;

  /// No description provided for @codeExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export code'**
  String get codeExportTitle;

  /// No description provided for @codeExportCopied.
  ///
  /// In en, this message translates to:
  /// **'{format} code copied.'**
  String codeExportCopied(String format);

  /// No description provided for @codeExportCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 character} other{{count} characters}}'**
  String codeExportCharCount(int count);

  /// No description provided for @codeExportCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get codeExportCopy;

  /// No description provided for @codeExportDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get codeExportDownload;

  /// No description provided for @codeExportNoticeHtml.
  ///
  /// In en, this message translates to:
  /// **'Single self-contained HTML file: bundled CSS and JS, works offline.'**
  String get codeExportNoticeHtml;

  /// No description provided for @codeExportNoticeReact.
  ///
  /// In en, this message translates to:
  /// **'Approximate conversion. Move <style> contents to a CSS file and inspect before use.'**
  String get codeExportNoticeReact;

  /// No description provided for @codeExportNoticeFlutter.
  ///
  /// In en, this message translates to:
  /// **'Approximate conversion. Translates inline styles only; <style> CSS is excluded. Inspect before use.'**
  String get codeExportNoticeFlutter;

  /// No description provided for @codeExportNoticeTailwind.
  ///
  /// In en, this message translates to:
  /// **'Approximate conversion. Requires Tailwind v3.2+; move <style> contents to a CSS file. Inspect before use.'**
  String get codeExportNoticeTailwind;

  /// No description provided for @codeExportTransformErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Code conversion failed'**
  String get codeExportTransformErrorTitle;

  /// No description provided for @codeExportTransformErrorFallback.
  ///
  /// In en, this message translates to:
  /// **'Alpha code could not be transformed into {format}.'**
  String codeExportTransformErrorFallback(String format);

  /// No description provided for @codeExportUseHtml.
  ///
  /// In en, this message translates to:
  /// **'Use HTML'**
  String get codeExportUseHtml;

  /// No description provided for @codeExportEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No UI to export yet'**
  String get codeExportEmptyTitle;

  /// No description provided for @codeExportEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a UI first.'**
  String get codeExportEmptyBody;

  /// No description provided for @mcpDesktopTitle.
  ///
  /// In en, this message translates to:
  /// **'MCP Server (Desktop)'**
  String get mcpDesktopTitle;

  /// No description provided for @mcpDesktopOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'MCP only runs on Desktop.'**
  String get mcpDesktopOnlyDesc;

  /// No description provided for @mcpRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get mcpRunning;

  /// No description provided for @mcpStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get mcpStopped;

  /// No description provided for @mcpDescription.
  ///
  /// In en, this message translates to:
  /// **'Bridge for AI agents (Claude Code, Cursor) to inspect and edit designs live.'**
  String get mcpDescription;

  /// No description provided for @mcpStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get mcpStarting;

  /// No description provided for @mcpStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get mcpStart;

  /// No description provided for @mcpAutoStartNote.
  ///
  /// In en, this message translates to:
  /// **'Server starts automatically when opening the app.'**
  String get mcpAutoStartNote;

  /// No description provided for @mcpCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get mcpCopyAddress;

  /// No description provided for @mcpAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied.'**
  String get mcpAddressCopied;

  /// No description provided for @mcpToolsList.
  ///
  /// In en, this message translates to:
  /// **'Tools: {tools}'**
  String mcpToolsList(String tools);

  /// No description provided for @mcpGuideOpen.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get mcpGuideOpen;

  /// No description provided for @mcpGuideTitle.
  ///
  /// In en, this message translates to:
  /// **'MCP guide'**
  String get mcpGuideTitle;

  /// No description provided for @mcpGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect an AI agent to this app.'**
  String get mcpGuideSubtitle;

  /// No description provided for @mcpGuideStepStart.
  ///
  /// In en, this message translates to:
  /// **'Start the server'**
  String get mcpGuideStepStart;

  /// No description provided for @mcpGuideStepStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Runs while the app is open. No sign-in needed.'**
  String get mcpGuideStepStartDesc;

  /// No description provided for @mcpGuideEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get mcpGuideEndpoint;

  /// No description provided for @mcpGuideStepConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect your agent'**
  String get mcpGuideStepConnect;

  /// No description provided for @mcpGuideStepConnectDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick your agent, then copy the snippet.'**
  String get mcpGuideStepConnectDesc;

  /// No description provided for @mcpGuideWhere.
  ///
  /// In en, this message translates to:
  /// **'File: {path}'**
  String mcpGuideWhere(String path);

  /// No description provided for @mcpGuideCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy snippet'**
  String get mcpGuideCopy;

  /// No description provided for @mcpGuideCopied.
  ///
  /// In en, this message translates to:
  /// **'Snippet copied.'**
  String get mcpGuideCopied;

  /// No description provided for @mcpGuideStepTest.
  ///
  /// In en, this message translates to:
  /// **'Check the connection'**
  String get mcpGuideStepTest;

  /// No description provided for @mcpGuideStepTestDesc.
  ///
  /// In en, this message translates to:
  /// **'Send this request, then look for your sessions.'**
  String get mcpGuideStepTestDesc;

  /// No description provided for @mcpGuideStepTools.
  ///
  /// In en, this message translates to:
  /// **'What the agent can do'**
  String get mcpGuideStepTools;

  /// No description provided for @mcpGuideStepToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Six tools: list first, detail later.'**
  String get mcpGuideStepToolsDesc;

  /// No description provided for @mcpGuideTipTitle.
  ///
  /// In en, this message translates to:
  /// **'If it won\'t connect'**
  String get mcpGuideTipTitle;

  /// No description provided for @mcpGuideTipAppClosed.
  ///
  /// In en, this message translates to:
  /// **'Keep the app open; closing it stops the server.'**
  String get mcpGuideTipAppClosed;

  /// No description provided for @mcpGuideTipPort.
  ///
  /// In en, this message translates to:
  /// **'If 8765 is taken, the app moves to 8766–8774.'**
  String get mcpGuideTipPort;

  /// No description provided for @mcpGuideTipLocal.
  ///
  /// In en, this message translates to:
  /// **'Local only. Never share this port.'**
  String get mcpGuideTipLocal;

  /// No description provided for @mcpToolListSessions.
  ///
  /// In en, this message translates to:
  /// **'Lists conversations with counts.'**
  String get mcpToolListSessions;

  /// No description provided for @mcpToolGetSession.
  ///
  /// In en, this message translates to:
  /// **'Reads one conversation and its pages.'**
  String get mcpToolGetSession;

  /// No description provided for @mcpToolGetPageHtml.
  ///
  /// In en, this message translates to:
  /// **'Returns one page\'s full HTML.'**
  String get mcpToolGetPageHtml;

  /// No description provided for @mcpToolWritePage.
  ///
  /// In en, this message translates to:
  /// **'Creates or replaces a page.'**
  String get mcpToolWritePage;

  /// No description provided for @mcpToolDeletePage.
  ///
  /// In en, this message translates to:
  /// **'Deletes a page.'**
  String get mcpToolDeletePage;

  /// No description provided for @mcpToolPostToChat.
  ///
  /// In en, this message translates to:
  /// **'Writes a reply into the chat.'**
  String get mcpToolPostToChat;

  /// No description provided for @chatProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get chatProcessing;

  /// No description provided for @chatUiReady.
  ///
  /// In en, this message translates to:
  /// **'UI ready'**
  String get chatUiReady;

  /// No description provided for @chatViewCode.
  ///
  /// In en, this message translates to:
  /// **'View code'**
  String get chatViewCode;

  /// No description provided for @chatHideCode.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get chatHideCode;

  /// No description provided for @chatNoMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatNoMessagesTitle;

  /// No description provided for @chatNoMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'Type a message to get started.'**
  String get chatNoMessagesBody;

  /// No description provided for @commonGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get commonGenericError;

  /// No description provided for @canvasMentionElementFallback.
  ///
  /// In en, this message translates to:
  /// **'Selected element'**
  String get canvasMentionElementFallback;

  /// No description provided for @canvasNoProvider.
  ///
  /// In en, this message translates to:
  /// **'No active provider. Add one to start.'**
  String get canvasNoProvider;

  /// No description provided for @canvasPagesTrimmed.
  ///
  /// In en, this message translates to:
  /// **'Extra pages were removed to match the number you asked for.'**
  String get canvasPagesTrimmed;

  /// No description provided for @canvasUntitledPage.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get canvasUntitledPage;

  /// No description provided for @canvasGenerationStopped.
  ///
  /// In en, this message translates to:
  /// **'Generation stopped.'**
  String get canvasGenerationStopped;

  /// No description provided for @promptAttachmentLimit.
  ///
  /// In en, this message translates to:
  /// **'Up to 6 attachments per message.'**
  String get promptAttachmentLimit;

  /// No description provided for @providerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Provider not found.'**
  String get providerNotFound;

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get errorCancelled;

  /// No description provided for @errorApiTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Check the address or your network.'**
  String get errorApiTimeout;

  /// No description provided for @errorApiUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect. Check the address.'**
  String get errorApiUnreachable;

  /// No description provided for @errorApiUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'The access key is invalid or has no access.'**
  String get errorApiUnauthorized;

  /// No description provided for @errorApiRateLimited.
  ///
  /// In en, this message translates to:
  /// **'The service is limiting requests. Try again shortly.'**
  String get errorApiRateLimited;

  /// No description provided for @errorApiNotFound.
  ///
  /// In en, this message translates to:
  /// **'Address or model not found. Check both.'**
  String get errorApiNotFound;

  /// No description provided for @errorApiRejected.
  ///
  /// In en, this message translates to:
  /// **'The service rejected the request.'**
  String get errorApiRejected;

  /// No description provided for @errorApiCertificate.
  ///
  /// In en, this message translates to:
  /// **'The server certificate isn\'t valid. Check the address.'**
  String get errorApiCertificate;

  /// No description provided for @errorApiSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the request. Check your connection and the address.'**
  String get errorApiSendFailed;

  /// No description provided for @errorApiBadResponse.
  ///
  /// In en, this message translates to:
  /// **'The reply wasn\'t in the expected format. The address should end with /v1.'**
  String get errorApiBadResponse;

  /// No description provided for @errorApiNoChatEndpoint.
  ///
  /// In en, this message translates to:
  /// **'This service has no chat address yet.'**
  String get errorApiNoChatEndpoint;

  /// No description provided for @errorApiModelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This model isn\'t available here. Pick another.'**
  String get errorApiModelUnavailable;

  /// No description provided for @errorApiConnectionBroken.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped. Try again.'**
  String get errorApiConnectionBroken;

  /// No description provided for @errorApiProviderReported.
  ///
  /// In en, this message translates to:
  /// **'Service message: {detail}'**
  String errorApiProviderReported(String detail);

  /// No description provided for @errorGenerationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Generation stopped: it took too long. Try again.'**
  String get errorGenerationTimeout;

  /// No description provided for @errorExportNotReady.
  ///
  /// In en, this message translates to:
  /// **'The page isn\'t ready yet. Wait a moment.'**
  String get errorExportNotReady;

  /// No description provided for @errorExportTimeout.
  ///
  /// In en, this message translates to:
  /// **'Export timed out. Try again.'**
  String get errorExportTimeout;

  /// No description provided for @errorExportNoElements.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet.'**
  String get errorExportNoElements;

  /// No description provided for @errorExportEmptyResult.
  ///
  /// In en, this message translates to:
  /// **'The result came back empty. Try again.'**
  String get errorExportEmptyResult;

  /// No description provided for @errorExportWriteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file. Try another location.'**
  String get errorExportWriteFailed;

  /// No description provided for @errorImportInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t valid JSON. Pick a Centauri .mydesign file.'**
  String get errorImportInvalidFile;

  /// No description provided for @errorImportNotProject.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a Centauri project file.'**
  String get errorImportNotProject;

  /// No description provided for @errorImportNewerVersion.
  ///
  /// In en, this message translates to:
  /// **'This file needs a newer Centauri version ({version}). Update the app first.'**
  String errorImportNewerVersion(String version);

  /// No description provided for @errorImportEmpty.
  ///
  /// In en, this message translates to:
  /// **'This project file is empty.'**
  String get errorImportEmpty;

  /// No description provided for @errorImportEmptyFile.
  ///
  /// In en, this message translates to:
  /// **'The file {name} is empty.'**
  String errorImportEmptyFile(String name);

  /// No description provided for @errorImportUnusable.
  ///
  /// In en, this message translates to:
  /// **'The file can\'t be read. Try another file.'**
  String get errorImportUnusable;

  /// No description provided for @errorImportUnusableFile.
  ///
  /// In en, this message translates to:
  /// **'The file {name} can\'t be read. Try another file.'**
  String errorImportUnusableFile(String name);

  /// No description provided for @errorAttachmentEmpty.
  ///
  /// In en, this message translates to:
  /// **'The file is empty.'**
  String get errorAttachmentEmpty;

  /// No description provided for @errorAttachmentEmptyFile.
  ///
  /// In en, this message translates to:
  /// **'The file {name} is empty.'**
  String errorAttachmentEmptyFile(String name);

  /// No description provided for @errorAttachmentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is too large (max {maxMb} MB).'**
  String errorAttachmentTooLarge(int maxMb);

  /// No description provided for @errorAttachmentUnsupported.
  ///
  /// In en, this message translates to:
  /// **'That format isn\'t supported. Use {formats}.'**
  String errorAttachmentUnsupported(String formats);

  /// No description provided for @errorStorageFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t access the key on this device.'**
  String get errorStorageFailed;

  /// No description provided for @errorTransformNoCode.
  ///
  /// In en, this message translates to:
  /// **'This page has no code yet.'**
  String get errorTransformNoCode;

  /// No description provided for @exportFigma.
  ///
  /// In en, this message translates to:
  /// **'Figma'**
  String get exportFigma;

  /// No description provided for @exportFigmaPlugin.
  ///
  /// In en, this message translates to:
  /// **'Figma (plugin)'**
  String get exportFigmaPlugin;

  /// No description provided for @exportFigmaCopiedWidth.
  ///
  /// In en, this message translates to:
  /// **'Copied at {width} px. Paste into Figma.'**
  String exportFigmaCopiedWidth(int width);

  /// No description provided for @catalogSectionFreeTier.
  ///
  /// In en, this message translates to:
  /// **'Free Tier'**
  String get catalogSectionFreeTier;

  /// No description provided for @catalogSectionApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get catalogSectionApiKey;

  /// No description provided for @appearanceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTooltip;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get appearanceModeLabel;

  /// No description provided for @appearanceModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceModeSystem;

  /// No description provided for @appearanceModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceModeLight;

  /// No description provided for @appearanceModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceModeDark;

  /// No description provided for @appearancePrimaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary color'**
  String get appearancePrimaryLabel;

  /// No description provided for @appearanceReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get appearanceReset;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorIndigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get colorIndigo;

  /// No description provided for @colorViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get colorViolet;

  /// No description provided for @colorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colorTeal;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colorAmber;

  /// No description provided for @colorRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get colorRose;

  /// No description provided for @colorSlate.
  ///
  /// In en, this message translates to:
  /// **'Slate'**
  String get colorSlate;

  /// No description provided for @generationStepPreparing.
  ///
  /// In en, this message translates to:
  /// **'Reading your message'**
  String get generationStepPreparing;

  /// No description provided for @generationStepWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the service'**
  String get generationStepWaiting;

  /// No description provided for @generationStepWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing the design'**
  String get generationStepWriting;

  /// No description provided for @generationStepBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building pages'**
  String get generationStepBuilding;

  /// No description provided for @generationCanvasBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building…'**
  String get generationCanvasBuilding;

  /// No description provided for @generationPageProgress.
  ///
  /// In en, this message translates to:
  /// **'Page {index} of {total}'**
  String generationPageProgress(int index, int total);

  /// No description provided for @generationPageProgressUnknown.
  ///
  /// In en, this message translates to:
  /// **'Page {index}'**
  String generationPageProgressUnknown(int index);

  /// No description provided for @generationTitle.
  ///
  /// In en, this message translates to:
  /// **'Building your design'**
  String get generationTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'fil',
    'fr',
    'id',
    'ja',
    'ko',
    'pt',
    'ru',
    'th',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fil':
      return AppLocalizationsFil();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
