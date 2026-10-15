import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'page_flip_book.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({
    super.key,
    this.bookAssets = const [
      'assets/json/book1.json',
      'assets/json/book2.json',
    ],
  });

  final List<String> bookAssets;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late Future<List<_Book>> _booksFuture;
  final PageFlipController _flipController = PageFlipController();
  int _pageIndex = 0;
  int _selectedBookIndex = 0;
  String? _language;

  KeyEventResult _handlePageKey(
    FocusNode node,
    KeyEvent event,
    bool isPersian,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (isPersian) {
        _flipController.previous();
      } else {
        _flipController.next();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (isPersian) {
        _flipController.next();
      } else {
        _flipController.previous();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadBooks();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<List<_Book>> _loadBooks() async {
    final books = await Future.wait(widget.bookAssets.map(_loadBook));
    if (books.isNotEmpty) _language ??= books.first.defaultLanguage;
    return books;
  }

  Future<_Book> _loadBook(String assetPath) async {
    final source = await rootBundle.loadString(assetPath);
    final json = jsonDecode(source) as Map<String, dynamic>;
    return _Book.fromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F0E8),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          final language = _language;
          if (language == null) return KeyEventResult.ignored;
          return _handlePageKey(node, event, language == 'fa');
        },
        child: SafeArea(
          child: FutureBuilder<List<_Book>>(
            future: _booksFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _LoadMessage(
                  message: 'This story could not be opened.',
                  detail: '${snapshot.error}',
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF45634A)),
                );
              }
              final books = snapshot.data!;
              if (books.isEmpty) {
                return const _LoadMessage(
                  message: 'No books are available.',
                  detail: 'Add a book JSON asset to the library.',
                );
              }
              final book = books[_selectedBookIndex.clamp(0, books.length - 1)];
              final language = _language ?? book.defaultLanguage;
              final isPersian = language == 'fa';
              final spreads = [
                for (var index = 0; index < book.pages.length; index++)
                  BookSpread(
                    left: _StoryPage(
                      book: book,
                      page: book.pages[index],
                      pageIndex: index,
                      isPersian: isPersian,
                      language: language,
                    ),
                    right: _IllustrationPage(
                      book: book,
                      page: book.pages[index],
                      pageIndex: index,
                      language: language,
                    ),
                  ),
              ];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final showSidebar = constraints.maxWidth >= 1000;
                  return Column(
                    children: [
                      _BookToolbar(
                        title: book.titleFor(language),
                        languages: book.supportedLanguages,
                        language: language,
                        onLanguageChanged: (value) =>
                            setState(() => _language = value),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            if (showSidebar)
                              _Sidebar(
                                books: books,
                                selectedBookIndex: _selectedBookIndex,
                                pages: book.pages,
                                selectedPage: _pageIndex,
                                language: language,
                                onBookSelected: (index) => setState(() {
                                  _selectedBookIndex = index;
                                  _pageIndex = 0;
                                }),
                                onPageSelected: _flipController.jumpTo,
                              ),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 1380,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      isWide ? 34 : 14,
                                      isWide ? 14 : 4,
                                      isWide ? 34 : 14,
                                      isWide ? 12 : 4,
                                    ),
                                    child: SizedBox(
                                      height:
                                          (constraints.maxHeight -
                                                  (isWide ? 26 : 8))
                                              .clamp(0.0, constraints.maxHeight)
                                              .toDouble(),
                                      child: PageFlipBook(
                                        key: ValueKey(_selectedBookIndex),
                                        spreads: spreads,
                                        currentIndex: _pageIndex,
                                        controller: _flipController,
                                        reverse: isPersian,
                                        onPageChanged: (index) =>
                                            setState(() => _pageIndex = index),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _PageControls(
                        currentPage: _pageIndex + 1,
                        totalPages: book.pages.length,
                        canGoBack: _pageIndex > 0,
                        canGoForward: _pageIndex < book.pages.length - 1,
                        onPrevious: _flipController.previous,
                        onNext: _flipController.next,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.books,
    required this.selectedBookIndex,
    required this.pages,
    required this.selectedPage,
    required this.language,
    required this.onBookSelected,
    required this.onPageSelected,
  });

  final List<_Book> books;
  final int selectedBookIndex;
  final List<_BookPage> pages;
  final int selectedPage;
  final String language;
  final ValueChanged<int> onBookSelected;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 252,
      decoration: const BoxDecoration(
        color: Color(0xFFEAE9DF),
        border: Border(right: BorderSide(color: Color(0xFFDEDDD2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 19, 16, 10),
            child: Text(
              'MY LIBRARY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF858A7F),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              final selected = index == selectedBookIndex;
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    selected: selected,
                    selectedTileColor: const Color(0xFFDDE4D8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      width: 38,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF45634A)
                            : const Color(0xFFD9DCCF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 19,
                        color: selected
                            ? const Color(0xFFF7F2E4)
                            : const Color(0xFF657360),
                      ),
                    ),
                    title: Text(
                      book.titleFor(language),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF344337)
                            : const Color(0xFF687064),
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${book.pages.length} pages',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onTap: () => onBookSelected(index),
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 23, 16, 9),
            child: Text(
              'PAGES',
              style: TextStyle(
                color: Color(0xFF858A7F),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                final page = pages[index];
                final excerpt =
                    page.content[language] ?? page.content.values.first;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      minLeadingWidth: 26,
                      selected: index == selectedPage,
                      selectedTileColor: const Color(0xFFDDE4D8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      leading: Text(
                        page.pageId.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: index == selectedPage
                              ? const Color(0xFF45634A)
                              : const Color(0xFF92978B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      title: Text(
                        excerpt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: index == selectedPage
                              ? const Color(0xFF344337)
                              : const Color(0xFF687064),
                          fontSize: 11,
                          fontWeight: index == selectedPage
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () => onPageSelected(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookToolbar extends StatelessWidget {
  const _BookToolbar({
    required this.title,
    required this.languages,
    required this.language,
    required this.onLanguageChanged,
  });

  final String title;
  final List<String> languages;
  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Back to library',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.auto_stories_rounded, color: Color(0xFF45634A)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2D382D),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E1D6)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: language,
                borderRadius: BorderRadius.circular(12),
                items: languages
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          item == 'fa' ? 'فارسی' : item.toUpperCase(),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onLanguageChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.book,
    required this.page,
    required this.pageIndex,
    required this.isPersian,
    required this.language,
  });

  final _Book book;
  final _BookPage page;
  final int pageIndex;
  final bool isPersian;
  final String language;

  @override
  Widget build(BuildContext context) {
    final text =
        page.content[language] ?? page.content[book.defaultLanguage] ?? '';
    return _PaperPage(
      isLeft: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(isPersian ? 30 : 38, 34, 30, 24),
        child: Directionality(
          textDirection: isPersian ? TextDirection.rtl : TextDirection.ltr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    color: Color(0xFFA18B63),
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.titleFor(language),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: .7,
                        color: Color(0xFF8F8067),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(height: 1, color: const Color(0xFFE4D9C4)),
              const SizedBox(height: 26),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    text,
                    textAlign: isPersian ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontFamily: isPersian ? null : 'Georgia',
                      color: const Color(0xFF423D33),
                      fontSize: isPersian ? 20 : 19,
                      height: isPersian ? 2.0 : 1.85,
                      letterSpacing: isPersian ? 0 : .1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              _PageFooter(pageNumber: pageIndex * 2 + 1, isLeft: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustrationPage extends StatelessWidget {
  const _IllustrationPage({
    required this.book,
    required this.page,
    required this.pageIndex,
    required this.language,
  });

  final _Book book;
  final _BookPage page;
  final int pageIndex;
  final String language;

  @override
  Widget build(BuildContext context) {
    final caption =
        page.content[language] ?? page.content[book.defaultLanguage] ?? '';
    return _PaperPage(
      isLeft: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(27, 34, 38, 24),
        child: Column(
          children: [
            Row(
              children: [
                const Spacer(),
                Text(
                  ' ${page.pageId.toString().padLeft(2, '0')} ',
                  style: const TextStyle(
                    color: Color(0xFF96876E),
                    fontSize: 12,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: page.assetPath.isEmpty
                    ? _StoryIllustration(pageIndex: pageIndex, caption: caption)
                    : Image.asset(
                        page.assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _StoryIllustration(
                              pageIndex: pageIndex,
                              caption: caption,
                            ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _PageFooter(pageNumber: pageIndex * 2 + 2, isLeft: false),
          ],
        ),
      ),
    );
  }
}

class _PaperPage extends StatelessWidget {
  const _PaperPage({required this.isLeft, required this.child});

  final bool isLeft;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          colors: const [
            Color(0xFFEDE5D1),
            Color(0xFFFFFDF5),
            Color(0xFFFBF8EF),
          ],
          stops: const [0, .12, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF786D56).withValues(alpha: .12),
            blurRadius: 16,
            offset: Offset(isLeft ? -5 : 5, 0),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StoryIllustration extends StatelessWidget {
  const _StoryIllustration({required this.pageIndex, required this.caption});

  final int pageIndex;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final palettes = [
      const [Color(0xFFDFE8D6), Color(0xFFB9C9A8)],
      const [Color(0xFFEFE0C2), Color(0xFFD9B77D)],
      const [Color(0xFFDCE6D7), Color(0xFF9CB395)],
      const [Color(0xFFF0DCC8), Color(0xFFCF9B6D)],
    ];
    final palette = palettes[pageIndex % palettes.length];
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.first, palette.last],
              ),
            ),
          ),
          Positioned(
            left: -constraints.maxWidth * .12,
            right: -constraints.maxWidth * .12,
            bottom: constraints.maxHeight * .13,
            child: Container(
              height: constraints.maxHeight * .23,
              decoration: BoxDecoration(
                color: const Color(0xFF84936D).withValues(alpha: .78),
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(constraints.maxWidth, 100),
                ),
              ),
            ),
          ),
          Positioned(
            top: 22,
            right: 22,
            child: Icon(
              Icons.wb_sunny_rounded,
              color: const Color(0xFFFFF1C9).withValues(alpha: .9),
              size: 42,
            ),
          ),
          Center(
            child: Icon(
              pageIndex < 4 ? Icons.pets_rounded : Icons.house_rounded,
              size: constraints.maxHeight * .31,
              color: const Color(0xFF805F4C),
              shadows: const [
                Shadow(
                  color: Color(0x335A4836),
                  blurRadius: 9,
                  offset: Offset(2, 4),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF1).withValues(alpha: .88),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF5F594B),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageFooter extends StatelessWidget {
  const _PageFooter({required this.pageNumber, required this.isLeft});

  final int pageNumber;
  final bool isLeft;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (!isLeft) const Spacer(),
      Container(width: 22, height: 1, color: const Color(0xFFD8CDB8)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Text(
          pageNumber.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: Color(0xFF9A8D75),
            fontSize: 11,
            letterSpacing: 1.1,
          ),
        ),
      ),
      Container(width: 22, height: 1, color: const Color(0xFFD8CDB8)),
      if (isLeft) const Spacer(),
    ],
  );
}

class _PageControls extends StatelessWidget {
  const _PageControls({
    required this.currentPage,
    required this.totalPages,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 15),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filledTonal(
          tooltip: 'Previous page',
          onPressed: canGoBack ? onPrevious : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 16),
        Text(
          '$currentPage / $totalPages',
          style: const TextStyle(
            color: Color(0xFF667061),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 16),
        IconButton.filledTonal(
          tooltip: 'Next page',
          onPressed: canGoForward ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    ),
  );
}

class _LoadMessage extends StatelessWidget {
  const _LoadMessage({required this.message, required this.detail});

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 40,
            color: Color(0xFF45634A),
          ),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _Book {
  const _Book({
    required this.title,
    required this.defaultLanguage,
    required this.supportedLanguages,
    required this.pages,
  });

  final Map<String, String> title;
  final String defaultLanguage;
  final List<String> supportedLanguages;
  final List<_BookPage> pages;

  String titleFor(String language) =>
      title[language] ?? title[defaultLanguage] ?? title.values.first;

  factory _Book.fromJson(Map<String, dynamic> json) => _Book(
    title: (json['title'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value.toString()),
    ),
    defaultLanguage: json['defaultLanguage'] as String? ?? 'en',
    supportedLanguages:
        (json['supportedLanguages'] as List<dynamic>? ?? const ['en'])
            .map((value) => value.toString())
            .toList(),
    pages: (json['pages'] as List<dynamic>)
        .map((page) => _BookPage.fromJson(page as Map<String, dynamic>))
        .toList(),
  );
}

class _BookPage {
  const _BookPage({
    required this.pageId,
    required this.content,
    required this.assetPath,
  });

  final int pageId;
  final Map<String, String> content;
  final String assetPath;

  factory _BookPage.fromJson(Map<String, dynamic> json) => _BookPage(
    pageId: json['page_id'] as int,
    content: (json['content'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, value.toString()),
    ),
    assetPath: json['assetPath'] as String? ?? '',
  );
}
