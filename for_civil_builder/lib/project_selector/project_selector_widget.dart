import '/backend/api/auth_service.dart';
import '/backend/api/auth_state.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/widgets/for_civil_layout.dart';
import 'project_selector_model.dart';
export 'project_selector_model.dart';

class ProjectSelectorWidget extends StatefulWidget {
  const ProjectSelectorWidget({super.key});

  static String routeName = 'ProjectSelector';
  static String routePath = '/projectSelector';

  @override
  State<ProjectSelectorWidget> createState() => _ProjectSelectorWidgetState();
}

class _ProjectSelectorWidgetState extends State<ProjectSelectorWidget> {
  late ProjectSelectorModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProjectSelectorModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    final roles = profile?.projectRoles ?? <ProjectRole>[];

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: ForCivilLayout(
        scaffoldKey: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24.0),
              Text(
                'Seleccionar proyecto',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 28.0,
                    ),
              ),
              Text(
                'Elige el proyecto con el que deseas trabajar',
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.normal,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).mutedforeground,
                      fontSize: 16.0,
                    ),
              ),
              const SizedBox(height: 24.0),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: roles.isNotEmpty ? roles.length : 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                  itemBuilder: (context, index) {
                    if (roles.isEmpty) {
                      return const _EmptyProjects();
                    }
                    final role = roles[index];
                    return _ProjectCard(
                      role: role,
                      onTap: () {
                        context.read<AuthState>().selectProject(role);
                        context.goNamed(MenuWidget.routeName);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.role, required this.onTap});

  final ProjectRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20.0),
      onTap: role.active ? onTap : null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: theme.border),
          boxShadow: const [
            BoxShadow(
              blurRadius: 20.0,
              color: Color(0x11000000),
              offset: Offset(0.0, 10.0),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Icon(
                  Icons.business_rounded,
                  color: theme.chart1,
                  size: 24.0,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.projectName,
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .fontStyle,
                            ),
                            color: theme.primaryText,
                            fontSize: 18.0,
                          ),
                    ),
                    Text(
                      'Rol: ${role.roleName}',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.normal,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: theme.mutedforeground,
                            fontSize: 14.0,
                          ),
                    ),
                  ].divide(const SizedBox(height: 6.0)),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'ID #${role.projectId}',
                    style: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(),
                          color: theme.mutedforeground,
                        ),
                  ),
                  if (!role.active)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Inactivo',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(),
                              color: theme.error,
                            ),
                      ),
                    ),
                ],
              ),
            ].divide(const SizedBox(width: 16.0)),
          ),
        ),
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.mutedforeground,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'No tienes proyectos asignados todavía.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: theme.mutedforeground,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
