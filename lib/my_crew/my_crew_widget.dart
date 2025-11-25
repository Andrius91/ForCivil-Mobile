import 'package:ff_theme/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/widgets/for_civil_layout.dart';

class MyCrewWidget extends StatelessWidget {
  const MyCrewWidget({super.key});

  static String routeName = 'MyCrew';
  static String routePath = '/myCrew';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final teams = _buildTeams();

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
              'Selecciona una cuadrilla para ver a sus integrantes, categoría y fecha de ingreso.',
              style: theme.bodyMedium.override(
                font: GoogleFonts.inter(),
                color: theme.mutedforeground,
              ),
            ),
            const SizedBox(height: 24.0),
            Expanded(
              child: ListView.separated(
                itemCount: teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16.0),
                itemBuilder: (context, index) =>
                    _CrewTeamTile(team: teams[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_CrewTeam> _buildTeams() {
    return [
      _CrewTeam(
        name: 'Cuadrilla Estructuras',
        label: 'Obra gruesa',
        members: [
          _CrewMember(
            name: 'Javier Camacho',
            category: 'Oficial',
            startDate: DateTime(2021, 3, 12),
            photoUrl: 'https://i.pravatar.cc/150?img=8',
          ),
          _CrewMember(
            name: 'María Torres',
            category: 'Oficial',
            startDate: DateTime(2020, 11, 2),
            photoUrl: 'https://i.pravatar.cc/150?img=45',
          ),
          _CrewMember(
            name: 'Luis Hidalgo',
            category: 'Ayudante',
            startDate: DateTime(2023, 1, 19),
            photoUrl: 'https://i.pravatar.cc/150?img=12',
          ),
        ],
      ),
      _CrewTeam(
        name: 'Cuadrilla Acabados',
        label: 'Terminaciones',
        members: [
          _CrewMember(
            name: 'Rosa Alvarado',
            category: 'Operaria',
            startDate: DateTime(2022, 7, 4),
            photoUrl: 'https://i.pravatar.cc/150?img=32',
          ),
          _CrewMember(
            name: 'Carlos Benites',
            category: 'Operario',
            startDate: DateTime(2019, 9, 15),
            photoUrl: 'https://i.pravatar.cc/150?img=28',
          ),
          _CrewMember(
            name: 'Lucía Romero',
            category: 'Ayudante',
            startDate: DateTime(2023, 5, 9),
            photoUrl: 'https://i.pravatar.cc/150?img=5',
          ),
        ],
      ),
      _CrewTeam(
        name: 'Cuadrilla Instalaciones',
        label: 'Redes y servicios',
        members: [
          _CrewMember(
            name: 'Pedro Gutierrez',
            category: 'Oficial',
            startDate: DateTime(2021, 9, 7),
            photoUrl: 'https://i.pravatar.cc/150?img=21',
          ),
          _CrewMember(
            name: 'Ana Salazar',
            category: 'Operaria',
            startDate: DateTime(2022, 2, 18),
            photoUrl: 'https://i.pravatar.cc/150?img=16',
          ),
        ],
      ),
    ];
  }
}

class _CrewTeamTile extends StatefulWidget {
  const _CrewTeamTile({required this.team});

  final _CrewTeam team;

  @override
  State<_CrewTeamTile> createState() => _CrewTeamTileState();
}

class _CrewTeamTileState extends State<_CrewTeamTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
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
                widget.team.name,
                style: theme.titleMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    fontStyle: theme.titleMedium.fontStyle,
                  ),
                ),
              ),
              const SizedBox(height: 4.0),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: theme.secondaryBackground,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: theme.border),
                ),
                child: Text(
                  widget.team.label,
                  style: theme.labelMedium.override(
                    font: GoogleFonts.inter(),
                    color: theme.mutedforeground,
                  ),
                ),
              ),
            ],
          ),
          children: widget.team.members
              .map((member) => Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 12.0),
                    child: _CrewCard(member: member),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _CrewCard extends StatelessWidget {
  const _CrewCard({required this.member});

  final _CrewMember member;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final dateLabel = dateTimeFormat('d MMM y', member.startDate, locale: 'es');
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
            backgroundImage: NetworkImage(member.photoUrl),
            radius: 28,
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: theme.titleMedium.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FontWeight.w600,
                      fontStyle: theme.titleMedium.fontStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  member.category,
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
                'Ingreso',
                style: theme.labelMedium.override(
                  font: GoogleFonts.inter(),
                  color: theme.mutedforeground,
                ),
              ),
              Text(
                dateLabel,
                style: theme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrewTeam {
  _CrewTeam({required this.name, required this.label, required this.members});

  final String name;
  final String label;
  final List<_CrewMember> members;
}

class _CrewMember {
  _CrewMember({
    required this.name,
    required this.category,
    required this.startDate,
    required this.photoUrl,
  });

  final String name;
  final String category;
  final DateTime startDate;
  final String photoUrl;
}
