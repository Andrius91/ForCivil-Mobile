import 'dart:async';

import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '/backend/api/auth_state.dart';
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
  late DateTime _now;
  Timer? _timer;
  String _mode = 'INGRESO';
  String? _message;
  final List<_AttendanceRecord> _history = [];

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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startScan(String mode) async {
    setState(() {
      _mode = mode;
      _message = null;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ScannerPage(
          mode: mode,
          onRegistered: _handleScanResult,
        ),
      ),
    );
  }

  void _handleScanResult(String mode, DateTime timestamp) {
    final formattedTime = dateTimeFormat('HH:mm:ss', timestamp, locale: 'es');
    setState(() {
      _message = '$mode registrado a las $formattedTime';
      _history.insert(0, _AttendanceRecord(mode: mode, timestamp: timestamp));
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(24, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: summaryContent,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.fromSTEB(8, 16, 24, 16),
                    child: _buildInfoPanel(theme),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: summaryContent,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 0, 24, 16),
                  child: _buildInfoPanel(theme),
                ),
              ),
            ],
          );
        },
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
      const SizedBox(height: 12.0),
      _buildHistorySection(theme),
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
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _startScan('INGRESO'),
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
          onPressed: () => _startScan('SALIDA'),
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

  Widget _buildHistorySection(FlutterFlowTheme theme) {
    final entries = _history.take(5).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.border),
      ),
      child: entries.isEmpty
          ? Text(
              'Sin registros recientes.',
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(),
                color: theme.mutedforeground,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historial reciente',
                  style: theme.titleSmall.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FontWeight.w600,
                      fontStyle: theme.titleSmall.fontStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                ...entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _modeColor(entry.mode, theme),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.mode,
                                style: theme.bodyMedium,
                              ),
                              Text(
                                dateTimeFormat(
                                  'd MMM y · HH:mm:ss',
                                  entry.timestamp,
                                  locale: 'es',
                                ),
                                style: theme.labelMedium.override(
                                  font: GoogleFonts.inter(),
                                  color: theme.mutedforeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoPanel(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: theme.border),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 64,
            color: theme.mutedforeground,
          ),
          const SizedBox(height: 10.0),
          Text(
            'Usa los botones para abrir la cámara y escanear un código QR',
            textAlign: TextAlign.center,
            style: theme.bodyLarge.override(
              font: GoogleFonts.inter(),
              color: theme.primaryText,
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
    required this.onRegistered,
  });

  final String mode;
  final void Function(String mode, DateTime timestamp) onRegistered;

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

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    _handled = true;
    final timestamp = DateTime.now();
    widget.onRegistered(widget.mode, timestamp);
    HapticFeedback.mediumImpact();
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

class _AttendanceRecord {
  _AttendanceRecord({required this.mode, required this.timestamp});

  final String mode;
  final DateTime timestamp;
}
