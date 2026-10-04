import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'data/note.dart';
import 'data/notes_store.dart';
import 'ui/app_shell.dart';
import 'ui/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep the semantics tree alive so iOS accessibilityIdentifiers are always
  // exposed to UI automation (XCUITest, accessibility inspectors).
  SemanticsBinding.instance.ensureSemantics();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = await NotesStore.load();
  runApp(MarkdownNotesApp(store: store));
}

class MarkdownNotesApp extends StatefulWidget {
  const MarkdownNotesApp({super.key, required this.store});

  final NotesStore store;

  @override
  State<MarkdownNotesApp> createState() => _MarkdownNotesAppState();
}

class _MarkdownNotesAppState extends State<MarkdownNotesApp>
    with WidgetsBindingObserver {
  bool _computeDark() => switch (widget.store.appearance) {
    Appearance.light => false,
    Appearance.dark => true,
    Appearance.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  @override
  void initState() {
    super.initState();
    AppColors.dark = _computeDark();
    WidgetsBinding.instance.addObserver(this);
    widget.store.addListener(_applyTheme);
  }

  @override
  void dispose() {
    widget.store.removeListener(_applyTheme);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _applyTheme();

  /// Switches the palette and rebuilds every element (including const
  /// widgets and pushed routes) so all colours follow the new theme while
  /// keeping state such as search text and the open editor.
  void _applyTheme() {
    final dark = _computeDark();
    if (dark == AppColors.dark) return;
    AppColors.dark = dark;
    setState(() {});
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.dark;
    final overlay = dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return CupertinoApp(
      title: 'Markdown Notes',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        primaryColor: AppColors.accent,
        scaffoldBackgroundColor: AppColors.bg,
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: child!,
        ),
      ),
      home: AppShell(store: widget.store),
    );
  }
}
