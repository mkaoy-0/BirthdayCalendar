import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dynamic_color/dynamic_color.dart'; // DynamicColorBuilderのエラー対策
import 'background_task.dart';
import 'calendar_storage_service.dart';
import 'calendar_view.dart';
import 'theme_service.dart'; // ThemeServiceのエラー対策
import 'notification_service.dart';
import 'wallpaper_service.dart';
import 'selected_date_panel.dart';
import 'tag_search_panel.dart';
import 'delete_confirm_dialog.dart'; // 削除確認ダイアログのインポート
import 'top_slide_menu.dart'; // スライド式メニューのインポート

// アプリの起動と各種バックグラウンド処理の初期化
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await Workmanager().initialize(callbackDispatcher);
  // 一定時間ごとに壁紙を自動更新するバックグラウンドタスクを登録する
  await Workmanager().registerPeriodicTask(
    '1',
    wallpaperTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
  // アプリのルートウィジェットを画面に描画
  runApp(const MyApp());
}

// アプリ全体の設定やテーマ管理を行う親ウィジェット
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false; // ダークモードが有効かどうかを管理するフラグ

  @override
  Widget build(BuildContext context) {
    // OSや壁紙から動的なカラーパレットを取得するビルダーを呼び出す
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 別スクリプト（ThemeService）に本物の壁紙色を渡してカラースキームを作ってもらう
        final ColorScheme lightColorScheme = ThemeService.createLightScheme(
          lightDynamic,
        );
        final ColorScheme darkColorScheme = ThemeService.createDarkScheme(
          darkDynamic,
        );

        return MaterialApp(
          title: 'Birthday Calendar',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme, // 抽出された本物の壁紙カラーパレットをアプリ全体に一発適用
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkColorScheme,
          ),
          // 現在の状態に応じてライトまたはダークテーマを適用
          themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: WallpaperCalendarPage(
            isDarkMode: _isDarkMode,
            onToggleTheme: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        );
      },
    );
  }
}

// カレンダー画面全体のレイアウトや状態管理を行うステートフルウィジェット
class WallpaperCalendarPage extends StatefulWidget {
  const WallpaperCalendarPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<WallpaperCalendarPage> createState() => _WallpaperCalendarPageState();
}

class _WallpaperCalendarPageState extends State<WallpaperCalendarPage>
    with SingleTickerProviderStateMixin {
  final CalendarStorageService _storage = CalendarStorageService();
  final WallpaperService _wallpaper = WallpaperService();
  late final PageController _pageController = PageController(
    initialPage: 1200 + currentMonth - 1,
  );
  int currentMonth = DateTime.now().month; // 現在表示している月を保持する変数。初期表示を現在の月にする

  // 各月が何日まであるかのデータ
  final Map<int, int> daysInMonth = {
    1: 31,
    2: 29,
    3: 31,
    4: 30,
    5: 31,
    6: 30,
    7: 31,
    8: 31,
    9: 30,
    10: 31,
    11: 30,
    12: 31,
  };

  final Map<String, String> selectedImages = {};  // 日付ごとの画像パスを保持するマップ
  final Map<String, String> dateMemos = {}; // 日付ごとのメモ内容を保持するマップ
  String defaultImagePath = ''; // アプリ全体で使用するデフォルト壁紙のパス

  int? selectedDay; // 現在選択されている日を覚える変数
  bool showTextField = false; // メモ入力欄の表示状態を管理するフラグ
  bool showTagEditor = false; // タグ編集欄の表示状態を管理するフラグ
  OverlayEntry? _tagSearchOverlay; // タグ検索パネルを表示するためのオーバーレイエントリ
  AnimationController? _tagSearchController; // タグ検索パネルのアニメーションを制御するコントローラー
  Animation<Offset>? _tagSearchOffset;
  bool _isMenuOpen = false; // デフォルト壁紙設定ウィンドウを開閉するフラグ
  bool _isSearchOpen = false; // 検索ウィンドウの開閉状態を管理するフラグ

  final textController = TextEditingController(); // テキスト入力欄のコントローラー
  final TextEditingController tagController = TextEditingController(); // タグ入力欄のコントローラー

  final FocusNode tagFocusNode = FocusNode(); // タグ入力欄のフォーカスを管理するノード

  final Map<String, List<String>> dateTags = {}; // 日付ごとのタグを保存するマップ
  int? editingTagIndex;

  // アプリ起動時に、スマホに保存されているデータを自動で読み込む処理
  @override
  void initState() {
    super.initState();
    _ensureTagSearchAnimation();
    _loadSavedImages(); // 読み込み開始
  }

// タグ検索パネルを開閉する際のアニメーション設定を構築する
  void _ensureTagSearchAnimation() {
    if (_tagSearchController != null) return;

    _tagSearchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _tagSearchOffset =
        Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _tagSearchController!,
            curve: Curves.easeOutCubic,
          ),
        );
    _tagSearchController!.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _tagSearchOverlay?.remove();
        _tagSearchOverlay = null;
      }
    });
  }

  // 画面破棄時にアニメーションとオーバーレイのリソースを解放する
  @override
  void dispose() {
    _tagSearchController?.dispose();
    _tagSearchOverlay?.remove();
    super.dispose();
  }

  // ストレージから保存済みの画像やメモ、タグデータを非同期で読み込む関数
  Future<void> _loadSavedImages() async {
    final data = await _storage.load();
    if (!mounted) return;
    setState(() {
      selectedImages.addAll(data.selectedImages);
      dateMemos.addAll(data.dateMemos);
      dateTags.addAll(data.dateTags);
      defaultImagePath = data.defaultImagePath;
    });

    // --- ここから起動時の自動適用処理を追加（iPhone用） ---
    final now = DateTime.now();
    final todayKey = '${now.month}-${now.day}';
    final todayImagePath = selectedImages[todayKey];

    // パスが空でなければ（保存データが存在するなら）、壁紙に反映を試みる
    if (todayImagePath != null && todayImagePath.isNotEmpty) {
      try {
        await _wallpaper.setWallpaper(path: todayImagePath, goToHome: false);
      } catch (error) {
        debugPrint('起動時の壁紙自動適用に失敗しました: $error');
      }
    }
    // ----------------------------------------

  }

  // デフォルト壁紙を選択してストレージに保存する関数
  Future<void> _pickDefaultWallpaper() async {
    final croppedPath = await _wallpaper.pickAndCrop('デフォルト壁紙の切り抜き');
    if (croppedPath != null) {
      await _storage.saveDefaultImage(croppedPath);

      setState(() {
        defaultImagePath = croppedPath;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('デフォルト壁紙を登録しました！')));
    }
  }

  // 日付に設定する画像を上書き・変更する関数
  Future<void> _updateImage(int month, int day) async {
    final croppedPath = await _wallpaper.pickAndCrop('壁紙サイズに切り抜き');
    if (croppedPath != null) {
      String key = '$month-$day';
      await _storage.saveImage(key, croppedPath);

      setState(() { // 画面上の画像保持マップを更新する
        selectedImages[key] = croppedPath;
      });

      if (month == DateTime.now().month && day == DateTime.now().day) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('今日の日付なので壁紙を変更中...')));

        try {
          await _wallpaper.setWallpaper(path: croppedPath, goToHome: true);
        } catch (error) {
          debugPrint('手動での壁紙変更に失敗しました: $error');
        }
      }
    }
  }

  // 特定の日付の画像を消去する関数
  Future<void> _deleteImage(int month, int day) async {
    String key = '$month-$day';
    await _storage.deleteImage(key);

    setState(() {
      selectedImages.remove(key); // マップから削除
    });

    // もし今日の日付の画像を消したなら、自動でデフォルト壁紙に戻す
    if (month == DateTime.now().month && day == DateTime.now().day) {
      String? defPath = await _storage.getDefaultImagePath();
      if (defPath != null && defPath.isNotEmpty) {
        try {
          await _wallpaper.setWallpaper(path: defPath, goToHome: false);
        } catch (error) {
          debugPrint('デフォルト壁紙への復帰に失敗しました: $error');
        }
      }
    }
  }

  // 削除確認ダイアログの呼び出し
  Future<void> _confirmDeleteImage(int month, int day) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogColorScheme = Theme.of(dialogContext).colorScheme;
        return DeleteConfirmDialog(colorScheme: dialogColorScheme);
      },
    );

    if (shouldDelete == true && mounted) {
      await _deleteImage(month, day);
    }
  }

  // 日付のメモを保存する関数
  Future<void> _saveMemo(int month, int day, String text) async {
    String key = '$month-$day';
    await _storage.saveMemo(key, text);
    if (text.isEmpty) {
      setState(() {
        dateMemos.remove(key);
      });
    } else {
      setState(() {
        dateMemos[key] = text;
      });
    }
  }

  // 日付のタグリストをストレージに保存
  Future<void> _saveTag(int month, int day, List<String> tags) async {
    String key = '$month-$day';
    await _storage.saveTags(key, tags);
    if (tags.isEmpty) {
      setState(() {
        dateTags.remove(key);
      });
    } else {
      setState(() {
        dateTags[key] = tags;
      });
    }
  }

  // タグ名をもとに該当する日付の一覧を表示する検索パネルをオーバーレイで開く
  void _openTagSearch(String tag) {
    if (_tagSearchOverlay != null) return;
    _ensureTagSearchAnimation();

    final overlay = Overlay.of(context, rootOverlay: true);

    _tagSearchOverlay = OverlayEntry(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Stack(
          children: [
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: _tagSearchOffset!,
                child: TagSearchPanel(
                  tag: tag,
                  dateTags: dateTags,
                  dateMemos: dateMemos,
                  onClose: _closeTagSearch,
                  onDateTap: _selectDateFromSearch,
                  colorScheme: cs,
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_tagSearchOverlay!);
    _tagSearchController?.forward(from: 0);
  }

  // 開いているタグ検索パネルをアニメーションさせて閉じる
  void _closeTagSearch() {
    if (_tagSearchOverlay == null) return;
    _tagSearchController?.reverse();
  }

  // 画面上部のスライドメニューや検索パネルの開閉状態を切り替える
  void _toggleTopPanel({required bool search}) {
    FocusScope.of(context).unfocus();

    final isCurrentPanelOpen = search ? _isSearchOpen : _isMenuOpen;
    if (isCurrentPanelOpen) {
      setState(() {
        _isMenuOpen = false;
        _isSearchOpen = false;
      });
      return;
    }

    setState(() {
      _isSearchOpen = search;
      _isMenuOpen = !search;
    });
  }

  // 検索結果から特定の日付が選択された際に、その月に移動して詳細を表示する
  Future<void> _selectDateFromSearch(String key) async {
    final parts = key.split('-');
    if (parts.length != 2) return;

    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final maxDays = month == null ? null : daysInMonth[month];
    if (month == null ||
        day == null ||
        maxDays == null ||
        day < 1 ||
        day > maxDays) {
      return;
    }

    _closeTagSearch();
    FocusScope.of(context).unfocus();
    setState(() {
      _isMenuOpen = false;
      _isSearchOpen = false;
      currentMonth = month;
      selectedDay = null;
      showTextField = false;
      showTagEditor = false;
      editingTagIndex = null;
      textController.clear();
      tagController.clear();
    });

    final targetPage = 1200 + month - 1;
    if (_pageController.hasClients &&
        _pageController.page?.round() != targetPage) {
      await _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;
    setState(() {
      currentMonth = month;
      selectedDay = day;
      textController.text = dateMemos[key] ?? '';
    });
  }

  // 今日のおおもとの日付にカレンダーを移動し選択状態にする
  Future<void> _selectToday() async {
    final today = DateTime.now();
    final month = today.month;
    final day = today.day;

    _closeTagSearch();
    FocusScope.of(context).unfocus();
    setState(() {
      _isMenuOpen = false;
      _isSearchOpen = false;
      currentMonth = month;
      selectedDay = null;
      showTextField = false;
      showTagEditor = false;
      editingTagIndex = null;
      textController.clear();
      tagController.clear();
    });

    final targetPage = 1200 + month - 1;
    if (_pageController.hasClients &&
        _pageController.page?.round() != targetPage) {
      await _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;
    setState(() {
      currentMonth = month;
      selectedDay = day;
      textController.text = dateMemos['$month-$day'] ?? '';
    });
  }

  // カレンダーのページめくりによって表示月が変更されたときの処理
  void _handleCalendarMonthChanged(int month) {
    setState(() {
      currentMonth = month;
      selectedDay = null;
      showTextField = false;
      showTagEditor = false;
      editingTagIndex = null;
      tagController.clear();
    });
  }

  // カレンダー上の日付セルがタップされたときの選択・非選択の切り替え処理
  void _handleCalendarDayTap(int day) {
    final key = '$currentMonth-$day';
    setState(() {
      if (selectedDay == day) {
        selectedDay = null;
        showTextField = false;
        showTagEditor = false;
      } else {
        selectedDay = day;
        showTextField = false;
        showTagEditor = false;
        textController.text = dateMemos[key] ?? '';
        tagController.clear();
      }
    });
  }

  // アプリのメイン画面全体のUI構造を組み立てて描画
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // スマホの今の壁紙の色パレット（Theme）をキャッチして変数に入れる
    final theme = Theme.of(context);
    final currentColors = theme.colorScheme;

    String selectedKey = selectedDay != null
        ? '$currentMonth-$selectedDay'
        : '';
    bool hasImage =
        selectedImages[selectedKey] != null &&
        selectedImages[selectedKey]!.isNotEmpty;
    final double menuHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Birthday Calendar',
          style: TextStyle(
            color: currentColors.onPrimary,
            fontSize: 20,
            fontFamily: 'fantasy',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: currentColors.primary,
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: currentColors.onPrimary,
            ),
            tooltip: 'ライト/ダークモード切替',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: Icon(
              Icons.today,
              color: currentMonth == now.month && selectedDay == now.day
                  ? currentColors.tertiaryContainer
                  : currentColors.onPrimary,
            ),
            tooltip: '今日の日付へ移動',
            onPressed: _selectToday,
          ),
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.close : Icons.search,
              color: currentColors.onPrimary,
            ),
            tooltip: '検索パネルを開く',
            onPressed: () => _toggleTopPanel(search: true),
          ),
          IconButton(
            icon: Icon(
              _isMenuOpen ? Icons.close : Icons.image,
              color: currentColors.onPrimary,
            ),
            tooltip: 'デフォルト壁紙設定',
            onPressed: () => _toggleTopPanel(search: false),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 日付の一覧エリア＋スマート操作エリア
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CalendarView(
                            pageController: _pageController,
                            currentMonth: currentMonth,
                            selectedDay: selectedDay,
                            daysInMonth: daysInMonth,
                            selectedImages: selectedImages,
                            colorScheme: currentColors,
                            now: now,
                            onMonthChanged: _handleCalendarMonthChanged,
                            onDayTap: _handleCalendarDayTap,
                          ),
                          if (selectedDay != null)
                            SelectedDatePanel(
                              month: currentMonth,
                              day: selectedDay!,
                              memo: dateMemos[selectedKey] ?? '',
                              tags: dateTags[selectedKey] ?? [],
                              hasImage: hasImage,
                              isEditingMemo: showTextField,
                              isEditingTags: showTagEditor,
                              editingTagIndex: editingTagIndex,
                              colorScheme: currentColors,
                              memoController: textController,
                              tagController: tagController,
                              tagFocusNode: tagFocusNode,
                              suggestionTags: dateTags.values
                                  .expand((tags) => tags)
                                  .toList(),
                              onToggleMemoEditing: () {
                                setState(() {
                                  showTextField = !showTextField;
                                  if (showTextField) {
                                    textController.text =
                                        dateMemos[selectedKey] ?? '';
                                  }
                                });
                              },
                              onMemoChanged: (text) => _saveMemo(
                                currentMonth,
                                selectedDay!,
                                text,
                              ),
                              onMemoSubmitted: (text) {
                                _saveMemo(currentMonth, selectedDay!, text);
                                setState(() => showTextField = false);
                              },
                              onSaveMemo: () async {
                                await _saveMemo(
                                  currentMonth,
                                  selectedDay!,
                                  textController.text,
                                );
                                if (mounted) {
                                  setState(() => showTextField = false);
                                }
                              },
                              onUpdateImage: () => _updateImage(
                                currentMonth,
                                selectedDay!,
                              ),
                              onDeleteImage: () => _confirmDeleteImage(
                                currentMonth,
                                selectedDay!,
                              ),
                              onToggleTagEditing: () async {
                                if (showTagEditor) {
                                  final tags = List<String>.from(
                                    dateTags[selectedKey] ?? [],
                                  );
                                  final newText = tagController.text.trim();
                                  if (editingTagIndex != null) {
                                    if (editingTagIndex! < tags.length) {
                                      if (newText.isEmpty) {
                                        tags.removeAt(editingTagIndex!);
                                      } else {
                                        tags[editingTagIndex!] = newText;
                                      }
                                    } else if (editingTagIndex == tags.length &&
                                        newText.isNotEmpty) {
                                      tags.add(newText);
                                    }
                                  } else if (newText.isNotEmpty) {
                                    tags.add(newText);
                                  }
                                  await _saveTag(
                                    currentMonth,
                                    selectedDay!,
                                    tags,
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    showTagEditor = false;
                                    editingTagIndex = null;
                                    tagController.clear();
                                  });
                                  FocusScope.of(context).unfocus();
                                } else {
                                  setState(() {
                                    showTagEditor = true;
                                    editingTagIndex = null;
                                    tagController.clear();
                                  });
                                }
                              },
                              onTagChanged: (_) {},
                              onTagButtonTap: (index) {
                                final tags = dateTags[selectedKey] ?? [];
                                setState(() {
                                  showTagEditor = true;
                                  editingTagIndex = index;
                                  tagController.text = index < tags.length
                                      ? tags[index]
                                      : '';
                                });
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => tagFocusNode.requestFocus(),
                                );
                              },
                              onTagSuggestionTap: (suggestion) async {
                                final tags = List<String>.from(
                                  dateTags[selectedKey] ?? [],
                                );
                                if (editingTagIndex == null) return;
                                if (editingTagIndex! < tags.length) {
                                  tags[editingTagIndex!] = suggestion;
                                } else if (editingTagIndex == tags.length) {
                                  tags.add(suggestion);
                                } else {
                                  return;
                                }
                                await _saveTag(
                                  currentMonth,
                                  selectedDay!,
                                  tags,
                                );
                                if (!mounted) return;
                                setState(() {
                                  showTagEditor = false;
                                  editingTagIndex = null;
                                  tagController.clear();
                                });
                                FocusScope.of(context).unfocus();
                              },
                              onTagTap: _openTagSearch,
                              onSubmitTag: () async {
                                final tags = List<String>.from(
                                  dateTags[selectedKey] ?? [],
                                );
                                final newText = tagController.text.trim();
                                if (editingTagIndex != null &&
                                    editingTagIndex! < tags.length) {
                                  if (newText.isEmpty) {
                                    tags.removeAt(editingTagIndex!);
                                  } else {
                                    tags[editingTagIndex!] = newText;
                                  }
                                } else if (newText.isNotEmpty) {
                                  tags.add(newText);
                                }
                                await _saveTag(
                                  currentMonth,
                                  selectedDay!,
                                  tags,
                                );
                                if (!mounted) return;
                                setState(() {
                                  showTagEditor = false;
                                  editingTagIndex = null;
                                });
                                FocusScope.of(context).unfocus();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 別ファイル化したスライドメニューを呼び出し
          TopSlideMenu(
            isOpen: _isMenuOpen,
            isSearchOpen: _isSearchOpen,
            menuHeight: menuHeight,
            currentColors: currentColors,
            defaultImagePath: defaultImagePath,
            onPickDefaultWallpaper: _pickDefaultWallpaper,
            dateMemos: dateMemos,
            dateTags: dateTags,
            onTagTap: _openTagSearch,
            onDateTap: _selectDateFromSearch,
          ),
          // TagSearchPanel is shown via Overlay so it can appear above AppBar
        ],
      ),
    );
  }
}