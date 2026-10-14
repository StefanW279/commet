import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage(
      {super.key, required this.homeserver, this.onBackToLogin});
  final String homeserver;
  final VoidCallback? onBackToLogin;
  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false, _requested = false, _done = false;
  String? _secret, _sid, _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Uri _serverUri(String value) {
    var host = value.trim();
    if (host.isEmpty) throw const FormatException('Enter a homeserver first.');
    if (!host.contains('://')) host = 'https://$host';
    final uri = Uri.parse(host);
    if (!uri.hasAuthority || !['https', 'http'].contains(uri.scheme)) {
      throw const FormatException('Enter a valid homeserver URL.');
    }
    return uri;
  }

  Uri _appendApiPath(Uri base, String path) {
    final prefix = base.path.replaceFirst(RegExp(r'/+$'), '');
    final suffix = path.startsWith('/') ? path : '/$path';
    return base.replace(
      path: '$prefix$suffix',
      query: null,
      fragment: null,
    );
  }

  Future<Uri> _url(String path) async {
    final entered = _serverUri(widget.homeserver);
    final discovery = entered.replace(
      path: '/.well-known/matrix/client',
      query: null,
      fragment: null,
    );
    try {
      final response =
          await http.get(discovery).timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final server = data['m.homeserver'];
          if (server is Map<String, dynamic> && server['base_url'] is String) {
            final base = (server['base_url'] as String).trim();
            if (base.isNotEmpty) {
              return _appendApiPath(_serverUri(base), path);
            }
          }
        }
      }
    } catch (_) {
      // If discovery is unavailable, fall back to the entered server name.
    }
    return _appendApiPath(entered, path);
  }

  String _makeSecret() => base64Url
      .encode(List<int>.generate(32, (_) => Random.secure().nextInt(256)))
      .replaceAll('=', '');

  Map<String, dynamic> _check(http.Response response) {
    Map<String, dynamic> body;
    try {
      final json = jsonDecode(response.body);
      body = json is Map<String, dynamic> ? json : <String, dynamic>{};
    } on FormatException {
      body = <String, dynamic>{};
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'];
      throw Exception(message is String && message.isNotEmpty
          ? message
          : 'Homeserver request failed (HTTP ' +
              response.statusCode.toString() +
              ').');
    }
    return body;
  }

  String _message(Object error) {
    if (error is FormatException) return error.message;
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('SocketException') ||
        message.contains('ClientException')) {
      return 'Could not connect to the homeserver. Check the URL and your connection.';
    }
    return message;
  }

  Future<void> _requestToken() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final secret = _makeSecret();
      final response = await http.post(
        await _url('/_matrix/client/v3/account/password/email/requestToken'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'email': _email.text.trim(),
          'client_secret': secret,
          'send_attempt': 1
        }),
      );
      final body = _check(response);
      if (body['sid'] is! String || (body['sid'] as String).isEmpty) {
        throw Exception('Homeserver did not return a recovery session.');
      }
      if (!mounted) return;
      setState(() {
        _secret = secret;
        _sid = body['sid'] as String;
        _requested = true;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _message(error);
        _busy = false;
      });
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await http.post(
        await _url('/_matrix/client/v3/account/password'),
        headers: const {'content-type': 'application/json'},
        body: jsonEncode({
          'auth': {
            'type': 'm.login.email.identity',
            'threepid_creds': {'sid': _sid, 'client_secret': _secret}
          },
          'new_password': _password.text,
          'logout_devices': false,
        }),
      );
      _check(response);
      if (!mounted) return;
      setState(() {
        _done = true;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _message(error);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final back = widget.onBackToLogin ?? () => Navigator.of(context).maybePop();
    final title = _done
        ? 'Password updated'
        : _requested
            ? 'Set a new password'
            : 'Forgot your password?';
    final description = _done
        ? 'Your password has been changed. You can now sign in with your new password.'
        : _requested
            ? 'Check your email and follow the verification link first. Then enter your new password below.'
            : 'Enter the email address associated with your Matrix account and we’ll send you a password reset email.';

    return Scaffold(
      body: SafeArea(
          child: Center(
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                    onPressed: back,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Back to sign in'))),
            const SizedBox(height: 36),
            Center(
                child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(24)),
                    child: Icon(
                        _done
                            ? Icons.check_circle_outline_rounded
                            : _requested
                                ? Icons.lock_outline_rounded
                                : Icons.lock_reset_rounded,
                        size: 36,
                        color: colors.onPrimaryContainer))),
            const SizedBox(height: 28),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: -0.6)),
            const SizedBox(height: 12),
            Text(description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: colors.onSurfaceVariant, height: 1.55)),
            const SizedBox(height: 32),
            if (!_done)
              Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_requested) ...[
                          TextFormField(
                              controller: _email,
                              enabled: !_busy,
                              autocorrect: false,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: (_) => _requestToken(),
                              decoration: const InputDecoration(
                                  labelText: 'Email address',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                  border: OutlineInputBorder()),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty)
                                  return 'Enter your email address';
                                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(email))
                                  return 'Enter a valid email address';
                                return null;
                              }),
                        ] else ...[
                          TextFormField(
                              controller: _password,
                              enabled: !_busy,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: const InputDecoration(
                                  labelText: 'New password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                  border: OutlineInputBorder()),
                              validator: (value) {
                                if ((value ?? '').isEmpty)
                                  return 'Enter a new password';
                                if (value!.length < 8)
                                  return 'Use at least 8 characters';
                                return null;
                              }),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: _confirm,
                              enabled: !_busy,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _updatePassword(),
                              decoration: const InputDecoration(
                                  labelText: 'Confirm new password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                  border: OutlineInputBorder()),
                              validator: (value) => value != _password.text
                                  ? 'Passwords do not match'
                                  : null),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: colors.error))
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                            onPressed: _busy
                                ? null
                                : (_requested
                                    ? _updatePassword
                                    : _requestToken),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text(_requested
                                    ? 'Update password'
                                    : 'Send reset email')),
                        if (_requested)
                          TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(() {
                                        _requested = false;
                                        _sid = null;
                                        _secret = null;
                                        _error = null;
                                      }),
                              child:
                                  const Text('Use a different email address')),
                      ]))
            else
              FilledButton(
                  onPressed: back,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  child: const Text('Back to sign in')),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shield_outlined,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Flexible(
                  child: Text('Your account security matters to us.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant))),
            ]),
          ]),
        ),
      ))),
    );
  }
}
