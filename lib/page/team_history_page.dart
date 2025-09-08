import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/team_controller.dart';
import 'team_detail_page.dart';

class TeamHistoryPage extends StatelessWidget {
  const TeamHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeamController>();
    final Color pokeYellow = const Color(0xFFFFCB05);
    final Color pokeBlue = const Color(0xFF3B4CCA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ทีมที่บันทึกไว้'),
        backgroundColor: pokeBlue,
        foregroundColor: pokeYellow,
      ),
      body: Obx(
        () => controller.teamHistory.isEmpty
            ? const Center(child: Text('ยังไม่มีทีมที่บันทึกไว้'))
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: controller.teamHistory.length,
                itemBuilder: (context, idx) {
                  final t = controller.teamHistory[idx];
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      title: Text(
                        t.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Wrap(
                        spacing: 4,
                        children: t.members
                            .map(
                              (p) => CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(p.imageUrl),
                              ),
                            )
                            .toList(),
                      ),
                      onTap: () {
                        // เข้าไปดูรายละเอียดของทีมนี้
                        Get.to(() => TeamDetailPage(teamIndex: idx));
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'โหลดทีมนี้มาแก้ไข',
                            icon: const Icon(Icons.download),
                            onPressed: () {
                              controller.loadTeamFromHistory(t);
                              Get.back(); // กลับไปหน้าเลือกโปเกมอน
                            },
                          ),
                          IconButton(
                            tooltip: 'ลบทิ้ง',
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => controller.deleteTeamAt(idx),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
