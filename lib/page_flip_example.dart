import 'package:flutter/material.dart';

import 'page_flip_book.dart';

void main() => runApp(const PageFlipExampleApp());

class PageFlipExampleApp extends StatelessWidget {
  const PageFlipExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: const Color(0xFF45634A)),
    home: const PageFlipExampleScreen(),
  );
}

class PageFlipExampleScreen extends StatefulWidget {
  const PageFlipExampleScreen({super.key});

  @override
  State<PageFlipExampleScreen> createState() => _PageFlipExampleScreenState();
}

class _PageFlipExampleScreenState extends State<PageFlipExampleScreen> {
  final _controller = PageFlipController();
  int _spreadIndex = 0;

  late final _spreads = [
    const BookSpread(
      left: _ExamplePage(
        title: 'A little fox',
        text: 'One quiet morning, a little fox found a paper boat.',
        color: Color(0xFFF8F0DE),
        icon: Icons.pets_rounded,
      ),
      right: _ExamplePage(
        title: 'By the stream',
        text: 'The boat bobbed along the stream, past reeds and round stones.',
        color: Color(0xFFDCE9DB),
        icon: Icons.water_rounded,
      ),
    ),
    const BookSpread(
      left: _ExamplePage(
        title: 'A new friend',
        text: 'A small blue bird landed beside the boat and waved a wing.',
        color: Color(0xFFEAE1F0),
        icon: Icons.flutter_dash_rounded,
      ),
      right: _ExamplePage(
        title: 'Home again',
        text: 'Together they carried it home before the stars came out.',
        color: Color(0xFFF3DFD2),
        icon: Icons.nightlight_round,
      ),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF2F0E8),
    appBar: AppBar(title: const Text('Page flip example')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: PageFlipBook(
              spreads: _spreads,
              currentIndex: _spreadIndex,
              controller: _controller,
              onPageChanged: (value) => setState(() => _spreadIndex = value),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Previous spread',
                onPressed: _controller.previous,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text('${_spreadIndex + 1} / ${_spreads.length}'),
              ),
              IconButton.filledTonal(
                tooltip: 'Next spread',
                onPressed: _controller.next,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Tap an outer page corner or use the controls.'),
        ],
      ),
    ),
  );
}

class _ExamplePage extends StatelessWidget {
  const _ExamplePage({
    required this.title,
    required this.text,
    required this.color,
    required this.icon,
  });

  final String title;
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [color, Color.lerp(color, Colors.white, .38)!],
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THE LITTLE STORYBOOK',
            style: TextStyle(
              color: Color(0xFF817963),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Center(child: Icon(icon, size: 64, color: const Color(0xFF58705A))),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF403B30),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5D594E),
              fontFamily: 'Georgia',
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const Spacer(),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text('01', style: TextStyle(color: Color(0xFF8E876F))),
          ),
        ],
      ),
    ),
  );
}
