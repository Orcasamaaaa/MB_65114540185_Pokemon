import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/team_controller.dart';

class TeamDetailPage extends StatelessWidget {
  final int teamIndex;
  const TeamDetailPage({super.key, required this.teamIndex});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamController>();
    final Color pokeYellow = const Color(0xFFFFCB05);
    final Color pokeBlue = const Color(0xFF3B4CCA);

    final team = controller.teamHistory[teamIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        backgroundColor: pokeBlue,
        foregroundColor: pokeYellow,
        actions: [
          IconButton(
            tooltip: 'โหลดทีมนี้มาแก้ไข',
            icon: const Icon(Icons.download),
            onPressed: () {
              controller.loadTeamFromHistory(team);
              Get.back(); // กลับไปหน้า history
              Get.back(); // กลับไปหน้าเลือกโปเกมอน เพื่อแก้ไขได้ทันที
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
        children: team.members.map((p) {
          return Card(
            elevation: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage(p.imageUrl),
                ),
                const SizedBox(height: 8),
                Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: p.types
                      .map(
                        (t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
