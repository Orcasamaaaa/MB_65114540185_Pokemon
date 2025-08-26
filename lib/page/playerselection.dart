import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// ignore_for_file: unused_field

class Player {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;

  Player({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'types': types,
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    id: json['id'],
    name: json['name'],
    imageUrl: json['imageUrl'],
    types: List<String>.from(json['types'] ?? []),
  );

  // Implement equality check for proper comparison in lists
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class TeamData {
  final String name;
  final List<Player> members;

  TeamData({required this.name, required this.members});

  Map<String, dynamic> toJson() => {
    'name': name,
    'members': members.map((e) => e.toJson()).toList(),
  };

  factory TeamData.fromJson(Map<String, dynamic> json) => TeamData(
    name: json['name'],
    members: (json['members'] as List).map((e) => Player.fromJson(e)).toList(),
  );
}

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
    // loadTeam is now called in PlayerSelectionPage after fetching players
  }

  void setTeamName(String name) {
    teamName.value = name;
    box.write('teamName', name);
  }

  void togglePlayer(Player player) {
    // Correctly check if the player is already selected by comparing IDs
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

  // ฟังก์ชันบันทึกหรือแก้ไขชื่อทีม (รองรับ rename)
  void saveOrUpdateTeamHistory(String name, {String? oldName}) {
    setTeamName(name);
    final List historyRaw = box.read('teamHistory') ?? [];
    final List<TeamData> history = historyRaw
        .map((e) => TeamData.fromJson(e))
        .toList();
    if (oldName != null && oldName != name) {
      // ถ้า rename ให้ลบชื่อเดิมออกก่อน
      history.removeWhere((t) => t.name == oldName);
    }
    final existingIndex = history.indexWhere((t) => t.name == name);
    if (existingIndex != -1) {
      history[existingIndex] = TeamData(
        name: name,
        members: selectedPlayers.toList(),
      );
    } else {
      history.insert(
        0,
        TeamData(name: name, members: selectedPlayers.toList()),
      );
    }
    box.write('teamHistory', history.map((e) => e.toJson()).toList());
    teamHistory.value = history;
    Get.snackbar(
      'สำเร็จ',
      'บันทึกทีมเรียบร้อยแล้ว',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  void loadTeamHistory() {
    final List historyRaw = box.read('teamHistory') ?? [];
    teamHistory.value = historyRaw.map((e) => TeamData.fromJson(e)).toList();
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
      final List<Player> savedPlayers = (saved as List)
          .map((e) => Player.fromJson(e))
          .toList();

      // Filter to only include players that still exist in the current API data
      selectedPlayers.value = savedPlayers
          .where((p) => allPlayers.any((ap) => ap.id == p.id))
          .toList();
    }

    final savedName = box.read('teamName');
    if (savedName != null) teamName.value = savedName;
  }
}

class PlayerSelectionPage extends StatefulWidget {
  @override
  State<PlayerSelectionPage> createState() => _PlayerSelectionPageState();
}

class _PlayerSelectionPageState extends State<PlayerSelectionPage> {
  final TeamController controller = Get.put(TeamController());
  List<Player> players = [];
  bool isLoading = true;
  String selectedType = 'all';
  List<String> allTypes = ['all'];

  @override
  void initState() {
    super.initState();
    fetchPokemon();
    // loadTeamHistory is now called in TeamController's onInit
  }

  Future<void> fetchPokemon() async {
    final response = await http.get(
      Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=50'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      List<Player> loadedPlayers = [];
      Set<String> typeSet = {};
      for (int i = 0; i < results.length; i++) {
        final poke = results[i];
        final pokeId = i + 1;
        final detailRes = await http.get(
          Uri.parse('https://pokeapi.co/api/v2/pokemon/$pokeId'),
        );
        List<String> types = [];
        if (detailRes.statusCode == 200) {
          final detail = json.decode(detailRes.body);
          types = (detail['types'] as List)
              .map((t) => t['type']['name'].toString())
              .toList();
          typeSet.addAll(types);
        }
        loadedPlayers.add(
          Player(
            id: pokeId,
            name: poke['name'][0].toUpperCase() + poke['name'].substring(1),
            imageUrl:
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pokeId.png',
            types: types,
          ),
        );
      }
      setState(() {
        players = loadedPlayers;
        allTypes = ['all', ...typeSet.toList()..sort()];
        isLoading = false;
      });
      // Load saved team after players are fetched
      controller.loadTeam(players);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color pokeYellow = Color(0xFFFFCB05);
    final Color pokeBlue = Color(0xFF3B4CCA);
    final Color pokeRed = Color(0xFFEA4335);

    return Scaffold(
      backgroundColor: pokeYellow.withOpacity(0.15),
      appBar: AppBar(
        backgroundColor: pokeBlue,
        title: Row(
          children: [
            Image.network(
              'https://raw.githubusercontent.com/PokeAPI/media/master/logo/pokeapi_256.png',
              height: 36,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.catching_pokemon, color: pokeYellow),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => Text(
                        controller.teamName.value,
                        style: TextStyle(
                          color: pokeYellow,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Pokemon',
                          fontSize: 18,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: pokeYellow, size: 20),
                    tooltip: 'แก้ไขชื่อทีม',
                    onPressed: () async {
                      final oldName = controller.teamName.value;
                      final name = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final ctrl = TextEditingController(
                            text: controller.teamName.value,
                          );
                          return AlertDialog(
                            title: Text('แก้ไขชื่อทีม'),
                            content: TextField(
                              controller: ctrl,
                              decoration: InputDecoration(
                                hintText: 'กรอกชื่อทีม',
                              ),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: Text('ยกเลิก'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, ctrl.text),
                                child: Text('บันทึก'),
                              ),
                            ],
                          );
                        },
                      );
                      if (name != null && name.trim().isNotEmpty) {
                        controller.saveOrUpdateTeamHistory(
                          name.trim(),
                          oldName: oldName,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: pokeYellow),
            tooltip: 'Reset Team',
            onPressed: controller.resetTeam,
          ),
        ],
        elevation: 6,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: pokeBlue))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ค้นหาโปเกมอน...',
                      prefixIcon: Icon(Icons.search, color: pokeBlue),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: pokeBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: pokeBlue.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: pokeBlue, width: 2),
                      ),
                    ),
                    onChanged: (value) => controller.filter.value = value,
                  ),
                ),
                // Filter by type
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'ธาตุ:',
                        style: TextStyle(
                          color: pokeBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          items: allTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type == 'all' ? 'ทั้งหมด' : type),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedType = value ?? 'all';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Selected Team
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        if (index < controller.selectedPlayers.length) {
                          final player = controller.selectedPlayers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: pokeRed,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: pokeRed.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: pokeYellow,
                                    backgroundImage: NetworkImage(
                                      player.imageUrl,
                                    ),
                                    onBackgroundImageError: (_, __) {},
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: pokeBlue,
                                  ),
                                ),
                                SizedBox(height: 4),
                                SizedBox(
                                  height: 28,
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: player.types
                                        .map(
                                          (t) => Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: pokeYellow.withOpacity(
                                                0.7,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              t,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: pokeBlue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey[400]!,
                                      width: 3,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.catching_pokemon,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }),
                    ),
                  ),
                ),
                Divider(
                  thickness: 2,
                  color: pokeBlue,
                  indent: 24,
                  endIndent: 24,
                ),
                // Pokémon List
                Expanded(
                  child: Obx(() {
                    final filteredPlayers = players
                        .where(
                          (player) =>
                              player.name.toLowerCase().contains(
                                controller.filter.value.toLowerCase(),
                              ) &&
                              (selectedType == 'all' ||
                                  player.types.contains(selectedType)),
                        )
                        .toList();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
                        children: filteredPlayers.map((player) {
                          final isSelected = controller.selectedPlayers
                              .contains(player);
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? pokeYellow.withOpacity(0.7)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? pokeRed
                                    : pokeBlue.withOpacity(0.3),
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: pokeRed.withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: Offset(0, 6),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: GestureDetector(
                              onTap: () => controller.togglePlayer(player),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: pokeYellow,
                                    backgroundImage: NetworkImage(
                                      player.imageUrl,
                                    ),
                                    onBackgroundImageError: (_, __) {},
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    player.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: pokeBlue,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  SizedBox(
                                    height: 16,
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 2,
                                      runSpacing: 0,
                                      children: player.types
                                          .map(
                                            (t) => Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 4,
                                                vertical: 0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: pokeYellow.withOpacity(
                                                  0.7,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                t,
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: pokeBlue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Icon(
                                    isSelected
                                        ? Icons.catching_pokemon
                                        : Icons.catching_pokemon_outlined,
                                    color: isSelected ? pokeRed : pokeBlue,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ),
                // ใต้ Obx Selected Team
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('บันทึกทีม'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pokeBlue,
                      foregroundColor: pokeYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () async {
                      final oldName = controller.teamName.value;
                      final ctrl = TextEditingController(
                        text: controller.teamName.value,
                      );
                      final name = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('บันทึกทีม'),
                          content: TextField(
                            controller: ctrl,
                            decoration: InputDecoration(
                              hintText: 'กรอกชื่อทีม',
                            ),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, null),
                              child: Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, ctrl.text),
                              child: Text('บันทึก'),
                            ),
                          ],
                        ),
                      );
                      if (name != null && name.trim().isNotEmpty) {
                        controller.saveOrUpdateTeamHistory(
                          name.trim(),
                          oldName: oldName,
                        );
                      }
                    },
                  ),
                ),
                // แสดงรายชื่อทีมที่บันทึกไว้
                Obx(
                  () => controller.teamHistory.isEmpty
                      ? SizedBox()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                'ทีมที่บันทึกไว้',
                                style: TextStyle(
                                  color: pokeBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: controller.teamHistory.length,
                                itemBuilder: (context, idx) {
                                  final team = controller.teamHistory[idx];
                                  return GestureDetector(
                                    onTap: () =>
                                        controller.loadTeamFromHistory(team),
                                    child: Card(
                                      color: pokeYellow.withOpacity(0.8),
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              team.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: pokeBlue,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: team.members
                                                  .map(
                                                    (p) => Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                          ),
                                                      child: CircleAvatar(
                                                        radius: 12,
                                                        backgroundImage:
                                                            NetworkImage(
                                                              p.imageUrl,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}
