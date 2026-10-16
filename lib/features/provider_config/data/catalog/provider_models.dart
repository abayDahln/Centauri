/// Katalog model siap-pakai per provider (hardcode).
///
/// Meniru format 9router: setiap provider punya `alias` (mis. `cbai`) dan
/// daftar `{ id, name }`. UI menampilkan `alias/id` (mis. `cbai/glm-5.2`)
/// dengan [ProviderModel.name] sebagai subtitle.
///
/// **Penting:** yang disimpan & dikirim ke provider adalah [ProviderModel.id]
/// **polos** (mis. `glm-5.2`). Prefix `alias/` hanya untuk tampilan — API
/// upstream memang mengharapkan id polos (9router melepas prefix sebelum
/// meneruskan request).
///
/// Sumber: registry 9router
/// (`open-sse/providers/registry/*.js`), dirapikan ke model populer/terkini.
/// Daftar ini bisa tertinggal dari ketersediaan aktual; karena itu UI selalu
/// menyediakan opsi "Custom" untuk mengetik id manual.
library;

/// Satu model: [id] polos yang dikirim ke API + [name] label ramah.
class ProviderModel {
  const ProviderModel(this.id, this.name);

  /// Id polos upstream, mis. `glm-5.2` atau `anthropic/claude-opus-4.7`.
  final String id;

  /// Nama tampilan, mis. `GLM-5.2`.
  final String name;
}

/// Alias + daftar model hardcode untuk satu provider.
class ProviderModelSet {
  const ProviderModelSet({required this.alias, required this.models});

  /// Prefix tampilan (mis. `qd`, `cbai`, `cl`).
  final String alias;

  final List<ProviderModel> models;

  /// Label tampilan bergaya 9router: `<alias>/<id>`.
  String label(ProviderModel model) => '$alias/${model.id}';
}

/// Registry model per id provider Centauri (id katalog / preset OAuth).
///
/// Provider yang tidak punya daftar statis (lokal & custom) tidak ada di sini
/// — UI jatuh ke input teks manual.
class ProviderModelCatalog {
  ProviderModelCatalog._();

  // ------------------------------------------------------------- oauth ----

  static const _claudeCode = ProviderModelSet(
    alias: 'cc',
    models: [
      ProviderModel('claude-opus-5-5', 'Claude Opus 5.5'),
      ProviderModel('claude-opus-5', 'Claude Opus 5'),
      ProviderModel('claude-sonnet-5-5', 'Claude Sonnet 5.5'),
      ProviderModel('claude-sonnet-5', 'Claude Sonnet 5'),
      ProviderModel('claude-fable-5-1', 'Claude Fable 5.1'),
      ProviderModel('claude-fable-5', 'Claude Fable 5'),
      ProviderModel('claude-haiku-4-5-20251001', 'Claude 4.5 Haiku'),
    ],
  );

  static const _antigravity = ProviderModelSet(
    alias: 'ag',
    models: [
      ProviderModel('gemini-3.8-flash', 'Gemini 3.8 Flash'),
      ProviderModel('gemini-3.7-flash-medium', 'Gemini 3.7 Flash'),
      ProviderModel('gemini-3.1-pro-high', 'Gemini 3.1 Pro (High)'),
      ProviderModel('claude-sonnet-4-6', 'Claude Sonnet 4.6 (Thinking)'),
      ProviderModel('claude-opus-4-6-thinking', 'Claude Opus 4.6 (Thinking)'),
      ProviderModel('gpt-oss-120b-medium', 'GPT-OSS 120B (Medium)'),
    ],
  );

  static const _qoder = ProviderModelSet(
    alias: 'qd',
    models: [
      ProviderModel('ultimate', 'Ultimate'),
      ProviderModel('auto', 'Auto'),
      ProviderModel('performance', 'Performance'),
      ProviderModel('efficient', 'Efficient'),
      ProviderModel('lite', 'Lite'),
      ProviderModel('qmodel_38max', 'Qwen3.8-Max'),
      ProviderModel('qmodel_latest', 'Qwen3.7-Max'),
      ProviderModel('qmodel', 'Qwen3.7-Plus'),
      ProviderModel('qfmodel', 'Qwen3.8-Flash'),
      ProviderModel('kmodel_latest', 'Kimi-K3'),
      ProviderModel('kmodel', 'Kimi-K2.7-Code'),
      ProviderModel('gmodel', 'GLM-5.3'),
      ProviderModel('gfmodel', 'GLM-5.3-Flash'),
      ProviderModel('dmodel', 'DeepSeek-V4-Pro'),
      ProviderModel('dfmodel', 'DeepSeek-V4-Flash'),
      ProviderModel('mmodel', 'MiniMax-M3'),
    ],
  );

  static const _openaiCodex = ProviderModelSet(
    alias: 'cx',
    models: [
      ProviderModel('gpt-6.1-sol', 'GPT 6.1 Sol'),
      ProviderModel('gpt-6-astra', 'GPT 6.0 Astra'),
      ProviderModel('gpt-6-sol', 'GPT 6.0 Sol'),
      ProviderModel('gpt-6-luna', 'GPT 6.0 Luna'),
      ProviderModel('gpt-5.6-sol', 'GPT 5.6 Sol'),
      ProviderModel('gpt-5.6-terra', 'GPT 5.6 Terra'),
      ProviderModel('gpt-5.6-luna', 'GPT 5.6 Luna'),
      ProviderModel('gpt-daybreak-blue-latest', 'GPT Daybreak Blue'),
    ],
  );

  static const _githubCopilot = ProviderModelSet(
    alias: 'gh',
    models: [
      ProviderModel('gpt-5.4', 'GPT-5.4'),
      ProviderModel('gpt-5.4-mini', 'GPT-5.4 Mini'),
      ProviderModel('gpt-5.3-codex', 'GPT-5.3 Codex'),
      ProviderModel('gpt-5.2', 'GPT-5.2'),
      ProviderModel('claude-opus-4.7', 'Claude Opus 4.7'),
      ProviderModel('claude-sonnet-4.6', 'Claude Sonnet 4.6'),
      ProviderModel('claude-haiku-4.5', 'Claude Haiku 4.5'),
      ProviderModel('gemini-3.1-pro-preview', 'Gemini 3.1 Pro'),
      ProviderModel('gemini-3-flash-preview', 'Gemini 3 Flash'),
      ProviderModel('grok-code-fast-1', 'Grok Code Fast 1'),
    ],
  );

  static const _cursor = ProviderModelSet(
    alias: 'cu',
    models: [
      ProviderModel('default', 'Auto (Server Picks)'),
      ProviderModel('claude-4.6-opus-max', 'Claude 4.6 Opus Max'),
      ProviderModel('claude-4.5-opus-high', 'Claude 4.5 Opus High'),
      ProviderModel('claude-4.5-sonnet', 'Claude 4.5 Sonnet'),
      ProviderModel('claude-4.5-haiku', 'Claude 4.5 Haiku'),
      ProviderModel('gpt-5.3-codex', 'GPT 5.3 Codex'),
      ProviderModel('gpt-5.2', 'GPT 5.2'),
      ProviderModel('gemini-3-flash-preview', 'Gemini 3 Flash Preview'),
      ProviderModel('kimi-k2.5', 'Kimi K2.5'),
    ],
  );

  static const _kiloCode = ProviderModelSet(
    alias: 'kc',
    models: [
      ProviderModel('anthropic/claude-sonnet-4-20250514', 'Claude Sonnet 4'),
      ProviderModel('anthropic/claude-opus-4-20250514', 'Claude Opus 4'),
      ProviderModel('google/gemini-2.5-pro', 'Gemini 2.5 Pro'),
      ProviderModel('google/gemini-2.5-flash', 'Gemini 2.5 Flash'),
      ProviderModel('openai/gpt-4.1', 'GPT-4.1'),
      ProviderModel('openai/o3', 'o3'),
      ProviderModel('deepseek/deepseek-chat', 'DeepSeek Chat'),
      ProviderModel('deepseek/deepseek-reasoner', 'DeepSeek Reasoner'),
    ],
  );

  static const _cline = ProviderModelSet(
    alias: 'cl',
    models: [
      ProviderModel('anthropic/claude-opus-4.7', 'Claude Opus 4.7'),
      ProviderModel('anthropic/claude-sonnet-4.6', 'Claude Sonnet 4.6'),
      ProviderModel('anthropic/claude-opus-4.6', 'Claude Opus 4.6'),
      ProviderModel('openai/gpt-5.3-codex', 'GPT-5.3 Codex'),
      ProviderModel('openai/gpt-5.4', 'GPT-5.4'),
      ProviderModel('google/gemini-3.1-pro-preview', 'Gemini 3.1 Pro Preview'),
      ProviderModel(
        'google/gemini-3.1-flash-lite-preview',
        'Gemini 3.1 Flash Lite Preview',
      ),
      ProviderModel('kwaipilot/kat-coder-pro', 'KAT Coder Pro'),
    ],
  );

  static const _codebuddy = ProviderModelSet(
    alias: 'cbai',
    models: [
      ProviderModel('glm-5.2', 'GLM-5.2'),
      ProviderModel('glm-5.1', 'GLM-5.1'),
      ProviderModel('glm-5.0', 'GLM-5.0'),
      ProviderModel('glm-5.0-turbo', 'GLM-5.0-Turbo'),
      ProviderModel('glm-5v-turbo', 'GLM-5v-Turbo'),
      ProviderModel('glm-4.7', 'GLM-4.7'),
      ProviderModel('minimax-m3', 'MiniMax-M3'),
      ProviderModel('minimax-m2.7', 'MiniMax-M2.7'),
      ProviderModel('kimi-k2.7', 'Kimi-K2.7-Code'),
      ProviderModel('kimi-k2.6', 'Kimi-K2.6'),
      ProviderModel('kimi-k2.5', 'Kimi-K2.5'),
      ProviderModel('hy3-preview', 'Hy3 Preview'),
      ProviderModel('deepseek-v4-pro', 'DeepSeek-V4-Pro'),
      ProviderModel('deepseek-v4.1-flash', 'DeepSeek-V4.1-Flash'),
      ProviderModel('deepseek-v3-2-volc', 'DeepSeek-V3.2'),
    ],
  );

  static const _zaiGlm = ProviderModelSet(
    alias: 'glm',
    models: [
      ProviderModel('glm-5.3', 'GLM 5.3'),
      ProviderModel('glm-5.3-flash', 'GLM 5.3 Flash (Vision)'),
      ProviderModel('glm-5.2', 'GLM 5.2'),
      ProviderModel('glm-5.1', 'GLM 5.1'),
      ProviderModel('glm-5-turbo', 'GLM 5 Turbo'),
      ProviderModel('glm-5', 'GLM 5'),
      ProviderModel('glm-4.7', 'GLM 4.7'),
      ProviderModel('glm-4.6v', 'GLM 4.6V (Vision)'),
    ],
  );

  static const _grokCli = ProviderModelSet(
    alias: 'gcli',
    models: [
      ProviderModel('grok-4.5', 'Grok 4.5'),
      ProviderModel('grok-4.5-high', 'Grok 4.5 (High)'),
      ProviderModel('grok-4.5-medium', 'Grok 4.5 (Medium)'),
      ProviderModel('grok-4.5-low', 'Grok 4.5 (Low)'),
    ],
  );

  static const _kiro = ProviderModelSet(
    alias: 'kr',
    models: [
      ProviderModel('claude-opus-4.8', 'Claude Opus 4.8'),
      ProviderModel('claude-sonnet-4.5', 'Claude Sonnet 4.5'),
      ProviderModel('claude-haiku-4.5', 'Claude Haiku 4.5'),
      ProviderModel('deepseek-3.2', 'DeepSeek 3.2'),
      ProviderModel('qwen3-coder-next', 'Qwen3 Coder Next'),
      ProviderModel('glm-5', 'GLM 5'),
      ProviderModel('MiniMax-M2.5', 'MiniMax M2.5'),
      ProviderModel('gpt-5.6-sol', 'GPT 5.6 Sol'),
      ProviderModel('gpt-5.6-terra', 'GPT 5.6 Terra'),
      ProviderModel('gpt-5.6-luna', 'GPT 5.6 Luna'),
    ],
  );

  // ---------------------------------------------------------- free tier ----

  static const _gemini = ProviderModelSet(
    alias: 'gemini',
    models: [
      ProviderModel('gemini-3.1-pro-preview', 'Gemini 3.1 Pro Preview'),
      ProviderModel(
        'gemini-3.1-flash-lite-preview',
        'Gemini 3.1 Flash Lite Preview',
      ),
      ProviderModel('gemini-3-flash-preview', 'Gemini 3 Flash Preview'),
      ProviderModel('gemini-2.5-pro', 'Gemini 2.5 Pro'),
      ProviderModel('gemini-2.5-flash', 'Gemini 2.5 Flash'),
      ProviderModel('gemini-2.5-flash-lite', 'Gemini 2.5 Flash Lite'),
    ],
  );

  static const _nvidia = ProviderModelSet(
    alias: 'nvidia',
    models: [
      ProviderModel('minimaxai/minimax-m3', 'MiniMax M3'),
      ProviderModel('minimaxai/minimax-m2.7', 'MiniMax M2.7'),
      ProviderModel('z-ai/glm-5.2', 'GLM 5.2'),
      ProviderModel('deepseek-ai/deepseek-v4-pro', 'DeepSeek V4 Pro'),
      ProviderModel('deepseek-ai/deepseek-v4-flash', 'DeepSeek V4 Flash'),
      ProviderModel('moonshotai/kimi-k2.6', 'Kimi K2.6'),
      ProviderModel(
        'nvidia/nemotron-3-ultra-550b-a55b',
        'Nemotron 3 Ultra',
      ),
    ],
  );

  static const _openrouter = ProviderModelSet(
    alias: 'openrouter',
    models: [
      ProviderModel('openai/gpt-5.4', 'GPT-5.4'),
      ProviderModel('anthropic/claude-opus-4.7', 'Claude Opus 4.7'),
      ProviderModel('google/gemini-3.1-pro-preview', 'Gemini 3.1 Pro Preview'),
      ProviderModel('deepseek/deepseek-v4-pro', 'DeepSeek V4 Pro'),
      ProviderModel('x-ai/grok-4.5', 'Grok 4.5'),
    ],
  );

  static const _opencode = ProviderModelSet(
    alias: 'oc',
    models: [
      ProviderModel(
        'muse-spark-1.3-contributor-free',
        'Muse Spark 1.3 Contributor Free',
      ),
      ProviderModel(
        'muse-spark-1.2-contributor-free',
        'Muse Spark 1.2 Contributor Free',
      ),
      ProviderModel('union-alpha', 'Union Alpha Free'),
      ProviderModel('jev-1.13-free', 'Jev 1.13 Free'),
    ],
  );

  static const _ollamaCloud = ProviderModelSet(
    alias: 'ollama',
    models: [
      ProviderModel('gpt-oss:120b', 'GPT OSS 120B'),
      ProviderModel('kimi-k2.5', 'Kimi K2.5'),
      ProviderModel('glm-5', 'GLM 5'),
      ProviderModel('minimax-m2.5', 'MiniMax M2.5'),
      ProviderModel('minimax-m3', 'MiniMax M3'),
      ProviderModel('glm-4.7-flash', 'GLM 4.7 Flash'),
      ProviderModel('qwen3.5', 'Qwen3.5'),
      ProviderModel('deepseek-v4.1-flash:cloud', 'DeepSeek V4.1 Flash'),
    ],
  );

  static const _groq = ProviderModelSet(
    alias: 'groq',
    models: [
      ProviderModel('llama-3.3-70b-versatile', 'Llama 3.3 70B'),
      ProviderModel(
        'meta-llama/llama-4-maverick-17b-128e-instruct',
        'Llama 4 Maverick',
      ),
      ProviderModel('qwen/qwen3-32b', 'Qwen3 32B'),
      ProviderModel('openai/gpt-oss-120b', 'GPT-OSS 120B'),
    ],
  );

  static const _cerebras = ProviderModelSet(
    alias: 'cerebras',
    models: [
      ProviderModel('gpt-oss-120b', 'GPT OSS 120B'),
      ProviderModel('zai-glm-4.7', 'ZAI GLM 4.7'),
      ProviderModel('llama-3.3-70b', 'Llama 3.3 70B'),
      ProviderModel('llama-4-scout-17b-16e-instruct', 'Llama 4 Scout'),
      ProviderModel('qwen-3-235b-a22b-instruct-2507', 'Qwen3 235B A22B'),
      ProviderModel('qwen-3-32b', 'Qwen3 32B'),
    ],
  );

  // ----------------------------------------------------------- api key ----

  static const _openai = ProviderModelSet(
    alias: 'openai',
    models: [
      ProviderModel('gpt-5.5', 'GPT-5.5'),
      ProviderModel('gpt-5.4', 'GPT-5.4'),
      ProviderModel('gpt-5.4-mini', 'GPT-5.4 Mini'),
      ProviderModel('gpt-5.4-nano', 'GPT-5.4 Nano'),
      ProviderModel('gpt-5.2', 'GPT-5.2'),
      ProviderModel('gpt-5.1', 'GPT-5.1'),
      ProviderModel('gpt-5', 'GPT-5'),
      ProviderModel('gpt-5-mini', 'GPT-5 Mini'),
      ProviderModel('gpt-4o', 'GPT-4o'),
      ProviderModel('gpt-4o-mini', 'GPT-4o Mini'),
      ProviderModel('gpt-4.1', 'GPT-4.1'),
      ProviderModel('o3', 'O3'),
      ProviderModel('o3-mini', 'O3 Mini'),
      ProviderModel('o4-mini', 'O4 Mini'),
    ],
  );

  static const _anthropic = ProviderModelSet(
    alias: 'anthropic',
    models: [
      ProviderModel('claude-sonnet-4-20250514', 'Claude Sonnet 4'),
      ProviderModel('claude-opus-4-20250514', 'Claude Opus 4'),
      ProviderModel('claude-3-5-sonnet-20241022', 'Claude 3.5 Sonnet'),
    ],
  );

  static const _mistral = ProviderModelSet(
    alias: 'mistral',
    models: [
      ProviderModel('mistral-large-latest', 'Mistral Large 3'),
      ProviderModel('codestral-latest', 'Codestral'),
      ProviderModel('mistral-medium-latest', 'Mistral Medium 3'),
    ],
  );

  static const _deepseek = ProviderModelSet(
    alias: 'ds',
    models: [
      ProviderModel('deepseek-v4-pro', 'DeepSeek V4 Pro'),
      ProviderModel('deepseek-v4.1-flash', 'DeepSeek V4.1 Flash'),
      ProviderModel('deepseek-v4-flash', 'DeepSeek V4 Flash'),
      ProviderModel('deepseek-chat', 'DeepSeek V3.2 Chat'),
      ProviderModel('deepseek-reasoner', 'DeepSeek V3.2 Reasoner'),
    ],
  );

  static const _xai = ProviderModelSet(
    alias: 'xai',
    models: [
      ProviderModel('grok-4.6', 'Grok 4.6'),
      ProviderModel('grok-4.5', 'Grok 4.5'),
      ProviderModel('grok-4', 'Grok 4'),
      ProviderModel('grok-4-fast-reasoning', 'Grok 4 Fast Reasoning'),
      ProviderModel('grok-code-fast-1', 'Grok Code Fast'),
      ProviderModel('grok-3', 'Grok 3'),
    ],
  );

  static const _cohere = ProviderModelSet(
    alias: 'cohere',
    models: [
      ProviderModel('command-r-plus-08-2024', 'Command R+ (Aug 2024)'),
      ProviderModel('command-r-08-2024', 'Command R (Aug 2024)'),
      ProviderModel('command-a-03-2025', 'Command A (Mar 2025)'),
    ],
  );

  static const _perplexity = ProviderModelSet(
    alias: 'pplx',
    models: [
      ProviderModel('sonar-pro', 'Sonar Pro'),
      ProviderModel('sonar', 'Sonar'),
    ],
  );

  static const _together = ProviderModelSet(
    alias: 'together',
    models: [
      ProviderModel(
        'meta-llama/Llama-3.3-70B-Instruct-Turbo',
        'Llama 3.3 70B Turbo',
      ),
      ProviderModel('deepseek-ai/DeepSeek-R1', 'DeepSeek R1'),
      ProviderModel('Qwen/Qwen3-235B-A22B', 'Qwen3 235B'),
      ProviderModel(
        'meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8',
        'Llama 4 Maverick',
      ),
    ],
  );

  static const _fireworks = ProviderModelSet(
    alias: 'fireworks',
    models: [
      ProviderModel(
        'accounts/fireworks/models/deepseek-v3p1',
        'DeepSeek V3.1',
      ),
      ProviderModel(
        'accounts/fireworks/models/llama-v3p3-70b-instruct',
        'Llama 3.3 70B',
      ),
      ProviderModel(
        'accounts/fireworks/models/qwen3-235b-a22b',
        'Qwen3 235B',
      ),
    ],
  );

  static const _nebius = ProviderModelSet(
    alias: 'nebius',
    models: [
      ProviderModel(
        'meta-llama/Llama-3.3-70B-Instruct',
        'Llama 3.3 70B Instruct',
      ),
    ],
  );

  static const _sambanova = ProviderModelSet(
    alias: 'samba',
    models: [ProviderModel('MiniMax-M2.7', 'MiniMax M2.7')],
  );

  static const _hyperbolic = ProviderModelSet(
    alias: 'hyp',
    models: [
      ProviderModel('Qwen/QwQ-32B', 'QwQ 32B'),
      ProviderModel('deepseek-ai/DeepSeek-R1', 'DeepSeek R1'),
      ProviderModel('deepseek-ai/DeepSeek-V3', 'DeepSeek V3'),
      ProviderModel('meta-llama/Llama-3.3-70B-Instruct', 'Llama 3.3 70B'),
      ProviderModel('Qwen/Qwen2.5-72B-Instruct', 'Qwen 2.5 72B'),
      ProviderModel('Qwen/Qwen2.5-Coder-32B-Instruct', 'Qwen 2.5 Coder 32B'),
    ],
  );

  static const _siliconflow = ProviderModelSet(
    alias: 'siliconflow',
    models: [
      ProviderModel('deepseek-ai/DeepSeek-V4-Pro', 'DeepSeek V4 Pro'),
      ProviderModel('deepseek-ai/DeepSeek-V4-Flash', 'DeepSeek V4 Flash'),
      ProviderModel('deepseek-ai/DeepSeek-V3.2', 'DeepSeek V3.2'),
      ProviderModel('Qwen/Qwen3.5-397B-A17B', 'Qwen 3.5 397B A17B'),
      ProviderModel('zai-org/GLM-5.1', 'GLM 5.1'),
      ProviderModel('moonshotai/Kimi-K2.6', 'Kimi K2.6'),
      ProviderModel('openai/gpt-oss-120b', 'GPT OSS 120B'),
      ProviderModel('MiniMaxAI/MiniMax-M2.5', 'MiniMax M2.5'),
    ],
  );

  static const _moonshot = ProviderModelSet(
    alias: 'kimi',
    models: [
      ProviderModel('kimi-k3', 'Kimi K3'),
      ProviderModel('k3', 'Kimi K3 (Code)'),
      ProviderModel('kimi-for-coding', 'Kimi for Coding'),
      ProviderModel('kimi-for-coding-highspeed', 'Kimi for Coding Highspeed'),
      ProviderModel('kimi-k2.7-code', 'Kimi K2.7 Code'),
      ProviderModel('kimi-k2.6', 'Kimi K2.6'),
      ProviderModel('kimi-k2.5', 'Kimi K2.5'),
    ],
  );

  static const _minimax = ProviderModelSet(
    alias: 'minimax',
    models: [
      ProviderModel('MiniMax-M3', 'MiniMax M3'),
      ProviderModel('MiniMax-M2.7', 'MiniMax M2.7'),
      ProviderModel('MiniMax-M2.5', 'MiniMax M2.5'),
      ProviderModel('MiniMax-M2.1', 'MiniMax M2.1'),
    ],
  );

  static const _llm7 = ProviderModelSet(
    alias: 'llm7',
    models: [
      ProviderModel('gpt-5.5', 'GPT-5.5 (LLM7)'),
      ProviderModel('claude-opus-5', 'Claude Opus 5 (LLM7)'),
      ProviderModel('deepseek-v4-flash', 'DeepSeek V4 Flash (LLM7)'),
      ProviderModel('grok-4.5', 'Grok 4.5 (LLM7)'),
      ProviderModel('kimi-k3', 'Kimi K3 (LLM7)'),
    ],
  );

  static const _featherless = ProviderModelSet(
    alias: 'fl',
    models: [
      ProviderModel('deepseek-ai/DeepSeek-V4-Pro', 'DeepSeek V4 Pro'),
      ProviderModel('deepseek-ai/DeepSeek-V4-Flash', 'DeepSeek V4 Flash'),
      ProviderModel('zai-org/GLM-5.2', 'GLM 5.2'),
      ProviderModel('zai-org/GLM-5.1', 'GLM 5.1'),
      ProviderModel('moonshotai/Kimi-K2.7-Code', 'Kimi K2.7 Code'),
      ProviderModel('moonshotai/Kimi-K2.6', 'Kimi K2.6'),
    ],
  );

  static const _commandCode = ProviderModelSet(
    alias: 'cmc',
    models: [
      ProviderModel('deepseek/deepseek-v4-pro', 'DeepSeek V4 Pro'),
      ProviderModel('deepseek/deepseek-v4-flash', 'DeepSeek V4 Flash'),
      ProviderModel('moonshotai/Kimi-K2.7-Code', 'Kimi K2.7 Code'),
      ProviderModel('moonshotai/Kimi-K2.6', 'Kimi K2.6'),
      ProviderModel('zai-org/GLM-5.2', 'GLM 5.2'),
      ProviderModel('zai-org/GLM-5.1', 'GLM 5.1'),
      ProviderModel('MiniMaxAI/MiniMax-M3', 'MiniMax M3'),
      ProviderModel('Qwen/Qwen3.7-Max', 'Qwen 3.7 Max'),
      ProviderModel('nvidia/nemotron-3-ultra-550b-a55b', 'Nemotron 3 Ultra'),
    ],
  );

  /// Peta id provider → set model. Id memakai id katalog / preset OAuth
  /// Centauri (bukan id 9router).
  static const Map<String, ProviderModelSet> _byProvider = {
    // OAuth
    'claude-code': _claudeCode,
    'antigravity': _antigravity,
    'qoder': _qoder,
    'openai-codex': _openaiCodex,
    'github-copilot': _githubCopilot,
    'cursor': _cursor,
    'kilo-code': _kiloCode,
    'cline': _cline,
    'codebuddy': _codebuddy,
    'zai-glm': _zaiGlm,
    'grok-cli': _grokCli,
    'kiro': _kiro,
    'kiro-ai': _kiro,
    // OAuth preset Google Gemini (id preset, bukan id entri katalog).
    'google-gemini': _gemini,
    // Free tier
    'gemini': _gemini,
    'nvidia': _nvidia,
    'openrouter': _openrouter,
    'opencode': _opencode,
    'ollama-cloud': _ollamaCloud,
    'groq': _groq,
    'cerebras': _cerebras,
    // API key
    'openai': _openai,
    'anthropic': _anthropic,
    'mistral': _mistral,
    'deepseek': _deepseek,
    'xai': _xai,
    'cohere': _cohere,
    'perplexity': _perplexity,
    'together': _together,
    'fireworks': _fireworks,
    'nebius': _nebius,
    'sambanova': _sambanova,
    'hyperbolic': _hyperbolic,
    'siliconflow': _siliconflow,
    'moonshot': _moonshot,
    'zai': _zaiGlm,
    'minimax': _minimax,
    'llm7': _llm7,
    'featherless': _featherless,
    'command-code': _commandCode,
  };

  /// Set model untuk provider [id], atau null bila tidak ada daftar statis
  /// (provider lokal / custom → UI pakai input manual).
  static ProviderModelSet? forProvider(String? id) =>
      id == null ? null : _byProvider[id];

  /// Daftar seluruh id provider yang punya daftar model statis.
  static Iterable<String> get providerIds => _byProvider.keys;
}
