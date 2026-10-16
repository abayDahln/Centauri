import 'package:centauri/features/provider_config/data/oauth/oauth_provider_presets.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthProviderPresets integrity', () {
    test('id preset unik', () {
      final ids = OAuthProviderPresets.all.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('preset non-custom punya label & description', () {
      for (final preset in OAuthProviderPresets.all.where((p) => !p.isCustom)) {
        expect(preset.label.trim(), isNotEmpty, reason: preset.id);
        expect(preset.description.trim(), isNotEmpty, reason: preset.id);
      }
    });

    test(
      'preset non-custom punya authorizationUrl & tokenUrl '
      '(kecuali import token)',
      () {
        for (final preset in OAuthProviderPresets.all.where(
          (p) => !p.isCustom && p.flow != OAuthFlow.importToken,
        )) {
          expect(preset.authorizationUrl.trim(), isNotEmpty, reason: preset.id);
          expect(preset.tokenUrl.trim(), isNotEmpty, reason: preset.id);
        }
      },
    );

    test('preset token-only tidak memakai Base URL', () {
      for (final preset in OAuthProviderPresets.all.where(
        (p) => p.isTokenOnly,
      )) {
        expect(preset.baseUrl, isEmpty, reason: preset.id);
      }
    });

    test('modelsUrl yang terisi berupa URL http(s) valid', () {
      for (final preset in OAuthProviderPresets.all.where(
        (p) => p.modelsUrl.trim().isNotEmpty,
      )) {
        final uri = Uri.tryParse(preset.modelsUrl);
        expect(uri, isNotNull, reason: preset.id);
        expect(
          uri!.hasScheme && uri.hasAuthority,
          isTrue,
          reason: preset.id,
        );
      }
    });

    test('preset reverse-engineered ditandai eksperimental', () {
      const experimental = {
        'claude-code',
        'antigravity',
        'qoder',
        'openai-codex',
        'github-copilot',
        'cursor',
        'kilo-code',
        'cline',
        'codebuddy',
        'zai-glm',
        'grok-cli',
        'kiro',
      };
      for (final id in experimental) {
        expect(
          OAuthProviderPresets.byId(id)?.isExperimental,
          isTrue,
          reason: id,
        );
      }
    });

    test('byId mengembalikan preset yang cocok', () {
      expect(OAuthProviderPresets.byId('claude-code')?.label, 'Claude Code');
      expect(OAuthProviderPresets.byId('github-copilot')?.flow,
          OAuthFlow.deviceCode);
      expect(OAuthProviderPresets.byId('cursor')?.flow,
          OAuthFlow.importToken);
      expect(OAuthProviderPresets.byId('tidak-ada'), isNull);
    });

    test('preset Codex memakai port & callback khusus', () {
      final config = OAuthProviderPresets.openaiCodex.toOAuthConfig();
      expect(config.redirectPort, 1455);
      expect(config.callbackPath, '/auth/callback');
    });

    test('preset Claude memakai body JSON', () {
      final config = OAuthProviderPresets.claudeCode.toOAuthConfig();
      expect(config.tokenBodyFormat, TokenBodyFormat.json);
    });

    test('preset GitHub Copilot memakai exchange token Copilot', () {
      final config = OAuthProviderPresets.githubCopilot.toOAuthConfig();
      expect(config.tokenExchange, TokenExchangeStyle.githubCopilot);
    });
  });
}
