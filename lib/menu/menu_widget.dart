import '/backend/api/auth_state.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/widgets/for_civil_layout.dart';
import 'menu_model.dart';
export 'menu_model.dart';

class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key});

  static String routeName = 'Menu';
  static String routePath = '/menu';

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  late MenuModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MenuModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final authState = context.watch<AuthState>();
    final userName = authState.profile?.fullName ?? 'Invitado';

    final tiles = [
      _MenuTileData(
        title: 'Registrar tareo',
        description: 'Control de asistencia',
        icon: Icons.assignment_outlined,
        accentColor: theme.primarycolor,
        onTap: () => context.pushNamed(RegisterTareoWidget.routeName),
      ),
      _MenuTileData(
        title: 'Mi cuadrilla',
        description: 'Gestión de personal',
        icon: Icons.groups_outlined,
        accentColor: theme.chart3,
        onTap: () => context.pushNamed(MyCrewWidget.routeName),
      ),
      _MenuTileData(
        title: 'Configurar marcador',
        description: 'Usar este dispositivo como marcador de asistencia',
        icon: Icons.fact_check,
        accentColor: theme.success,
        onTap: () => context.pushNamed(AttendanceMarkerWidget.routeName),
      ),
    ];

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: ForCivilLayout(
        scaffoldKey: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32.0),
                Text(
                  'Panel principal',
                  style: theme.headlineLarge.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FontWeight.w700,
                      fontStyle: theme.headlineLarge.fontStyle,
                    ),
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  'Bienvenido, $userName',
                  style: theme.bodyLarge.override(
                    font: GoogleFonts.inter(
                      fontWeight: theme.bodyLarge.fontWeight,
                      fontStyle: theme.bodyLarge.fontStyle,
                    ),
                    color: theme.mutedforeground,
                  ),
                ),
                const SizedBox(height: 24.0),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tiles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    return _MenuTile(data: tiles[index]);
                  },
                ),
                const SizedBox(height: 48.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTileData {
  const _MenuTileData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
}

class _MenuTile extends StatefulWidget {
  const _MenuTile({required this.data});

  final _MenuTileData data;

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final borderColor = _hovered ? theme.primarycolor : theme.border;
    final hasAction = widget.data.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: hasAction ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.08 : 0.04),
              blurRadius: 18.0,
              offset: const Offset(0.0, 8.0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.data.onTap,
            borderRadius: BorderRadius.circular(20.0),
            splashColor: theme.primarycolor.withOpacity(0.08),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56.0,
                    height: 56.0,
                    decoration: BoxDecoration(
                      color: widget.data.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Icon(
                      widget.data.icon,
                      color: widget.data.accentColor,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    widget.data.title,
                    style: theme.titleMedium.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                        fontStyle: theme.titleMedium.fontStyle,
                      ),
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    widget.data.description,
                    style: theme.bodySmall.override(
                      font: GoogleFonts.inter(
                        fontWeight: theme.bodySmall.fontWeight,
                        fontStyle: theme.bodySmall.fontStyle,
                      ),
                      color: theme.mutedforeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
