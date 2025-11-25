import '/backend/api/auth_service.dart';
import '/backend/api/auth_state.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();

    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthState>();
    final theme = FlutterFlowTheme.of(context);

    Future<void> submitLogin() async {
      final username = _model.textController1?.text.trim() ?? '';
      final password = _model.textController2?.text ?? '';

      if (!(_model.formKey.currentState?.validate() ?? false)) {
        return;
      }

      setState(() {
        _model.errorMessage = null;
        _model.isSubmitting = true;
      });

      try {
        await context.read<AuthState>().login(username, password);
        if (!mounted) return;
        context.goNamed(ProjectSelectorWidget.routeName);
      } on ApiException catch (e) {
        setState(() => _model.errorMessage = e.message);
      } catch (_) {
        setState(() {
          _model.errorMessage =
              'No se pudo iniciar sesión. Revisa tus datos e inténtalo de nuevo';
        });
      } finally {
        if (mounted) {
          setState(() => _model.isSubmitting = false);
        }
      }
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: theme.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 24.0,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120.0,
                            height: 120.0,
                            decoration: BoxDecoration(
                              color: theme.primarycolor,
                              borderRadius: BorderRadius.circular(24.0),
                            ),
                            child: const Icon(Icons.engineering,
                                color: Colors.white, size: 52.0),
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            'ForCivil · Builder',
                            textAlign: TextAlign.center,
                            style: theme.displaySmall.override(
                              font: GoogleFonts.interTight(
                                fontWeight: FontWeight.w700,
                                fontStyle: theme.displaySmall.fontStyle,
                              ),
                              color: theme.primaryText,
                              fontSize: 28.0,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Inicia sesión para acceder a tu panel de control',
                            textAlign: TextAlign.center,
                            style: theme.bodyMedium.override(
                              font: GoogleFonts.inter(),
                              color: theme.mutedforeground,
                            ),
                          ),
                          const SizedBox(height: 32.0),
                          Form(
                            key: _model.formKey,
                            child: Column(
                              children: [
                                _LoginField(
                                  controller: _model.textController1,
                                  focusNode: _model.textFieldFocusNode1,
                                  label: 'Correo o usuario',
                                  hint: 'Ingresa tu correo o usuario',
                                  prefix: Icons.person_outline,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Ingresa tu correo o usuario';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20.0),
                                _LoginField(
                                  controller: _model.textController2,
                                  focusNode: _model.textFieldFocusNode2,
                                  label: 'Contraseña',
                                  hint: 'Ingresa tu contraseña',
                                  prefix: Icons.lock_outline,
                                  obscureText: !_model.passwordVisibility,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                      () => _model.passwordVisibility =
                                          !_model.passwordVisibility,
                                    ),
                                    icon: Icon(
                                      _model.passwordVisibility
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: theme.mutedforeground,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Ingresa tu contraseña';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (_model.errorMessage != null) ...[
                            const SizedBox(height: 20.0),
                            _ErrorBanner(message: _model.errorMessage!),
                          ],
                          const SizedBox(height: 24.0),
                          FFButtonWidget(
                            onPressed: () async {
                              if (_model.isSubmitting) return;
                              await submitLogin();
                            },
                            text: _model.isSubmitting
                                ? 'Ingresando...'
                                : 'Iniciar sesión',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 52.0,
                              padding: EdgeInsets.zero,
                              color: theme.primarycolor,
                              textStyle: theme.titleMedium.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: theme.titleMedium.fontStyle,
                                ),
                                color: theme.primaryforeground,
                              ),
                              elevation: 0,
                              borderRadius: BorderRadius.circular(12.0),
                              disabledColor: theme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    Text(
                      '¿Necesitas acceso?',
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(),
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    FFButtonWidget(
                      onPressed: () {},
                      text: 'Solicitar cuenta',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 52.0,
                        padding: EdgeInsets.zero,
                        color: theme.secondaryBackground,
                        textStyle: theme.titleMedium.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                            fontStyle: theme.titleMedium.fontStyle,
                          ),
                          color: theme.primaryText,
                        ),
                        elevation: 0,
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: theme.border),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Text(
                      '© 2025 ForCivil - Sistema de Gestión de Obra',
                      textAlign: TextAlign.center,
                      style: theme.bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.mutedforeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: theme.labelMedium,
        hintStyle: theme.bodyMedium.copyWith(color: theme.mutedforeground),
        filled: true,
        fillColor: theme.secondaryBackground,
        prefixIcon: Icon(prefix, color: theme.mutedforeground),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: theme.primarycolor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: theme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.0),
          borderSide: BorderSide(color: theme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      ),
      style: theme.bodyMedium,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.error),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              message,
              style: theme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
