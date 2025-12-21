import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/backend/api/auth_service.dart';
import '/backend/api/auth_state.dart';
import '/backend/api/crew_service.dart';
import '/widgets/for_civil_layout.dart';

class MyCrewWidget extends StatefulWidget {
  const MyCrewWidget({super.key});

  static String routeName = 'MyCrew';
  static String routePath = '/myCrew';

  @override
  State<MyCrewWidget> createState() => _MyCrewWidgetState();
}

class _MyCrewWidgetState extends State<MyCrewWidget> {
  final _crewService = CrewService();
  late Future<List<Crew>> _crewFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _crewFuture = _loadCrews();
      _initialized = true;
    }
  }

  Future<List<Crew>> _loadCrews() async {
    final authState = context.read<AuthState>();
    final token = authState.token;
    final profile = authState.profile;
    final project = authState.selectedProject;

    if (token == null || profile == null) {
      throw ApiException('Debes iniciar sesión para ver tus cuadrillas');
    }
    if (project == null) {
      throw ApiException(
          'Selecciona un proyecto antes de consultar tus cuadrillas');
    }

    return _crewService.fetchCrews(
      userId: profile.id,
      projectId: project.projectId,
      token: token,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _crewFuture = _loadCrews();
    });
    await _crewFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return ForCivilLayout(
      scaffoldKey: GlobalKey<ScaffoldState>(),
      backgroundColor: theme.primaryBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24.0),
            Text(
              'Mis cuadrillas',
              style: theme.headlineMedium.override(
                font: GoogleFonts.interTight(
                  fontWeight: FontWeight.w700,
                  fontStyle: theme.headlineMedium.fontStyle,
                ),
              ),
            ),
            Text(
              'Selecciona una cuadrilla para ver a sus integrantes, capataz y partidas asignadas.',
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(),
                color: theme.mutedforeground,
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: RefreshIndicator(
                color: theme.primarycolor,
                onRefresh: _refresh,
                child: FutureBuilder<List<Crew>>(
                  future: _crewFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _CrewLoadingList();
                    }
                    if (snapshot.hasError) {
                      return _CrewErrorState(
                        error: snapshot.error,
                        onRetry: _refresh,
                      );
                    }
                    final crews = snapshot.data ?? const [];
                    if (crews.isEmpty) {
                      return const _CrewEmptyState();
                    }
                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: crews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                      itemBuilder: (context, index) =>
                          _CrewTeamTile(crew: crews[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrewTeamTile extends StatefulWidget {
  const _CrewTeamTile({required this.crew});

  final Crew crew;

  @override
  State<_CrewTeamTile> createState() => _CrewTeamTileState();
}

class _CrewTeamTileState extends State<_CrewTeamTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final crew = widget.crew;
    return Container(
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: theme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16.0,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
          initiallyExpanded: _expanded,
          onExpansionChanged: (value) => setState(() => _expanded = value),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                crew.name,
                style: theme.titleMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    fontStyle: theme.titleMedium.fontStyle,
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Capataz: ${crew.foremanName}',
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(),
                        color: theme.mutedforeground,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: theme.border),
                    ),
                    child: Text(
                      crew.active ? 'Activa' : 'Inactiva',
                      style: theme.labelMedium.override(
                        font: GoogleFonts.inter(),
                        color: crew.active ? theme.success : theme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (crew.members.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 16.0),
                child: Text(
                  'Esta cuadrilla aún no tiene integrantes registrados.',
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: theme.mutedforeground,
                  ),
                ),
              )
            else
              ...crew.members.map(
                (member) => Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 12.0),
                  child: _CrewCard(member: member),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CrewCard extends StatelessWidget {
  const _CrewCard({required this.member});

  final CrewMember member;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final initials = member.fullName.isNotEmpty
        ? member.fullName.trim().split(' ').take(2).map((e) => e[0]).join()
        : 'C';
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundImage:
                member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            radius: 28,
            child: member.photoUrl == null
                ? Text(initials, style: theme.titleMedium)
                : null,
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: theme.titleMedium.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FontWeight.w600,
                      fontStyle: theme.titleMedium.fontStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  member.specialty.isNotEmpty
                      ? '${member.category} · ${member.specialty}'
                      : member.category,
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: theme.mutedforeground,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Código',
                style: theme.labelMedium.override(
                  font: GoogleFonts.inter(),
                  color: theme.mutedforeground,
                ),
              ),
              Text(
                member.id.toString(),
                style: theme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrewLoadingList extends StatelessWidget {
  const _CrewLoadingList();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16.0),
      itemBuilder: (context, index) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: theme.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CrewErrorState extends StatelessWidget {
  const _CrewErrorState({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final message = error is ApiException
        ? (error as ApiException).message
        : 'No pudimos cargar tus cuadrillas. Inténtalo nuevamente.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          margin: const EdgeInsets.only(top: 32.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: theme.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: theme.error),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error al cargar cuadrillas',
                style: theme.titleMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    fontStyle: theme.titleMedium.fontStyle,
                  ),
                  color: theme.error,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(message, style: theme.bodyMedium),
              const SizedBox(height: 16.0),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CrewEmptyState extends StatelessWidget {
  const _CrewEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          margin: const EdgeInsets.only(top: 32.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sin cuadrillas disponibles',
                style: theme.titleMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    fontStyle: theme.titleMedium.fontStyle,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Aún no se te han asignado cuadrillas. Vuelve a intentarlo más tarde o consulta con tu administrador.',
                style: theme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
