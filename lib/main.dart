import 'package:flutter/material.dart';

import 'book_screen.dart';

void main() => runApp(const AnimationBookApp());

class AnimationBookApp extends StatelessWidget {
  const AnimationBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF20251F);
    return MaterialApp(
      title: 'Animation Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F2),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF54735D)),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 34,
            height: 1.12,
            fontWeight: FontWeight.w700,
            color: ink,
            letterSpacing: -1.2,
          ),
          titleLarge: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: ink,
            letterSpacing: -.4,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF73796F)),
        ),
      ),
      home: const BookScreen(),
    );
  }
}

class LibraryHome extends StatefulWidget {
  const LibraryHome({super.key});

  @override
  State<LibraryHome> createState() => _LibraryHomeState();
}

class _LibraryHomeState extends State<LibraryHome> {
  int _selectedNav = 0;
  String _filter = 'All animations';

  static const _filters = ['All animations', 'Character', 'Motion', 'Loops'];
  static const _projects = [
    AnimationProject(
      'Sunday stroll',
      'Character · 12 frames',
      'MAYA R.',
      Color(0xFFD8E7D7),
      Color(0xFF456C55),
      Icons.directions_walk_rounded,
    ),
    AnimationProject(
      'Little orbit',
      'Motion · 8 frames',
      'JAMIE K.',
      Color(0xFFF0DCC8),
      Color(0xFFB46A45),
      Icons.public_rounded,
    ),
    AnimationProject(
      'Bloom study',
      'Loops · 16 frames',
      'ALEX M.',
      Color(0xFFE8DDF0),
      Color(0xFF89649B),
      Icons.local_florist_rounded,
    ),
    AnimationProject(
      'Rainy day',
      'Character · 24 frames',
      'SAM T.',
      Color(0xFFD9E4EF),
      Color(0xFF4C7596),
      Icons.umbrella_rounded,
    ),
    AnimationProject(
      'Paper plane',
      'Motion · 10 frames',
      'MAYA R.',
      Color(0xFFF0E9C9),
      Color(0xFF927F39),
      Icons.near_me_rounded,
    ),
    AnimationProject(
      'Tiny dancer',
      'Loops · 12 frames',
      'JAMIE K.',
      Color(0xFFF0D8D8),
      Color(0xFFB05858),
      Icons.music_note_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        final large = constraints.maxWidth >= 1200;
        final page = _selectedNav == 0
            ? 'Animation library'
            : _selectedNav == 1
            ? 'Your favorites'
            : 'Recent work';
        return Scaffold(
          appBar: wide
              ? null
              : AppBar(
                  backgroundColor: const Color(0xFFF7F7F2),
                  title: const _Brand(),
                  actions: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search_rounded),
                    ),
                    const _Avatar(),
                    const SizedBox(width: 16),
                  ],
                ),
          body: Row(
            children: [
              if (wide)
                _Sidebar(
                  selected: _selectedNav,
                  onSelected: (value) => setState(() => _selectedNav = value),
                ),
              Expanded(
                child: SafeArea(
                  top: wide,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1260),
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              large ? 48 : 32,
                              28,
                              large ? 48 : 32,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _TopBar(isWide: wide),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              large ? 48 : 32,
                              38,
                              large ? 48 : 32,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _WelcomeHeader(title: page),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              large ? 48 : 32,
                              28,
                              large ? 48 : 32,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _FeaturedCard(
                                onPressed: () => _createProject(context),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              large ? 48 : 32,
                              42,
                              large ? 48 : 32,
                              18,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: _SectionHeader(
                                onPressed: () => _createProject(context),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              large ? 48 : 32,
                              0,
                              large ? 48 : 32,
                              32,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _filters
                                    .map(
                                      (filter) => _FilterChip(
                                        label: filter,
                                        selected: filter == _filter,
                                        onTap: () =>
                                            setState(() => _filter = filter),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              large ? 48 : 32,
                              0,
                              large ? 48 : 32,
                              52,
                            ),
                            sliver: SliverLayoutBuilder(
                              builder: (context, geometry) {
                                final width = geometry.crossAxisExtent;
                                final columns = width >= 1000
                                    ? 3
                                    : width >= 620
                                    ? 2
                                    : 1;
                                final visible = _projects
                                    .where(
                                      (project) =>
                                          _filter == 'All animations' ||
                                          project.category.startsWith(
                                            _filter.substring(
                                              0,
                                              _filter.length -
                                                  (_filter == 'Loops' ? 1 : 0),
                                            ),
                                          ),
                                    )
                                    .toList();
                                final matches = _filter == 'All animations'
                                    ? _projects
                                    : _projects
                                          .where(
                                            (p) => _filter == 'Character'
                                                ? p.category.startsWith(
                                                    'Character',
                                                  )
                                                : _filter == 'Motion'
                                                ? p.category.startsWith(
                                                    'Motion',
                                                  )
                                                : p.category.startsWith(
                                                    'Loops',
                                                  ),
                                          )
                                          .toList();
                                return SliverGrid.count(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  childAspectRatio: columns == 1 ? 1.5 : 1.03,
                                  children:
                                      (matches.isEmpty ? visible : matches)
                                          .map(
                                            (project) =>
                                                _ProjectCard(project: project),
                                          )
                                          .toList(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedNav,
                  onDestinationSelected: (value) =>
                      setState(() => _selectedNav = value),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      label: 'Library',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border_rounded),
                      label: 'Favorites',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.history_rounded),
                      label: 'Recent',
                    ),
                  ],
                ),
          floatingActionButton: wide
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _createProject(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New animation'),
                ),
        );
      },
    );
  }

  void _createProject(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new animation'),
        content: const Text('Your next idea starts with a blank page.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF345C45),
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 19,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'frame by frame',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16),
      ),
    ],
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    width: 252,
    decoration: const BoxDecoration(
      color: Color(0xFFF1F2EB),
      border: Border(right: BorderSide(color: Color(0xFFE5E7DE))),
    ),
    padding: const EdgeInsets.fromLTRB(24, 28, 16, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Brand(),
        const SizedBox(height: 54),
        Text(
          'WORKSPACE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.4,
            color: const Color(0xFF92978B),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _NavItem(
          icon: Icons.grid_view_rounded,
          label: 'Animation library',
          selected: selected == 0,
          onTap: () => onSelected(0),
        ),
        _NavItem(
          icon: Icons.favorite_border_rounded,
          label: 'Favorites',
          selected: selected == 1,
          onTap: () => onSelected(1),
        ),
        _NavItem(
          icon: Icons.history_rounded,
          label: 'Recent work',
          selected: selected == 2,
          onTap: () => onSelected(2),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E9DD),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFF52715B),
              ),
              const SizedBox(height: 9),
              Text(
                'A little practice, every day.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              const Text(
                'Your sketchbook is ready when you are.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF73796F),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            _Avatar(),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Your studio',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.more_horiz_rounded, color: Color(0xFF73796F)),
          ],
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      selected: selected,
      selectedTileColor: const Color(0xFFDDE7DA),
      leading: Icon(
        icon,
        size: 20,
        color: selected ? const Color(0xFF345C45) : const Color(0xFF747B70),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? const Color(0xFF345C45) : const Color(0xFF5F665B),
        ),
      ),
      onTap: onTap,
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar();
  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [Color(0xFFF0CDAF), Color(0xFFBA8063)]),
    ),
    child: const Center(
      child: Text(
        'A',
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isWide});
  final bool isWide;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (isWide) const Expanded(child: _Breadcrumb()) else const Spacer(),
      if (isWide)
        SizedBox(
          width: 230,
          height: 42,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search animations',
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      if (isWide) const SizedBox(width: 16),
      if (isWide) const _Avatar(),
    ],
  );
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Text(
        'Workspace',
        style: TextStyle(color: Color(0xFF858B80), fontSize: 13),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 9),
        child: Icon(
          Icons.chevron_right_rounded,
          size: 17,
          color: Color(0xFFA4A99F),
        ),
      ),
      Text(
        'Animation library',
        style: TextStyle(
          color: Color(0xFF444B42),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'YOUR CREATIVE SPACE',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.5,
          color: const Color(0xFF82897C),
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 9),
      const Text(
        'A home for the little worlds you bring to life.',
        style: TextStyle(fontSize: 15, color: Color(0xFF73796F)),
      ),
    ],
  );
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 178),
    decoration: BoxDecoration(
      color: const Color(0xFFE5EBDF),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Stack(
      children: [
        Positioned(
          right: 42,
          top: -32,
          child: Container(
            width: 205,
            height: 205,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD3DECD), width: 30),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(26),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'YOUR NEXT IDEA',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF63806A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Make something\nmove.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 26,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start with one frame. See where it goes.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF73796F)),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onPressed,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New animation'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF345C45),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 560)
                const SizedBox(width: 190, child: _FeaturedArt()),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FeaturedArt extends StatelessWidget {
  const _FeaturedArt();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 140,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -.12,
          child: Container(
            width: 118,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6ED),
              borderRadius: BorderRadius.circular(9),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F405445),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.north_east_rounded,
                size: 64,
                color: Color(0xFF54735D),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 6,
          child: Transform.rotate(
            angle: .16,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFF2D69B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.wb_sunny_rounded,
                color: Color(0xFFAB7B2D),
                size: 22,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 2,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFD5E3D3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF52715B),
              size: 20,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your animations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text(
              'A few frames can tell a whole story.',
              style: TextStyle(fontSize: 13, color: Color(0xFF73796F)),
            ),
          ],
        ),
      ),
      TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('New project'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF345C45)),
      ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: false,
    labelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: selected ? Colors.white : const Color(0xFF687064),
    ),
    selectedColor: const Color(0xFF345C45),
    backgroundColor: Colors.white,
    side: BorderSide(
      color: selected ? const Color(0xFF345C45) : const Color(0xFFE7E9E2),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    visualDensity: VisualDensity.compact,
  );
}

class AnimationProject {
  const AnimationProject(
    this.title,
    this.category,
    this.author,
    this.background,
    this.accent,
    this.icon,
  );
  final String title;
  final String category;
  final String author;
  final Color background;
  final Color accent;
  final IconData icon;
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project});
  final AnimationProject project;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8EAE3)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            color: project.background,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  right: -14,
                  top: -25,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: project.accent.withValues(alpha: .09),
                        width: 18,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .65),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(project.icon, size: 38, color: project.accent),
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 13,
                  child: Row(
                    children: List.generate(
                      5,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: index == 2 ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: project.accent.withValues(
                            alpha: index == 2 ? .8 : .28,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .75),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: project.accent,
                      size: 19,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF858B80),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                project.author,
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: .5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9A9F95),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
