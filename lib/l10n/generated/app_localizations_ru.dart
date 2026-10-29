// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Centauri — AI-канвас для UI/UX';

  @override
  String get languageTooltip => 'Язык';

  @override
  String get languageDialogTitle => 'Язык';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonEdit => 'Изменить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonUndo => 'Отменить';

  @override
  String get commonActive => 'Активен';

  @override
  String get commonSetActive => 'Сделать активным';

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
      'Все данные хранятся и шифруются на вашем устройстве.';

  @override
  String get providerListLoadFailed => 'Не удалось загрузить Provider.';

  @override
  String get providerListEmptyTitle => 'Provider пока нет';

  @override
  String get providerListEmptyBody =>
      'Добавьте Provider, чтобы начать работу с Centauri.';

  @override
  String get providerListAddProvider => 'Добавить Provider';

  @override
  String get providerDeleted => 'Provider удалён';

  @override
  String get providerDetailPickProvider => 'Сначала выберите Provider.';

  @override
  String get providerDetailPickModel => 'Сначала выберите Model.';

  @override
  String providerDetailSaveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'Не удалось удалить API Key: $error';
  }

  @override
  String get providerDetailUpdated => 'Provider обновлён';

  @override
  String get providerDetailAdded => 'Provider добавлен';

  @override
  String get providerDetailTestOk => 'Соединение работает.';

  @override
  String get providerDetailTitleEdit => 'Изменить Provider';

  @override
  String get providerDetailTitleNew => 'Добавить Provider';

  @override
  String get providerDetailDeleteTooltip => 'Удалить Provider';

  @override
  String get providerDetailFieldName => 'Название';

  @override
  String get providerDetailNameHint => 'например, \"OpenAI Pro\"';

  @override
  String get providerDetailNameRequired => 'Введите название.';

  @override
  String get providerDetailPickProviderLabel => 'Выберите Provider';

  @override
  String get providerDetailFieldProviderName => 'Название Provider';

  @override
  String get providerDetailProviderNameHint => 'например, \"OpenAI\"';

  @override
  String get providerDetailProviderNameRequired => 'Введите название Provider.';

  @override
  String get providerDetailPickModelLabel => 'Выберите Model';

  @override
  String get providerDetailPickProviderFirst => 'Сначала выберите Provider';

  @override
  String get providerDetailTestAction => 'Проверить';

  @override
  String get providerDetailBaseUrlRequired => 'Введите Base URL.';

  @override
  String get providerDetailBaseUrlInvalid =>
      'Введите корректный URL (пример: https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'Из Provider';

  @override
  String get providerDetailApiKeyStored =>
      'API Key сохранён. Сбросьте, чтобы заменить.';

  @override
  String get providerDetailApiKeyCleared =>
      'API Key будет удалён при сохранении.';

  @override
  String get providerDetailApiKeyOptional =>
      'Оставьте пустым для локального сервиса без авторизации.';

  @override
  String get providerDetailReset => 'Сбросить';

  @override
  String get providerDeleteTargetFallback => 'этот Provider';

  @override
  String get providerDeleteTitle => 'Удалить этот Provider?';

  @override
  String providerDeleteBody(String target) {
    return '$target и сохранённые данные будут удалены навсегда.';
  }

  @override
  String get modelCardDeleteTooltip => 'Удалить Model';

  @override
  String get modelCardCopyIdTooltip => 'Копировать ID Model';

  @override
  String modelCardCopied(String model) {
    return 'Скопировано: $model';
  }

  @override
  String get modelPickerTitle => 'Выберите Model';

  @override
  String get modelPickerCustom => 'Свой Model';

  @override
  String get modelPickerAddModel => 'Добавить Model';

  @override
  String get modelPickerIdHint => 'например, \"gpt-4o\"';

  @override
  String get providerPickerTitle => 'Выберите Provider';

  @override
  String get commonAllPages => 'Все страницы';

  @override
  String get canvasUntitledProject => 'Новый прототип';

  @override
  String get canvasHideHistory => 'Скрыть историю';

  @override
  String get canvasShowHistory => 'Показать историю';

  @override
  String get canvasHideChat => 'Скрыть чат';

  @override
  String get canvasShowChat => 'Показать чат';

  @override
  String get canvasHidePreview => 'Скрыть предпросмотр';

  @override
  String get canvasShowPreview => 'Показать предпросмотр';

  @override
  String get canvasUndoTooltip => 'Отменить (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'Повторить (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count экрана',
      many: '$count экранов',
      few: '$count экрана',
      one: '$count экран',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'Дизайн';

  @override
  String get canvasModeCode => 'Код';

  @override
  String get canvasShowCode => 'Показать код';

  @override
  String get canvasHideCode => 'Скрыть код';

  @override
  String get canvasLayoutDesktop => 'Десктоп';

  @override
  String get canvasLayoutMobile => 'Мобильный';

  @override
  String get canvasServiceSettings => 'Настройки сервиса';

  @override
  String get canvasSelectionOff => 'Отключить выбор элементов';

  @override
  String get canvasSelectionOn => 'Выберите элемент на канве';

  @override
  String get canvasBreadcrumbFallback => 'канва';

  @override
  String get canvasStopGenerating => 'Остановить создание';

  @override
  String get canvasStopAction => 'Остановить';

  @override
  String get canvasEmptyTitle => 'UI пока нет';

  @override
  String get canvasEmptyBody => 'Введите сообщение, чтобы начать.';

  @override
  String get canvasPrototypeTitle => 'Прототип';

  @override
  String get canvasChatPanelTooltip => 'Панель чата и истории';

  @override
  String get storageFailedTitle => 'Не удалось открыть локальное хранилище. ';

  @override
  String get storageFailedBody =>
      'Закройте другое окно Centauri и повторите попытку.';

  @override
  String get previewGenericError => 'В предпросмотре произошла ошибка.';

  @override
  String previewLinkInvalid(String href) {
    return 'Неверная ссылка: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'Не удалось открыть: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'Страница не найдена: $href';
  }

  @override
  String get previewDeleteFailed =>
      'Не удалось удалить компонент. Повторите попытку.';

  @override
  String get previewEditText => 'Изменить текст';

  @override
  String get previewEditWithAi => 'Изменить с ИИ';

  @override
  String get previewTextEditFailed =>
      'Не удалось сохранить текст. Повторите попытку.';

  @override
  String get previewComponentDeleted => 'Компонент удалён';

  @override
  String get previewLoading => 'Загрузка…';

  @override
  String get previewNoPagesTitle => 'Страниц пока нет';

  @override
  String get previewNoPagesBody => 'Введите сообщение, чтобы создать страницу.';

  @override
  String get previewLoadFailedTitle => 'Не удалось загрузить предпросмотр';

  @override
  String get previewWebView2Hint =>
      'Если ошибка повторяется, установите Microsoft Edge WebView2 Runtime.';

  @override
  String get exportNoPages => 'Пока нет страниц для экспорта.';

  @override
  String exportSaved(String path) {
    return 'Сохранено: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Данные Figma ($count элем.) скопированы.';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Данные Figma ($count элем.) сохранены: $path';
  }

  @override
  String get exportFailed => 'Не удалось экспортировать. Повторите попытку.';

  @override
  String get exportPageTooltip => 'Экспорт страницы';

  @override
  String get exportPageTooltipCompact => 'Экспорт страницы (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (изображение)';

  @override
  String get exportSvg => 'SVG (вектор)';

  @override
  String get exportPdf => 'PDF (документ)';

  @override
  String get exportAction => 'Экспорт';

  @override
  String get codePanelCopied => 'HTML скопирован.';

  @override
  String get codePanelCopyTooltip => 'Копировать HTML';

  @override
  String get codePanelSaveTooltip => 'Сохранить как .html';

  @override
  String get codePanelEmpty => 'Кода пока нет.\nСначала создайте UI.';

  @override
  String get promptAnalyzeImage => 'Проанализируйте это изображение.';

  @override
  String promptUnsupportedFormat(String name) {
    return 'Формат «$name» не поддерживается.';
  }

  @override
  String promptReadFailed(String name) {
    return 'Не удалось прочитать «$name».';
  }

  @override
  String get promptPlaceholder => 'Введите сообщение…';

  @override
  String get promptAttachTooltip => 'Прикрепить файл';

  @override
  String get promptStopTooltip => 'Остановить создание';

  @override
  String get promptMentionPagesTooltip => 'Упомянуть страницу';

  @override
  String get attachmentImageFailed => 'Не удалось показать изображение.';

  @override
  String get attachmentRemoveTooltip => 'Удалить вложение';

  @override
  String get chatWelcomeTitle => 'Начните с сообщения';

  @override
  String get chatWelcomeBody =>
      'Спросите совет по дизайну или попросите всё создать.';

  @override
  String get chatTabChat => 'Чат';

  @override
  String get chatTabHistory => 'История';

  @override
  String get pageRenameTitle => 'Переименовать страницу';

  @override
  String get pageRenameHint => 'Название страницы';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(двойной щелчок — переименовать)';
  }

  @override
  String get markdownEmpty => '(пусто)';

  @override
  String get windowMinimize => 'Свернуть';

  @override
  String get windowMaximize => 'Развернуть';

  @override
  String get windowRestore => 'Восстановить';

  @override
  String get windowClose => 'Закрыть';

  @override
  String get historyRenameTitle => 'Переименовать';

  @override
  String get historyRenameHint => 'Название чата';

  @override
  String get historyNewChat => 'Новый чат';

  @override
  String get historySearchHint => 'Поиск чатов';

  @override
  String get historyRecent => 'Недавние';

  @override
  String get historyRenameTooltip => 'Переименовать';

  @override
  String get historyEmptySearch => 'Подходящих чатов нет.';

  @override
  String get historyEmptyList => 'Сохранённых чатов пока нет.';

  @override
  String get codeExportTitle => 'Экспорт кода';

  @override
  String codeExportCopied(String format) {
    return 'Код $format скопирован.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count символа',
      many: '$count символов',
      few: '$count символа',
      one: '$count символ',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'Копировать';

  @override
  String get codeExportDownload => 'Скачать';

  @override
  String get codeExportNoticeHtml =>
      'Один самодостаточный HTML-файл: CSS и JS внутри, работает офлайн.';

  @override
  String get codeExportNoticeReact =>
      'Приблизительная конвертация. Перенесите содержимое <style> в CSS-файл и проверьте перед использованием.';

  @override
  String get codeExportNoticeFlutter =>
      'Приблизительная конвертация. Переносятся только встроенные стили; CSS из <style> не включается. Проверьте перед использованием.';

  @override
  String get codeExportNoticeTailwind =>
      'Приблизительная конвертация. Нужен Tailwind v3.2+; перенесите содержимое <style> в CSS-файл. Проверьте перед использованием.';

  @override
  String get codeExportTransformErrorTitle => 'Не удалось преобразовать код';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Код Alpha не удалось преобразовать в $format.';
  }

  @override
  String get codeExportUseHtml => 'Использовать HTML';

  @override
  String get codeExportEmptyTitle => 'Пока нет UI для экспорта';

  @override
  String get codeExportEmptyBody => 'Сначала создайте UI.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP работает только в настольной версии.';

  @override
  String get mcpRunning => 'Работает';

  @override
  String get mcpStopped => 'Остановлен';

  @override
  String get mcpDescription =>
      'AI-агенты (Claude Code, Cursor) могут смотреть и менять дизайн в реальном времени.';

  @override
  String get mcpStarting => 'Запуск…';

  @override
  String get mcpStart => 'Запустить';

  @override
  String get mcpAutoStartNote =>
      'Сервер запускается сам при открытии приложения.';

  @override
  String get mcpCopyAddress => 'Копировать';

  @override
  String get mcpAddressCopied => 'Адрес скопирован.';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get mcpGuideOpen => 'Руководство';

  @override
  String get mcpGuideTitle => 'Руководство MCP';

  @override
  String get mcpGuideSubtitle => 'Подключите ИИ-агента к приложению.';

  @override
  String get mcpGuideStepStart => 'Запустите сервер';

  @override
  String get mcpGuideStepStartDesc => 'Работает, пока открыто приложение.';

  @override
  String get mcpGuideEndpoint => 'Адрес';

  @override
  String get mcpGuideStepConnect => 'Подключите агента';

  @override
  String get mcpGuideStepConnectDesc => 'Выберите агента и скопируйте код.';

  @override
  String mcpGuideWhere(String path) {
    return 'Файл: $path';
  }

  @override
  String get mcpGuideCopy => 'Копировать код';

  @override
  String get mcpGuideCopied => 'Код скопирован.';

  @override
  String get mcpGuideStepTest => 'Проверьте подключение';

  @override
  String get mcpGuideStepTestDesc =>
      'Отправьте запрос и посмотрите список бесед.';

  @override
  String get mcpGuideStepTools => 'Что умеет агент';

  @override
  String get mcpGuideStepToolsDesc =>
      'Шесть инструментов: сначала список, потом детали.';

  @override
  String get mcpGuideTipTitle => 'Если не подключается';

  @override
  String get mcpGuideTipAppClosed =>
      'Держите приложение открытым: при закрытии сервер останавливается.';

  @override
  String get mcpGuideTipPort =>
      'Если порт 8765 занят, приложение перейдёт на 8766–8774.';

  @override
  String get mcpGuideTipLocal => 'Только локально. Не открывайте порт в сеть.';

  @override
  String get mcpToolListSessions => 'Список бесед с количеством.';

  @override
  String get mcpToolGetSession => 'Читает беседу и список её страниц.';

  @override
  String get mcpToolGetPageHtml => 'Возвращает полный HTML страницы.';

  @override
  String get mcpToolWritePage => 'Создаёт или заменяет страницу.';

  @override
  String get mcpToolDeletePage => 'Удаляет страницу.';

  @override
  String get mcpToolPostToChat => 'Пишет ответ в чат.';

  @override
  String get chatProcessing => 'Обработка…';

  @override
  String get chatUiReady => 'UI готов';

  @override
  String get chatViewCode => 'Смотреть код';

  @override
  String get chatHideCode => 'Скрыть';

  @override
  String get chatNoMessagesTitle => 'Чатов пока нет';

  @override
  String get chatNoMessagesBody => 'Введите сообщение, чтобы начать.';

  @override
  String chatStreamPage(int page) {
    return 'Пишу страницу $page…';
  }

  @override
  String chatStreamPageOf(int page, int total) {
    return 'Пишу страницу $page из $total…';
  }

  @override
  String get chatStreamFinishing => 'Готовлю страницы…';

  @override
  String get commonGenericError => 'Что-то пошло не так. Повторите попытку.';

  @override
  String get canvasMentionElementFallback => 'Выбранный элемент';

  @override
  String get canvasNoProvider =>
      'Нет активного Provider. Добавьте его, чтобы начать.';

  @override
  String get canvasPagesTrimmed =>
      'Лишние страницы удалены, чтобы соответствовать запрошенному количеству.';

  @override
  String get canvasUntitledPage => 'Без названия';

  @override
  String get canvasGenerationStopped => 'Создание остановлено.';

  @override
  String get promptAttachmentLimit => 'До 6 вложений на сообщение.';

  @override
  String get providerNotFound => 'Provider не найден.';

  @override
  String get errorCancelled => 'Отменено.';

  @override
  String get errorApiTimeout =>
      'Время подключения истекло. Проверьте адрес или сеть.';

  @override
  String get errorApiUnreachable => 'Не удалось подключиться. Проверьте адрес.';

  @override
  String get errorApiUnauthorized =>
      'Ключ доступа недействителен или не имеет прав.';

  @override
  String get errorApiRateLimited =>
      'Сервис ограничивает запросы. Повторите попытку позже.';

  @override
  String get errorApiInsufficientCredits =>
      'На балансе аккаунта нет средств. Пополните баланс и повторите попытку.';

  @override
  String get errorApiNotFound =>
      'Адрес или Model не найдены. Проверьте и то и другое.';

  @override
  String get errorApiRejected => 'Сервис отклонил запрос.';

  @override
  String get errorApiCertificate =>
      'Сертификат сервера недействителен. Проверьте адрес.';

  @override
  String get errorApiSendFailed =>
      'Не удалось отправить запрос. Проверьте подключение и адрес.';

  @override
  String get errorApiBadResponse =>
      'Ответ пришёл в неожиданном формате. Адрес должен заканчиваться на /v1.';

  @override
  String get errorApiNoChatEndpoint =>
      'У этого сервиса пока нет адреса для чата.';

  @override
  String get errorApiModelUnavailable =>
      'Эта Model здесь недоступна. Выберите другую.';

  @override
  String get errorApiConnectionBroken =>
      'Подключение прервалось. Повторите попытку.';

  @override
  String errorApiProviderReported(String detail) {
    return 'Сообщение сервиса: $detail';
  }

  @override
  String get errorGenerationTimeout =>
      'Генерация остановлена: это заняло слишком много времени. Повторите попытку.';

  @override
  String get errorExportNotReady =>
      'Страница ещё не готова. Подождите немного.';

  @override
  String get errorExportTimeout => 'Время экспорта истекло. Повторите попытку.';

  @override
  String get errorExportNoElements => 'Пока нечего экспортировать.';

  @override
  String get errorExportEmptyResult =>
      'Результат оказался пустым. Повторите попытку.';

  @override
  String get errorExportWriteFailed =>
      'Не удалось сохранить файл. Выберите другое место.';

  @override
  String get errorImportInvalidFile =>
      'Этот файл не является допустимым JSON. Выберите файл Centauri .mydesign.';

  @override
  String get errorImportNotProject => 'Это не файл проекта Centauri.';

  @override
  String errorImportNewerVersion(String version) {
    return 'Для этого файла нужна более новая версия Centauri ($version). Сначала обновите приложение.';
  }

  @override
  String get errorImportEmpty => 'Этот файл проекта пуст.';

  @override
  String errorImportEmptyFile(String name) {
    return 'Файл $name пуст.';
  }

  @override
  String get errorImportUnusable =>
      'Не удалось прочитать файл. Выберите другой файл.';

  @override
  String errorImportUnusableFile(String name) {
    return 'Не удалось прочитать файл $name. Выберите другой файл.';
  }

  @override
  String get errorAttachmentEmpty => 'Файл пуст.';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'Файл $name пуст.';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'Файл слишком большой (макс. $maxMb MB).';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'Этот формат не поддерживается. Используйте $formats.';
  }

  @override
  String get errorStorageFailed =>
      'Не удалось получить доступ к ключу на этом устройстве.';

  @override
  String get errorTransformNoCode => 'У этой страницы пока нет кода.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get exportFigmaPlugin => 'Figma (плагин)';

  @override
  String exportFigmaCopiedWidth(int width) {
    return 'Скопировано с шириной $width px. Вставьте в Figma.';
  }

  @override
  String get catalogSectionFreeTier => 'Бесплатный тариф';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => 'Оформление';

  @override
  String get appearanceTitle => 'Оформление';

  @override
  String get appearanceModeLabel => 'Режим';

  @override
  String get appearanceModeSystem => 'Системный';

  @override
  String get appearanceModeLight => 'Светлая';

  @override
  String get appearanceModeDark => 'Тёмная';

  @override
  String get appearancePrimaryLabel => 'Основной цвет';

  @override
  String get appearanceReset => 'Сбросить';

  @override
  String get commonDone => 'Готово';

  @override
  String get colorBlue => 'Синий';

  @override
  String get colorIndigo => 'Индиго';

  @override
  String get colorViolet => 'Фиолетовый';

  @override
  String get colorTeal => 'Бирюзовый';

  @override
  String get colorGreen => 'Зелёный';

  @override
  String get colorAmber => 'Янтарный';

  @override
  String get colorRose => 'Розовый';

  @override
  String get colorSlate => 'Грифельный';

  @override
  String get generationStepPreparing => 'Читаю сообщение';

  @override
  String get generationStepWaiting => 'Жду ответа сервиса';

  @override
  String get generationStepWriting => 'Создаю дизайн';

  @override
  String get generationStepBuilding => 'Собираю страницы';

  @override
  String get generationCanvasBuilding => 'Собираю…';

  @override
  String generationPageProgress(int index, int total) {
    return 'Страница $index из $total';
  }

  @override
  String generationPageProgressUnknown(int index) {
    return 'Страница $index';
  }

  @override
  String get oauthConnect => 'Подключить';

  @override
  String get oauthConnecting => 'Подключение…';

  @override
  String oauthConnectedAs(String account) {
    return 'Вы вошли как $account';
  }

  @override
  String oauthBalance(String amount) {
    return 'Баланс $amount';
  }

  @override
  String get oauthDisconnect => 'Выйти';

  @override
  String get oauthLoginRequired => 'Сначала войдите, чтобы продолжить.';

  @override
  String get providerSubtitleOpencode => 'Бесплатные модели для кода';

  @override
  String get providerSubtitleOpenrouter => 'Много моделей, один ключ';

  @override
  String get providerSubtitleNvidia => 'Бесплатный аккаунт разработчика';

  @override
  String get providerSubtitleOllamaCloud => 'Работает в облаке';

  @override
  String get providerSubtitleGemini => 'Ключ из Google AI Studio';

  @override
  String get providerSubtitleCline => 'Вход через аккаунт';

  @override
  String get providerSubtitleCommandCode => 'Нужен платный план';

  @override
  String get providerSubtitleGroq => 'Быстрые ответы';

  @override
  String get providerSubtitleMinimax => 'Модели MiniMax';

  @override
  String get providerSubtitleMistral => 'Модели Mistral';

  @override
  String get providerSubtitleZai => 'Модели GLM';

  @override
  String get providerSubtitleKiro => 'Нужен локальный прокси';

  @override
  String get providerSubtitleCustom => 'Свой сервис';

  @override
  String get clineLoginTitle => 'Вход с аккаунтом Cline';

  @override
  String get clineLoginBody => 'Войдите в браузере — здесь всё обновится само.';

  @override
  String get clinePasteBody =>
      'Если браузер не вернулся, вставьте ссылку, которую он показал.';

  @override
  String get clineFieldLink => 'Ссылка для входа';

  @override
  String get clineFieldLinkHint => 'Вставьте ссылку из Cline';

  @override
  String get clineLinkInvalid =>
      'Ссылка не подходит. Скопируйте её из Cline заново.';

  @override
  String get providerDetailTestAccount => 'Проверить аккаунт';

  @override
  String get generationTitle => 'Создание дизайна';
}
