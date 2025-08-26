import 'package:flutter/material.dart';
import 'package:my_app/page/second.dart';
import 'package:my_app/page/detail.dart';
import 'package:my_app/page/playerselection.dart'; // เพิ่ม import

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });

    //   Navigator.push(context,
    //   MaterialPageRoute(builder: (context) =>
    //     const Detail()
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'player-selection',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlayerSelectionPage()),
              );
            },
            tooltip: 'เลือกผู้เล่น',
            child: const Icon(Icons.people),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            heroTag: 'image-hero',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SecondPage()),
              );
            },
            tooltip: 'dogggg',
            child: Image.asset(
              'assets/images/golden1.jpg',
              width: 30,
              height: 30,
            ),
          ),
        ],
      ),
    );
  }
}
