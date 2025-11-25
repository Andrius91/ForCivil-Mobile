import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/widgets/for_civil_layout.dart';

class RegisterTareoWidget extends StatefulWidget {
  const RegisterTareoWidget({super.key});

  static String routeName = 'RegisterTareo';
  static String routePath = '/registerTareo';

  @override
  State<RegisterTareoWidget> createState() => _RegisterTareoWidgetState();
}

class _RegisterTareoWidgetState extends State<RegisterTareoWidget> {
  late final List<PhaseItem> _phases;
  late final List<CrewMember> _crew;

  @override
  void initState() {
    super.initState();
    _phases = _buildPhases();
    _crew = _buildCrew();
  }

  List<PhaseItem> _buildPhases() {
    return [
      PhaseItem(
        name: 'Fase 1 · Estructura',
        workItems: [
          WorkItem(
            id: 'cim-01',
            name: 'Cimentación',
            quantity: 120,
            subItems: [
              WorkItem(
                  id: 'cim-01-1', name: 'Excavación de zapatas', quantity: 45),
              WorkItem(
                  id: 'cim-01-2', name: 'Llenado de zapatas', quantity: 30),
            ],
          ),
          WorkItem(
            id: 'col-01',
            name: 'Columnas primer nivel',
            subItems: [
              WorkItem(id: 'col-01-1', name: 'Encofrado', quantity: 25),
              WorkItem(id: 'col-01-2', name: 'Armado de acero', quantity: 18),
              WorkItem(
                  id: 'col-01-3', name: 'Vaciado de concreto', quantity: 22),
            ],
          ),
        ],
      ),
      PhaseItem(
        name: 'Fase 2 · Albañilería',
        workItems: [
          WorkItem(id: 'muro-01', name: 'Muros interiores', quantity: 80),
          WorkItem(
            id: 'muro-02',
            name: 'Muros exteriores',
            subItems: [
              WorkItem(
                  id: 'muro-02-1', name: 'Tabiques livianos', quantity: 40),
              WorkItem(id: 'muro-02-2', name: 'Revoque', quantity: 35),
            ],
          ),
        ],
      ),
      PhaseItem(
        name: 'Fase 3 · Acabados',
        workItems: [
          WorkItem(id: 'pint-01', name: 'Pintura general', quantity: 60),
          WorkItem(
            id: 'piso-01',
            name: 'Instalación de pisos',
            subItems: [
              WorkItem(id: 'piso-01-1', name: 'Piso cerámico', quantity: 25),
              WorkItem(id: 'piso-01-2', name: 'Piso laminado', quantity: 20),
            ],
          ),
        ],
      ),
    ];
  }

  List<CrewMember> _buildCrew() {
    return [
      CrewMember(
        id: 'worker-1',
        name: 'Javier Camacho',
        category: 'Oficial',
        specialty: 'Encofrador',
        photoUrl: 'https://i.pravatar.cc/150?img=1',
      ),
      CrewMember(
        id: 'worker-2',
        name: 'Rosa Alvarado',
        category: 'Operaria',
        specialty: 'Armadura',
        photoUrl: 'https://i.pravatar.cc/150?img=2',
      ),
      CrewMember(
        id: 'worker-3',
        name: 'Luis Hidalgo',
        category: 'Ayudante',
        specialty: 'Acabados',
        photoUrl: 'https://i.pravatar.cc/150?img=3',
      ),
      CrewMember(
        id: 'worker-4',
        name: 'María Torres',
        category: 'Oficial',
        specialty: 'Pintura',
        photoUrl: 'https://i.pravatar.cc/150?img=4',
      ),
    ];
  }

  Future<void> _openAssignment(WorkItem item) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CrewAssignmentPage(workItem: item, crew: _crew),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Horas registradas para ${item.name}'),
          backgroundColor: FlutterFlowTheme.of(context).primarycolor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final layout = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 960;
        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 2, child: _PhasePanel()),
              const SizedBox(width: 16.0),
              Expanded(child: _CrewPanel()),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(
                height: constraints.maxHeight * 0.65, child: _PhasePanel()),
            const SizedBox(height: 16.0),
            SizedBox(height: constraints.maxHeight * 0.25, child: _CrewPanel()),
          ],
        );
      },
    );

    return ForCivilLayout(
      scaffoldKey: GlobalKey<ScaffoldState>(),
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24.0),
            Text(
              'Registrar tareo',
              style: FlutterFlowTheme.of(context).headlineMedium.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FontWeight.w700,
                      fontStyle:
                          FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                  ),
            ),
            Text(
              'Selecciona la fase, partida o subpartida trabajada y asigna horas a tu cuadrilla.',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).mutedforeground,
                  ),
            ),
            const SizedBox(height: 24.0),
            Expanded(child: layout),
          ],
        ),
      ),
    );
  }

  Widget _PhasePanel() {
    final theme = FlutterFlowTheme.of(context);
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
            itemCount: _phases.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16.0),
            itemBuilder: (context, index) {
              final phase = _phases[index];
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
                      phase.name,
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w500,
                          fontStyle: theme.titleSmall.fontStyle,
                        ),
                        color: theme.primaryText,
                      ),
                    ),
                    children: phase.workItems
                        .map((item) => _buildWorkItemTile(item))
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

  Widget _buildWorkItemTile(WorkItem item) {
    final theme = FlutterFlowTheme.of(context);
    if (item.subItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                      item.name,
                      style: theme.titleSmall.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w500,
                          fontStyle: theme.titleSmall.fontStyle,
                        ),
                        color: theme.primaryText,
                      ),
                    ),
                    if (item.quantity != null)
                      Text(
                        'Metrado: ${item.quantity!.toStringAsFixed(1)} m²',
                        style: theme.bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: theme.mutedforeground,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openAssignment(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primarycolor,
                  foregroundColor: theme.primaryforeground,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
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
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: theme.border),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsetsDirectional.only(start: 32.0, end: 20.0),
          childrenPadding:
              const EdgeInsetsDirectional.only(bottom: 8.0, top: 4.0),
          title: Text(
            item.name,
            style: theme.bodyLarge.override(
              font: GoogleFonts.interTight(
                fontWeight: FontWeight.w500,
                fontStyle: theme.bodyLarge.fontStyle,
              ),
              color: theme.primaryText,
            ),
          ),
          children:
              item.subItems.map((sub) => _buildWorkItemTile(sub)).toList(),
        ),
      ),
    );
  }

  Widget _CrewPanel() {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 72,
              color: theme.mutedforeground,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Al seleccionar una partida se abrirá la pantalla para registrar las horas de la cuadrilla.',
              textAlign: TextAlign.center,
              style: theme.bodyLarge.override(
                font: GoogleFonts.inter(),
                color: theme.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CrewAssignmentPage extends StatefulWidget {
  const CrewAssignmentPage({required this.workItem, required this.crew});

  final WorkItem workItem;
  final List<CrewMember> crew;

  @override
  State<CrewAssignmentPage> createState() => _CrewAssignmentPageState();
}

class _CrewAssignmentPageState extends State<CrewAssignmentPage> {
  late final Map<String, TextEditingController> _normalControllers;
  late final Map<String, TextEditingController> _extraControllers;

  @override
  void initState() {
    super.initState();
    _normalControllers = {
      for (final member in widget.crew) member.id: TextEditingController()
    };
    _extraControllers = {
      for (final member in widget.crew) member.id: TextEditingController()
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
                  widget.workItem.name,
                  style: FlutterFlowTheme.of(context)
                      .titleMedium
                      .override(font: GoogleFonts.interTight()),
                ),
                subtitle: widget.workItem.quantity != null
                    ? Text('Metrado: ${widget.workItem.quantity} m²',
                        style: FlutterFlowTheme.of(context).bodySmall)
                    : null,
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: ListView.separated(
                itemCount: widget.crew.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                itemBuilder: (context, index) {
                  final member = widget.crew[index];
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
                                backgroundImage: NetworkImage(member.photoUrl),
                                radius: 24,
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: FlutterFlowTheme.of(context)
                                          .titleSmall,
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
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primarycolor,
                  foregroundColor: theme.primaryforeground,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: const Text('Guardar horas'),
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

class PhaseItem {
  PhaseItem({required this.name, required this.workItems});

  final String name;
  final List<WorkItem> workItems;
}

class WorkItem {
  WorkItem({
    required this.id,
    required this.name,
    this.quantity,
    this.subItems = const [],
  });

  final String id;
  final String name;
  final double? quantity;
  final List<WorkItem> subItems;
}

class CrewMember {
  CrewMember({
    required this.id,
    required this.name,
    required this.category,
    required this.specialty,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String category;
  final String specialty;
  final String photoUrl;
}
