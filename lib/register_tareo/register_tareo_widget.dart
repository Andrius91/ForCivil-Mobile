import 'package:cached_network_image/cached_network_image.dart';
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
  final _timesheetService = TimesheetService();

  bool _initialized = false;
  late Future<_RegisterData> _dataFuture;
  int? _selectedCrewId;
  DateTime _selectedDate = DateTime.now();
  final Map<int, List<PlanPhase>> _filteredCache = {};
  final Map<int, List<_PendingEntry>> _pendingEntries = {};
  bool _isSubmittingTareo = false;
  String? _submitError;
  bool _isConfigured = false;

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
    await authState.ensureValidToken();
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
      _filteredCache.clear();
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
    final result = await Navigator.of(context).push<_AssignmentResult>(
      MaterialPageRoute(
        builder: (_) => CrewAssignmentPage(
          partida: partida,
          crew: crew,
          workDate: _selectedDate,
        ),
      ),
    );

    if (result != null && result.lines.isNotEmpty) {
      setState(() {
        _pendingEntries.putIfAbsent(crew.id, () => []).addAll(
              result.lines
                  .map(
                    (line) => _PendingEntry(
                      memberId: line.memberId,
                      memberName: line.memberName,
                      partidaId: line.partidaId,
                      partidaName: line.partidaName,
                      hoursRegular: line.hoursRegular,
                      hoursExtra: line.hoursExtra,
                    ),
                  )
                  .toList(),
            );
      });
      _showMessage('Horas guardadas en borrador para ${partida.name}');
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

  void _clearPending(int crewId) {
    setState(() {
      _pendingEntries.remove(crewId);
      _submitError = null;
    });
  }

  Future<void> _showPendingDetail(Crew crew) async {
    final entries = _pendingEntries[crew.id];
    if (entries == null || entries.isEmpty) {
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _PendingEntriesDetail(
            entries: entries,
            date: _selectedDate,
            isSubmitting: _isSubmittingTareo,
            errorMessage: _submitError,
            onClear: () {
              Navigator.of(context).pop();
              _clearPending(crew.id);
            },
            onSubmit: () {
              Navigator.of(context).pop();
              _submitPendingEntries(crew);
            },
          ),
        );
      },
    );
  }

  Future<void> _submitPendingEntries(Crew crew) async {
    final pending = _pendingEntries[crew.id];
    if (pending == null || pending.isEmpty) {
      _showMessage('No hay horas pendientes para enviar.');
      return;
    }

    final authState = context.read<AuthState>();
    await authState.ensureValidToken();
    final token = authState.token;
    final project = authState.selectedProject;

    if (token == null || project == null) {
      _showMessage('Debes iniciar sesión nuevamente.');
      return;
    }

    final lines = pending
        .map(
          (entry) => TimesheetLineInput(
            personId: entry.memberId,
            partidaId: entry.partidaId,
            hoursRegular: entry.hoursRegular,
            hoursOvertime: entry.hoursExtra,
          ),
        )
        .toList();

    setState(() {
      _isSubmittingTareo = true;
      _submitError = null;
    });

    try {
      await _timesheetService.createTimesheet(
        token: token,
        projectId: project.projectId,
        crewId: crew.id,
        workDate: _selectedDate,
        lines: lines,
        note: 'Registro desde app',
      );
      setState(() {
        _pendingEntries.remove(crew.id);
      });
      _showMessage('Tareo enviado correctamente');
    } on ApiException catch (e) {
      setState(() => _submitError = e.message);
    } catch (_) {
      setState(
        () => _submitError =
            'No se pudo enviar el tareo. Revisa tu conexión e inténtalo nuevamente.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingTareo = false);
      }
    }
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

                  if (!_isConfigured || selectedCrew == null) {
                    return _SetupView(
                      date: _selectedDate,
                      crews: crews,
                      selectedCrewId: _selectedCrewId,
                      onSelectCrew: (crew) => setState(() {
                        _selectedCrewId = crew.id;
                      }),
                      onChangeDate: _pickDate,
                      onContinue: selectedCrew == null
                          ? null
                          : () => setState(() => _isConfigured = true),
                    );
                  }

                  final crew = selectedCrew;
                  final filteredPhases =
                      _filteredCache[crew.id] ??=
                          _filterPhasesForCrew(data.phases, crew);
                  final crewPending = _pendingEntries[crew.id] ?? const [];

                  final phasePanel = _PhasePanel(
                    phases: filteredPhases,
                    onAssign: (partida) => _openAssignment(partida, crew),
                  );

                  return Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              _InfoChip(
                                icon: Icons.calendar_month,
                                label: dateTimeFormat(
                                    'EEE d MMM', _selectedDate,
                                    locale: 'es'),
                                onTap: _pickDate,
                              ),
                              _InfoChip(
                                icon: Icons.groups,
                                label: crew.name,
                                onTap: () => setState(() {
                                  _isConfigured = false;
                                }),
                              ),
                            ],
                          ),
                          if (crewPending.isNotEmpty) ...[
                            const SizedBox(height: 8.0),
                            Text(
                              '${crewPending.length} registros en borrador',
                              style: theme.bodySmall.override(
                                font: GoogleFonts.inter(),
                                color: theme.mutedforeground,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12.0),
                          Expanded(child: phasePanel),
                        ],
                      ),
                      if (crewPending.isNotEmpty)
                        Positioned(
                          bottom: 24,
                          right: 24,
                          child: FloatingActionButton.extended(
                            onPressed: () => _showPendingDetail(crew),
                            icon: const Icon(Icons.outbox),
                            label: Text('Enviar (${crewPending.length})'),
                          ),
                        ),
                    ],
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
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24.0),
      itemCount: phases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final phase = phases[index];
        return Container(
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(color: theme.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              title: Text(
                phase.phaseName,
                style: theme.titleSmall,
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

class _InitialSelectionStep extends StatelessWidget {
  const _InitialSelectionStep({
    required this.date,
    required this.crews,
    required this.selectedCrew,
    required this.onSelectCrew,
    required this.onChangeDate,
    required this.onConfirm,
  });

  final DateTime date;
  final List<Crew> crews;
  final Crew? selectedCrew;
  final ValueChanged<Crew> onSelectCrew;
  final VoidCallback onChangeDate;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateSelector(date: date, onTap: onChangeDate),
        const SizedBox(height: 12.0),
        if (selectedCrew != null)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: theme.border),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(selectedCrew!.name, style: theme.titleMedium),
                      Text(
                        'Integrantes: ${selectedCrew!.members.length}\nCapataz: ${selectedCrew!.foremanName}',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: theme.mutedforeground,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('Continuar'),
                )
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Selecciona una cuadrilla para continuar',
              style: theme.bodyMedium,
            ),
          ),
        SizedBox(
          height: 280,
          child: _CrewSelectionView(
            crews: crews,
            selectedCrewId: selectedCrew?.id,
            onSelect: onSelectCrew,
          ),
        ),
      ],
    );
  }
}

class _CrewSelectionView extends StatelessWidget {
  const _CrewSelectionView({
    required this.crews,
    required this.onSelect,
    this.selectedCrewId,
  });

  final List<Crew> crews;
  final ValueChanged<Crew> onSelect;
  final int? selectedCrewId;

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
    return ListView.separated(
      itemCount: crews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        final crew = crews[index];
        final isSelected = crew.id == selectedCrewId;
        return InkWell(
          onTap: () => onSelect(crew),
          borderRadius: BorderRadius.circular(18.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.primarycolor.withOpacity(0.08)
                  : theme.card,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(
                color: isSelected ? theme.primarycolor : theme.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        crew.name,
                        style: theme.titleMedium,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: theme.primarycolor),
                  ],
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


class _PendingEntry {
  _PendingEntry({
    required this.memberId,
    required this.memberName,
    required this.partidaId,
    required this.partidaName,
    required this.hoursRegular,
    required this.hoursExtra,
  });

  final int memberId;
  final String memberName;
  final int partidaId;
  final String partidaName;
  final double hoursRegular;
  final double hoursExtra;
}

class _PendingEntriesDetail extends StatelessWidget {
  const _PendingEntriesDetail({
    required this.entries,
    required this.date,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onClear,
    this.errorMessage,
  });

  final List<_PendingEntry> entries;
  final DateTime date;
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final grouped = <int, List<_PendingEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.partidaId, () => []).add(entry);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detalle del tareo', style: theme.titleMedium),
                      Text(
                        dateTimeFormat('EEEE d MMMM y', date, locale: 'es'),
                        style: theme.bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: theme.mutedforeground,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: grouped.entries.map((entry) {
                  final partidaName = entry.value.first.partidaName;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partidaName, style: theme.labelLarge),
                        ...entry.value.map(
                          (line) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(line.memberName, style: theme.bodyMedium),
                            subtitle: Text(
                              'Normales: ${line.hoursRegular} · Extra: ${line.hoursExtra}',
                              style: theme.bodySmall.override(
                                font: GoogleFonts.inter(),
                                color: theme.mutedforeground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8.0),
              Text(
                errorMessage!,
                style: theme.bodyMedium.override(color: theme.error),
              ),
            ],
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting ? null : onClear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Vaciar'),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(isSubmitting ? 'Enviando...' : 'Enviar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupView extends StatelessWidget {
  const _SetupView({
    required this.date,
    required this.crews,
    required this.selectedCrewId,
    required this.onSelectCrew,
    required this.onChangeDate,
    this.onContinue,
  });

  final DateTime date;
  final List<Crew> crews;
  final int? selectedCrewId;
  final ValueChanged<Crew> onSelectCrew;
  final VoidCallback onChangeDate;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DateSelector(date: date, onTap: onChangeDate),
        const SizedBox(height: 12.0),
        Text('Selecciona una cuadrilla', style: theme.titleMedium),
        const SizedBox(height: 8.0),
        Expanded(
          child: _CrewSelectionView(
            crews: crews,
            selectedCrewId: selectedCrewId,
            onSelect: onSelectCrew,
          ),
        ),
        SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  selectedCrewId == null ? null : onContinue,
              child: const Text('Continuar'),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.0, color: theme.primaryText),
            const SizedBox(width: 6.0),
            Text(label, style: theme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _AssignmentResult {
  _AssignmentResult({required this.lines});

  final List<_AssignmentLine> lines;
}

class _AssignmentLine {
  _AssignmentLine({
    required this.memberId,
    required this.memberName,
    required this.partidaId,
    required this.partidaName,
    required this.hoursRegular,
    required this.hoursExtra,
  });

  final int memberId;
  final String memberName;
  final int partidaId;
  final String partidaName;
  final double hoursRegular;
  final double hoursExtra;
}

class _HoursStepper extends StatelessWidget {
  const _HoursStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.labelLarge,
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              IconButton(
                onPressed: enabled
                    ? () => onChanged(_decrement(value))
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                    style: theme.headlineSmall,
                  ),
                ),
              ),
              IconButton(
                onPressed: enabled
                    ? () => onChanged(_increment(value))
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _increment(double current) => (current + 0.5).clamp(0, 24);
  double _decrement(double current) => (current - 0.5).clamp(0, 24);
}

ImageProvider? _memberPhotoProvider(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }
  return CachedNetworkImageProvider(url);
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
  final Map<int, double> _normalHours = {};
  final Map<int, double> _extraHours = {};
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final member in widget.crew.members) {
      _normalHours[member.id] = 0;
      _extraHours[member.id] = 0;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _save() async {
    final entries = <_AssignmentLine>[];
    for (final member in widget.crew.members) {
      final regular = _normalHours[member.id] ?? 0;
      final extra = _extraHours[member.id] ?? 0;
      if (regular <= 0 && extra <= 0) {
        continue;
      }
      final name = member.fullName.isNotEmpty ? member.fullName : member.name;
      entries.add(
        _AssignmentLine(
          memberId: member.id,
          memberName: name,
          partidaId: widget.partida.id,
          partidaName: widget.partida.name,
          hoursRegular: regular.clamp(0, 24).toDouble(),
          hoursExtra: extra.clamp(0, 24).toDouble(),
        ),
      );
    }

    if (entries.isEmpty) {
      setState(() {
        _error = 'Ingresa al menos un registro de horas';
      });
      return;
    }

    setState(() => _error = null);
    Navigator.of(context).pop(_AssignmentResult(lines: entries));
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
                                backgroundImage:
                                    _memberPhotoProvider(member.photoUrl),
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
                                child: _HoursStepper(
                                  label: 'Horas normales',
                                  value: _normalHours[member.id] ?? 0,
                                  enabled: !_submitting,
                                  onChanged: (value) => setState(() {
                                    _normalHours[member.id] = value;
                                  }),
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: _HoursStepper(
                                  label: 'Horas extra',
                                  value: _extraHours[member.id] ?? 0,
                                  enabled: !_submitting,
                                  onChanged: (value) => setState(() {
                                    _extraHours[member.id] = value;
                                  }),
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

}

class _RegisterData {
  _RegisterData({required this.phases, required this.crews});

  final List<PlanPhase> phases;
  final List<Crew> crews;
}
