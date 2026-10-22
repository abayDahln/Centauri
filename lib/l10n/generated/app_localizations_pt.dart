// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Centauri — Canvas de UI/UX com IA';

  @override
  String get languageTooltip => 'Idioma';

  @override
  String get languageDialogTitle => 'Idioma';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonRetry => 'Tentar novamente';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonUndo => 'Desfazer';

  @override
  String get commonActive => 'Ativo';

  @override
  String get commonSetActive => 'Ativar';

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
      'Todos os dados ficam armazenados e criptografados no seu dispositivo.';

  @override
  String get providerListLoadFailed => 'Não foi possível carregar os Provider.';

  @override
  String get providerListEmptyTitle => 'Nenhum Provider ainda';

  @override
  String get providerListEmptyBody =>
      'Adicione um Provider para começar a usar o Centauri.';

  @override
  String get providerListAddProvider => 'Adicionar Provider';

  @override
  String get providerDeleted => 'Provider excluído';

  @override
  String get providerDetailPickProvider => 'Escolha um Provider primeiro.';

  @override
  String get providerDetailPickModel => 'Escolha um Model primeiro.';

  @override
  String providerDetailSaveFailed(String error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String providerDetailClearKeyFailed(String error) {
    return 'Não foi possível remover a API Key: $error';
  }

  @override
  String get providerDetailUpdated => 'Provider atualizado';

  @override
  String get providerDetailAdded => 'Provider adicionado';

  @override
  String get providerDetailTestOk => 'A conexão funciona.';

  @override
  String get providerDetailTitleEdit => 'Editar Provider';

  @override
  String get providerDetailTitleNew => 'Adicionar Provider';

  @override
  String get providerDetailDeleteTooltip => 'Excluir Provider';

  @override
  String get providerDetailFieldName => 'Nome';

  @override
  String get providerDetailNameHint => 'ex.: \"OpenAI Pro\"';

  @override
  String get providerDetailNameRequired => 'O nome é obrigatório.';

  @override
  String get providerDetailPickProviderLabel => 'Escolher Provider';

  @override
  String get providerDetailFieldProviderName => 'Nome do Provider';

  @override
  String get providerDetailProviderNameHint => 'ex.: \"OpenAI\"';

  @override
  String get providerDetailProviderNameRequired =>
      'O nome do Provider é obrigatório.';

  @override
  String get providerDetailPickModelLabel => 'Escolher Model';

  @override
  String get providerDetailPickProviderFirst => 'Escolha um Provider primeiro';

  @override
  String get providerDetailTestAction => 'Testar';

  @override
  String get providerDetailBaseUrlRequired => 'A Base URL é obrigatória.';

  @override
  String get providerDetailBaseUrlInvalid =>
      'Digite uma URL válida (exemplo: https://...).';

  @override
  String get providerDetailApiKeyFromProvider => 'Do Provider';

  @override
  String get providerDetailApiKeyStored =>
      'API Key salva. Redefina para substituir.';

  @override
  String get providerDetailApiKeyCleared =>
      'A API Key será removida ao salvar.';

  @override
  String get providerDetailApiKeyOptional =>
      'Deixe vazio para um serviço local sem autenticação.';

  @override
  String get providerDetailReset => 'Redefinir';

  @override
  String get providerDeleteTargetFallback => 'este Provider';

  @override
  String get providerDeleteTitle => 'Excluir este Provider?';

  @override
  String providerDeleteBody(String target) {
    return '$target e os dados salvos serão excluídos permanentemente.';
  }

  @override
  String get modelCardDeleteTooltip => 'Excluir Model';

  @override
  String get modelCardCopyIdTooltip => 'Copiar ID do Model';

  @override
  String modelCardCopied(String model) {
    return 'Copiado: $model';
  }

  @override
  String get modelPickerTitle => 'Escolher Model';

  @override
  String get modelPickerCustom => 'Model personalizado';

  @override
  String get modelPickerAddModel => 'Adicionar Model';

  @override
  String get modelPickerIdHint => 'ex.: \"gpt-4o\"';

  @override
  String get providerPickerTitle => 'Escolher Provider';

  @override
  String get commonAllPages => 'Todas as páginas';

  @override
  String get canvasUntitledProject => 'Novo protótipo';

  @override
  String get canvasHideHistory => 'Ocultar histórico';

  @override
  String get canvasShowHistory => 'Mostrar histórico';

  @override
  String get canvasHideChat => 'Ocultar chat';

  @override
  String get canvasShowChat => 'Mostrar chat';

  @override
  String get canvasHidePreview => 'Ocultar prévia';

  @override
  String get canvasShowPreview => 'Mostrar prévia';

  @override
  String get canvasUndoTooltip => 'Desfazer (Ctrl+Z)';

  @override
  String get canvasRedoTooltip => 'Refazer (Ctrl+Y)';

  @override
  String canvasPageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count telas',
      one: '1 tela',
    );
    return '$_temp0';
  }

  @override
  String get canvasModeDesign => 'Design';

  @override
  String get canvasModeCode => 'Código';

  @override
  String get canvasShowCode => 'Mostrar código';

  @override
  String get canvasHideCode => 'Ocultar código';

  @override
  String get canvasServiceSettings => 'Configurações do serviço';

  @override
  String get canvasSelectionOff => 'Parar de selecionar elementos';

  @override
  String get canvasSelectionOn => 'Selecione um elemento na tela';

  @override
  String get canvasBreadcrumbFallback => 'tela';

  @override
  String get canvasStopGenerating => 'Parar geração';

  @override
  String get canvasStopAction => 'Parar';

  @override
  String get canvasEmptyTitle => 'Nenhuma UI ainda';

  @override
  String get canvasEmptyBody => 'Digite uma mensagem para começar.';

  @override
  String get canvasPrototypeTitle => 'Protótipo';

  @override
  String get canvasChatPanelTooltip => 'Painel de chat e histórico';

  @override
  String get storageFailedTitle =>
      'Não foi possível abrir o armazenamento local. ';

  @override
  String get storageFailedBody =>
      'Feche a outra janela do Centauri e tente novamente.';

  @override
  String get previewGenericError => 'Algo deu errado na prévia.';

  @override
  String previewLinkInvalid(String href) {
    return 'Link inválido: $href';
  }

  @override
  String previewLinkOpenFailed(String href) {
    return 'Não foi possível abrir: $href';
  }

  @override
  String previewPageNotFound(String href) {
    return 'Página não encontrada: $href';
  }

  @override
  String get previewDeleteFailed =>
      'Não foi possível excluir o componente. Tente novamente.';

  @override
  String get previewEditText => 'Editar texto';

  @override
  String get previewEditWithAi => 'Editar com IA';

  @override
  String get previewTextEditFailed =>
      'Não foi possível salvar o texto. Tente novamente.';

  @override
  String get previewComponentDeleted => 'Componente excluído';

  @override
  String get previewLoading => 'Carregando…';

  @override
  String get previewNoPagesTitle => 'Nenhuma página ainda';

  @override
  String get previewNoPagesBody => 'Digite uma mensagem para criar uma página.';

  @override
  String get previewLoadFailedTitle => 'Falha ao carregar a prévia';

  @override
  String get previewWebView2Hint =>
      'Se continuar falhando, instale o Microsoft Edge WebView2 Runtime.';

  @override
  String get exportNoPages => 'Nenhuma página para exportar ainda.';

  @override
  String exportSaved(String path) {
    return 'Salvo: $path';
  }

  @override
  String exportFigmaCopied(int count) {
    return 'Dados do Figma ($count elementos) copiados.';
  }

  @override
  String exportFigmaSaved(int count, String path) {
    return 'Dados do Figma ($count elementos) salvos: $path';
  }

  @override
  String get exportFailed => 'Falha na exportação. Tente novamente.';

  @override
  String get exportPageTooltip => 'Exportar página';

  @override
  String get exportPageTooltipCompact => 'Exportar página (PNG/SVG/PDF/Figma)';

  @override
  String get exportPng => 'PNG (imagem)';

  @override
  String get exportSvg => 'SVG (vetor)';

  @override
  String get exportPdf => 'PDF (documento)';

  @override
  String get exportAction => 'Exportar';

  @override
  String get codePanelCopied => 'HTML copiado.';

  @override
  String get codePanelCopyTooltip => 'Copiar HTML';

  @override
  String get codePanelSaveTooltip => 'Salvar como .html';

  @override
  String get codePanelEmpty => 'Nenhum código ainda.\nCrie uma UI primeiro.';

  @override
  String get promptAnalyzeImage => 'Analise esta imagem.';

  @override
  String promptUnsupportedFormat(String name) {
    return 'Formato não suportado: \"$name\".';
  }

  @override
  String promptReadFailed(String name) {
    return 'Não foi possível ler \"$name\".';
  }

  @override
  String get promptPlaceholder => 'Digite uma mensagem…';

  @override
  String get promptAttachTooltip => 'Anexar arquivo';

  @override
  String get promptStopTooltip => 'Parar geração';

  @override
  String get promptMentionPagesTooltip => 'Mencionar página';

  @override
  String get attachmentImageFailed => 'Não foi possível exibir a imagem.';

  @override
  String get attachmentRemoveTooltip => 'Remover anexo';

  @override
  String get chatWelcomeTitle => 'Comece com uma mensagem';

  @override
  String get chatWelcomeBody =>
      'Peça dicas de design ou peça para criar direto.';

  @override
  String get chatTabChat => 'Chat';

  @override
  String get chatTabHistory => 'Histórico';

  @override
  String get pageRenameTitle => 'Renomear página';

  @override
  String get pageRenameHint => 'Nome da página';

  @override
  String pageSlugTooltip(String slug) {
    return '$slug\n(clique duas vezes para renomear)';
  }

  @override
  String get markdownEmpty => '(vazio)';

  @override
  String get windowMinimize => 'Minimizar';

  @override
  String get windowMaximize => 'Maximizar';

  @override
  String get windowRestore => 'Restaurar';

  @override
  String get windowClose => 'Fechar';

  @override
  String get historyRenameTitle => 'Renomear';

  @override
  String get historyRenameHint => 'Nome do chat';

  @override
  String get historyNewChat => 'Novo chat';

  @override
  String get historySearchHint => 'Buscar chats';

  @override
  String get historyRecent => 'Recentes';

  @override
  String get historyRenameTooltip => 'Renomear';

  @override
  String get historyEmptySearch => 'Nenhum chat correspondente.';

  @override
  String get historyEmptyList => 'Nenhum chat salvo ainda.';

  @override
  String get codeExportTitle => 'Exportar código';

  @override
  String codeExportCopied(String format) {
    return 'Código $format copiado.';
  }

  @override
  String codeExportCharCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres',
      one: '1 caractere',
    );
    return '$_temp0';
  }

  @override
  String get codeExportCopy => 'Copiar';

  @override
  String get codeExportDownload => 'Baixar';

  @override
  String get codeExportNoticeHtml =>
      'Um único arquivo HTML independente: CSS e JS incluídos, funciona offline.';

  @override
  String get codeExportNoticeReact =>
      'Conversão aproximada. Mova o conteúdo de <style> para um arquivo CSS e verifique antes de usar.';

  @override
  String get codeExportNoticeFlutter =>
      'Conversão aproximada. Só estilos inline são traduzidos; o CSS de <style> fica de fora. Verifique antes de usar.';

  @override
  String get codeExportNoticeTailwind =>
      'Conversão aproximada. Requer Tailwind v3.2+; mova o conteúdo de <style> para um arquivo CSS. Verifique antes de usar.';

  @override
  String get codeExportTransformErrorTitle => 'Falha ao converter o código';

  @override
  String codeExportTransformErrorFallback(String format) {
    return 'Não foi possível converter o código do Alpha em $format.';
  }

  @override
  String get codeExportUseHtml => 'Usar HTML';

  @override
  String get codeExportEmptyTitle => 'Nenhuma UI para exportar ainda';

  @override
  String get codeExportEmptyBody => 'Crie uma UI primeiro.';

  @override
  String get mcpDesktopTitle => 'MCP Server (Desktop)';

  @override
  String get mcpDesktopOnlyDesc => 'O MCP só funciona no Desktop.';

  @override
  String get mcpRunning => 'Em execução';

  @override
  String get mcpStopped => 'Parado';

  @override
  String get mcpDescription =>
      'Ponte para agentes de IA (Claude Code, Cursor) verem e editarem designs ao vivo.';

  @override
  String get mcpStarting => 'Iniciando…';

  @override
  String get mcpStart => 'Iniciar';

  @override
  String get mcpAutoStartNote =>
      'O servidor inicia automaticamente ao abrir o app.';

  @override
  String get mcpCopyAddress => 'Copiar';

  @override
  String get mcpAddressCopied => 'Endereço copiado.';

  @override
  String mcpToolsList(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get mcpGuideOpen => 'Guia';

  @override
  String get mcpGuideTitle => 'Guia do MCP';

  @override
  String get mcpGuideSubtitle => 'Conecte um agente de IA a este app.';

  @override
  String get mcpGuideStepStart => 'Iniciar servidor';

  @override
  String get mcpGuideStepStartDesc => 'Funciona enquanto o app estiver aberto.';

  @override
  String get mcpGuideEndpoint => 'Endereço';

  @override
  String get mcpGuideStepConnect => 'Conectar agente';

  @override
  String get mcpGuideStepConnectDesc => 'Escolha o agente e copie o código.';

  @override
  String mcpGuideWhere(String path) {
    return 'Arquivo: $path';
  }

  @override
  String get mcpGuideCopy => 'Copiar código';

  @override
  String get mcpGuideCopied => 'Código copiado.';

  @override
  String get mcpGuideStepTest => 'Verificar conexão';

  @override
  String get mcpGuideStepTestDesc => 'Envie esta solicitação e veja a lista.';

  @override
  String get mcpGuideStepTools => 'O que o agente pode fazer';

  @override
  String get mcpGuideStepToolsDesc =>
      'Seis ferramentas: lista primeiro, detalhes depois.';

  @override
  String get mcpGuideTipTitle => 'Se não conectar';

  @override
  String get mcpGuideTipAppClosed =>
      'Mantenha o app aberto; fechar para o servidor.';

  @override
  String get mcpGuideTipPort =>
      'Se a porta 8765 estiver ocupada, o app usa 8766–8774.';

  @override
  String get mcpGuideTipLocal =>
      'Somente local. Não abra esta porta para a rede.';

  @override
  String get mcpToolListSessions => 'Lista conversas com contagens.';

  @override
  String get mcpToolGetSession => 'Lê uma conversa e suas páginas.';

  @override
  String get mcpToolGetPageHtml => 'Devolve o HTML completo de uma página.';

  @override
  String get mcpToolWritePage => 'Cria ou substitui uma página.';

  @override
  String get mcpToolDeletePage => 'Apaga uma página.';

  @override
  String get mcpToolPostToChat => 'Escreve uma resposta no chat.';

  @override
  String get chatProcessing => 'Processando…';

  @override
  String get chatUiReady => 'UI pronta';

  @override
  String get chatViewCode => 'Ver código';

  @override
  String get chatHideCode => 'Ocultar';

  @override
  String get chatNoMessagesTitle => 'Nenhuma conversa ainda';

  @override
  String get chatNoMessagesBody => 'Digite uma mensagem para começar.';

  @override
  String get commonGenericError => 'Algo deu errado. Tente novamente.';

  @override
  String get canvasMentionElementFallback => 'Elemento selecionado';

  @override
  String get canvasNoProvider =>
      'Nenhum Provider ativo. Adicione um para começar.';

  @override
  String get canvasPagesTrimmed =>
      'Páginas extras foram removidas para corresponder ao número que você pediu.';

  @override
  String get canvasUntitledPage => 'Sem título';

  @override
  String get canvasGenerationStopped => 'Geração interrompida.';

  @override
  String get promptAttachmentLimit => 'Até 6 anexos por mensagem.';

  @override
  String get providerNotFound => 'Provider não encontrado.';

  @override
  String get errorCancelled => 'Cancelado.';

  @override
  String get errorApiTimeout =>
      'A conexão expirou. Verifique o endereço ou a rede.';

  @override
  String get errorApiUnreachable =>
      'Não foi possível conectar. Verifique o endereço.';

  @override
  String get errorApiUnauthorized =>
      'A chave de acesso é inválida ou não tem permissão.';

  @override
  String get errorApiRateLimited =>
      'O serviço está limitando pedidos. Tente de novo em instantes.';

  @override
  String get errorApiNotFound =>
      'Endereço ou Model não encontrado. Verifique os dois.';

  @override
  String get errorApiRejected => 'O serviço recusou o pedido.';

  @override
  String get errorApiCertificate =>
      'O certificado do servidor não é válido. Verifique o endereço.';

  @override
  String get errorApiSendFailed =>
      'Não foi possível enviar o pedido. Verifique a conexão e o endereço.';

  @override
  String get errorApiBadResponse =>
      'A resposta não veio no formato esperado. O endereço deve terminar em /v1.';

  @override
  String get errorApiNoChatEndpoint =>
      'Este serviço ainda não tem endereço de chat.';

  @override
  String get errorApiModelUnavailable =>
      'Este Model não está disponível aqui. Escolha outro.';

  @override
  String get errorApiConnectionBroken => 'A conexão caiu. Tente de novo.';

  @override
  String errorApiProviderReported(String detail) {
    return 'Mensagem do serviço: $detail';
  }

  @override
  String get errorGenerationTimeout =>
      'Geração interrompida: demorou demais. Tente de novo.';

  @override
  String get errorExportNotReady =>
      'A página ainda não está pronta. Aguarde um momento.';

  @override
  String get errorExportTimeout => 'A exportação expirou. Tente de novo.';

  @override
  String get errorExportNoElements => 'Ainda não há nada para exportar.';

  @override
  String get errorExportEmptyResult => 'O resultado veio vazio. Tente de novo.';

  @override
  String get errorExportWriteFailed =>
      'Não foi possível salvar o arquivo. Escolha outro local.';

  @override
  String get errorImportInvalidFile =>
      'Este arquivo não é um JSON válido. Escolha um arquivo Centauri .mydesign.';

  @override
  String get errorImportNotProject =>
      'Este não é um arquivo de projeto Centauri.';

  @override
  String errorImportNewerVersion(String version) {
    return 'Este arquivo precisa de uma versão mais nova do Centauri ($version). Atualize o app primeiro.';
  }

  @override
  String get errorImportEmpty => 'Este arquivo de projeto está vazio.';

  @override
  String errorImportEmptyFile(String name) {
    return 'O arquivo $name está vazio.';
  }

  @override
  String get errorImportUnusable =>
      'Não foi possível ler o arquivo. Escolha outro arquivo.';

  @override
  String errorImportUnusableFile(String name) {
    return 'Não foi possível ler o arquivo $name. Escolha outro arquivo.';
  }

  @override
  String get errorAttachmentEmpty => 'O arquivo está vazio.';

  @override
  String errorAttachmentEmptyFile(String name) {
    return 'O arquivo $name está vazio.';
  }

  @override
  String errorAttachmentTooLarge(int maxMb) {
    return 'O arquivo é grande demais (máx. $maxMb MB).';
  }

  @override
  String errorAttachmentUnsupported(String formats) {
    return 'Este formato não é aceito. Use $formats.';
  }

  @override
  String get errorStorageFailed =>
      'Não foi possível acessar a chave neste dispositivo.';

  @override
  String get errorTransformNoCode => 'Esta página ainda não tem código.';

  @override
  String get exportFigma => 'Figma';

  @override
  String get exportFigmaPlugin => 'Figma (plugin)';

  @override
  String exportFigmaCopiedWidth(int width) {
    return 'Copiado em $width px. Cole no Figma.';
  }

  @override
  String get catalogSectionFreeTier => 'Plano gratuito';

  @override
  String get catalogSectionApiKey => 'API Key';

  @override
  String get appearanceTooltip => 'Aparência';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearanceModeLabel => 'Modo';

  @override
  String get appearanceModeSystem => 'Sistema';

  @override
  String get appearanceModeLight => 'Claro';

  @override
  String get appearanceModeDark => 'Escuro';

  @override
  String get appearancePrimaryLabel => 'Cor principal';

  @override
  String get appearanceReset => 'Redefinir';

  @override
  String get commonDone => 'Concluído';

  @override
  String get colorBlue => 'Azul';

  @override
  String get colorIndigo => 'Índigo';

  @override
  String get colorViolet => 'Violeta';

  @override
  String get colorTeal => 'Turquesa';

  @override
  String get colorGreen => 'Verde';

  @override
  String get colorAmber => 'Âmbar';

  @override
  String get colorRose => 'Rosa';

  @override
  String get colorSlate => 'Ardósia';
}
