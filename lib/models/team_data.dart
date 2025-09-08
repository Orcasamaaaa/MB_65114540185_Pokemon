import 'player.dart';

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
        members:
            (json['members'] as List).map((e) => Player.fromJson(e)).toList(),
      );
}
