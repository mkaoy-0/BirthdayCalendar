import 'dart:io'; // ファイルを扱うために追加
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 画像選択のために追加
import 'package:image_cropper/image_cropper.dart'; // ★追加
import 'package:shared_preferences/shared_preferences.dart'; // ★追加
import 'package:async_wallpaper/async_wallpaper.dart'; // ★追加
import 'package:workmanager/workmanager.dart'; // ★追加
import 'package:dynamic_color/dynamic_color.dart'; // DynamicColorBuilderのエラーを消すお守り
import 'theme_service.dart'; // 👈 ThemeServiceのエラーを消すお守り
import 'notification_service.dart';
import 'search_menu_panel.dart';
import 'tag_edit_panel.dart';
import 'tag_search_panel.dart';

// ★裏方タスクの名前を定義
const String wallpaperTaskName = "com.example.dailyWallpaperTask";
const String defaultWallpaperKey = "default_wallpaper_path"; // ★デフォルト壁紙用の保存キー

@pragma('vm:entry-point') // 必須：裏で動くコードであることをFlutterに示すお守り
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.init(requestPermission: false);

    // 1. 現在の「月」と「日」を取得
    final now = DateTime.now();
    String key = "${now.month}-${now.day}";
    String lastUpdatedKey = "last_updated_date"; // 最後に壁紙を変えた日を記録するキー

    // 2. スマホの保存庫を開く
    final prefs = await SharedPreferences.getInstance();

    // もし最後に壁紙を変えた日が「今日」なら、もう0時の仕事は終わっているので何もせず終了する
    String? lastUpdated = prefs.getString(lastUpdatedKey);
    if (lastUpdated == key) {
      return Future.value(true);
    }

    // ======= 💡ここから新設：毎朝のメモ通知処理 =======
    // 保存庫から「memo_月-日」のデータを狙い撃ちで読み込む
    String memoKey = "memo_$key";
    String? todayMemo = prefs.getString(memoKey);

    // もし今日の日付にメモが書かれていたら、通知を送信する
    if (todayMemo != null && todayMemo.isNotEmpty) {
      final int targetHour = 0;
      final int targetMinute = 0;
      final String formattedDate = '${now.month}/${now.day}';
      final String notificationText = '$formattedDateは$todayMemoの誕生日です！おめでとう🎉';
      if (now.hour > targetHour ||
          (now.hour == targetHour && now.minute >= targetMinute)) {
        await NotificationService.showMemoNotification(notificationText);
      } else {
        await NotificationService.scheduleDailyNotification(
          'HAPPY BIRTHDAY🎉',
          notificationText,
          targetHour,
          targetMinute,
        );
      }
    }
    // ================================================

    String? imagePath = prefs.getString(key);

    // もし今日の日付が空っぽなら、デフォルト壁紙のパスを読み込む
    if (imagePath == null || imagePath.isEmpty) {
      imagePath = prefs.getString(defaultWallpaperKey);
    }

    // 3. もし今日の日付に画像が登録されていたら、壁紙を変更する！
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        await AsyncWallpaper.setWallpaper(
          WallpaperRequest(
            target: WallpaperTarget.home, // ホーム画面に設定
            sourceType: WallpaperSourceType.file, // ファイルから読み込む
            source: imagePath, // 画像のパス
            goToHome: false,
          ),
        );

        // 壁紙の変更に成功したら、「今日の日付」をスタンプとしてスマホに保存する
        await prefs.setString(lastUpdatedKey, key);
      } catch (e) {
        debugPrint("壁紙の自動変更に失敗しました: $e");
      }
    }
    return Future.value(true);
  });
}

void main() async {
  // Flutterの初期化を確実に入力
  WidgetsFlutterBinding.ensureInitialized();

  // 通知システムの起動設定
  await NotificationService.init();

  // WorkManager（裏方システム）の初期化
  await Workmanager().initialize(callbackDispatcher);

  // 毎日定期的に裏でタスクを実行するようにOSに予約
  await Workmanager().registerPeriodicTask(
    "1",
    wallpaperTaskName,
    frequency: const Duration(minutes: 15), // 15分ごとに今日用の画像がないか裏でチェックしに行く
    existingWorkPolicy:
        ExistingPeriodicWorkPolicy.update, // すでに同じタスクがあるときは上書きする
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ここで公式の DynamicColorBuilder を呼び出します！
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 別スクリプト（ThemeService）に本物の壁紙色（lightDynamic）を渡して、カラースキームを作ってもらう
        final ColorScheme lightColorScheme = ThemeService.createLightScheme(
          lightDynamic,
        );

        return MaterialApp(
          title: 'Birthday Calendar',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme, // 👈 抽出された「本物の壁紙カラーパレット」をアプリ全体に一発適用！
          ),
          home: const WallpaperCalendarPage(),
        );
      },
    );
  }
}

class WallpaperCalendarPage extends StatefulWidget {
  const WallpaperCalendarPage({super.key});

  @override
  State<WallpaperCalendarPage> createState() => _WallpaperCalendarPageState();
}

class _WallpaperCalendarPageState extends State<WallpaperCalendarPage> {
  late final PageController _pageController = PageController(
    initialPage: 1200 + currentMonth - 1,
  );
  int currentMonth = DateTime.now().month; // 初期表示を「現在の月」にするように進化！

  // 各月が何日まであるかのデータ（うるう年は一旦無視して2月は28日）
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

  // ★選んだ画像のパスを保存する「記憶庫」
  final Map<String, String> selectedImages = {};
  final Map<String, String> dateMemos = {}; // ★日付ごとのメモを保存するための新しい「記憶庫」
  String defaultImagePath = ''; // ★デフォルト壁紙のパスを覚える変数

  // ★追加：現在選択されている「日」を覚える変数（ハイライト用）
  int? selectedDay;
  // ★追加：テキスト入力欄を表示するかどうかのフラグ
  bool showTextField = false;
  bool showTagEditor = false;
  bool showTagSearch = false;
  String? searchTag;
  // ★追加：右側から出るメニューを開閉するフラグ
  bool _isMenuOpen = false;

  final textController = TextEditingController(); // ★テキスト入力欄のコントローラー
  final TextEditingController tagController = TextEditingController();

  final FocusNode tagFocusNode = FocusNode();

  final Map<String, String> dateTags = {}; // ★日付ごとのタグを保存するマップ

  // ★アプリ起動時に、スマホに保存されているデータを自動で読み込む処理
  @override
  void initState() {
    super.initState();
    _loadSavedImages(); // 読み込み開始
  }

  // ★スマホからデータを読み込む関数
  Future<void> _loadSavedImages() async {
    final prefs = await SharedPreferences.getInstance();
    // スマホ内に保存されているすべての「キー（月-日）」を取得
    final keys = prefs.getKeys();

    setState(() {
      for (String key in keys) {
        if (key == defaultWallpaperKey) {
          defaultImagePath = prefs.getString(key) ?? ''; // デフォルト壁紙のパスを読み込む
        } else if (key.contains('memo_')) {
          String dateKey = key.replaceFirst('memo_', '');
          dateMemos[dateKey] = prefs.getString(key) ?? ''; // メモのデータを読み込む
        } else if (key.contains('tag_')) {
          String dateKey = key.replaceFirst('tag_', '');
          dateTags[dateKey] = prefs.getString(key) ?? ''; // タグのデータを読み込む
        } else {
          selectedImages[key] =
              prefs.getString(key) ?? ''; // それ以外は画像のデータとして読み込む
        }
      }
    });
  }

  // 画像を指定したサイズにトリミングする関数
  Future<String?> _cropImage(String sourcePath, String title) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title, // 👈 ここで送られてきたタイトル（'デフォルト壁紙の切り抜き' など）が使われます
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(defaultWallpaperKey, croppedPath);

        setState(() {
          defaultImagePath = croppedPath;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('デフォルト壁紙を登録しました！')));
      }
    }
  }

  // 画像を上書き・変更する関数（_pickImageから名前を変更して整理）
  Future<void> _updateImage(int month, int day) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      String? croppedPath = await _cropImage(image.path, '壁紙サイズに切り抜き');
      if (croppedPath != null) {
        final prefs = await SharedPreferences.getInstance();
        String key = '$month-$day';
        await prefs.setString(key, croppedPath); // 切り抜かれた画像のパスを保存

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

  // ★追加：画像を消去する関数
  Future<void> _deleteImage(int month, int day) async {
    final prefs = await SharedPreferences.getInstance();
    String key = '$month-$day';
    await prefs.remove(key); // スマホから削除

    setState(() {
      selectedImages.remove(key); // 記憶庫から削除
    });

    // もし今日の日付の画像を消したなら、自動でデフォルト壁紙に戻す
    if (month == DateTime.now().month && day == DateTime.now().day) {
      String? defPath = prefs.getString(defaultWallpaperKey);
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

  // ★追加：メモを保存する関数
  Future<void> _saveMemo(int month, int day, String text) async {
    final prefs = await SharedPreferences.getInstance();
    String key = '$month-$day';
    if (text.isEmpty) {
      await prefs.remove('memo_$key');
      setState(() {
        dateMemos.remove(key);
      });
    } else {
      await prefs.setString('memo_$key', text);
      setState(() {
        dateMemos[key] = text;
      });
    }
  }

  Future<void> _saveTag(int month, int day, String text) async {
    final prefs = await SharedPreferences.getInstance();
    String key = '$month-$day';
    if (text.isEmpty) {
      await prefs.remove('tag_$key');
      setState(() {
        dateTags.remove(key);
      });
    } else {
      await prefs.setString('tag_$key', text);
      setState(() {
        dateTags[key] = text;
      });
    }
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
            fontFamily: 'fantasy',
            fontWeight: FontWeight.w500, // ほんの少しだけ線を細くして上品に（お好みで太くもできます）
          ),
        ),
        backgroundColor: currentColors.primary,
        actions: [
          IconButton(
            icon: Icon(
              _isMenuOpen ? Icons.close : Icons.menu,
              color: currentColors.onPrimary,
            ),
            tooltip: 'メニュー',
            onPressed: () {
              FocusScope.of(context).unfocus(); // キーボードが出ているときは閉じる
              setState(() {
                _isMenuOpen = !_isMenuOpen;
              });
            },
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
                          fontSize: 24,
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
                              // 💡 上で定義したコントローラーをここにセット！
                              controller: _pageController,
                              // 💡 itemCountをあえて指定しないことで無限スワイプを可能にします
                              onPageChanged: (index) {
                                setState(() {
                                  // 💡 インデックスから「1〜12月」のどれに該当するかを計算
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
                                          color: const Color.fromARGB(
                                            255,
                                            232,
                                            232,
                                            232,
                                          ),
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

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (selectedDay == dayNumber) {
                                            selectedDay = null;
                                            showTextField = false;
                                          showTagEditor = false;
                                        } else {
                                          selectedDay = dayNumber;
                                          showTextField = false;
                                          showTagEditor = false;
                                          textController.text =
                                              dateMemos[key] ?? '';
                                          tagController.text =
                                              dateTags[key] ?? '';
                                          }
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            // color: const Color.fromARGB(255, 0, 0, 0),
                                            color: isToday
                                                ? currentColors.error
                                                : Colors.black,
                                            width: isToday ? 3.0 : 0.45,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            1,
                                          ),
                                          color:
                                              imagePath == null ||
                                                  imagePath.isEmpty
                                              ? const Color.fromARGB(
                                                  0,
                                                  205,
                                                  205,
                                                  205,
                                                )
                                              : null,
                                          image:
                                              imagePath != null &&
                                                  imagePath.isNotEmpty
                                              ? DecorationImage(
                                                  image: FileImage(
                                                    File(imagePath),
                                                  ),
                                                  fit: BoxFit.cover,
                                                  colorFilter: ColorFilter.mode(
                                                    Colors.black.withValues(
                                                      alpha: 0.4,
                                                    ),
                                                    BlendMode.srcATop,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            dayNumber.toString().padLeft(
                                              2,
                                              '0',
                                            ),
                                            style: TextStyle(
                                              fontSize: isSelected ? 18 : 12,
                                              fontStyle: FontStyle.italic,
                                              fontFamily: 'Times New Roman',
                                              color:
                                                  imagePath == null ||
                                                      imagePath.isEmpty
                                                  ? Colors.black
                                                  : Colors.white,
                                              shadows:
                                                  imagePath != null &&
                                                      imagePath.isNotEmpty
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
                                      color: const Color.fromARGB(
                                        0,
                                        250,
                                        250,
                                        250,
                                      ),
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                          255,
                                          52,
                                          52,
                                          52,
                                        ),
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
                                                : Colors.grey[700],
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
                                            color: Colors.grey[700],
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
                                                : Colors.grey[300],
                                          ),
                                          onPressed: hasImage
                                              ? () => _deleteImage(
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
                                        color: const Color.fromARGB(
                                          255,
                                          82,
                                          82,
                                          82,
                                        ),
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
                                          fontFamily: 'serif',
                                          fontSize: 16,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'メモを入力',
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                          border: UnderlineInputBorder(),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                255,
                                                117,
                                                117,
                                                117,
                                              ),
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
                                      icon: const Icon(
                                        Icons.check,
                                        color: Color.fromARGB(
                                          255,
                                          111,
                                          111,
                                          111,
                                        ),
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                          color: Colors.grey.shade700,
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
                                      tagText: dateTags[selectedKey] ?? '',
                                      isEditing: showTagEditor,
                                      colorScheme: currentColors,
                                      tagController: tagController,
                                      tagFocusNode: tagFocusNode,
                                      onToggleEditing: () {
                                        final wasEditing = showTagEditor;
                                        setState(() {
                                          showTagEditor = !showTagEditor;
                                          if (showTagEditor) {
                                            tagController.text =
                                                dateTags[selectedKey] ??
                                                    '';
                                          }
                                        });
                                        if (!wasEditing && !showTagEditor) {
                                          // no-op
                                        }
                                        if (showTagEditor) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            tagFocusNode.requestFocus();
                                          });
                                        } else {
                                          FocusScope.of(context).unfocus();
                                        }
                                      },
                                      onTagChanged: (text) {
                                        _saveTag(
                                          currentMonth,
                                          selectedDay!,
                                          text,
                                        );
                                      },
                                      onTagTap: (tag) {
                                        setState(() {
                                          showTagSearch = true;
                                          searchTag = tag;
                                        });
                                      },
                                      onSubmit: () async {
                                        await _saveTag(
                                          currentMonth,
                                          selectedDay!,
                                          tagController.text,
                                        );
                                        setState(() {
                                          showTagEditor = false;
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
            top: _isMenuOpen ? 0 : -menuHeight,
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
                        colorScheme: currentColors,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showTagSearch && searchTag != null) ...[
            ModalBarrier(
              dismissible: false,
              color: Colors.black54,
            ),
            TagSearchPanel(
              tag: searchTag!,
              dateTags: dateTags,
              dateMemos: dateMemos,
              onClose: () {
                setState(() {
                  showTagSearch = false;
                  searchTag = null;
                });
              },
              colorScheme: currentColors,
            ),
          ],
        ],
      ),
    );
  }
}
