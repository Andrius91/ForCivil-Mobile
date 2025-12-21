import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/backend/api/auth_service.dart';
import '/backend/api/auth_state.dart';
import '/backend/api/crew_service.dart';
import '/backend/api/plan_service.dart';
import '/backend/api/timesheet_service.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/widgets/for_civil_layout.dart';

class RegisterTareoWidget extends StatefulWidget {
  const RegisterTareoWidget({super.key});

  static String routeName = 'RegisterTareo';
  static String routePath = '/registerTareo';

  @override
  State<RegisterTareoWidget> createState() => _RegisterTareoWidgetState();
}

class _RegisterTareoWidgetState extends State<RegisterTareoWidget> {
  final _planService = PlanService();
  final _crewService = CrewService();

  bool _initialized = false;
  late Future<_RegisterData> _dataFuture;
  int? _selectedCrewId;
  DateTime _selectedDate = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _dataFuture = _loadData();
      _initialized = true;
    }
  }

  Future<_RegisterData> _loadData() async {
    final authState = context.read<AuthState>();
    final token = authState.token;
    final profile = authState.profile;
    final project = authState.selectedProject;

    if (token == null || profile == null || project == null) {
      throw ApiException(
        'Debes iniciar sesión y seleccionar un proyecto para registrar tareos',
      );
    }

    final phasesFuture = _planService.fetchStructure(
      token: token,
      projectId: project.projectId,
    );
    final crewsFuture = _crewService.fetchCrews(
      userId: profile.id,
      projectId: project.projectId,
      token: token,
    );

    final phases = await phasesFuture;
    final crews = await crewsFuture;
    return _RegisterData(phases: phases, crews: crews);
  }

  Future<void> _reload() async {
    setState(() {
      _dataFuture = _loadData();
    });
    await _dataFuture;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year + 1, now.month, now.day);
    final newDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecciona la fecha de trabajo',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      locale: const Locale('es'),
    );
    if (newDate != null) {
      setState(() => _selectedDate = newDate);
    }
  }

  Future<void> _openAssignment(PlanPartida partida, Crew crew) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CrewAssignmentPage(
          partida: partida,
          crew: crew,
          workDate: _selectedDate,
        ),
      ),
    );

    if (result == true && mounted) {
      _showMessage('Horas registradas para ${partida.name}');
    }
  }

  List<PlanPhase> _filterPhasesForCrew(
    List<PlanPhase> phases,
    Crew crew,
  ) {
    final codeSet = crew.partidas
        .map((p) => _normalizeCode(p.code))
        .whereType<String>()
        .toSet();
    final nameSet = crew.partidas
        .map((p) => _normalizeName(p.name))
        .whereType<String>()
        .toSet();

    PlanPartida? filterPartida(PlanPartida partida) {
      final filteredChildren = partida.children
          .map(filterPartida)
          .whereType<PlanPartida>()
          .toList();
      final codeMatch = codeSet.isNotEmpty
          ? codeSet.contains(_normalizeCode(partida.code))
          : false;
      final nameMatch = nameSet.isNotEmpty
          ? nameSet.contains(_normalizeName(partida.name))
          : false;
      if (!codeMatch && !nameMatch && filteredChildren.isEmpty) {
        return null;
      }
      return PlanPartida(
        id: partida.id,
        code: partida.code,
        name: partida.name,
        unit: partida.unit,
        metric: partida.metric,
        children: filteredChildren,
        leaf: filteredChildren.isEmpty,
      );
    }

    final filteredPhases = <PlanPhase>[];
    for (final phase in phases) {
      final filteredPartidas = phase.partidas
          .map(filterPartida)
          .whereType<PlanPartida>()
          .toList();
      if (filteredPartidas.isEmpty) {
        continue;
      }
      filteredPhases.add(
        PlanPhase(
          phaseId: phase.phaseId,
          phaseName: phase.phaseName,
          partidas: filteredPartidas,
        ),
      );
    }
    return filteredPhases;
  }

  String? _normalizeCode(String? code) {
    if (code == null) {
      return null;
    }
    final normalized = code.trim().toUpperCase();
    return normalized.isEmpty ? null : normalized;
  }

  String? _normalizeName(String? name) {
    if (name == null) {
      return null;
    }
    final normalized = name.trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
              'Registrar tareo',
              style: theme.headlineMedium.override(
                font: GoogleFonts.interTight(
                  fontWeight: FontWeight.w700,
                  fontStyle: theme.headlineMedium.fontStyle,
                ),
                color: theme.primaryText,
              ),
            ),
            Text(
              'Selecciona la fase, partida o subpartida trabajada y asigna horas reales a tu cuadrilla.',
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(),
                color: theme.mutedforeground,
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: FutureBuilder<_RegisterData>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _RegisterError(
                      message: snapshot.error?.toString() ?? 'Error inesperado',
                      onRetry: _reload,
                    );
                  }
                  final data = snapshot.data;
                  if (data == null || data.phases.isEmpty) {
                    return _RegisterError(
                      message:
                          'No encontramos fases o partidas configuradas para este proyecto.',
                      onRetry: _reload,
                      isInfo: true,
                    );
                  }
                  final crews = data.crews;
                  Crew? selectedCrew;
                  for (final crew in crews) {
                    if (crew.id == _selectedCrewId) {
                      selectedCrew = crew;
                      break;
                    }
                  }

                  final dateSelector = _DateSelector(
                    date: _selectedDate,
                    onTap: _pickDate,
                  );

                  if (selectedCrew == null) {
                    return Column(
                      children: [
                        dateSelector,
                        const SizedBox(height: 12.0),
                        Expanded(
                          child: _CrewSelectionView(
                            crews: crews,
                            onSelect: (crew) =>
                                setState(() => _selectedCrewId = crew.id),
                          ),
                        ),
                      ],
                    );
                  }

                  final crew = selectedCrew!;
                  final filteredPhases =
                      _filterPhasesForCrew(data.phases, crew);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 960;
                      final phasePanel = _PhasePanel(
                        phases: filteredPhases,
                        onAssign: (partida) => _openAssignment(partida, crew),
                      );
                      final crewHeader = _SelectedCrewHeader(
                        crew: crew,
                        onChange: () => setState(() => _selectedCrewId = null),
                      );

                      return Column(
                        children: [
                          dateSelector,
                          const SizedBox(height: 12.0),
                          crewHeader,
                          const SizedBox(height: 12.0),
                          Expanded(child: phasePanel),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhasePanel extends StatelessWidget {
  const _PhasePanel({required this.phases, required this.onAssign});

  final List<PlanPhase> phases;
  final void Function(PlanPartida partida) onAssign;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (phases.isEmpty) {
      return Center(
        child: Text(
          'Esta cuadrilla no tiene partidas asignadas en el plan.',
          textAlign: TextAlign.center,
          style: theme.bodyMedium.override(
            font: GoogleFonts.inter(),
            color: theme.mutedforeground,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fases y partidas',
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(
              fontWeight: FontWeight.w600,
              fontStyle: theme.titleMedium.fontStyle,
            ),
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12.0),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
            itemCount: phases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16.0),
            itemBuilder: (context, index) {
              final phase = phases[index];
              return Container(
                decoration: BoxDecoration(
                  color: theme.card,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: theme.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 18.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    listTileTheme: ListTileThemeData(
                      iconColor: theme.primaryText,
                      textColor: theme.primaryText,
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 4.0,
                    ),
                    title: Text(
                      phase.phaseName,
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w500,
                          fontStyle: theme.titleSmall.fontStyle,
                        ),
                        color: theme.primaryText,
                      ),
                    ),
                    children: phase.partidas
                        .map((partida) => _PartidaTile(
                              partida: partida,
                              onAssign: onAssign,
                              level: 0,
                            ))
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PartidaTile extends StatelessWidget {
  const _PartidaTile({
    required this.partida,
    required this.onAssign,
    required this.level,
  });

  final PlanPartida partida;
  final void Function(PlanPartida partida) onAssign;
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final indent = 20.0 * level;
    if (partida.children.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(left: indent, right: 12.0),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12.0),
          title: Text(
            '${partida.code} · ${partida.name}',
            style: theme.titleSmall,
          ),
          children: partida.children
              .map(
                (child) => _PartidaTile(
                  partida: child,
                  onAssign: onAssign,
                  level: level + 1,
                ),
              )
              .toList(),
        ),
      );
    }
    final metricLabel = partida.metric != null
        ? 'Metrado: ${partida.metric!.toStringAsFixed(1)} ${partida.unit ?? ''}'
        : null;
    return Container(
      margin: EdgeInsets.fromLTRB(indent + 20.0, 12.0, 20.0, 4.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${partida.code} · ${partida.name}',
                    style: theme.titleSmall.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FontWeight.w500,
                        fontStyle: theme.titleSmall.fontStyle,
                      ),
                      color: theme.primaryText,
                    ),
                  ),
                  if (metricLabel != null)
                    Text(
                      metricLabel,
                      style: theme.bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: theme.mutedforeground,
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => onAssign(partida),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primarycolor,
                foregroundColor: theme.primaryforeground,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.launch, size: 18.0),
              label: const Text('Asignar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: theme.border),
      ),
      child: ListTile(
        title: Text(
          'Fecha de trabajo',
          style: theme.labelLarge,
        ),
        subtitle: Text(
          dateTimeFormat('EEEE d MMMM y', date, locale: 'es'),
          style: theme.bodyMedium,
        ),
        trailing: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.calendar_today),
          label: const Text('Cambiar'),
        ),
      ),
    );
  }
}

class _CrewSelectionView extends StatelessWidget {
  const _CrewSelectionView({required this.crews, required this.onSelect});

  final List<Crew> crews;
  final ValueChanged<Crew> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    if (crews.isEmpty) {
      return _RegisterError(
        message:
            'No tienes cuadrillas asignadas en este proyecto todavía.',
        onRetry: () {},
        isInfo: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona la cuadrilla con la que deseas registrar el tareo.',
          style: theme.bodyMedium,
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: ListView.separated(
            itemCount: crews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12.0),
            itemBuilder: (context, index) {
              final crew = crews[index];
              return InkWell(
                onTap: () => onSelect(crew),
                borderRadius: BorderRadius.circular(18.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(18.0),
                    border: Border.all(color: theme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crew.name,
                        style: theme.titleMedium,
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Integrantes: ${crew.members.length}\nCapataz: ${crew.foremanName}',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: theme.mutedforeground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelectedCrewHeader extends StatelessWidget {
  const _SelectedCrewHeader({required this.crew, required this.onChange});

  final Crew crew;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.primarycolor.withOpacity(0.15),
            child: Icon(Icons.groups, color: theme.primarycolor),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crew.name,
                  style: theme.titleMedium,
                ),
                Text(
                  'Integrantes: ${crew.members.length} · Capataz: ${crew.foremanName}',
                  style: theme.bodySmall.override(
                    font: GoogleFonts.inter(),
                    color: theme.mutedforeground,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

class _RegisterError extends StatelessWidget {
  const _RegisterError({
    required this.message,
    required this.onRetry,
    this.isInfo = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isInfo;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isInfo ? Icons.info_outline : Icons.error_outline,
            size: 48,
            color: isInfo ? theme.mutedforeground : theme.error,
          ),
          const SizedBox(height: 16.0),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.bodyLarge,
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class CrewAssignmentPage extends StatefulWidget {
  const CrewAssignmentPage({
    required this.partida,
    required this.crew,
    required this.workDate,
  });

  final PlanPartida partida;
  final Crew crew;
  final DateTime workDate;

  @override
  State<CrewAssignmentPage> createState() => _CrewAssignmentPageState();
}

class _CrewAssignmentPageState extends State<CrewAssignmentPage> {
  late final Map<int, TextEditingController> _normalControllers;
  late final Map<int, TextEditingController> _extraControllers;
  final _timesheetService = TimesheetService();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _normalControllers = {
      for (final member in widget.crew.members)
        member.id: TextEditingController(),
    };
    _extraControllers = {
      for (final member in widget.crew.members)
        member.id: TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final controller in _normalControllers.values) {
      controller.dispose();
    }
    for (final controller in _extraControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final authState = context.read<AuthState>();
    final token = authState.token;
    final project = authState.selectedProject;

    if (token == null || project == null) {
      setState(() {
        _error = 'Debes iniciar sesión nuevamente';
      });
      return;
    }

    final lines = <TimesheetLineInput>[];
    for (final member in widget.crew.members) {
      final regular = double.tryParse(
            _normalControllers[member.id]?.text.replaceAll(',', '.') ?? '',
          ) ??
          0;
      final extra = double.tryParse(
            _extraControllers[member.id]?.text.replaceAll(',', '.') ?? '',
          ) ??
          0;
      if (regular <= 0 && extra <= 0) {
        continue;
      }
      lines.add(
        TimesheetLineInput(
          personId: member.id,
          partidaId: widget.partida.id,
          hoursRegular: regular.clamp(0, 24).toDouble(),
          hoursOvertime: extra.clamp(0, 24).toDouble(),
        ),
      );
    }

    if (lines.isEmpty) {
      setState(() {
        _error = 'Ingresa al menos un registro de horas';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await _timesheetService.createTimesheet(
        token: token,
        projectId: project.projectId,
        crewId: widget.crew.id,
        workDate: widget.workDate,
        lines: lines,
        note: 'Registro desde app',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
        () => _error = 'No se pudo guardar el tareo. Inténtalo nuevamente',
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: const Text('Asignar horas'),
        backgroundColor: theme.primaryBackground,
        foregroundColor: theme.primaryText,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: theme.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
                side: BorderSide(color: theme.border),
              ),
              child: ListTile(
                title: Text(
                  widget.partida.name,
                  style: FlutterFlowTheme.of(context)
                      .titleMedium
                      .override(font: GoogleFonts.interTight()),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.partida.metric != null)
                      Text(
                        'Metrado: ${widget.partida.metric} ${widget.partida.unit ?? ''}',
                        style: FlutterFlowTheme.of(context).bodySmall,
                      ),
                    Text(
                      'Fecha: ${dateTimeFormat('d MMMM y', widget.workDate, locale: 'es')}',
                      style: FlutterFlowTheme.of(context)
                          .labelMedium
                          .override(
                            font: GoogleFonts.inter(),
                            color: theme.mutedforeground,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            Card(
              color: theme.secondaryBackground,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
                side: BorderSide(color: theme.border),
              ),
              child: ListTile(
                title: Text('Cuadrilla: ${widget.crew.name}'),
                subtitle: Text(
                  '${widget.crew.members.length} integrantes',
                  style: theme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  _error!,
                  style: theme.bodyMedium.override(color: theme.error),
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: widget.crew.members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                itemBuilder: (context, index) {
                  final member = widget.crew.members[index];
                  return Card(
                    color: theme.card,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      side: BorderSide(color: theme.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage: member.photoUrl != null
                                    ? NetworkImage(member.photoUrl!)
                                    : null,
                                child: member.photoUrl == null
                                    ? Text(
                                        member.fullName.isNotEmpty
                                            ? member.fullName[0]
                                            : member.name[0],
                                        style: theme.titleMedium,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.fullName,
                                      style:
                                          FlutterFlowTheme.of(context).titleSmall,
                                    ),
                                    Text(
                                      '${member.category} · ${member.specialty}',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.inter(),
                                            color: theme.mutedforeground,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _normalControllers[member.id],
                                  enabled: !_submitting,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: _hoursDecoration(
                                      context, 'Horas normales'),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: TextField(
                                  controller: _extraControllers[member.id],
                                  enabled: !_submitting,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration:
                                      _hoursDecoration(context, 'Horas extra'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primarycolor,
                  foregroundColor: theme.primaryforeground,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar horas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _hoursDecoration(BuildContext context, String label) {
    final theme = FlutterFlowTheme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: '0',
      filled: true,
      fillColor: theme.secondaryBackground,
      labelStyle: TextStyle(color: theme.mutedforeground),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: theme.primarycolor),
      ),
    );
  }
}

class _RegisterData {
  _RegisterData({required this.phases, required this.crews});

  final List<PlanPhase> phases;
  final List<Crew> crews;
}
