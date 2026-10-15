# Animation Book

A responsive Flutter starter for an animation library. The starter screen includes a workspace sidebar on tablet and desktop, compact bottom navigation on phones, a centered content area, and a project grid that adjusts to the available width.

## Run

```sh
flutter pub get
flutter run
```

## Supported targets

The project is scaffolded for Android phones and tablets, iPhone and iPad, web, Windows, macOS, and Linux. Layout breakpoints are based on available width so the interface also adapts when a desktop window is resized.

## Reusable page flip

The reusable two-page turn lives in `lib/page_flip_book.dart`. Each `BookSpread`
accepts arbitrary Flutter widgets for its left and right page. Keep a
`PageFlipController` in the owning `State` to turn pages from buttons, keyboard
shortcuts, or a table of contents:

```dart
final flipController = PageFlipController();
int spreadIndex = 0;

PageFlipBook(
  spreads: [
    BookSpread(left: const Text('Story'), right: Image.asset('assets/scene.png')),
    BookSpread(left: const Text('Next story'), right: Image.asset('assets/next.png')),
  ],
  currentIndex: spreadIndex,
  controller: flipController,
  onPageChanged: (index) => setState(() => spreadIndex = index),
)

// Trigger turns from a control:
flipController.next();
flipController.previous();
```

Tap either outer corner to turn in that direction. Set `reverse: true` for
right-to-left books. `PageFlipController.jumpTo(index)` changes spreads without
animation for direct navigation. Run the standalone sample with
`flutter run -t lib/page_flip_example.dart`.

Place the book in a widget with bounded width and height, such as `Expanded`
or `SizedBox`. Dispose the controller in the owning State's `dispose()` method.
No additional packages are required.

During a turn, page widgets are captured as textures and warped over a curved
triangle mesh with perspective and shading. Both faces can be visible along the
curl. Content is frozen for the duration of the turn (760 ms by default), then
the live widgets resume. Forward/backward turns, corner taps, and controller
methods share this rendering path. Reduced-motion settings skip the animation.
