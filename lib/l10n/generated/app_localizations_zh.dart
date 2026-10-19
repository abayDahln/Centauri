// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Centauri — AI UI/UX 画布';

  @override
  String get languageTooltip => '语言';

  @override
  String get languageDialogTitle => '语言';

  @override
  String get commonAdd => '添加';

  @override
  String get commonRetry => '重试';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonDelete => '删除';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '关闭';

  @override
  String get commonActive => '已启用';

  @override
  String get commonSetActive => '设为启用';

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
  String get providerListSubtitle => '所有数据都保存在本机并加密。';

  @override
  String get providerListLoadFailed => '无法加载 Provider。';

  @override
  String get providerListEmptyTitle => '还没有 Provider';

  @override
  String get providerListEmptyBody => '添加 Provider 以开始使用 Centauri。';

  @override
  String get providerListAddProvider => '添加 Provider';

  @override
  String get providerDeleted => 'Provider 已删除';

  @override
  String get providerDetailPickProvider => '请先选择 Provider。';

  @override
  String get providerDetailPickModel => '请先选择 Model。';

  @override
  String providerDetailSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return '无法移除 API Key：$error';
  }

  @override
  String get providerDetailUpdated => 'Provider 已更新';

  @override
  String get providerDetailAdded => 'Provider 已添加';

  @override
  String get providerDetailTestOk => '连接正常。';

  @override
  String get providerDetailTitleEdit => '编辑 Provider';

  @override
  String get providerDetailTitleNew => '添加 Provider';

  @override
  String get providerDetailDeleteTooltip => '删除 Provider';

  @override
  String get providerDetailFieldName => '名称';

  @override
  String get providerDetailNameHint => '例如“OpenAI Pro”';

  @override
  String get providerDetailNameRequired => '请填写名称。';

  @override
  String get providerDetailPickProviderLabel => '选择 Provider';

  @override
  String get providerDetailFieldProviderName => 'Provider 名称';

  @override
  String get providerDetailProviderNameHint => '例如“OpenAI”';

  @override
  String get providerDetailProviderNameRequired => '请填写 Provider 名称。';

  @override
  String get providerDetailPickModelLabel => '选择 Model';

  @override
  String get providerDetailPickProviderFirst => '请先选择 Provider';

  @override
  String get providerDetailTestAction => '测试';

  @override
  String get providerDetailBaseUrlRequired => '请填写 Base URL。';

  @override
  String get providerDetailBaseUrlInvalid => '请输入有效的 URL（例如：https://...）。';

  @override
  String get providerDetailApiKeyFromProvider => '来自 Provider';

  @override
  String get providerDetailApiKeyStored => 'API Key 已保存。重置后可替换。';

  @override
  String get providerDetailApiKeyCleared => '保存后将移除 API Key。';

  @override
  String get providerDetailApiKeyOptional => '本地服务无需验证时可留空。';

  @override
  String get providerDetailReset => '重置';

  @override
  String get providerDeleteTargetFallback => '此 Provider';

  @override
  String get providerDeleteTitle => '删除此 Provider？';

  @override
  String providerDeleteBody(String target) {
    return '$target 及其保存的数据将被永久删除。';
  }

  @override
  String get modelCardDeleteTooltip => '删除 Model';

  @override
  String get modelCardCopyIdTooltip => '复制 Model ID';

  @override
  String modelCardCopied(String model) {
    return '已复制：$model';
  }

  @override
  String get modelPickerTitle => '选择 Model';

  @override
  String get modelPickerCustom => '自定义 Model';

  @override
  String get modelPickerAddModel => '添加 Model';

  @override
  String get modelPickerIdHint => '例如“gpt-4o”';

  @override
  String get providerPickerTitle => '选择 Provider';

  @override
  String get commonAllPages => '所有页面';

  @override
  String get canvasUntitledProject => '新原型';

  @override
  String get canvasHideHistory => '隐藏历史';

  @override
  String get canvasShowHistory => '显示历史';

  @override
  String get canvasHidePreview => '隐藏预览';

  @override
  String get canvasShowPreview => '显示预览';

  @override
  String get canvasUndoTooltip => '撤销 (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => '重做 (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个页面',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => '设计';

  @override
  String get canvasModeCode => '代码';

  @override
  String get canvasServiceSettings => '服务设置';

  @override
  String get canvasSelectionOff => '停止选择元素';

  @override
  String get canvasSelectionOn => '在画布上选择元素';

  @override
  String get canvasBreadcrumbFallback => '画布';

  @override
  String get canvasStopGenerating => '停止生成';

  @override
  String get canvasStopAction => '停止';

  @override
  String get canvasEmptyTitle => '还没有 UI';

  @override
  String get canvasEmptyBody => '输入消息即可开始。';

  @override
  String get canvasPrototypeTitle => '原型';

  @override
  String get canvasChatPanelTooltip => '对话与历史面板';

  @override
  String get storageFailedTitle => '无法打开本地存储。 ';

  @override
  String get storageFailedBody => '关闭另一个 Centauri 窗口后重试。';

  @override
  String get previewGenericError => '预览出现错误。';

  @override
  String previewLinkInvalid(String href) {
    return '链接无效：$href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return '无法打开：$href';
  }

  @override
  String previewPageNotFound(String href) {
    return '找不到页面：$href';
  }

  @override
  String get previewDeleteFailed => '无法删除组件。请重试。';

  @override
  String get previewLoading => '加载中…';

  @override
  String get previewNoPagesTitle => '还没有页面';

  @override
  String get previewNoPagesBody => '输入消息以创建页面。';

  @override
  String get previewLoadFailedTitle => '预览加载失败';

  @override
  String get previewWebView2Hint =>
      '如果仍然失败，请安装 Microsoft Edge WebView2 Runtime。';

  @override
  String get exportNoPages => '还没有可导出的页面。';

  @override
  String exportSaved(String path) {
    return '已保存：$path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Figma 数据（$count 个元素）已复制。';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Figma 数据（$count 个元素）已保存：$path';
  }

  @override
  String get exportFailed => '导出失败。请重试。';

  @override
  String get exportPageTooltip => '导出页面';

  @override
  String get exportPageTooltipCompact => '导出页面（PNG/SVG/PDF/Figma）';

  @override
  String get exportPng => 'PNG（图片）';

  @override
  String get exportSvg => 'SVG（矢量）';

  @override
  String get exportPdf => 'PDF（文档）';

  @override
  String get exportAction => '导出';

  @override
  String get codePanelCopied => 'HTML 已复制。';

  @override
  String get codePanelCopyTooltip => '复制 HTML';

  @override
  String get codePanelSaveTooltip => '保存为 .html';

  @override
  String get codePanelEmpty => '还没有代码。\n先创建 UI。';

  @override
  String get promptAnalyzeImage => '分析这张图片。';

  @override
  String promptUnsupportedFormat(String name) {
    return '不支持格式“$name”。';
  }

  @override
  String promptReadFailed(String name) {
    return '无法读取“$name”。';
  }

  @override
  String get promptPlaceholder => '输入消息…';

  @override
  String get promptAttachTooltip => '添加附件';

  @override
  String get promptStopTooltip => '停止生成';

  @override
  String get promptMentionPagesTooltip => '引用页面';

  @override
  String get attachmentImageFailed => '无法显示图片。';

  @override
  String get attachmentRemoveTooltip => '移除附件';

  @override
  String get chatWelcomeTitle => '从一条消息开始';

  @override
  String get chatWelcomeBody => '可以咨询设计建议，也可以直接让我来做。';

  @override
  String get chatTabChat => '对话';

  @override
  String get chatTabHistory => '历史';

  @override
  String get pageRenameTitle => '重命名页面';

  @override
  String get pageRenameHint => '页面名称';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n（双击重命名）';
  }

  @override
  String get markdownEmpty => '（空）';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowMaximize => '最大化';

  @override
  String get windowRestore => '还原';

  @override
  String get windowClose => '关闭';

  @override
  String get historyRenameTitle => '重命名';

  @override
  String get historyRenameHint => '对话名称';

  @override
  String get historyNewChat => '新对话';

  @override
  String get historySearchHint => '搜索对话';

  @override
  String get historyRecent => '最近';

  @override
  String get historyRenameTooltip => '重命名';

  @override
  String get historyEmptySearch => '没有匹配的对话。';

  @override
  String get historyEmptyList => '还没有保存的对话。';

  @override
  String get codeExportTitle => '导出代码';

  @override
  String codeExportCopied(String format) {
    return '已复制 $format 代码。';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个字符',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => '复制';

  @override
  String get codeExportDownload => '下载';

  @override
  String get codeExportNoticeHtml => '单个自包含 HTML 文件：CSS 与 JS 已内置，可离线使用。';

  @override
  String get codeExportNoticeReact => '近似转换。请把 <style> 内容移到 CSS 文件，使用前先检查。';

  @override
  String get codeExportNoticeFlutter =>
      '近似转换。只转换内联样式，<style> 中的 CSS 不会包含。使用前先检查。';

  @override
  String get codeExportNoticeTailwind =>
      '近似转换。需要 Tailwind v3.2+；请把 <style> 内容移到 CSS 文件。使用前先检查。';

  @override
  String get codeExportTransformErrorTitle => '代码转换失败';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Alpha 代码无法转换为 $format。';
  }

  @override
  String get codeExportUseHtml => '改用 HTML';

  @override
  String get codeExportEmptyTitle => '还没有可导出的 UI';

  @override
  String get codeExportEmptyBody => '先创建 UI。';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP 仅在桌面版运行。';

  @override
  String get mcpRunning => '运行中';

  @override
  String get mcpStopped => '已停止';

  @override
  String get mcpDescription => '让 AI agent（Claude Code、Cursor）实时查看和修改设计。';

  @override
  String get mcpStarting => '启动中…';

  @override
  String get mcpStart => '启动';

  @override
  String get mcpAutoStartNote => '打开应用后服务器会自动启动。';

  @override
  String get mcpCopyAddress => '复制';

  @override
  String get mcpAddressCopied => '地址已复制。';

  @override
  String get chatProcessing => '处理中…';

  @override
  String get chatUiReady => 'UI 已就绪';

  @override
  String get chatViewCode => '查看代码';

  @override
  String get chatHideCode => '隐藏';

  @override
  String get chatNoMessagesTitle => '还没有对话';

  @override
  String get chatNoMessagesBody => '输入消息即可开始。';

  @override
  String get commonGenericError => '出现错误。请重试。';

  @override
  String get canvasMentionElementFallback => '所选元素';

  @override
  String get canvasNoProvider => '没有启用的 Provider。请先添加。';

  @override
  String get canvasUntitledPage => '无标题';

  @override
  String get canvasGenerationStopped => '生成已停止。';

  @override
  String get promptAttachmentLimit => '每条消息最多 6 个附件。';

  @override
  String get providerNotFound => '找不到 Provider。';

  @override
  String get exportFigma => 'Figma';

  @override
  String get catalogSectionFreeTier => '免费额度';

  @override
  String get catalogSectionApiKey => 'API Key';
}
