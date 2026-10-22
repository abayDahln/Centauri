// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Centauri — لوحة UI/UX بالذكاء الاصطناعي';

  @override
  String get languageTooltip => 'اللغة';

  @override
  String get languageDialogTitle => 'اللغة';

  @override
  String get commonAdd => 'إضافة';

  @override
  String get commonRetry => 'إعادة المحاولة';

  @override
  String get commonEdit => 'تعديل';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonUndo => 'تراجع';

  @override
  String get commonActive => 'مفعّل';

  @override
  String get commonSetActive => 'تفعيل';

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
  String get providerListSubtitle => 'كل البيانات محفوظة ومشفّرة على جهازك.';

  @override
  String get providerListLoadFailed => 'تعذّر تحميل Provider.';

  @override
  String get providerListEmptyTitle => 'لا يوجد Provider بعد';

  @override
  String get providerListEmptyBody => 'أضف Provider لبدء استخدام Centauri.';

  @override
  String get providerListAddProvider => 'إضافة Provider';

  @override
  String get providerDeleted => 'تم حذف Provider';

  @override
  String get providerDetailPickProvider => 'اختر Provider أولًا.';

  @override
  String get providerDetailPickModel => 'اختر Model أولًا.';

  @override
  String providerDetailSaveFailed(String error) {
    return 'تعذّر الحفظ: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'تعذّر حذف API Key: $error';
  }

  @override
  String get providerDetailUpdated => 'تم تحديث Provider';

  @override
  String get providerDetailAdded => 'تمت إضافة Provider';

  @override
  String get providerDetailTestOk => 'الاتصال يعمل.';

  @override
  String get providerDetailTitleEdit => 'تعديل Provider';

  @override
  String get providerDetailTitleNew => 'إضافة Provider';

  @override
  String get providerDetailDeleteTooltip => 'حذف Provider';

  @override
  String get providerDetailFieldName => 'الاسم';

  @override
  String get providerDetailNameHint => 'مثال: \"OpenAI Pro\"';

  @override
  String get providerDetailNameRequired => 'الاسم مطلوب.';

  @override
  String get providerDetailPickProviderLabel => 'اختر Provider';

  @override
  String get providerDetailFieldProviderName => 'اسم Provider';

  @override
  String get providerDetailProviderNameHint => 'مثال: \"OpenAI\"';

  @override
  String get providerDetailProviderNameRequired => 'اسم Provider مطلوب.';

  @override
  String get providerDetailPickModelLabel => 'اختر Model';

  @override
  String get providerDetailPickProviderFirst => 'اختر Provider أولًا';

  @override
  String get providerDetailTestAction => 'اختبار';

  @override
  String get providerDetailBaseUrlRequired => 'Base URL مطلوب.';

  @override
  String get providerDetailBaseUrlInvalid =>
      'أدخل URL صالحًا (مثال: https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'من Provider';

  @override
  String get providerDetailApiKeyStored =>
      'API Key محفوظ. أعد الضبط لاستبداله.';

  @override
  String get providerDetailApiKeyCleared => 'سيُحذف API Key عند الحفظ.';

  @override
  String get providerDetailApiKeyOptional =>
      'اتركه فارغًا لخدمة محلية بدون تحقق.';

  @override
  String get providerDetailReset => 'إعادة ضبط';

  @override
  String get providerDeleteTargetFallback => 'هذا Provider';

  @override
  String get providerDeleteTitle => 'حذف هذا Provider؟';

  @override
  String providerDeleteBody(String target) {
    return 'سيُحذف $target وبياناته المحفوظة نهائيًا.';
  }

  @override
  String get modelCardDeleteTooltip => 'حذف Model';

  @override
  String get modelCardCopyIdTooltip => 'نسخ معرّف Model';

  @override
  String modelCardCopied(String model) {
    return 'تم النسخ: $model';
  }

  @override
  String get modelPickerTitle => 'اختر Model';

  @override
  String get modelPickerCustom => 'Model مخصّص';

  @override
  String get modelPickerAddModel => 'إضافة Model';

  @override
  String get modelPickerIdHint => 'مثال: \"gpt-4o\"';

  @override
  String get providerPickerTitle => 'اختر Provider';

  @override
  String get commonAllPages => 'كل الصفحات';

  @override
  String get canvasUntitledProject => 'نموذج جديد';

  @override
  String get canvasHideHistory => 'إخفاء السجل';

  @override
  String get canvasShowHistory => 'عرض السجل';

  @override
  String get canvasHideChat => 'إخفاء المحادثة';

  @override
  String get canvasShowChat => 'عرض المحادثة';

  @override
  String get canvasHidePreview => 'إخفاء المعاينة';

  @override
  String get canvasShowPreview => 'عرض المعاينة';

  @override
  String get canvasUndoTooltip => 'تراجع (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'إعادة (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شاشة',
      many: '$count شاشة',
      few: '$count شاشات',
      one: 'شاشة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'تصميم';

  @override
  String get canvasModeCode => 'كود';

  @override
  String get canvasShowCode => 'عرض الكود';

  @override
  String get canvasHideCode => 'إخفاء الكود';

  @override
  String get canvasServiceSettings => 'إعدادات الخدمة';

  @override
  String get canvasSelectionOff => 'إيقاف تحديد العناصر';

  @override
  String get canvasSelectionOn => 'حدّد عنصرًا على اللوحة';

  @override
  String get canvasBreadcrumbFallback => 'اللوحة';

  @override
  String get canvasStopGenerating => 'إيقاف الإنشاء';

  @override
  String get canvasStopAction => 'إيقاف';

  @override
  String get canvasEmptyTitle => 'لا توجد واجهة بعد';

  @override
  String get canvasEmptyBody => 'اكتب رسالة للبدء.';

  @override
  String get canvasPrototypeTitle => 'نموذج';

  @override
  String get canvasChatPanelTooltip => 'لوحة المحادثة والسجل';

  @override
  String get storageFailedTitle => 'تعذّر فتح التخزين المحلي. ';

  @override
  String get storageFailedBody => 'أغلق نافذة Centauri الأخرى ثم أعد المحاولة.';

  @override
  String get previewGenericError => 'حدث خطأ في المعاينة.';

  @override
  String previewLinkInvalid(String href) {
    return 'رابط غير صالح: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'تعذّر الفتح: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'الصفحة غير موجودة: $href';
  }

  @override
  String get previewDeleteFailed => 'تعذّر حذف العنصر. أعد المحاولة.';

  @override
  String get previewEditText => 'تعديل النص';

  @override
  String get previewEditWithAi => 'تعديل بالذكاء الاصطناعي';

  @override
  String get previewTextEditFailed => 'تعذّر حفظ النص. أعد المحاولة.';

  @override
  String get previewComponentDeleted => 'تم حذف المكوّن';

  @override
  String get previewLoading => 'جارٍ التحميل…';

  @override
  String get previewNoPagesTitle => 'لا توجد صفحات بعد';

  @override
  String get previewNoPagesBody => 'اكتب رسالة لإنشاء صفحة.';

  @override
  String get previewLoadFailedTitle => 'تعذّر تحميل المعاينة';

  @override
  String get previewWebView2Hint =>
      'إذا استمر الفشل، ثبّت Microsoft Edge WebView2 Runtime.';

  @override
  String get exportNoPages => 'لا توجد صفحات للتصدير بعد.';

  @override
  String exportSaved(String path) {
    return 'تم الحفظ: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'تم نسخ بيانات Figma ($count عناصر).';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'تم حفظ بيانات Figma ($count عناصر): $path';
  }

  @override
  String get exportFailed => 'فشل التصدير. أعد المحاولة.';

  @override
  String get exportPageTooltip => 'تصدير الصفحة';

  @override
  String get exportPageTooltipCompact => 'تصدير الصفحة (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (صورة)';

  @override
  String get exportSvg => 'SVG (متجه)';

  @override
  String get exportPdf => 'PDF (مستند)';

  @override
  String get exportAction => 'تصدير';

  @override
  String get codePanelCopied => 'تم نسخ HTML.';

  @override
  String get codePanelCopyTooltip => 'نسخ HTML';

  @override
  String get codePanelSaveTooltip => 'حفظ كملف .html';

  @override
  String get codePanelEmpty => 'لا يوجد كود بعد.\nأنشئ واجهة أولًا.';

  @override
  String get promptAnalyzeImage => 'حلّل هذه الصورة.';

  @override
  String promptUnsupportedFormat(String name) {
    return 'التنسيق \"$name\" غير مدعوم.';
  }

  @override
  String promptReadFailed(String name) {
    return 'تعذّرت قراءة \"$name\".';
  }

  @override
  String get promptPlaceholder => 'اكتب رسالة…';

  @override
  String get promptAttachTooltip => 'إرفاق ملف';

  @override
  String get promptStopTooltip => 'إيقاف الإنشاء';

  @override
  String get promptMentionPagesTooltip => 'ذكر صفحة';

  @override
  String get attachmentImageFailed => 'تعذّر عرض الصورة.';

  @override
  String get attachmentRemoveTooltip => 'إزالة المرفق';

  @override
  String get chatWelcomeTitle => 'ابدأ برسالة';

  @override
  String get chatWelcomeBody => 'اسأل عن نصيحة تصميم أو اطلب الإنشاء مباشرة.';

  @override
  String get chatTabChat => 'محادثة';

  @override
  String get chatTabHistory => 'السجل';

  @override
  String get pageRenameTitle => 'إعادة تسمية الصفحة';

  @override
  String get pageRenameHint => 'اسم الصفحة';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(انقر مرتين لإعادة التسمية)';
  }

  @override
  String get markdownEmpty => '(فارغ)';

  @override
  String get windowMinimize => 'تصغير';

  @override
  String get windowMaximize => 'تكبير';

  @override
  String get windowRestore => 'استعادة';

  @override
  String get windowClose => 'إغلاق';

  @override
  String get historyRenameTitle => 'إعادة تسمية';

  @override
  String get historyRenameHint => 'اسم المحادثة';

  @override
  String get historyNewChat => 'محادثة جديدة';

  @override
  String get historySearchHint => 'بحث في المحادثات';

  @override
  String get historyRecent => 'الأحدث';

  @override
  String get historyRenameTooltip => 'إعادة تسمية';

  @override
  String get historyEmptySearch => 'لا توجد محادثات مطابقة.';

  @override
  String get historyEmptyList => 'لا توجد محادثات محفوظة بعد.';

  @override
  String get codeExportTitle => 'تصدير الكود';

  @override
  String codeExportCopied(String format) {
    return 'تم نسخ كود $format.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حرفًا',
      many: '$count حرفًا',
      few: '$count أحرف',
      one: 'حرف واحد',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'نسخ';

  @override
  String get codeExportDownload => 'تنزيل';

  @override
  String get codeExportNoticeHtml =>
      'ملف HTML واحد مكتفٍ ذاتيًا: CSS وJS مدمجان ويعمل دون اتصال.';

  @override
  String get codeExportNoticeReact =>
      'تحويل تقريبي. انقل محتوى <style> إلى ملف CSS وافحصه قبل الاستخدام.';

  @override
  String get codeExportNoticeFlutter =>
      'تحويل تقريبي. تُحوَّل الأنماط المضمّنة فقط؛ CSS داخل <style> غير مشمول. افحصه قبل الاستخدام.';

  @override
  String get codeExportNoticeTailwind =>
      'تحويل تقريبي. يتطلب Tailwind v3.2+؛ انقل محتوى <style> إلى ملف CSS. افحصه قبل الاستخدام.';

  @override
  String get codeExportTransformErrorTitle => 'تعذّر تحويل الكود';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'تعذّر تحويل كود Alpha إلى $format.';
  }

  @override
  String get codeExportUseHtml => 'استخدام HTML';

  @override
  String get codeExportEmptyTitle => 'لا توجد واجهة للتصدير بعد';

  @override
  String get codeExportEmptyBody => 'أنشئ واجهة أولًا.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP يعمل على نسخة Desktop فقط.';

  @override
  String get mcpRunning => 'يعمل';

  @override
  String get mcpStopped => 'متوقف';

  @override
  String get mcpDescription =>
      'جسر لوكلاء الذكاء الاصطناعي (Claude Code، Cursor) لعرض التصاميم وتعديلها مباشرة.';

  @override
  String get mcpStarting => 'جارٍ البدء…';

  @override
  String get mcpStart => 'بدء';

  @override
  String get mcpAutoStartNote => 'يبدأ الخادم تلقائيًا عند فتح التطبيق.';

  @override
  String get mcpCopyAddress => 'نسخ';

  @override
  String get mcpAddressCopied => 'تم نسخ العنوان.';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get mcpGuideOpen => 'الدليل';

  @override
  String get mcpGuideTitle => 'دليل MCP';

  @override
  String get mcpGuideSubtitle => 'اربط وكيل ذكاء اصطناعي بهذا التطبيق.';

  @override
  String get mcpGuideStepStart => 'شغّل الخادم';

  @override
  String get mcpGuideStepStartDesc => 'يعمل ما دام التطبيق مفتوحًا.';

  @override
  String get mcpGuideEndpoint => 'العنوان';

  @override
  String get mcpGuideStepConnect => 'اربط الوكيل';

  @override
  String get mcpGuideStepConnectDesc => 'اختر الوكيل ثم انسخ الشيفرة.';

  @override
  String mcpGuideWhere(String path) {
    return 'الملف: $path';
  }

  @override
  String get mcpGuideCopy => 'انسخ الشيفرة';

  @override
  String get mcpGuideCopied => 'تم نسخ الشيفرة.';

  @override
  String get mcpGuideStepTest => 'تحقّق من الاتصال';

  @override
  String get mcpGuideStepTestDesc => 'أرسل هذا الطلب ثم راجع قائمة المحادثات.';

  @override
  String get mcpGuideStepTools => 'ما يستطيعه الوكيل';

  @override
  String get mcpGuideStepToolsDesc => 'ست أدوات: القائمة أولًا ثم التفاصيل.';

  @override
  String get mcpGuideTipTitle => 'إذا لم يتصل';

  @override
  String get mcpGuideTipAppClosed =>
      'أبقِ التطبيق مفتوحًا؛ إغلاقه يوقف الخادم.';

  @override
  String get mcpGuideTipPort =>
      'إذا كان المنفذ 8765 مشغولًا ينتقل التطبيق إلى 8766–8774.';

  @override
  String get mcpGuideTipLocal => 'محلي فقط. لا تفتح هذا المنفذ على الشبكة.';

  @override
  String get mcpToolListSessions => 'يسرد المحادثات مع الأعداد.';

  @override
  String get mcpToolGetSession => 'يقرأ محادثة وقائمة صفحاتها.';

  @override
  String get mcpToolGetPageHtml => 'يعيد HTML الكامل لصفحة.';

  @override
  String get mcpToolWritePage => 'ينشئ صفحة أو يستبدلها.';

  @override
  String get mcpToolDeletePage => 'يحذف صفحة.';

  @override
  String get mcpToolPostToChat => 'يكتب ردًا في المحادثة.';

  @override
  String get chatProcessing => 'جارٍ المعالجة…';

  @override
  String get chatUiReady => 'الواجهة جاهزة';

  @override
  String get chatViewCode => 'عرض الكود';

  @override
  String get chatHideCode => 'إخفاء';

  @override
  String get chatNoMessagesTitle => 'لا توجد محادثات بعد';

  @override
  String get chatNoMessagesBody => 'اكتب رسالة للبدء.';

  @override
  String get commonGenericError => 'حدث خطأ. أعد المحاولة.';

  @override
  String get canvasMentionElementFallback => 'العنصر المحدد';

  @override
  String get canvasNoProvider => 'لا يوجد Provider مفعّل. أضف واحدًا للبدء.';

  @override
  String get canvasPagesTrimmed =>
      'تمت إزالة الصفحات الزائدة لمطابقة العدد الذي طلبته.';

  @override
  String get canvasUntitledPage => 'بلا عنوان';

  @override
  String get canvasGenerationStopped => 'تم إيقاف الإنشاء.';

  @override
  String get promptAttachmentLimit => 'حتى 6 مرفقات لكل رسالة.';

  @override
  String get providerNotFound => 'Provider غير موجود.';

  @override
  String get errorCancelled => 'تم الإلغاء.';

  @override
  String get errorApiTimeout =>
      'انتهت مهلة الاتصال. تحقق من العنوان أو الشبكة.';

  @override
  String get errorApiUnreachable => 'تعذر الاتصال. تحقق من العنوان.';

  @override
  String get errorApiUnauthorized => 'مفتاح الوصول غير صالح أو بلا صلاحية.';

  @override
  String get errorApiRateLimited =>
      'الخدمة تحدّ من الطلبات. أعد المحاولة بعد قليل.';

  @override
  String get errorApiNotFound =>
      'لم يتم العثور على العنوان أو Model. تحقق من كليهما.';

  @override
  String get errorApiRejected => 'رفضت الخدمة الطلب.';

  @override
  String get errorApiCertificate => 'شهادة الخادم غير صالحة. تحقق من العنوان.';

  @override
  String get errorApiSendFailed =>
      'تعذر إرسال الطلب. تحقق من الاتصال والعنوان.';

  @override
  String get errorApiBadResponse =>
      'لم تكن الاستجابة بالتنسيق المتوقع. يجب أن ينتهي العنوان بـ /v1.';

  @override
  String get errorApiNoChatEndpoint => 'لا تملك هذه الخدمة عنوان محادثة بعد.';

  @override
  String get errorApiModelUnavailable => 'هذا Model غير متاح هنا. اختر غيره.';

  @override
  String get errorApiConnectionBroken => 'انقطع الاتصال. أعد المحاولة.';

  @override
  String errorApiProviderReported(String detail) {
    return 'رسالة الخدمة: $detail';
  }

  @override
  String get errorGenerationTimeout =>
      'توقف الإنشاء: استغرق وقتًا طويلًا. أعد المحاولة.';

  @override
  String get errorExportNotReady => 'الصفحة ليست جاهزة بعد. انتظر قليلًا.';

  @override
  String get errorExportTimeout => 'انتهت مهلة التصدير. أعد المحاولة.';

  @override
  String get errorExportNoElements => 'لا يوجد شيء للتصدير بعد.';

  @override
  String get errorExportEmptyResult => 'عادت النتيجة فارغة. أعد المحاولة.';

  @override
  String get errorExportWriteFailed => 'تعذر حفظ الملف. اختر موقعًا آخر.';

  @override
  String get errorImportInvalidFile =>
      'هذا الملف ليس JSON صالحًا. اختر ملف .mydesign من Centauri.';

  @override
  String get errorImportNotProject => 'هذا ليس ملف مشروع Centauri.';

  @override
  String errorImportNewerVersion(String version) {
    return 'يحتاج هذا الملف إلى إصدار أحدث من Centauri ($version). حدّث التطبيق أولًا.';
  }

  @override
  String get errorImportEmpty => 'ملف المشروع هذا فارغ.';

  @override
  String errorImportEmptyFile(String name) {
    return 'الملف $name فارغ.';
  }

  @override
  String get errorImportUnusable => 'تعذر قراءة الملف. اختر ملفًا آخر.';

  @override
  String errorImportUnusableFile(String name) {
    return 'تعذر قراءة الملف $name. اختر ملفًا آخر.';
  }

  @override
  String get errorAttachmentEmpty => 'الملف فارغ.';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'الملف $name فارغ.';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'الملف كبير جدًا (بحد أقصى $maxMb MB).';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'هذا التنسيق غير مدعوم. استخدم $formats.';
  }

  @override
  String get errorStorageFailed => 'تعذر الوصول إلى المفتاح على هذا الجهاز.';

  @override
  String get errorTransformNoCode => 'لا تحتوي هذه الصفحة على كود بعد.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get exportFigmaPlugin => 'Figma (إضافة)';

  @override
  String exportFigmaCopiedWidth(int width) {
    return 'تم النسخ بعرض $width بكسل. الصق في Figma.';
  }

  @override
  String get catalogSectionFreeTier => 'الخطة المجانية';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => 'المظهر';

  @override
  String get appearanceTitle => 'المظهر';

  @override
  String get appearanceModeLabel => 'الوضع';

  @override
  String get appearanceModeSystem => 'النظام';

  @override
  String get appearanceModeLight => 'فاتح';

  @override
  String get appearanceModeDark => 'داكن';

  @override
  String get appearancePrimaryLabel => 'اللون الأساسي';

  @override
  String get appearanceReset => 'إعادة الضبط';

  @override
  String get commonDone => 'تم';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get colorIndigo => 'نيلي';

  @override
  String get colorViolet => 'بنفسجي';

  @override
  String get colorTeal => 'أزرق مخضر';

  @override
  String get colorGreen => 'أخضر';

  @override
  String get colorAmber => 'عنبري';

  @override
  String get colorRose => 'وردي';

  @override
  String get colorSlate => 'أردوازي';
}
