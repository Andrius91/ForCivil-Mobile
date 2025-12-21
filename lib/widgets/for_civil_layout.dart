import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/menu/menu_widget.dart';
import '/project_selector/project_selector_widget.dart';

class ForCivilLayout extends StatelessWidget {
  const ForCivilLayout({
    super.key,
    required this.scaffoldKey,
    required this.body,
    this.backgroundColor = Colors.white,
    this.showDrawer = true,
    this.padding,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget body;
  final Color backgroundColor;
  final bool showDrawer;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: showDrawer ? const _ForCivilDrawer() : null,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primarycolor, theme.tertiary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: theme.primarycolor.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.layers, color: Colors.white, size: 22),
            ),
            Text(
              'ForCivil',
              style: theme.titleLarge.override(
                fontFamily: theme.titleLargeFamily,
                color: theme.primaryText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ].divide(const SizedBox(width: 12)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
            child: FlutterFlowIconButton(
              borderColor: theme.border,
              borderRadius: 14,
              borderWidth: 1,
              buttonSize: 40,
              fillColor: theme.secondaryBackground,
              icon: Icon(Icons.menu, color: theme.primaryText, size: 20),
              onPressed: () => scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: body,
        ),
      ),
    );
  }
}

class _ForCivilDrawer extends StatelessWidget {
  const _ForCivilDrawer();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Drawer(
      backgroundColor: theme.secondaryBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ForCivil Builder',
                    style: theme.headlineSmall.override(
                      fontFamily: theme.headlineSmallFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Gestiona tus proyectos',
                    style: theme.bodyMedium.override(
                        fontFamily: theme.bodyMediumFamily,
                        color: theme.mutedforeground),
                  ),
                ].divide(const SizedBox(height: 4)),
              ),
            ),
            Divider(height: 1, color: theme.border),
            _DrawerItem(
              label: 'Panel principal',
              icon: Icons.dashboard_customize_rounded,
              onTap: () {
                Navigator.of(context).pop();
                context.goNamed(MenuWidget.routeName);
              },
            ),
            _DrawerItem(
              label: 'Seleccionar Proyecto',
              icon: Icons.business_center,
              onTap: () {
                Navigator.of(context).pop();
                context.goNamed(ProjectSelectorWidget.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.accent1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.primarycolor, size: 22),
      ),
      title: Text(
        label,
        style: theme.titleMedium.override(
          fontFamily: theme.titleMediumFamily,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
