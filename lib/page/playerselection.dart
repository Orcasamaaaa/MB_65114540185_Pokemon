import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../controllers/team_controller.dart';
import '../models/player.dart';
import 'team_history_page.dart';

class PlayerSelectionPage extends StatefulWidget {
  const PlayerSelectionPage({super.key});

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

      controller.loadTeam(players);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color pokeYellow = const Color(0xFFFFCB05);
    final Color pokeBlue = const Color(0xFF3B4CCA);
    final Color pokeRed = const Color(0xFFEA4335);

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
            const SizedBox(width: 12),
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
                            title: const Text('แก้ไขชื่อทีม'),
                            content: TextField(
                              controller: ctrl,
                              decoration: const InputDecoration(
                                hintText: 'กรอกชื่อทีม',
                              ),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: const Text('ยกเลิก'),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pop(context, ctrl.text),
                                child: const Text('บันทึก'),
                              ),
                            ],
                          );
                        },
                      );
                      if (name != null && name.trim().isNotEmpty) {
                        controller.renameCurrentTeam(oldName, name.trim());
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
            icon: Icon(Icons.history, color: pokeYellow),
            tooltip: 'ทีมที่บันทึกไว้',
            onPressed: () {
              // ใช้ GetX Navigator
              Get.to(() => const TeamHistoryPage());
            },
          ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ค้นหาโปเกมอน...',
                      prefixIcon: Icon(Icons.search, color: pokeBlue),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: pokeBlue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide:
                            BorderSide(color: pokeBlue.withOpacity(0.3)),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'ธาตุ:',
                        style: TextStyle(
                          color: pokeBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
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

                // Selected Team (3 slot)
                Obx(
                  () => Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final Color pokeRed = const Color(0xFFEA4335);
                        final Color pokeBlue = const Color(0xFF3B4CCA);
                        final Color pokeYellow = const Color(0xFFFFCB05);

                        if (index < controller.selectedPlayers.length) {
                          final player = controller.selectedPlayers[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: pokeRed, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: pokeRed.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: pokeYellow,
                                    backgroundImage: NetworkImage(player.imageUrl),
                                    onBackgroundImageError: (_, __) {},
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: pokeBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 28,
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 4,
                                    runSpacing: 2,
                                    children: player.types
                                        .map(
                                          (t) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: pokeYellow.withOpacity(0.7),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.grey[400]!, width: 3),
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.grey[300],
                                    child: const Icon(
                                      Icons.catching_pokemon,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
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

                Divider(thickness: 2, color: pokeBlue, indent: 24, endIndent: 24),

                // Pokémon Grid
                Expanded(
                  child: Obx(() {
                    final filteredPlayers = players
                        .where(
                          (player) =>
                              player.name
                                  .toLowerCase()
                                  .contains(controller.filter.value.toLowerCase()) &&
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
                          final isSelected =
                              controller.selectedPlayers.contains(player);
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
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
                                        offset: const Offset(0, 6),
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
                                    backgroundImage: NetworkImage(player.imageUrl),
                                    onBackgroundImageError: (_, __) {},
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    player.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: pokeBlue,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 16,
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 2,
                                      runSpacing: 0,
                                      children: player.types
                                          .map(
                                            (t) => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4, vertical: 0),
                                              decoration: BoxDecoration(
                                                color:
                                                    pokeYellow.withOpacity(0.7),
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
                                  const SizedBox(height: 2),
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

                // Save button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('บันทึกทีม'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pokeBlue,
                      foregroundColor: pokeYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () async {
                      final ctrl =
                          TextEditingController(text: controller.teamName.value);
                      final name = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('บันทึกทีม'),
                          content: TextField(
                            controller: ctrl,
                            decoration: const InputDecoration(
                              hintText: 'กรอกชื่อทีม',
                            ),
                            autofocus: true,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, null),
                              child: const Text('ยกเลิก'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(context, ctrl.text),
                              child: const Text('บันทึก'),
                            ),
                          ],
                        ),
                      );
                      if (name != null && name.trim().isNotEmpty) {
                        controller.addNewTeam(name.trim());
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
