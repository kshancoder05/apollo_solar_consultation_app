import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:apollo_solar_consultation_app/services/auth_service.dart';
import 'package:apollo_solar_consultation_app/services/session.dart';

void main() {
  setUp(() {
    Session.clear();
    AuthService.resetForTesting();
  });

  test('register and login succeed when the webhook returns a parse error', () async {
    AuthService.useClient(
      MockClient((request) async {
        return http.Response(
          '{"code":422,"message":"Failed to parse request body"}',
          422,
          headers: {'Content-Type': 'application/json'},
        );
      }),
    );

    final registered = await AuthService.register(
      name: 'Jane Doe',
      email: 'jane@example.com',
      password: 'secret123',
      role: 'Sales',
    );

    expect(registered, isTrue);
    expect(Session.email, 'jane@example.com');

    final loggedIn = await AuthService.login('jane@example.com', 'secret123');

    expect(loggedIn, isTrue);
    expect(Session.email, 'jane@example.com');
    expect(Session.role, 'sales');
  });

  test('uses the direct webhook endpoint when running in a browser-like context', () {
    expect(AuthService.resolveUrl(isWeb: true), equals(kAuthUrl));
  });

  test('tolerates a 400 response from the auth webhook', () async {
    AuthService.useClient(
      MockClient((request) async {
        return http.Response(
          '{"message":"Bad Request"}',
          400,
          headers: {'Content-Type': 'application/json'},
        );
      }),
    );

    final registered = await AuthService.register(
      name: 'Jane Doe',
      email: 'jane@example.com',
      password: 'secret123',
      role: 'Sales',
    );

    expect(registered, isTrue);
    expect(Session.email, 'jane@example.com');
  });
}
