import 'dart:async';

import 'package:centauri/features/provider_config/data/services/browser_launcher.dart';
import 'package:centauri/features/provider_config/domain/entities/api_provider.dart';
import 'package:centauri/features/provider_config/domain/entities/device_authorization.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_config.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_flow.dart';
import 'package:centauri/features/provider_config/domain/entities/oauth_token_set.dart';
import 'package:centauri/features/provider_config/domain/entities/provider_auth_type.dart';
import 'package:centauri/features/provider_config/domain/services/oauth_service.dart';
import 'package:centauri/features/provider_config/presentation/providers/provider_config_provider.dart';
import 'package:centauri/features/provider_config/presentation/widgets/device_connect_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBrowser implements BrowserLauncher {
  Uri? opened;

  @override
  Future<bool> open(Uri url) async {
    opened = url;
    return true;
  }
}

class _FakeOAuthService implements OAuthService {
  _FakeOAuthService(this.auth);

  final DeviceAuthorization auth;
  final Completer<OAuthTokenSet> pollCompleter = Completer<OAuthTokenSet>();

  @override
  Future<DeviceAuthorization> startDeviceFlow(ApiProvider provider) async =>
      auth;

  @override
  Future<OAuthTokenSet> pollDeviceFlow(
    ApiProvider provider,
    DeviceAuthorization authorization, {
    required Future<void> cancel,
  }) {
    cancel.then((_) {
      if (!pollCompleter.isCompleted) {
        pollCompleter.completeError(OAuthException('Dibatalkan.'));
      }
    });
    return pollCompleter.future;
  }

  @override
  Future<OAuthTokenSet> authorize(ApiProvider provider) async =>
      throw UnimplementedError();

  @override
  Future<OAuthTokenSet> refresh(
    ApiProvider provider,
    OAuthTokenSet current,
  ) async => throw UnimplementedError();

  @override
  Future<void> revoke(ApiProvider provider, OAuthTokenSet tokens) async {}
}

ApiProvider _provider() => ApiProvider(
  id: 'q',
  name: 'Qoder',
  baseUrl: '',
  model: '',
  authType: AuthType.oauth,
  oauthConfig: const OAuthConfig(
    authorizationUrl: 'https://qoder.com/device/selectAccounts',
    tokenUrl: 'https://openapi.qoder.sh/api/v1/deviceToken/poll',
    clientId: '',
    flow: OAuthFlow.deviceCode,
    deviceFlowStyle: DeviceFlowStyle.qoder,
    isTokenOnly: true,
    isExperimental: true,
  ),
);

DeviceAuthorization _auth() => DeviceAuthorization(
  flow: OAuthFlow.deviceCode,
  style: DeviceFlowStyle.qoder,
  verificationUri: Uri.parse(
    'https://qoder.com/device/selectAccounts?nonce=abc',
  ),
  userCode: 'DAAF7FDD',
  deviceCode: 'abc',
  codeVerifier: 'verifier',
  interval: const Duration(seconds: 1),
  expiresAt: DateTime.now().add(const Duration(minutes: 5)),
);

Widget _host({
  required _FakeOAuthService service,
  required _FakeBrowser launcher,
  required void Function(OAuthTokenSet?) onResult,
}) {
  return ProviderScope(
    overrides: [oauthServiceProvider.overrideWithValue(service)],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                final tokens = await showDeviceConnectDialog(
                  context,
                  provider: _provider(),
                  launcher: launcher,
                );
                onResult(tokens);
              },
              child: const Text('connect'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('menampilkan Login URL + kode, membuka browser, sukses', (
    tester,
  ) async {
    final service = _FakeOAuthService(_auth());
    final launcher = _FakeBrowser();
    OAuthTokenSet? result;
    var completed = false;

    await tester.pumpWidget(
      _host(
        service: service,
        launcher: launcher,
        onResult: (tokens) {
          result = tokens;
          completed = true;
        },
      ),
    );

    await tester.tap(find.text('connect'));
    await tester.pump(); // bangun dialog
    await tester.pump(const Duration(milliseconds: 50)); // jalankan _begin

    expect(find.text('DAAF7FDD'), findsOneWidget);
    expect(find.textContaining('Menunggu persetujuan'), findsOneWidget);
    expect(launcher.opened, isNotNull);
    expect(launcher.opened!.queryParameters['nonce'], 'abc');

    service.pollCompleter.complete(
      OAuthTokenSet(
        accessToken: 'dt-x',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(completed, isTrue);
    expect(result?.accessToken, 'dt-x');
  });

  testWidgets('Batal mengembalikan null', (tester) async {
    final service = _FakeOAuthService(_auth());
    final launcher = _FakeBrowser();
    OAuthTokenSet? result;
    var completed = false;

    await tester.pumpWidget(
      _host(
        service: service,
        launcher: launcher,
        onResult: (tokens) {
          result = tokens;
          completed = true;
        },
      ),
    );

    await tester.tap(find.text('connect'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Batal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(completed, isTrue);
    expect(result, isNull);
  });
}
