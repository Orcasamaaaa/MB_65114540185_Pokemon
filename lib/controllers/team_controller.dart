import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/player.dart';
import '../models/team_data.dart';

class TeamController extends GetxController {
  final box = GetStorage();

  var teamName = 'My Pokémon Team'.obs;
  var selectedPlayers = <Player>[].obs;
  var filter = ''.obs;
  var teamHistory = <TeamData>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTeamHistory();
    // loadTeam() จะถูกเรียกหลังจากหน้าเลือกโปเกมอน fetch ข้อมูลเสร็จ
  }

  void setTeamName(String name) {
    teamName.value = name;
    box.write('teamName', name);
  }

  void togglePlayer(Player player) {
    final existingIndex = selectedPlayers.indexWhere((p) => p.id == player.id);
    if (existingIndex != -1) {
      selectedPlayers.removeAt(existingIndex);
    } else {
      if (selectedPlayers.length < 3) {
        selectedPlayers.add(player);
      } else {
        Get.snackbar(
          'แจ้งเตือน',
          'เลือกได้สูงสุด 3 ตัวเท่านั้น',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    }
    saveTeam();
  }

  void resetTeam() {
    selectedPlayers.clear();
    saveTeam();
  }

  void saveTeam() {
    box.write('team', selectedPlayers.map((e) => e.toJson()).toList());
  }

  /// เพิ่มทีมใหม่เสมอ
  void addNewTeam(String name) {
    setTeamName(name);
    final List<TeamData> history = List<TeamData>.from(teamHistory);
    history.insert(0, TeamData(name: name, members: selectedPlayers.toList()));
    box.write('teamHistory', history.map((e) => e.toJson()).toList());
    teamHistory.value = history;

    Get.snackbar(
      'สำเร็จ',
      'เพิ่มทีมใหม่เรียบร้อยแล้ว',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  /// แก้ไขชื่อทีมเดิม (ถ้าไม่เจอชื่อเดิม จะสร้างใหม่)
  void renameCurrentTeam(String oldName, String newName) {
    setTeamName(newName);
    final List<TeamData> history = List<TeamData>.from(teamHistory);

    final idx = history.indexWhere((t) => t.name == oldName);
    if (idx != -1) {
      history[idx] = TeamData(name: newName, members: selectedPlayers.toList());
      box.write('teamHistory', history.map((e) => e.toJson()).toList());
      teamHistory.value = history;

      Get.snackbar(
        'สำเร็จ',
        'แก้ไขชื่อทีมเรียบร้อยแล้ว',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } else {
      history.insert(
        0,
        TeamData(name: newName, members: selectedPlayers.toList()),
      );
      box.write('teamHistory', history.map((e) => e.toJson()).toList());
      teamHistory.value = history;

      Get.snackbar(
        'บันทึกเป็นทีมใหม่',
        'ไม่พบชื่อเดิม จึงสร้างรายการใหม่ให้',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  void loadTeamHistory() {
    final List historyRaw = box.read('teamHistory') ?? [];
    teamHistory.value = historyRaw.map((e) => TeamData.fromJson(e)).toList();
  }

  void deleteTeamAt(int index) {
    final List<TeamData> history = List<TeamData>.from(teamHistory);
    if (index >= 0 && index < history.length) {
      final removed = history.removeAt(index);
      box.write('teamHistory', history.map((e) => e.toJson()).toList());
      teamHistory.value = history;

      Get.snackbar(
        'ลบแล้ว',
        'ลบทีม "${removed.name}" เรียบร้อย',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  void loadTeamFromHistory(TeamData team) {
    teamName.value = team.name;
    selectedPlayers.value = team.members;
    saveTeam();

    Get.snackbar(
      'สำเร็จ',
      'โหลดทีมจากประวัติเรียบร้อยแล้ว',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  void loadTeam(List<Player> allPlayers) {
    final saved = box.read('team');
    if (saved != null) {
      final List<Player> savedPlayers =
          (saved as List).map((e) => Player.fromJson(e)).toList();

      selectedPlayers.value = savedPlayers
          .where((p) => allPlayers.any((ap) => ap.id == p.id))
          .toList();
    }
    final savedName = box.read('teamName');
    if (savedName != null) teamName.value = savedName;
  }
}
