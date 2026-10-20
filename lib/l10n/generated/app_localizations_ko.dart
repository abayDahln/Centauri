// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Centauri — AI UI/UX 캔버스';

  @override
  String get languageTooltip => '언어';

  @override
  String get languageDialogTitle => '언어';

  @override
  String get commonAdd => '추가';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get commonEdit => '편집';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonCancel => '취소';

  @override
  String get commonSave => '저장';

  @override
  String get commonClose => '닫기';

  @override
  String get commonActive => '사용 중';

  @override
  String get commonSetActive => '사용하기';

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
  String get providerListSubtitle => '모든 데이터는 기기에 암호화되어 저장돼요.';

  @override
  String get providerListLoadFailed => 'Provider를 불러오지 못했어요.';

  @override
  String get providerListEmptyTitle => 'Provider가 없어요';

  @override
  String get providerListEmptyBody => 'Provider를 추가하고 Centauri를 시작해 보세요.';

  @override
  String get providerListAddProvider => 'Provider 추가';

  @override
  String get providerDeleted => 'Provider를 삭제했어요';

  @override
  String get providerDetailPickProvider => '먼저 Provider를 선택해 주세요.';

  @override
  String get providerDetailPickModel => '먼저 Model을 선택해 주세요.';

  @override
  String providerDetailSaveFailed(String error) {
    return '저장하지 못했어요: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'API Key를 삭제하지 못했어요: $error';
  }

  @override
  String get providerDetailUpdated => 'Provider를 업데이트했어요';

  @override
  String get providerDetailAdded => 'Provider를 추가했어요';

  @override
  String get providerDetailTestOk => '연결되었어요.';

  @override
  String get providerDetailTitleEdit => 'Provider 편집';

  @override
  String get providerDetailTitleNew => 'Provider 추가';

  @override
  String get providerDetailDeleteTooltip => 'Provider 삭제';

  @override
  String get providerDetailFieldName => '이름';

  @override
  String get providerDetailNameHint => '예: \"OpenAI Pro\"';

  @override
  String get providerDetailNameRequired => '이름을 입력해 주세요.';

  @override
  String get providerDetailPickProviderLabel => 'Provider 선택';

  @override
  String get providerDetailFieldProviderName => 'Provider 이름';

  @override
  String get providerDetailProviderNameHint => '예: \"OpenAI\"';

  @override
  String get providerDetailProviderNameRequired => 'Provider 이름을 입력해 주세요.';

  @override
  String get providerDetailPickModelLabel => 'Model 선택';

  @override
  String get providerDetailPickProviderFirst => '먼저 Provider 선택';

  @override
  String get providerDetailTestAction => '테스트';

  @override
  String get providerDetailBaseUrlRequired => 'Base URL을 입력해 주세요.';

  @override
  String get providerDetailBaseUrlInvalid =>
      '올바른 URL을 입력해 주세요(예: https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'Provider에서 가져옴';

  @override
  String get providerDetailApiKeyStored => 'API Key가 저장되어 있어요. 재설정하면 교체됩니다.';

  @override
  String get providerDetailApiKeyCleared => '저장하면 API Key가 삭제됩니다.';

  @override
  String get providerDetailApiKeyOptional => '인증이 없는 로컬 서비스는 비워 두세요.';

  @override
  String get providerDetailReset => '재설정';

  @override
  String get providerDeleteTargetFallback => '이 Provider';

  @override
  String get providerDeleteTitle => '이 Provider를 삭제할까요?';

  @override
  String providerDeleteBody(String target) {
    return '$target와 저장된 데이터가 영구 삭제됩니다.';
  }

  @override
  String get modelCardDeleteTooltip => 'Model 삭제';

  @override
  String get modelCardCopyIdTooltip => 'Model ID 복사';

  @override
  String modelCardCopied(String model) {
    return '복사했어요: $model';
  }

  @override
  String get modelPickerTitle => 'Model 선택';

  @override
  String get modelPickerCustom => '사용자 Model';

  @override
  String get modelPickerAddModel => 'Model 추가';

  @override
  String get modelPickerIdHint => '예: \"gpt-4o\"';

  @override
  String get providerPickerTitle => 'Provider 선택';

  @override
  String get commonAllPages => '모든 페이지';

  @override
  String get canvasUntitledProject => '새 프로토타입';

  @override
  String get canvasHideHistory => '기록 숨기기';

  @override
  String get canvasShowHistory => '기록 보기';

  @override
  String get canvasHideChat => '채팅 숨기기';

  @override
  String get canvasShowChat => '채팅 보기';

  @override
  String get canvasHidePreview => '미리보기 숨기기';

  @override
  String get canvasShowPreview => '미리보기 보기';

  @override
  String get canvasUndoTooltip => '실행 취소 (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => '다시 실행 (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 화면',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => '디자인';

  @override
  String get canvasModeCode => '코드';

  @override
  String get canvasShowCode => '코드 보기';

  @override
  String get canvasHideCode => '코드 숨기기';

  @override
  String get canvasServiceSettings => '서비스 설정';

  @override
  String get canvasSelectionOff => '요소 선택 끄기';

  @override
  String get canvasSelectionOn => '캔버스에서 요소 선택';

  @override
  String get canvasBreadcrumbFallback => '캔버스';

  @override
  String get canvasStopGenerating => '생성 중지';

  @override
  String get canvasStopAction => '중지';

  @override
  String get canvasEmptyTitle => '아직 UI가 없어요';

  @override
  String get canvasEmptyBody => '메시지를 보내 시작해 보세요.';

  @override
  String get canvasPrototypeTitle => '프로토타입';

  @override
  String get canvasChatPanelTooltip => '채팅 및 기록 패널';

  @override
  String get storageFailedTitle => '로컬 저장소를 열지 못했어요. ';

  @override
  String get storageFailedBody => '다른 Centauri 창을 닫고 다시 시도해 주세요.';

  @override
  String get previewGenericError => '미리보기에서 문제가 발생했어요.';

  @override
  String previewLinkInvalid(String href) {
    return '잘못된 링크: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return '열지 못했어요: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return '페이지를 찾을 수 없어요: $href';
  }

  @override
  String get previewDeleteFailed => '구성 요소를 삭제하지 못했어요. 다시 시도해 주세요.';

  @override
  String get previewLoading => '불러오는 중…';

  @override
  String get previewNoPagesTitle => '아직 페이지가 없어요';

  @override
  String get previewNoPagesBody => '메시지를 보내 페이지를 만들어 보세요.';

  @override
  String get previewLoadFailedTitle => '미리보기를 불러오지 못했어요';

  @override
  String get previewWebView2Hint =>
      '계속 실패하면 Microsoft Edge WebView2 Runtime을 설치해 주세요.';

  @override
  String get exportNoPages => '내보낼 페이지가 아직 없어요.';

  @override
  String exportSaved(String path) {
    return '저장했어요: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Figma 데이터($count개 요소)를 복사했어요.';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Figma 데이터($count개 요소)를 저장했어요: $path';
  }

  @override
  String get exportFailed => '내보내지 못했어요. 다시 시도해 주세요.';

  @override
  String get exportPageTooltip => '페이지 내보내기';

  @override
  String get exportPageTooltipCompact => '페이지 내보내기 (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG(이미지)';

  @override
  String get exportSvg => 'SVG(벡터)';

  @override
  String get exportPdf => 'PDF(문서)';

  @override
  String get exportAction => '내보내기';

  @override
  String get codePanelCopied => 'HTML을 복사했어요.';

  @override
  String get codePanelCopyTooltip => 'HTML 복사';

  @override
  String get codePanelSaveTooltip => '.html로 저장';

  @override
  String get codePanelEmpty => '아직 코드가 없어요.\n먼저 UI를 만들어 주세요.';

  @override
  String get promptAnalyzeImage => '이 이미지를 분석해 주세요.';

  @override
  String promptUnsupportedFormat(String name) {
    return '\"$name\" 형식은 지원하지 않아요.';
  }

  @override
  String promptReadFailed(String name) {
    return '\"$name\"을(를) 읽지 못했어요.';
  }

  @override
  String get promptPlaceholder => '메시지를 입력하세요…';

  @override
  String get promptAttachTooltip => '파일 첨부';

  @override
  String get promptStopTooltip => '생성 중지';

  @override
  String get promptMentionPagesTooltip => '페이지 언급';

  @override
  String get attachmentImageFailed => '이미지를 표시하지 못했어요.';

  @override
  String get attachmentRemoveTooltip => '첨부 삭제';

  @override
  String get chatWelcomeTitle => '메시지로 시작하기';

  @override
  String get chatWelcomeBody => '디자인 조언을 묻거나 바로 만들어 달라고 해보세요.';

  @override
  String get chatTabChat => '채팅';

  @override
  String get chatTabHistory => '기록';

  @override
  String get pageRenameTitle => '페이지 이름 변경';

  @override
  String get pageRenameHint => '페이지 이름';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(두 번 클릭해 이름 변경)';
  }

  @override
  String get markdownEmpty => '(비어 있음)';

  @override
  String get windowMinimize => '최소화';

  @override
  String get windowMaximize => '최대화';

  @override
  String get windowRestore => '복원';

  @override
  String get windowClose => '닫기';

  @override
  String get historyRenameTitle => '이름 변경';

  @override
  String get historyRenameHint => '채팅 이름';

  @override
  String get historyNewChat => '새 채팅';

  @override
  String get historySearchHint => '채팅 검색';

  @override
  String get historyRecent => '최근';

  @override
  String get historyRenameTooltip => '이름 변경';

  @override
  String get historyEmptySearch => '일치하는 채팅이 없어요.';

  @override
  String get historyEmptyList => '저장된 채팅이 아직 없어요.';

  @override
  String get codeExportTitle => '코드 내보내기';

  @override
  String codeExportCopied(String format) {
    return '$format 코드를 복사했어요.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count자',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => '복사';

  @override
  String get codeExportDownload => '다운로드';

  @override
  String get codeExportNoticeHtml =>
      '단일 HTML 파일이에요. CSS와 JS가 포함되어 오프라인에서도 동작해요.';

  @override
  String get codeExportNoticeReact =>
      '근사 변환이에요. <style> 내용을 CSS 파일로 옮기고 사용 전에 확인해 주세요.';

  @override
  String get codeExportNoticeFlutter =>
      '근사 변환이에요. 인라인 스타일만 변환하며 <style>의 CSS는 포함되지 않아요. 사용 전에 확인해 주세요.';

  @override
  String get codeExportNoticeTailwind =>
      '근사 변환이에요. Tailwind v3.2+가 필요해요. <style> 내용을 CSS 파일로 옮기고 사용 전에 확인해 주세요.';

  @override
  String get codeExportTransformErrorTitle => '코드를 변환하지 못했어요';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Alpha 코드를 $format(으)로 변환하지 못했어요.';
  }

  @override
  String get codeExportUseHtml => 'HTML 사용';

  @override
  String get codeExportEmptyTitle => '내보낼 UI가 아직 없어요';

  @override
  String get codeExportEmptyBody => '먼저 UI를 만들어 주세요.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'MCP는 데스크톱에서만 실행돼요.';

  @override
  String get mcpRunning => '실행 중';

  @override
  String get mcpStopped => '중지됨';

  @override
  String get mcpDescription =>
      'AI 에이전트(Claude Code, Cursor)가 디자인을 실시간으로 확인하고 편집해요.';

  @override
  String get mcpStarting => '시작 중…';

  @override
  String get mcpStart => '시작';

  @override
  String get mcpAutoStartNote => '앱을 열면 서버가 자동으로 시작돼요.';

  @override
  String get mcpCopyAddress => '복사';

  @override
  String get mcpAddressCopied => '주소를 복사했어요.';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get chatProcessing => '처리 중…';

  @override
  String get chatUiReady => 'UI 준비 완료';

  @override
  String get chatViewCode => '코드 보기';

  @override
  String get chatHideCode => '숨기기';

  @override
  String get chatNoMessagesTitle => '아직 대화가 없어요';

  @override
  String get chatNoMessagesBody => '메시지를 보내 시작해 보세요.';

  @override
  String get commonGenericError => '문제가 발생했어요. 다시 시도해 주세요.';

  @override
  String get canvasMentionElementFallback => '선택한 요소';

  @override
  String get canvasNoProvider => '사용 중인 Provider가 없어요. 추가하고 시작해 보세요.';

  @override
  String get canvasUntitledPage => '제목 없음';

  @override
  String get canvasGenerationStopped => '생성을 중지했어요.';

  @override
  String get promptAttachmentLimit => '메시지당 최대 첨부 6개.';

  @override
  String get providerNotFound => 'Provider를 찾을 수 없어요.';

  @override
  String get errorCancelled => '취소했어요.';

  @override
  String get errorApiTimeout => '연결 시간이 초과됐어요. 주소나 네트워크를 확인해 주세요.';

  @override
  String get errorApiUnreachable => '연결하지 못했어요. 주소를 확인해 주세요.';

  @override
  String get errorApiUnauthorized => '액세스 키가 유효하지 않거나 권한이 없어요.';

  @override
  String get errorApiRateLimited => '서비스가 요청을 제한하고 있어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get errorApiNotFound => '주소나 Model을 찾을 수 없어요. 둘 다 확인해 주세요.';

  @override
  String get errorApiRejected => '서비스가 요청을 거부했어요.';

  @override
  String get errorApiCertificate => '서버 인증서가 유효하지 않아요. 주소를 확인해 주세요.';

  @override
  String get errorApiSendFailed => '요청을 보내지 못했어요. 연결과 주소를 확인해 주세요.';

  @override
  String get errorApiBadResponse => '응답 형식이 예상과 달라요. 주소는 /v1로 끝나야 해요.';

  @override
  String get errorApiNoChatEndpoint => '이 서비스에는 아직 채팅 주소가 없어요.';

  @override
  String get errorApiModelUnavailable =>
      '이 Model은 여기에서 사용할 수 없어요. 다른 것을 선택해 주세요.';

  @override
  String get errorApiConnectionBroken => '연결이 끊겼어요. 다시 시도해 주세요.';

  @override
  String errorApiProviderReported(String detail) {
    return '서비스 메시지: $detail';
  }

  @override
  String get errorGenerationTimeout => '생성이 중단됐어요. 시간이 너무 오래 걸렸어요. 다시 시도해 주세요.';

  @override
  String get errorExportNotReady => '페이지가 아직 준비되지 않았어요. 잠시 기다려 주세요.';

  @override
  String get errorExportTimeout => '내보내기 시간이 초과됐어요. 다시 시도해 주세요.';

  @override
  String get errorExportNoElements => '아직 내보낼 것이 없어요.';

  @override
  String get errorExportEmptyResult => '결과가 비어 있어요. 다시 시도해 주세요.';

  @override
  String get errorExportWriteFailed => '파일을 저장하지 못했어요. 다른 위치를 선택해 주세요.';

  @override
  String get errorImportInvalidFile =>
      '이 파일은 올바른 JSON이 아니에요. Centauri .mydesign 파일을 선택해 주세요.';

  @override
  String get errorImportNotProject => 'Centauri 프로젝트 파일이 아니에요.';

  @override
  String errorImportNewerVersion(String version) {
    return '이 파일은 더 새로운 Centauri 버전($version)이 필요해요. 먼저 앱을 업데이트해 주세요.';
  }

  @override
  String get errorImportEmpty => '이 프로젝트 파일은 비어 있어요.';

  @override
  String errorImportEmptyFile(String name) {
    return '$name 파일이 비어 있어요.';
  }

  @override
  String get errorImportUnusable => '이 파일을 읽을 수 없어요. 다른 파일을 선택해 주세요.';

  @override
  String errorImportUnusableFile(String name) {
    return '$name 파일을 읽을 수 없어요. 다른 파일을 선택해 주세요.';
  }

  @override
  String get errorAttachmentEmpty => '파일이 비어 있어요.';

  @override
  String errorAttachmentEmptyFile(String name) {
    return '$name 파일이 비어 있어요.';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return '파일이 너무 커요(최대 $maxMb MB).';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return '지원하지 않는 형식이에요. 사용 가능한 형식: $formats.';
  }

  @override
  String get errorStorageFailed => '이 기기의 키에 접근하지 못했어요.';

  @override
  String get errorTransformNoCode => '이 페이지에는 아직 코드가 없어요.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get catalogSectionFreeTier => '무료 요금제';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => '모양';

  @override
  String get appearanceTitle => '모양';

  @override
  String get appearanceModeLabel => '모드';

  @override
  String get appearanceModeSystem => '시스템';

  @override
  String get appearanceModeLight => '라이트';

  @override
  String get appearanceModeDark => '다크';

  @override
  String get appearancePrimaryLabel => '기본 색상';

  @override
  String get appearanceReset => '초기화';

  @override
  String get commonDone => '완료';

  @override
  String get colorBlue => '파랑';

  @override
  String get colorIndigo => '인디고';

  @override
  String get colorViolet => '보라';

  @override
  String get colorTeal => '청록';

  @override
  String get colorGreen => '초록';

  @override
  String get colorAmber => '앰버';

  @override
  String get colorRose => '장미색';

  @override
  String get colorSlate => '슬레이트';
}
