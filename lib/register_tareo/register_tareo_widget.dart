import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/backend/api/attendance_service.dart';
import '/backend/api/auth_service.dart';
import '/backend/api/auth_state.dart';
import '/backend/api/crew_service.dart';
import '/backend/api/plan_service.dart';
import '/backend/api/timesheet_service.dart';
import '/backend/api/project_service.dart';
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
  final _projectService = ProjectService();
  final _attendanceService = AttendanceService();

  bool _initialized = false;
  late Future<_RegisterData> _dataFuture;
  int? _selectedCrewId;
  DateTime _selectedDate = DateTime.now();
  final Map<int, List<PlanPhase>> _filteredCache = {};
  final Map<int, List<_PendingEntry>> _pendingEntries = {};
  bool _isSubmittingTareo = false;
  String? _submitError;
  bool _isConfigured = false;
  ProjectDetail? _projectDetail;
  bool _attendanceLoading = false;
  bool _attendanceReady = false;
  String? _attendanceError;
  Map<int, AttendanceRecord> _attendanceByMember = {};
  DateTime? _attendanceDate;
  int? _attendanceCrewId;

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
    final projectFuture = _projectService.fetchProject(
      token: token,
      projectId: project.projectId,
    );

    final phases = await phasesFuture;
    final crews = await crewsFuture;
    final projectDetail = await projectFuture;

    _projectDetail = projectDetail;

    return _RegisterData(
      phases: phases,
      crews: crews,
      project: projectDetail,
    );
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
      if (_selectedCrewId != null) {
        unawaited(_loadAttendanceForCrew(_selectedCrewId!, newDate));
      } else {
        _resetAttendanceState();
      }
    }
  }

  void _resetAttendanceState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _attendanceByMember = {};
      _attendanceReady = false;
      _attendanceError = null;
      _attendanceCrewId = null;
      _attendanceDate = null;
      _attendanceLoading = false;
    });
  }

  bool _attendanceMatchesSelection(int crewId, DateTime date) {
    if (!_attendanceReady || _attendanceCrewId != crewId) {
      return false;
    }
    final currentDate = _attendanceDate;
    if (currentDate == null) {
      return false;
    }
    return DateUtils.isSameDay(currentDate, date);
  }

  Future<bool> _ensureAttendanceForCrew(int crewId, DateTime date) async {
    if (_attendanceMatchesSelection(crewId, date)) {
      return true;
    }
    return _loadAttendanceForCrew(crewId, date);
  }

  Future<bool> _loadAttendanceForCrew(int crewId, DateTime date) async {
    final authState = context.read<AuthState>();
    await authState.ensureValidToken();
    final token = authState.token;
    final project = authState.selectedProject;
    if (token == null || project == null) {
      setState(() {
        _attendanceError = 'Debes iniciar sesión y seleccionar un proyecto.';
        _attendanceByMember = {};
        _attendanceReady = false;
        _attendanceCrewId = null;
        _attendanceDate = null;
      });
      return false;
    }

    setState(() {
      _attendanceLoading = true;
      _attendanceError = null;
      _attendanceReady = false;
    });

    try {
      final records = await _attendanceService.fetchCrewAttendance(
        token: token,
        projectId: project.projectId,
        crewId: crewId,
        date: date,
      );
      final mapped = <int, AttendanceRecord>{};
      for (final record in records) {
        final memberId = record.personId;
        if (memberId != null) {
          mapped[memberId] = record;
        }
      }
      if (!mounted) {
        return false;
      }
      setState(() {
        _attendanceByMember = mapped;
        _attendanceCrewId = crewId;
        _attendanceDate = date;
        _attendanceLoading = false;
        _attendanceReady = true;
      });
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _attendanceLoading = false;
        _attendanceError = error.toString();
        _attendanceByMember = {};
        _attendanceReady = false;
        _attendanceCrewId = null;
        _attendanceDate = null;
      });
      return false;
    }
  }

  Future<void> _openAssignment(PlanPartida partida, Crew crew) async {
    final attendanceOk = await _ensureAttendanceForCrew(crew.id, _selectedDate);
    if (!attendanceOk) {
      _showMessage('No se pudo obtener la asistencia para esta fecha.');
      return;
    }
    final normalLimit = _projectDetail?.limitForDate(_selectedDate);
    final remainingPerMember = <int, double>{};
    final remainingExtraPerMember = <int, double>{};
    final attendance = Map<int, AttendanceRecord>.from(_attendanceByMember);
    final existingEntries =
        (_pendingEntries[crew.id] ?? const []).where((entry) =>
            entry.partidaId == partida.id);
    final initialNormal = <int, double>{};
    final initialExtra = <int, double>{};
    for (final entry in existingEntries) {
      initialNormal[entry.memberId] = entry.hoursRegular;
      initialExtra[entry.memberId] = entry.hoursExtra;
    }
    final pendingEntries = _pendingEntries[crew.id] ?? const [];
    final usedNormal = <int, double>{};
    final usedExtra = <int, double>{};
    for (final entry in pendingEntries) {
      if (entry.partidaId == partida.id) {
        continue;
      }
      usedNormal.update(
        entry.memberId,
        (value) => value + entry.hoursRegular,
        ifAbsent: () => entry.hoursRegular,
      );
      usedExtra.update(
        entry.memberId,
        (value) => value + entry.hoursExtra,
        ifAbsent: () => entry.hoursExtra,
      );
    }
    for (final member in crew.members) {
      final record = attendance[member.id];
      if (record == null || !record.present) {
        continue;
      }
      double? allowedNormal = record.hoursNormal;
      if (normalLimit != null) {
        if (allowedNormal != null) {
          allowedNormal = allowedNormal > normalLimit ? normalLimit : allowedNormal;
        } else {
          allowedNormal = normalLimit;
        }
      }
      final usableNormal = ((allowedNormal ?? 0).clamp(0, 24)).toDouble();
      final usedHours = usedNormal[member.id] ?? 0;
      final remainingNormal = usableNormal - usedHours;
      remainingPerMember[member.id] =
          remainingNormal > 0 ? remainingNormal : 0;

      final allowedExtra = ((record.hoursExtra ?? 0).clamp(0, 24)).toDouble();
      final usedExtraHours = usedExtra[member.id] ?? 0;
      final remainingExtra = allowedExtra - usedExtraHours;
      remainingExtraPerMember[member.id] =
          remainingExtra > 0 ? remainingExtra : 0;
    }

    final result = await Navigator.of(context).push<_AssignmentResult>(
      MaterialPageRoute(
        builder: (_) => CrewAssignmentPage(
          partida: partida,
          crew: crew,
          workDate: _selectedDate,
          normalHourLimit: normalLimit,
          remainingNormalHours: remainingPerMember.isEmpty
              ? null
              : remainingPerMember,
          remainingExtraHours:
              remainingExtraPerMember.isEmpty ? null : remainingExtraPerMember,
          attendanceRecords: Map<int, AttendanceRecord>.from(attendance),
          initialNormalHours: initialNormal.isEmpty ? null : initialNormal,
          initialExtraHours: initialExtra.isEmpty ? null : initialExtra,
        ),
      ),
    );

    if (result != null && result.lines.isNotEmpty) {
      setState(() {
        _pendingEntries.putIfAbsent(crew.id, () => []);
        _pendingEntries[crew.id]!
            .removeWhere((entry) => entry.partidaId == partida.id);
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
                  _projectDetail ??= data.project;

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
                      onSelectCrew: (crew) {
                        setState(() {
                          _selectedCrewId = crew.id;
                        });
                        unawaited(
                          _loadAttendanceForCrew(crew.id, _selectedDate),
                        );
                      },
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _InfoChip(
                            icon: Icons.calendar_month,
                            label: dateTimeFormat('EEE d MMM', _selectedDate,
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
                      const SizedBox(height: 12.0),
                      if (_attendanceLoading)
                        const LinearProgressIndicator(),
                      if (_attendanceError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'No se pudo sincronizar la asistencia: $_attendanceError',
                            style: theme.bodySmall.override(
                              font: GoogleFonts.inter(),
                              color: theme.error,
                            ),
                          ),
                        ),
                      if (_attendanceLoading || _attendanceError != null)
                        const SizedBox(height: 12.0),
                      Expanded(child: phasePanel),
                      SafeArea(
                        top: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (crewPending.isNotEmpty)
                              Text(
                                '${crewPending.length} partidas con horas en borrador',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: theme.mutedforeground,
                                ),
                              )
                            else
                              Text(
                                'Guarda horas en una partida para habilitar el envío.',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: theme.mutedforeground,
                                ),
                              ),
                            const SizedBox(height: 8.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: crewPending.isEmpty
                                    ? null
                                    : () => _showPendingDetail(crew),
                                icon: const Icon(Icons.send),
                                label: Text(crewPending.isEmpty
                                    ? 'Enviar tareo'
                                    : 'Enviar tareo (${crewPending.length})'),
                              ),
                            ),
                          ],
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
  double get totalHours => hoursRegular + hoursExtra;
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
    this.maxValue = 24,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: enabled ? () => _openNumberPad(context) : null,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.labelMedium.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatValue(value),
                          style: theme.displaySmall,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Disponible: ${maxValue.toStringAsFixed(1)} h',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.inter(color: theme.mutedforeground),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              Expanded(
                child: _StepperActionButton(
                  icon: Icons.add,
                  onTap: enabled ? () => onChanged(_increment(value)) : null,
                  height: 50,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: _StepperActionButton(
                  icon: Icons.remove,
                  onTap: enabled ? () => onChanged(_decrement(value)) : null,
                  height: 50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatValue(double value) =>
      value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

  double _increment(double current) => (current + 0.5).clamp(0, maxValue);
  double _decrement(double current) => (current - 0.5).clamp(0, maxValue);

  Future<void> _openNumberPad(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    String inputValue = _formatValue(value);

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final parsedValue = double.tryParse(inputValue);
            final exceedsMax =
                parsedValue != null && parsedValue > maxValue;
            final isNegative = parsedValue != null && parsedValue < 0;
            final hasInvalidNumber =
                parsedValue == null && inputValue.isNotEmpty;
            final isValid =
                !hasInvalidNumber && !exceedsMax && !isNegative;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28.0),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Asignar ${label.toLowerCase()}',
                            style: theme.titleMedium.override(
                              font: GoogleFonts.interTight(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, color: theme.mutedforeground),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        decoration: BoxDecoration(
                          color: theme.card,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: theme.border),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Horas totales',
                              style: theme.labelMedium.override(
                                font: GoogleFonts.inter(
                                  color: theme.mutedforeground,
                                ),
                              ),
                            ),
                            Text(
                              inputValue.isEmpty ? '0' : inputValue,
                              style: theme.displaySmall,
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              exceedsMax
                                  ? 'Máximo ${maxValue.toStringAsFixed(1)} h'
                                  : 'Disponible: ${maxValue.toStringAsFixed(1)} h',
                              style: theme.bodySmall.override(
                                font: GoogleFonts.inter(
                                  color: exceedsMax
                                      ? theme.error
                                      : theme.mutedforeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isNegative || hasInvalidNumber)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            isNegative
                                ? 'Ingresa un valor mayor o igual a 0'
                                : 'Ingresa un número válido',
                            style: theme.bodySmall.override(
                              font: GoogleFonts.inter(color: theme.error),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16.0),
                      ..._buildKeyRows(theme, inputValue, (newValue) {
                        setModalState(() => inputValue = newValue);
                      }),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primarycolor,
                                foregroundColor: theme.primaryforeground,
                              ),
                              onPressed: isValid
                                  ? () {
                                      final parsed =
                                          double.tryParse(inputValue) ?? 0;
                                      final normalized =
                                          ((parsed * 2).round() / 2)
                                              .clamp(0, maxValue)
                                              .toDouble();
                                      Navigator.of(context)
                                          .pop(normalized);
                                    }
                                  : null,
                              child: const Text('Aplicar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      onChanged(result);
    }
  }

  List<Widget> _buildKeyRows(
    FlutterFlowTheme theme,
    String inputValue,
    ValueChanged<String> onChangedValue,
  ) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '<'],
    ];
    return rows
        .map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: row
                  .map(
                    (key) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _KeyButton(
                          label: key,
                          theme: theme,
                          onTap: () => onChangedValue(
                            _handleKeyPress(key, inputValue),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        )
        .toList();
  }

  String _handleKeyPress(String key, String current) {
    var value = current;
    if (key == '<') {
      if (value.isNotEmpty) {
        value = value.substring(0, value.length - 1);
      }
      return value;
    }
    if (key == '.') {
      if (value.contains('.')) {
        return value;
      }
      if (value.isEmpty) {
        return '0.5';
      }
      return '$value.5';
    }
    if (value.contains('.')) {
      // Evita agregar más dígitos después de fijar el decimal .5
      return value;
    }
    if (value == '0') {
      value = key;
    } else {
      value += key;
    }
    return value;
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.label,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final FlutterFlowTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.card,
          foregroundColor: theme.primaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
            side: BorderSide(color: theme.border),
          ),
        ),
        onPressed: onTap,
        child: label == '<'
            ? Icon(Icons.backspace_outlined, color: theme.primaryText)
            : Text(
                label,
                style: theme.titleMedium,
              ),
      ),
    );
  }
}

class _StepperActionButton extends StatelessWidget {
  const _StepperActionButton({
    required this.icon,
    required this.onTap,
    this.height = 60,
    this.width,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primarycolor,
          foregroundColor: theme.primaryforeground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: EdgeInsets.zero,
          minimumSize: Size(width ?? 60, height),
        ),
        onPressed: onTap,
        child: Center(child: Icon(icon, size: 22)),
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.title,
    required this.value,
    required this.available,
    required this.enabled,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTapValue,
  });

  final String title;
  final String value;
  final double available;
  final bool enabled;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onTapValue;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTapValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.labelMedium.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                Container(
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.card,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: theme.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: theme.headlineSmall,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Disponible: ${available.toStringAsFixed(1)} h',
                  style: theme.bodySmall.override(
                    font: GoogleFonts.inter(color: theme.mutedforeground),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Column(
          children: [
            _StepperActionButton(
              icon: Icons.add,
              onTap: enabled ? onIncrement : null,
              height: 64,
              width: 44,
            ),
            const SizedBox(height: 8.0),
            _StepperActionButton(
              icon: Icons.remove,
              onTap: enabled ? onDecrement : null,
              height: 64,
              width: 44,
            ),
          ],
        ),
      ],
    );
  }
}

ImageProvider? _memberPhotoProvider(BuildContext context, int personId) {
  final token = context.read<AuthState>().token;
  if (token == null) {
    return null;
  }
  final url = 'https://api.forcivil.com/persons/$personId/photo';
  return CachedNetworkImageProvider(url, headers: {
    'Authorization': 'Bearer $token',
  });
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
    this.normalHourLimit,
    this.remainingNormalHours,
    this.remainingExtraHours,
    this.attendanceRecords,
    this.initialNormalHours,
    this.initialExtraHours,
  });

  final PlanPartida partida;
  final Crew crew;
  final DateTime workDate;
  final double? normalHourLimit;
  final Map<int, double>? remainingNormalHours;
  final Map<int, double>? remainingExtraHours;
  final Map<int, AttendanceRecord>? attendanceRecords;
  final Map<int, double>? initialNormalHours;
  final Map<int, double>? initialExtraHours;

  @override
  State<CrewAssignmentPage> createState() => _CrewAssignmentPageState();
}

class _CrewAssignmentPageState extends State<CrewAssignmentPage> {
  final Map<int, double> _normalHours = {};
  final Map<int, double> _extraHours = {};
  final Map<int, bool> _selectedMembers = {};
  bool _submitting = false;
  String? _error;

  AttendanceRecord? _attendanceFor(int memberId) {
    return widget.attendanceRecords?[memberId];
  }

  bool _canAssignMember(int memberId) {
    final record = _attendanceFor(memberId);
    return record != null && record.present;
  }

  double _maxNormalFor(int memberId) {
    return widget.remainingNormalHours?[memberId] ?? 0;
  }

  double _maxExtraFor(int memberId) {
    return widget.remainingExtraHours?[memberId] ?? 0;
  }

  @override
  void initState() {
    super.initState();
    for (final member in widget.crew.members) {
      final maxNormal = _maxNormalFor(member.id);
      final defaultNormal = widget.initialNormalHours?[member.id];
      final defaultExtra = widget.initialExtraHours?[member.id];
      _normalHours[member.id] =
          defaultNormal ?? (maxNormal > 0 ? maxNormal : 0);
      _extraHours[member.id] = defaultExtra ?? 0;
      final canAssign = _canAssignMember(member.id);
      final hasInitial = (defaultNormal ?? 0) > 0 || (defaultExtra ?? 0) > 0;
      final hasCapacity = maxNormal > 0 || _maxExtraFor(member.id) > 0;
      _selectedMembers[member.id] = canAssign && (hasInitial || hasCapacity);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _save() async {
    final entries = <_AssignmentLine>[];
    for (final member in widget.crew.members) {
      if (!_canAssignMember(member.id)) {
        continue;
      }
      final selected = _selectedMembers[member.id] ?? false;
      if (!selected) {
        continue;
      }
      final maxNormal = _maxNormalFor(member.id);
      final maxExtra = _maxExtraFor(member.id);
      final regularRaw = _normalHours[member.id] ?? 0;
      final extraRaw = _extraHours[member.id] ?? 0;
      final regular = regularRaw > maxNormal ? maxNormal : regularRaw;
      final extra = extraRaw > maxExtra ? maxExtra : extraRaw;
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
                  final attendanceRecord = _attendanceFor(member.id);
                  final canAssign = _canAssignMember(member.id);
                  final normalMax = _maxNormalFor(member.id);
                  final extraMax = _maxExtraFor(member.id);
                  final normalValue =
                      (_normalHours[member.id] ?? 0).clamp(0, normalMax).toDouble();
                  final extraValue =
                      (_extraHours[member.id] ?? 0).clamp(0, extraMax).toDouble();
                  final hasCapacity = normalMax > 0 || extraMax > 0;
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
                  Checkbox(
                    value: _selectedMembers[member.id] ?? false,
                    onChanged: canAssign
                        ? (value) => setState(() {
                              final checked = value ?? false;
                              _selectedMembers[member.id] = checked;
                              if (!checked) {
                                _normalHours[member.id] = 0;
                                _extraHours[member.id] = 0;
                              } else {
                                final maxNormal = _maxNormalFor(member.id);
                                if ((_normalHours[member.id] ?? 0) == 0 &&
                                    maxNormal > 0) {
                                  _normalHours[member.id] = maxNormal;
                                }
                              }
                            })
                        : null,
                    activeColor: theme.primarycolor,
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundImage:
                                    _memberPhotoProvider(context, member.id),
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
                              label: 'H.N',
                              value: normalValue,
                              enabled:
                                  !_submitting &&
                                      canAssign &&
                                      normalMax > 0 &&
                                      (_selectedMembers[member.id] ?? false),
                              maxValue: normalMax,
                              onChanged: (value) => setState(() {
                                _normalHours[member.id] = value;
                              }),
                            ),
                          ),
                              const SizedBox(width: 12.0),
                              Expanded(
                            child: _HoursStepper(
                              label: 'H.E',
                              value: extraValue,
                              enabled:
                                  !_submitting &&
                                      canAssign &&
                                      extraMax > 0 &&
                                      (_selectedMembers[member.id] ?? false),
                              maxValue: extraMax,
                              onChanged: (value) => setState(() {
                                _extraHours[member.id] = value;
                              }),
                                ),
                              ),
                            ],
                          ),
                          if (!canAssign)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Sin asistencia válida para la fecha seleccionada.',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: theme.mutedforeground,
                                ),
                              ),
                            )
                          else if (!hasCapacity)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'No quedan horas disponibles para este trabajador.',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: theme.mutedforeground,
                                ),
                              ),
                            )
                          else if (attendanceRecord != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Disponible: ${normalMax.toStringAsFixed(1)}h normales · ${extraMax.toStringAsFixed(1)}h extra',
                                style: theme.bodySmall.override(
                                  font: GoogleFonts.inter(),
                                  color: theme.mutedforeground,
                                ),
                              ),
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
  _RegisterData({
    required this.phases,
    required this.crews,
    required this.project,
  });

  final List<PlanPhase> phases;
  final List<Crew> crews;
  final ProjectDetail project;
}
