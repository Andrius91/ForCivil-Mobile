import 'dart:async';
import 'dart:convert';

import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '/backend/api/attendance_service.dart';
import '/backend/api/auth_service.dart';
import '/backend/api/auth_state.dart';
import '/backend/api/crew_service.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/widgets/for_civil_layout.dart';

class AttendanceMarkerWidget extends StatefulWidget {
  const AttendanceMarkerWidget({super.key});

  static String routeName = 'AttendanceMarker';
  static String routePath = '/attendanceMarker';

  @override
  State<AttendanceMarkerWidget> createState() => _AttendanceMarkerWidgetState();
}

class _AttendanceMarkerWidgetState extends State<AttendanceMarkerWidget> {
  final AttendanceService _attendanceService = AttendanceService();
  final CrewService _crewService = CrewService();

  late DateTime _now;
  Timer? _timer;
  String _mode = 'INGRESO';
  String? _message;
  bool _dataInitialized = false;
  bool _isLoadingData = false;
  String? _loadError;
  Crew? _selectedCrew;
  List<AttendanceRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dataInitialized) {
      _dataInitialized = true;
      _loadCrewAndRecords();
    }
  }

  Future<void> _loadCrewAndRecords() async {
    final currentDate = DateTime.now();
    setState(() {
      _isLoadingData = true;
      _loadError = null;
    });
    try {
      final authState = context.read<AuthState>();
      await authState.ensureValidToken();
      final token = authState.token;
      final profile = authState.profile;
      final project = authState.selectedProject;

      if (token == null || profile == null || project == null) {
        throw ApiException(
            'Inicia sesión y selecciona un proyecto para usar el marcador');
      }

      final crews = await _crewService.fetchCrews(
        userId: profile.id,
        projectId: project.projectId,
        token: token,
      );

      if (crews.isEmpty) {
        throw ApiException('No se encontraron cuadrillas disponibles');
      }

      final crew = crews.first;
      final records = await _attendanceService.fetchCrewAttendance(
        token: token,
        projectId: project.projectId,
        crewId: crew.id,
        date: currentDate,
      );

      if (!mounted) return;
      setState(() {
        _selectedCrew = crew;
        _records = records;
      });
    } on ApiException catch (e) {
      setState(() => _loadError = e.message);
    } catch (_) {
      setState(() => _loadError = 'No se pudo cargar la asistencia.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startScan(String mode) async {
    if (_selectedCrew == null || _isLoadingData) {
      _showMessage('Aún no hay una cuadrilla disponible para registrar.');
      return;
    }

    setState(() {
      _mode = mode;
      _message = null;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ScannerPage(
          mode: mode,
          onRegister: (scanMode, payload) => _handleScan(scanMode, payload),
        ),
      ),
    );
  }

  Future<bool> _handleScan(String mode, String payload) async {
    final dni = _decodeDni(payload);
    if (dni == null) {
      _showMessage('No se leyó un DNI válido en el código escaneado.');
      return false;
    }
    final crew = _selectedCrew;
    final authState = context.read<AuthState>();
    final token = authState.token;
    final project = authState.selectedProject;

    if (crew == null || token == null || project == null) {
      _showMessage('Debes iniciar sesión nuevamente.');
      return false;
    }

    final timestamp = DateTime.now();
    try {
      await authState.ensureValidToken();
      final freshToken = authState.token;
      if (freshToken == null) {
        _showMessage('Debes iniciar sesión nuevamente.');
        return false;
      }
      await _attendanceService.registerAttendance(
        token: freshToken,
        projectId: project.projectId,
        crewId: crew.id,
        dni: dni,
        isCheckIn: mode == 'INGRESO',
        timestamp: timestamp,
      );

      final records = await _attendanceService.fetchCrewAttendance(
        token: freshToken,
        projectId: project.projectId,
        crewId: crew.id,
        date: timestamp,
      );

      if (!mounted) {
        return true;
      }

      setState(() {
        _records = records;
        final formattedTime =
            dateTimeFormat('HH:mm:ss', timestamp, locale: 'es');
        _message = '$mode registrado para DNI $dni a las $formattedTime';
      });
      return true;
    } on ApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('No se pudo registrar la asistencia. Inténtalo nuevamente.');
    }
    return false;
  }

  String? _decodeDni(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['dni', 'documento', 'doc', 'documentId']) {
          if (decoded[key] != null) {
            return decoded[key].toString();
          }
        }
      }
    } catch (_) {
      // ignore json errors
    }
    final match = RegExp(r'(\d{8,12})').firstMatch(trimmed);
    return match?.group(0) ?? trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    final theme = FlutterFlowTheme.of(context);
    final fullName = profile?.fullName ?? 'Dispositivo marcador';

    final dateString = dateTimeFormat('EEEE, d MMMM y', _now, locale: 'es');
    final timeString = dateTimeFormat('HH:mm:ss', _now, locale: 'es');

    final summaryContent = _buildSummarySections(
      theme: theme,
      dateString: dateString,
      timeString: timeString,
      fullName: fullName,
    );

    return ForCivilLayout(
      scaffoldKey: GlobalKey<ScaffoldState>(),
      showDrawer: false,
      backgroundColor: theme.primaryBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: summaryContent,
        ),
      ),
    );
  }

  List<Widget> _buildSummarySections({
    required FlutterFlowTheme theme,
    required String dateString,
    required String timeString,
    required String fullName,
  }) {
    return [
      _buildDateCard(theme, dateString, timeString, fullName),
      const SizedBox(height: 16.0),
      _buildActionButtons(theme),
      if (_message != null) ...[
        const SizedBox(height: 12.0),
        _buildMessageBanner(theme),
      ],
    ];
  }

  Widget _buildDateCard(
    FlutterFlowTheme theme,
    String dateString,
    String timeString,
    String fullName,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateString,
            style: theme.labelLarge.override(
              font: GoogleFonts.inter(),
              color: theme.mutedforeground,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            timeString,
            style: theme.displayMedium.override(
              font: GoogleFonts.interTight(
                fontWeight: FontWeight.w700,
                fontStyle: theme.displayMedium.fontStyle,
              ),
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Marcador de asistencia',
            style: theme.titleMedium.override(
              font: GoogleFonts.interTight(
                fontWeight: FontWeight.w600,
                fontStyle: theme.titleMedium.fontStyle,
              ),
              color: theme.primaryText,
            ),
          ),
          Text(
            fullName,
            style: theme.bodyMedium.override(
              font: GoogleFonts.inter(),
              color: theme.mutedforeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(FlutterFlowTheme theme) {
    final canScan = !_isLoadingData && _selectedCrew != null;
    return Column(
      children: [
        ElevatedButton(
          onPressed: canScan ? () => _startScan('INGRESO') : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primarycolor,
            padding: const EdgeInsets.symmetric(vertical: 26.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: Text(
                'INGRESO',
                style: theme.titleLarge.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w700,
                    fontStyle: theme.titleLarge.fontStyle,
                  ),
                  color: theme.primaryforeground,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14.0),
        OutlinedButton(
          onPressed: canScan ? () => _startScan('SALIDA') : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 26.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
            side: BorderSide(color: theme.primarycolor, width: 1.2),
          ),
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: Text(
                'SALIDA',
                style: theme.titleLarge.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w700,
                    fontStyle: theme.titleLarge.fontStyle,
                  ),
                  color: theme.primarycolor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBanner(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: theme.success),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              _message!,
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(),
                color: theme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _modeColor(String mode, FlutterFlowTheme theme) {
    return mode == 'INGRESO' ? theme.success : const Color(0xFFF28A2E);
  }
}

class _ScannerPage extends StatefulWidget {
  const _ScannerPage({
    required this.mode,
    required this.onRegister,
  });

  final String mode;
  final Future<bool> Function(String mode, String payload) onRegister;

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    facing: CameraFacing.back,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();
  bool _handled = false;
  bool _showSuccess = false;
  Timer? _successTimer;
  late Color _successColor;

  @override
  void initState() {
    super.initState();
    _successColor = widget.mode == 'INGRESO'
        ? const Color(0xFF16A34A)
        : const Color(0xFFF28A2E);
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final payload = _payloadFromCapture(capture);
    if (payload == null) {
      _showScanMessage('No se pudo leer el código. Acércalo nuevamente.');
      return;
    }
    _handled = true;
    final success = await widget.onRegister(widget.mode, payload);
    if (!mounted) return;
    if (!success) {
      _handled = false;
      return;
    }
    HapticFeedback.mediumImpact();
    _playSound();
    setState(() {
      _showSuccess = true;
    });

    _successTimer?.cancel();
    _successTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showSuccess = false;
        _handled = false;
      });
    });
  }

  void _playSound() {
    if (widget.mode == 'INGRESO') {
      _player.play(
        android: AndroidSounds.notification,
        ios: IosSounds.glass,
        volume: 0.8,
        looping: false,
        asAlarm: false,
      );
    } else {
      _player.play(
        android: AndroidSounds.alarm,
        ios: IosSounds.alarm,
        volume: 0.8,
        looping: false,
        asAlarm: true,
      );
    }
  }

  String? _payloadFromCapture(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw != null && raw.isNotEmpty) {
        return raw;
      }
    }
    return null;
  }

  void _showScanMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Escanear (${widget.mode})'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          if (_showSuccess)
            Container(
              color: _successColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 64, color: Colors.white),
                    const SizedBox(height: 12.0),
                    Text(
                      '${widget.mode} REGISTRADA',
                      style: FlutterFlowTheme.of(context).titleLarge.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w700,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .fontStyle,
                            ),
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt, color: Colors.white),
                    const SizedBox(height: 8.0),
                    Text(
                      'Alinea el código QR dentro del recuadro',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(),
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
