// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Centauri — AI UI/UX キャンバス';

  @override
  String get languageTooltip => '言語';

  @override
  String get languageDialogTitle => '言語';

  @override
  String get commonAdd => '追加';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonEdit => '編集';

  @override
  String get commonDelete => '削除';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonActive => '有効';

  @override
  String get commonSetActive => '有効にする';

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
  String get providerListSubtitle => 'データはすべて端末内に暗号化して保存されます。';

  @override
  String get providerListLoadFailed => 'Provider を読み込めませんでした。';

  @override
  String get providerListEmptyTitle => 'Provider がありません';

  @override
  String get providerListEmptyBody => 'Provider を追加して Centauri を始めましょう。';

  @override
  String get providerListAddProvider => 'Provider を追加';

  @override
  String get providerDeleted => 'Provider を削除しました';

  @override
  String get providerDetailPickProvider => '先に Provider を選んでください。';

  @override
  String get providerDetailPickModel => '先に Model を選んでください。';

  @override
  String providerDetailSaveFailed(String error) {
    return '保存できませんでした: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'API Key を削除できませんでした: $error';
  }

  @override
  String get providerDetailUpdated => 'Provider を更新しました';

  @override
  String get providerDetailAdded => 'Provider を追加しました';

  @override
  String get providerDetailTestOk => '接続できました。';

  @override
  String get providerDetailTitleEdit => 'Provider を編集';

  @override
  String get providerDetailTitleNew => 'Provider を追加';

  @override
  String get providerDetailDeleteTooltip => 'Provider を削除';

  @override
  String get providerDetailFieldName => '名前';

  @override
  String get providerDetailNameHint => '例:「OpenAI Pro」';

  @override
  String get providerDetailNameRequired => '名前を入力してください。';

  @override
  String get providerDetailPickProviderLabel => 'Provider を選択';

  @override
  String get providerDetailFieldProviderName => 'Provider 名';

  @override
  String get providerDetailProviderNameHint => '例:「OpenAI」';

  @override
  String get providerDetailProviderNameRequired => 'Provider 名を入力してください。';

  @override
  String get providerDetailPickModelLabel => 'Model を選択';

  @override
  String get providerDetailPickProviderFirst => '先に Provider を選択';

  @override
  String get providerDetailTestAction => 'テスト';

  @override
  String get providerDetailBaseUrlRequired => 'Base URL を入力してください。';

  @override
  String get providerDetailBaseUrlInvalid =>
      '有効な URL を入力してください（例: https://...）。';

  @override
  String get providerDetailApiKeyFromProvider => 'Provider から取得';

  @override
  String get providerDetailApiKeyStored => 'API Key は保存済みです。リセットすると置き換えられます。';

  @override
  String get providerDetailApiKeyCleared => '保存すると API Key が削除されます。';

  @override
  String get providerDetailApiKeyOptional => '認証のないローカルサービスでは空欄にします。';

  @override
  String get providerDetailReset => 'リセット';

  @override
  String get providerDeleteTargetFallback => 'この Provider';

  @override
  String get providerDeleteTitle => 'この Provider を削除しますか？';

  @override
  String providerDeleteBody(String target) {
    return '$target と保存データが完全に削除されます。';
  }

  @override
  String get modelCardDeleteTooltip => 'Model を削除';

  @override
  String get modelCardCopyIdTooltip => 'Model ID をコピー';

  @override
  String modelCardCopied(String model) {
    return 'コピーしました: $model';
  }

  @override
  String get modelPickerTitle => 'Model を選択';

  @override
  String get modelPickerCustom => 'カスタム Model';

  @override
  String get modelPickerAddModel => 'Model を追加';

  @override
  String get modelPickerIdHint => '例:「gpt-4o」';

  @override
  String get providerPickerTitle => 'Provider を選択';

  @override
  String get commonAllPages => 'すべてのページ';

  @override
  String get canvasUntitledProject => '新しいプロトタイプ';

  @override
  String get canvasHideHistory => '履歴を隠す';

  @override
  String get canvasShowHistory => '履歴を表示';

  @override
  String get canvasHideChat => 'チャットを隠す';

  @override
  String get canvasShowChat => 'チャットを表示';

  @override
  String get canvasHidePreview => 'プレビューを隠す';

  @override
  String get canvasShowPreview => 'プレビューを表示';

  @override
  String get canvasUndoTooltip => '元に戻す (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'やり直す (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 画面',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'デザイン';

  @override
  String get canvasModeCode => 'コード';

  @override
  String get canvasShowCode => 'コードを表示';

  @override
  String get canvasHideCode => 'コードを隠す';

  @override
  String get canvasServiceSettings => 'サービス設定';

  @override
  String get canvasSelectionOff => '要素の選択を終了';

  @override
  String get canvasSelectionOn => 'キャンバスで要素を選択';

  @override
  String get canvasBreadcrumbFallback => 'キャンバス';

  @override
  String get canvasStopGenerating => '生成を停止';

  @override
  String get canvasStopAction => '停止';

  @override
  String get canvasEmptyTitle => 'UI はまだありません';

  @override
  String get canvasEmptyBody => 'メッセージを送って始めましょう。';

  @override
  String get canvasPrototypeTitle => 'プロトタイプ';

  @override
  String get canvasChatPanelTooltip => 'チャットと履歴のパネル';

  @override
  String get storageFailedTitle => 'ローカル保存を開けませんでした。 ';

  @override
  String get storageFailedBody => '他の Centauri を閉じて、もう一度お試しください。';

  @override
  String get previewGenericError => 'プレビューで問題が発生しました。';

  @override
  String previewLinkInvalid(String href) {
    return '無効なリンク: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return '開けませんでした: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'ページが見つかりません: $href';
  }

  @override
  String get previewDeleteFailed => 'コンポーネントを削除できませんでした。もう一度お試しください。';

  @override
  String get previewLoading => '読み込み中…';

  @override
  String get previewNoPagesTitle => 'ページはまだありません';

  @override
  String get previewNoPagesBody => 'メッセージを送ってページを作成しましょう。';

  @override
  String get previewLoadFailedTitle => 'プレビューを読み込めませんでした';

  @override
  String get previewWebView2Hint =>
      '解決しない場合は Microsoft Edge WebView2 Runtime をインストールしてください。';

  @override
  String get exportNoPages => '書き出せるページがまだありません。';

  @override
  String exportSaved(String path) {
    return '保存しました: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Figma データ（$count 個の要素）をコピーしました。';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Figma データ（$count 個の要素）を保存しました: $path';
  }

  @override
  String get exportFailed => '書き出しに失敗しました。もう一度お試しください。';

  @override
  String get exportPageTooltip => 'ページを書き出す';

  @override
  String get exportPageTooltipCompact => 'ページを書き出す（PNG/SVG/PDF/Figma）';

  @override
  String get exportPng => 'PNG（画像）';

  @override
  String get exportSvg => 'SVG（ベクター）';

  @override
  String get exportPdf => 'PDF（文書）';

  @override
  String get exportAction => '書き出す';

  @override
  String get codePanelCopied => 'HTML をコピーしました。';

  @override
  String get codePanelCopyTooltip => 'HTML をコピー';

  @override
  String get codePanelSaveTooltip => '.html として保存';

  @override
  String get codePanelEmpty => 'コードはまだありません。\n先に UI を作成してください。';

  @override
  String get promptAnalyzeImage => 'この画像を分析してください。';

  @override
  String promptUnsupportedFormat(String name) {
    return '「$name」は未対応の形式です。';
  }

  @override
  String promptReadFailed(String name) {
    return '「$name」を読み込めませんでした。';
  }

  @override
  String get promptPlaceholder => 'メッセージを入力…';

  @override
  String get promptAttachTooltip => 'ファイルを添付';

  @override
  String get promptStopTooltip => '生成を停止';

  @override
  String get promptMentionPagesTooltip => 'ページを指定';

  @override
  String get attachmentImageFailed => '画像を表示できませんでした。';

  @override
  String get attachmentRemoveTooltip => '添付を削除';

  @override
  String get chatWelcomeTitle => 'メッセージから始める';

  @override
  String get chatWelcomeBody => 'デザインの相談も、作成の依頼もできます。';

  @override
  String get chatTabChat => 'チャット';

  @override
  String get chatTabHistory => '履歴';

  @override
  String get pageRenameTitle => 'ページ名を変更';

  @override
  String get pageRenameHint => 'ページ名';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n（ダブルクリックで名前を変更）';
  }

  @override
  String get markdownEmpty => '（空）';

  @override
  String get windowMinimize => '最小化';

  @override
  String get windowMaximize => '最大化';

  @override
  String get windowRestore => '元に戻す';

  @override
  String get windowClose => '閉じる';

  @override
  String get historyRenameTitle => '名前を変更';

  @override
  String get historyRenameHint => 'チャット名';

  @override
  String get historyNewChat => '新しいチャット';

  @override
  String get historySearchHint => 'チャットを検索';

  @override
  String get historyRecent => '最近';

  @override
  String get historyRenameTooltip => '名前を変更';

  @override
  String get historyEmptySearch => '一致するチャットがありません。';

  @override
  String get historyEmptyList => '保存されたチャットはまだありません。';

  @override
  String get codeExportTitle => 'コードを書き出す';

  @override
  String codeExportCopied(String format) {
    return '$format のコードをコピーしました。';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 文字',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'コピー';

  @override
  String get codeExportDownload => 'ダウンロード';

  @override
  String get codeExportNoticeHtml =>
      '単一の HTML ファイルです。CSS と JS を内蔵し、オフラインでも動作します。';

  @override
  String get codeExportNoticeReact =>
      '近似変換です。<style> の中身を CSS ファイルに移し、使用前に確認してください。';

  @override
  String get codeExportNoticeFlutter =>
      '近似変換です。インラインスタイルのみ変換し、<style> の CSS は含まれません。使用前に確認してください。';

  @override
  String get codeExportNoticeTailwind =>
      '近似変換です。Tailwind v3.2+ が必要です。<style> の中身を CSS ファイルに移してください。使用前に確認してください。';

  @override
  String get codeExportTransformErrorTitle => 'コードを変換できませんでした';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Alpha のコードを $format に変換できませんでした。';
  }

  @override
  String get codeExportUseHtml => 'HTML を使う';

  @override
  String get codeExportEmptyTitle => '書き出せる UI がまだありません';

  @override
  String get codeExportEmptyBody => '先に UI を作成してください。';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP はデスクトップ版でのみ動作します。';

  @override
  String get mcpRunning => '実行中';

  @override
  String get mcpStopped => '停止中';

  @override
  String get mcpDescription =>
      'AI エージェント（Claude Code、Cursor）がデザインをリアルタイムで確認・編集できます。';

  @override
  String get mcpStarting => '起動中…';

  @override
  String get mcpStart => '起動';

  @override
  String get mcpAutoStartNote => 'アプリを開くとサーバーが自動で起動します。';

  @override
  String get mcpCopyAddress => 'コピー';

  @override
  String get mcpAddressCopied => 'アドレスをコピーしました。';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get chatProcessing => '処理中…';

  @override
  String get chatUiReady => 'UI の準備完了';

  @override
  String get chatViewCode => 'コードを見る';

  @override
  String get chatHideCode => '隠す';

  @override
  String get chatNoMessagesTitle => 'チャットはまだありません';

  @override
  String get chatNoMessagesBody => 'メッセージを送って始めましょう。';

  @override
  String get commonGenericError => '問題が発生しました。もう一度お試しください。';

  @override
  String get canvasMentionElementFallback => '選択中の要素';

  @override
  String get canvasNoProvider => '有効な Provider がありません。追加して始めてください。';

  @override
  String get canvasUntitledPage => '無題';

  @override
  String get canvasGenerationStopped => '生成を停止しました。';

  @override
  String get promptAttachmentLimit => '1 通につき最大 6 個の添付。';

  @override
  String get providerNotFound => 'Provider が見つかりません。';

  @override
  String get errorCancelled => 'キャンセルしました。';

  @override
  String get errorApiTimeout => '接続がタイムアウトしました。アドレスかネットワークを確認してください。';

  @override
  String get errorApiUnreachable => '接続できませんでした。アドレスを確認してください。';

  @override
  String get errorApiUnauthorized => 'アクセスキーが無効か、権限がありません。';

  @override
  String get errorApiRateLimited => 'サービスがリクエストを制限しています。しばらくしてからもう一度お試しください。';

  @override
  String get errorApiNotFound => 'アドレスまたは Model が見つかりません。両方を確認してください。';

  @override
  String get errorApiRejected => 'サービスがリクエストを拒否しました。';

  @override
  String get errorApiCertificate => 'サーバー証明書が無効です。アドレスを確認してください。';

  @override
  String get errorApiSendFailed => 'リクエストを送信できませんでした。接続とアドレスを確認してください。';

  @override
  String get errorApiBadResponse => '返信の形式が想定と違います。アドレスは /v1 で終わる必要があります。';

  @override
  String get errorApiNoChatEndpoint => 'このサービスにはまだチャット用アドレスがありません。';

  @override
  String get errorApiModelUnavailable => 'この Model は利用できません。別のものを選んでください。';

  @override
  String get errorApiConnectionBroken => '接続が切れました。もう一度お試しください。';

  @override
  String errorApiProviderReported(String detail) {
    return 'サービスからのメッセージ：$detail';
  }

  @override
  String get errorGenerationTimeout => '生成を停止しました。時間がかかりすぎています。もう一度お試しください。';

  @override
  String get errorExportNotReady => 'ページの準備ができていません。少しお待ちください。';

  @override
  String get errorExportTimeout => 'エクスポートがタイムアウトしました。もう一度お試しください。';

  @override
  String get errorExportNoElements => 'まだエクスポートできるものがありません。';

  @override
  String get errorExportEmptyResult => '結果が空でした。もう一度お試しください。';

  @override
  String get errorExportWriteFailed => 'ファイルを保存できませんでした。別の場所を選んでください。';

  @override
  String get errorImportInvalidFile =>
      'このファイルは有効な JSON ではありません。Centauri の .mydesign ファイルを選んでください。';

  @override
  String get errorImportNotProject => 'これは Centauri のプロジェクトファイルではありません。';

  @override
  String errorImportNewerVersion(String version) {
    return 'このファイルには新しい Centauri バージョン（$version）が必要です。先にアプリを更新してください。';
  }

  @override
  String get errorImportEmpty => 'このプロジェクトファイルは空です。';

  @override
  String errorImportEmptyFile(String name) {
    return 'ファイル $name は空です。';
  }

  @override
  String get errorImportUnusable => 'このファイルを読み取れません。別のファイルを選んでください。';

  @override
  String errorImportUnusableFile(String name) {
    return 'ファイル $name を読み取れません。別のファイルを選んでください。';
  }

  @override
  String get errorAttachmentEmpty => 'ファイルは空です。';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'ファイル $name は空です。';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'ファイルが大きすぎます（最大 $maxMb MB）。';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'この形式はサポートされていません。$formats を使用してください。';
  }

  @override
  String get errorStorageFailed => 'このデバイス上のキーにアクセスできませんでした。';

  @override
  String get errorTransformNoCode => 'このページにはまだコードがありません。';

  @override
  String get exportFigma => 'Figma';

  @override
  String get exportFigmaPlugin => 'Figma（プラグイン）';

  @override
  String exportFigmaCopiedWidth(int width) {
    return '$width px でコピーしました。Figma に貼り付けてください。';
  }

  @override
  String get catalogSectionFreeTier => '無料枠';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => '外観';

  @override
  String get appearanceTitle => '外観';

  @override
  String get appearanceModeLabel => 'モード';

  @override
  String get appearanceModeSystem => 'システム';

  @override
  String get appearanceModeLight => 'ライト';

  @override
  String get appearanceModeDark => 'ダーク';

  @override
  String get appearancePrimaryLabel => 'メインカラー';

  @override
  String get appearanceReset => 'リセット';

  @override
  String get commonDone => '完了';

  @override
  String get colorBlue => 'ブルー';

  @override
  String get colorIndigo => 'インディゴ';

  @override
  String get colorViolet => 'バイオレット';

  @override
  String get colorTeal => 'ティール';

  @override
  String get colorGreen => 'グリーン';

  @override
  String get colorAmber => 'アンバー';

  @override
  String get colorRose => 'ローズ';

  @override
  String get colorSlate => 'スレート';
}
