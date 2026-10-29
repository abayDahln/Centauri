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
  String get commonUndo => '撤销';

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
  String get canvasHideChat => '隐藏聊天';

  @override
  String get canvasShowChat => '显示聊天';

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
  String get canvasShowCode => '显示代码';

  @override
  String get canvasHideCode => '隐藏代码';

  @override
  String get canvasLayoutDesktop => '桌面端';

  @override
  String get canvasLayoutMobile => '移动端';

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
  String get previewEditText => '编辑文字';

  @override
  String get previewEditWithAi => '用 AI 编辑';

  @override
  String get previewTextEditFailed => '无法保存文字。请重试。';

  @override
  String get previewComponentDeleted => '组件已删除';

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
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get mcpGuideOpen => '指南';

  @override
  String get mcpGuideTitle => 'MCP 指南';

  @override
  String get mcpGuideSubtitle => '将 AI 助手连接到本应用。';

  @override
  String get mcpGuideStepStart => '启动服务器';

  @override
  String get mcpGuideStepStartDesc => '应用打开期间自动运行。';

  @override
  String get mcpGuideEndpoint => '地址';

  @override
  String get mcpGuideStepConnect => '连接助手';

  @override
  String get mcpGuideStepConnectDesc => '选择助手，然后复制代码。';

  @override
  String mcpGuideWhere(String path) {
    return '文件：$path';
  }

  @override
  String get mcpGuideCopy => '复制代码';

  @override
  String get mcpGuideCopied => '代码已复制。';

  @override
  String get mcpGuideStepTest => '检查连接';

  @override
  String get mcpGuideStepTestDesc => '发送此请求，然后查看会话列表。';

  @override
  String get mcpGuideStepTools => '助手可以做什么';

  @override
  String get mcpGuideStepToolsDesc => '六个工具：先列表，再取详情。';

  @override
  String get mcpGuideTipTitle => '如果无法连接';

  @override
  String get mcpGuideTipAppClosed => '保持应用打开；关闭应用会停止服务器。';

  @override
  String get mcpGuideTipPort => '如果 8765 被占用，应用会改用 8766–8774。';

  @override
  String get mcpGuideTipLocal => '仅限本机。不要将此端口开放到网络。';

  @override
  String get mcpToolListSessions => '列出会话及数量。';

  @override
  String get mcpToolGetSession => '读取一个会话及其页面列表。';

  @override
  String get mcpToolGetPageHtml => '返回一个页面的完整 HTML。';

  @override
  String get mcpToolWritePage => '新建或替换页面。';

  @override
  String get mcpToolDeletePage => '删除页面。';

  @override
  String get mcpToolPostToChat => '把回复写入对话。';

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
  String chatStreamPage(int page) {
    return '正在写第 $page 页…';
  }

  @override
  String chatStreamPageOf(int page, int total) {
    return '正在写第 $page 页，共 $total 页…';
  }

  @override
  String get chatStreamFinishing => '正在准备页面…';

  @override
  String get commonGenericError => '出现错误。请重试。';

  @override
  String get canvasMentionElementFallback => '所选元素';

  @override
  String get canvasNoProvider => '没有启用的 Provider。请先添加。';

  @override
  String get canvasPagesTrimmed => '已移除多余页面，以符合你要求的数量。';

  @override
  String get canvasUntitledPage => '无标题';

  @override
  String get canvasGenerationStopped => '生成已停止。';

  @override
  String get promptAttachmentLimit => '每条消息最多 6 个附件。';

  @override
  String get providerNotFound => '找不到 Provider。';

  @override
  String get errorCancelled => '已取消。';

  @override
  String get errorApiTimeout => '连接超时。请检查地址或网络。';

  @override
  String get errorApiUnreachable => '无法连接。请检查地址。';

  @override
  String get errorApiUnauthorized => '访问密钥无效或没有权限。';

  @override
  String get errorApiRateLimited => '服务正在限制请求。请稍后再试。';

  @override
  String get errorApiInsufficientCredits => '账户余额不足。请充值后重试。';

  @override
  String get errorApiNotFound => '找不到地址或 Model。请检查两者。';

  @override
  String get errorApiRejected => '服务拒绝了请求。';

  @override
  String get errorApiCertificate => '服务器证书无效。请检查地址。';

  @override
  String get errorApiSendFailed => '无法发送请求。请检查网络和地址。';

  @override
  String get errorApiBadResponse => '回复格式不符。地址应以 /v1 结尾。';

  @override
  String get errorApiNoChatEndpoint => '此服务还没有聊天地址。';

  @override
  String get errorApiModelUnavailable => '此 Model 不可用。请换一个。';

  @override
  String get errorApiConnectionBroken => '连接中断。请重试。';

  @override
  String errorApiProviderReported(String detail) {
    return '服务消息：$detail';
  }

  @override
  String get errorGenerationTimeout => '生成已停止：耗时过长。请重试。';

  @override
  String get errorExportNotReady => '页面尚未就绪。请稍等。';

  @override
  String get errorExportTimeout => '导出超时。请重试。';

  @override
  String get errorExportNoElements => '还没有可导出的内容。';

  @override
  String get errorExportEmptyResult => '结果为空。请重试。';

  @override
  String get errorExportWriteFailed => '无法保存文件。请换个位置。';

  @override
  String get errorImportInvalidFile =>
      '此文件不是有效的 JSON。请选择 Centauri .mydesign 文件。';

  @override
  String get errorImportNotProject => '这不是 Centauri 项目文件。';

  @override
  String errorImportNewerVersion(String version) {
    return '此文件需要更新的 Centauri 版本（$version）。请先更新应用。';
  }

  @override
  String get errorImportEmpty => '此项目文件为空。';

  @override
  String errorImportEmptyFile(String name) {
    return '文件 $name 为空。';
  }

  @override
  String get errorImportUnusable => '无法读取此文件。请换一个文件。';

  @override
  String errorImportUnusableFile(String name) {
    return '无法读取文件 $name。请换一个文件。';
  }

  @override
  String get errorAttachmentEmpty => '文件为空。';

  @override
  String errorAttachmentEmptyFile(String name) {
    return '文件 $name 为空。';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return '文件太大（最大 $maxMb MB）。';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return '不支持此格式。请使用 $formats。';
  }

  @override
  String get errorStorageFailed => '无法访问此设备上的密钥。';

  @override
  String get errorTransformNoCode => '此页面还没有代码。';

  @override
  String get exportFigma => 'Figma';

  @override
  String get exportFigmaPlugin => 'Figma（插件）';

  @override
  String exportFigmaCopiedWidth(int width) {
    return '已按 $width px 复制，粘贴到 Figma。';
  }

  @override
  String get catalogSectionFreeTier => '免费额度';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => '外观';

  @override
  String get appearanceTitle => '外观';

  @override
  String get appearanceModeLabel => '模式';

  @override
  String get appearanceModeSystem => '跟随系统';

  @override
  String get appearanceModeLight => '浅色';

  @override
  String get appearanceModeDark => '深色';

  @override
  String get appearancePrimaryLabel => '主色';

  @override
  String get appearanceReset => '重置';

  @override
  String get commonDone => '完成';

  @override
  String get colorBlue => '蓝色';

  @override
  String get colorIndigo => '靛蓝';

  @override
  String get colorViolet => '紫色';

  @override
  String get colorTeal => '青色';

  @override
  String get colorGreen => '绿色';

  @override
  String get colorAmber => '琥珀色';

  @override
  String get colorRose => '玫瑰红';

  @override
  String get colorSlate => '石板灰';

  @override
  String get generationStepPreparing => '正在读取消息';

  @override
  String get generationStepWaiting => '等待服务响应';

  @override
  String get generationStepWriting => '正在撰写设计';

  @override
  String get generationStepBuilding => '正在构建页面';

  @override
  String get generationCanvasBuilding => '正在构建…';

  @override
  String generationPageProgress(int index, int total) {
    return '第 $index 页，共 $total 页';
  }

  @override
  String generationPageProgressUnknown(int index) {
    return '第 $index 页';
  }

  @override
  String get oauthConnect => '连接';

  @override
  String get oauthConnecting => '正在连接…';

  @override
  String oauthConnectedAs(String account) {
    return '已登录为 $account';
  }

  @override
  String oauthBalance(String amount) {
    return '余额 $amount';
  }

  @override
  String get oauthDisconnect => '退出登录';

  @override
  String get oauthLoginRequired => '请先登录再继续。';

  @override
  String get providerSubtitleOpencode => '免费编程模型';

  @override
  String get providerSubtitleOpenrouter => '多个模型，一个密钥';

  @override
  String get providerSubtitleNvidia => '免费开发者账号';

  @override
  String get providerSubtitleOllamaCloud => '云端运行';

  @override
  String get providerSubtitleGemini => 'Google AI Studio 密钥';

  @override
  String get providerSubtitleCline => '使用账号登录';

  @override
  String get providerSubtitleCommandCode => '需要付费套餐';

  @override
  String get providerSubtitleGroq => '回复更快';

  @override
  String get providerSubtitleMinimax => 'MiniMax 模型';

  @override
  String get providerSubtitleMistral => 'Mistral 模型';

  @override
  String get providerSubtitleZai => 'GLM 模型';

  @override
  String get providerSubtitleKiro => '需要本地代理';

  @override
  String get providerSubtitleCustom => '自有服务';

  @override
  String get clineLoginTitle => '使用 Cline 账户登录';

  @override
  String get clineLoginBody => '在浏览器中登录，完成后这里会自动更新。';

  @override
  String get clinePasteBody => '如果浏览器没有自动返回，请粘贴它显示的链接。';

  @override
  String get clineFieldLink => '登录链接';

  @override
  String get clineFieldLinkHint => '粘贴来自 Cline 的链接';

  @override
  String get clineLinkInvalid => '链接无效。请从 Cline 重新复制。';

  @override
  String get providerDetailTestAccount => '测试账户';

  @override
  String get generationTitle => '正在生成界面';
}
