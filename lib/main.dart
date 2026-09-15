import 'dart:io'; // ファイルを扱う用
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 画像選択用
import 'package:image_cropper/image_cropper.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dynamic_color/dynamic_color.dart'; // DynamicColorBuilderのエラー対策
import 'background_task.dart';
import 'calendar_storage_service.dart';
import 'theme_service.dart'; // ThemeServiceのエラー対策
import 'notification_service.dart';
import 'search_menu_panel.dart';
import 'tag_edit_panel.dart';
import 'tag_search_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.init();

  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    '1',
    wallpaperTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    // DynamicColorBuilder を呼び出す
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 別スクリプト（ThemeService）に本物の壁紙色（lightDynamic）を渡して、カラースキームを作ってもらう
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
  late final PageController _pageController = PageController(
    initialPage: 1200 + currentMonth - 1,
  );
  int currentMonth = DateTime.now().month; // 初期表示を現在の月にする

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

  // 選んだ画像のパスを保存する記憶庫
  final Map<String, String> selectedImages = {};
  final Map<String, String> dateMemos = {}; // 日付ごとのメモを保存するための新しい記憶庫
  String defaultImagePath = ''; // デフォルト壁紙のパスを覚える変数

  // 現在選択されている日を覚える変数（ハイライト用）
  int? selectedDay;
  // テキスト入力欄を表示するかどうかのフラグ
  bool showTextField = false;
  bool showTagEditor = false;
  OverlayEntry? _tagSearchOverlay;
  AnimationController? _tagSearchController;
  Animation<Offset>? _tagSearchOffset;
  // 右側から出るメニューを開閉するフラグ
  bool _isMenuOpen = false;
  bool _isSearchOpen = false;

  final textController = TextEditingController(); // テキスト入力欄のコントローラー
  final TextEditingController tagController = TextEditingController();

  final FocusNode tagFocusNode = FocusNode();

  final Map<String, List<String>> dateTags = {}; // 日付ごとのタグを保存するマップ
  int? editingTagIndex;

  // アプリ起動時に、スマホに保存されているデータを自動で読み込む処理
  @override
  void initState() {
    super.initState();
    _ensureTagSearchAnimation();
    _loadSavedImages(); // 読み込み開始
  }

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

  @override
  void dispose() {
    _tagSearchController?.dispose();
    _tagSearchOverlay?.remove();
    super.dispose();
  }

  // スマホからデータを読み込む関数
  Future<void> _loadSavedImages() async {
    final data = await _storage.load();
    if (!mounted) return;
    setState(() {
      selectedImages.addAll(data.selectedImages);
      dateMemos.addAll(data.dateMemos);
      dateTags.addAll(data.dateTags);
      defaultImagePath = data.defaultImagePath;
    });
  }

  // 画像を指定したサイズにトリミングする関数
  Future<String?> _cropImage(String sourcePath, String title) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title, // ここで送られてきたタイトル（'デフォルト壁紙の切り抜き' など）が使われる
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
      ],
    );
    return croppedFile?.path;
  }

  // デフォルト壁紙を設定する関数
  Future<void> _pickDefaultWallpaper() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      String? croppedPath = await _cropImage(image.path, 'デフォルト壁紙の切り抜き');
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
  }

  // 画像を上書き・変更する関数
  Future<void> _updateImage(int month, int day) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      String? croppedPath = await _cropImage(image.path, '壁紙サイズに切り抜き');
      if (croppedPath != null) {
        String key = '$month-$day';
        await _storage.saveImage(key, croppedPath);

        setState(() {
          selectedImages[key] = croppedPath;
        });

        // 画像を登録したその場で、現在の壁紙にも即時反映させてみるテスト
        if (month == DateTime.now().month && day == DateTime.now().day) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('今日の日付なので壁紙を変更中...')));

          try {
            await AsyncWallpaper.setWallpaper(
              WallpaperRequest(
                target: WallpaperTarget.home, // ホーム画面に設定
                sourceType: WallpaperSourceType.file, // ファイルから読み込む
                source: croppedPath, // 切り抜いた画像のパス
                goToHome: true, // 設定後に自動でホームに戻る
              ),
            );
          } catch (e) {
            debugPrint("手動での壁紙変更に失敗しました: $e");
          }
        }
      }
    }
  }

  // 画像を消去する関数
  Future<void> _deleteImage(int month, int day) async {
    String key = '$month-$day';
    await _storage.deleteImage(key);

    setState(() {
      selectedImages.remove(key); // 記憶庫から削除
    });

    // もし今日の日付の画像を消したなら、自動でデフォルト壁紙に戻す
    if (month == DateTime.now().month && day == DateTime.now().day) {
      String? defPath = await _storage.getDefaultImagePath();
      if (defPath != null && defPath.isNotEmpty) {
        try {
          await AsyncWallpaper.setWallpaper(
            WallpaperRequest(
              target: WallpaperTarget.home,
              sourceType: WallpaperSourceType.file,
              source: defPath,
              goToHome: false,
            ),
          );
        } catch (e) {
          debugPrint("デフォルト壁紙への復帰に失敗しました: $e");
        }
      }
    }
  }

  Future<void> _confirmDeleteImage(int month, int day) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final dialogColorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          // 角をとがらせる
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            // ウィンドウの枠線はタイトルの文字色と揃える
            side: BorderSide(
              color: dialogColorScheme.onSurface,
              width: 1.0,
            ),
          ),
          // タイトルの文字サイズを変更
          title: Text(
            '画像を削除しますか？',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dialogColorScheme.onSurface,
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          // ボタンを横幅いっぱい、半分ずつに配置する
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Text('YES'),
                  ),
                ),
                const SizedBox(width: 12), // ボタンとボタンの間のすき間
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    child: const Text('NO'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && mounted) {
      await _deleteImage(month, day);
    }
  }

  // メモを保存する関数
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

  void _openTagSearch(String tag) {
    if (_tagSearchOverlay != null) return;
    _ensureTagSearchAnimation();

    final overlay = Overlay.of(context, rootOverlay: true);

    _tagSearchOverlay = OverlayEntry(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Stack(
          children: [
            ModalBarrier(dismissible: false, color: Colors.black54),
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

  void _closeTagSearch() {
    if (_tagSearchOverlay == null) return;
    _tagSearchController?.reverse();
  }

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
            color: currentColors.onPrimary, // タイトルの文字色も壁紙に合わせて変化させる
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
                // 【1】月を切り替えるヘッダーエリア
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // [←] ボタン（前の月へ）
                      IconButton(
                        icon: const Icon(Icons.arrow_left, size: 30),
                        onPressed: () {
                          // アニメーションしながら前のページへ戻す
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                      Text(
                        '$currentMonth月',
                        style: const TextStyle(
                          fontSize: 23,
                          letterSpacing: 2.0,
                          fontFamily: 'serif',
                        ),
                      ),
                      // [→] ボタン（次の月へ）
                      IconButton(
                        icon: const Icon(Icons.arrow_right, size: 30),
                        onPressed: () {
                          // アニメーションしながら次のページへ進める
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 【2】日付の一覧エリア ＋ 【3】スマート操作エリア
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height:
                                (MediaQuery.of(context).size.width - 32) /
                                7 /
                                0.55 *
                                5.1,
                            child: PageView.builder(
                              // 上で定義したコントローラーをここにセット
                              controller: _pageController,
                              // itemCountをあえて指定しないことで無限スワイプを可能に
                              onPageChanged: (index) {
                                setState(() {
                                  // インデックスから「1〜12月」のどれに該当するかを計算
                                  currentMonth = (index % 12) + 1;
                                  selectedDay = null;
                                  showTextField = false;
                                });
                              },
                              itemBuilder: (context, pageIndex) {
                                // 現在のページが「何月」にあたるかを計算
                                int monthForPage = (pageIndex % 12) + 1;
                                int maxDaysForPage =
                                    daysInMonth[monthForPage] ?? 30;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 7,
                                        mainAxisSpacing: 10.0,
                                        crossAxisSpacing: 4.0,
                                        childAspectRatio: 0.55,
                                      ),
                                  itemCount: 35,
                                  itemBuilder: (context, index) {
                                    int dayNumber = index + 1;

                                    if (dayNumber > maxDaysForPage) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: currentColors.surfaceVariant
                                              .withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                        ),
                                      );
                                    }

                                    String key = '$monthForPage-$dayNumber';
                                    String? imagePath = selectedImages[key];

                                    bool isToday =
                                        now.month == monthForPage &&
                                        now.day == dayNumber;
                                    bool isSelected =
                                        selectedDay == dayNumber &&
                                        currentMonth == monthForPage;

                                    // 写真があるかどうかを事前に判定（判定処理の重複を減らしてスッキリさせる）
                                    final hasImage =
                                        imagePath != null &&
                                        imagePath.isNotEmpty;

                                    return InkWell(
                                      // マス目がタップされたときの処理
                                      onTap: () {
                                        setState(() {
                                          // もしすでに選択されている日付をもう一度タップしたら選択を解除する
                                          if (selectedDay == dayNumber) {
                                            selectedDay = null;
                                            showTextField = false;
                                            showTagEditor = false;
                                          } else {
                                            // タップした日を選択状態にする
                                            selectedDay = dayNumber;
                                            showTextField = false;
                                            showTagEditor = false;
                                            textController.text =
                                                dateMemos[key] ?? '';
                                            tagController.clear();
                                          }
                                        });
                                      },

                                      // マス目自体の見た目
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            // 枠線
                                            color: currentColors.onSurface,
                                            width: 0.45,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                          color:
                                              hasImage // 画像があるときは背景色を敷く
                                              ? currentColors.surface
                                              : null,
                                          image: hasImage
                                              ? DecorationImage(
                                                  image: FileImage(
                                                    File(imagePath),
                                                  ),
                                                  fit: BoxFit.cover,
                                                  colorFilter: ColorFilter.mode(
                                                    Colors.black.withValues(
                                                      // 画像の上に黒い半透明を重ねて文字を見やすくする
                                                      alpha: 0.4,
                                                    ),
                                                    BlendMode.srcATop,
                                                  ),
                                                )
                                              : null,
                                        ),

                                        // マス目の真ん中に日付の数字を配置
                                        child: Center(
                                          child: Container(
                                            width: isToday
                                                ? (isSelected ? 42.0 : 32.0)
                                                : null,
                                            height: isToday
                                                ? (isSelected ? 42.0 : 32.0)
                                                : null,
                                            alignment: Alignment.center,
                                            // 今日の日付の場合は、丸い背景を描画して目立たせる
                                            decoration: isToday
                                                ? BoxDecoration(
                                                    color: currentColors
                                                        .inversePrimary
                                                        .withValues(alpha: 0.9),
                                                    shape: BoxShape.circle,
                                                  )
                                                : null,
                                            // マス目に表示する日付の数字
                                            child: Text(
                                              dayNumber.toString().padLeft(
                                                2,
                                                '0',
                                              ),
                                              style: TextStyle(
                                                fontSize: isSelected ? 19 : 13,
                                                fontStyle: FontStyle.italic,
                                                fontFamily: 'Times New Roman',
                                                // 画像があるときは白文字
                                                color: hasImage
                                                    ? Colors.white
                                                    : currentColors.onSurface,
                                                // 画像の上にあるときは、文字が埋もれないように黒い影をつける
                                                shadows: hasImage
                                                    ? const [
                                                        Shadow(
                                                          color: Colors.black,
                                                          blurRadius: 4,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          if (selectedDay != null) ...[
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 0.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentColors.surface,
                                      border: Border.all(
                                        color: currentColors.onSurface,
                                        width: 0.6,
                                      ),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: showTextField
                                                ? currentColors.primary
                                                : currentColors.secondary,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              showTextField = !showTextField;
                                              if (showTextField) {
                                                textController.text =
                                                    dateMemos[selectedKey] ??
                                                    '';
                                              }
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.image,
                                            color: currentColors.secondary,
                                          ),
                                          onPressed: () => _updateImage(
                                            currentMonth,
                                            selectedDay!,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: hasImage
                                                ? currentColors.error
                                                      .withValues(alpha: 0.8)
                                                : currentColors.surfaceVariant,
                                          ),
                                          onPressed: hasImage
                                              ? () => _confirmDeleteImage(
                                                  currentMonth,
                                                  selectedDay!,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Text(
                                      '${currentMonth.toString().padLeft(2, '0')}${selectedDay!.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Times New Roman',
                                        color: currentColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (showTextField)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8.0,
                                  left: 4.0,
                                  right: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: textController,
                                        autofocus: true,
                                        style: const TextStyle(
                                          fontFamily: 'roboto',
                                          fontSize: 16,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'メモを入力',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                          border: UnderlineInputBorder(),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: currentColors.outline,
                                            ),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: currentColors.outline,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        onChanged: (text) => _saveMemo(
                                          currentMonth,
                                          selectedDay!,
                                          text,
                                        ),
                                        onSubmitted: (text) {
                                          _saveMemo(
                                            currentMonth,
                                            selectedDay!,
                                            text,
                                          );
                                          setState(() {
                                            showTextField = false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.check,
                                        color: currentColors.primary,
                                      ),
                                      onPressed: () async {
                                        await _saveMemo(
                                          currentMonth,
                                          selectedDay!,
                                          textController.text,
                                        );
                                        setState(() {
                                          showTextField = false;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),

                            if (!showTextField &&
                                dateMemos['$currentMonth-$selectedDay'] !=
                                    null &&
                                dateMemos['$currentMonth-$selectedDay']!
                                    .isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        top: 10.0,
                                        left: 4.0,
                                      ),
                                      child: Text(
                                        dateMemos['$currentMonth-$selectedDay']!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: 'serif',
                                          color: currentColors.onSurfaceVariant,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 4.0,
                                      bottom: 16.0,
                                    ),
                                    child: TagEditPanel(
                                      tags: dateTags[selectedKey] ?? [],
                                      editingIndex: editingTagIndex,
                                      isEditing: showTagEditor,
                                      colorScheme: currentColors,
                                      tagController: tagController,
                                      tagFocusNode: tagFocusNode,
                                      onToggleEditing: () async {
                                        if (showTagEditor) {
                                          // 編集中（チェックボタン）の時に押されたら保存を実行
                                          final tags = List<String>.from(
                                            dateTags[selectedKey] ?? [],
                                          );
                                          final newText = tagController.text
                                              .trim();

                                          if (editingTagIndex != null) {
                                            if (editingTagIndex! <
                                                tags.length) {
                                              if (newText.isEmpty) {
                                                tags.removeAt(editingTagIndex!);
                                              } else {
                                                tags[editingTagIndex!] =
                                                    newText;
                                              }
                                            } else if (editingTagIndex ==
                                                    tags.length &&
                                                newText.isNotEmpty) {
                                              tags.add(newText);
                                            }
                                          } else if (newText.isNotEmpty) {
                                            tags.add(newText);
                                          }

                                          // データの保存（ここで async/await が必要になる）
                                          await _saveTag(
                                            currentMonth,
                                            selectedDay!,
                                            tags,
                                          );

                                          // 保存が完了したら編集モードを閉じる
                                          setState(() {
                                            showTagEditor = false;
                                            editingTagIndex = null;
                                            tagController.clear();
                                          });
                                          FocusScope.of(context).unfocus();
                                        } else {
                                          // 非編集中の時に押されたら編集モードを開く
                                          setState(() {
                                            showTagEditor = true;
                                            editingTagIndex = null;
                                            tagController.clear();
                                          });
                                        }
                                      },
                                      onTagChanged: (text) {
                                        // controller already tracks text
                                      },
                                      suggestionTags: dateTags.values
                                          .expand((tags) => tags)
                                          .toList(),
                                      onTagSuggestionTap: (suggestion) async {
                                        final tags = List<String>.from(
                                          dateTags[selectedKey] ?? [],
                                        );
                                        if (editingTagIndex == null) return;

                                        if (editingTagIndex! < tags.length) {
                                          tags[editingTagIndex!] = suggestion;
                                        } else if (editingTagIndex ==
                                            tags.length) {
                                          tags.add(suggestion);
                                        } else {
                                          return;
                                        }

                                        await _saveTag(
                                          currentMonth,
                                          selectedDay!,
                                          tags,
                                        );
                                        if (!context.mounted) return;
                                        setState(() {
                                          showTagEditor = false;
                                          editingTagIndex = null;
                                          tagController.clear();
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                      onTagButtonTap: (index) {
                                        final tags =
                                            dateTags[selectedKey] ?? [];
                                        setState(() {
                                          showTagEditor = true;
                                          editingTagIndex = index;
                                          if (index < tags.length) {
                                            tagController.text = tags[index];
                                          } else {
                                            tagController.clear();
                                          }
                                        });
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              tagFocusNode.requestFocus();
                                            });
                                      },
                                      onTagTap: (tag) => _openTagSearch(tag),
                                      onSubmit: () async {
                                        final tags = List<String>.from(
                                          dateTags[selectedKey] ?? [],
                                        );
                                        final newText = tagController.text
                                            .trim();
                                        if (editingTagIndex != null) {
                                          if (editingTagIndex! < tags.length) {
                                            if (newText.isEmpty) {
                                              tags.removeAt(editingTagIndex!);
                                            } else {
                                              tags[editingTagIndex!] = newText;
                                            }
                                          } else if (editingTagIndex ==
                                                  tags.length &&
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
                                        setState(() {
                                          showTagEditor = false;
                                          editingTagIndex = null;
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            top: _isMenuOpen || _isSearchOpen ? 0 : -menuHeight,
            height: menuHeight,
            child: Material(
              color: currentColors.primary,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: MenuSearchPanel(
                        defaultImagePath: defaultImagePath,
                        onPickDefaultWallpaper: _pickDefaultWallpaper,
                        dateMemos: dateMemos,
                        dateTags: dateTags,
                        onTagTap: _openTagSearch,
                        onDateTap: _selectDateFromSearch,
                        showSearch: _isSearchOpen,
                        colorScheme: currentColors,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // TagSearchPanel is shown via Overlay so it can appear above AppBar
        ],
      ),
    );
  }
}
