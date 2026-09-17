import 'package:shared_preferences/shared_preferences.dart';

import 'background_task.dart';

class CalendarStorageData {
  const CalendarStorageData({
    required this.selectedImages,
    required this.dateMemos,
    required this.dateTags,
    required this.defaultImagePath,
  });

  final Map<String, String> selectedImages;
  final Map<String, String> dateMemos;
  final Map<String, List<String>> dateTags;
  final String defaultImagePath;
}

class CalendarStorageService {
  Future<CalendarStorageData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final selectedImages = <String, String>{};
    final dateMemos = <String, String>{};
    final dateTags = <String, List<String>>{};
    var defaultImagePath = '';

    for (final key in prefs.getKeys()) {
      if (key == defaultWallpaperKey) {
        defaultImagePath = prefs.getString(key) ?? '';
      } else if (key.startsWith('memo_')) {
        final dateKey = key.replaceFirst('memo_', '');
        dateMemos[dateKey] = prefs.getString(key) ?? '';
      } else if (key.startsWith('tag_')) {
        final dateKey = key.replaceFirst('tag_', '');
        final savedTags = prefs.getStringList(key);
        if (savedTags != null) {
          dateTags[dateKey] = savedTags;
        } else {
          final singleTag = prefs.getString(key);
          if (singleTag != null && singleTag.isNotEmpty) {
            dateTags[dateKey] = [singleTag];
          }
        }
      } else {
        selectedImages[key] = prefs.getString(key) ?? '';
      }
    }

    return CalendarStorageData(
      selectedImages: selectedImages,
      dateMemos: dateMemos,
      dateTags: dateTags,
      defaultImagePath: defaultImagePath,
    );
  }

  Future<void> saveDefaultImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(defaultWallpaperKey, path);
  }

  Future<void> saveImage(String key, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, path);
  }

  Future<void> deleteImage(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> saveMemo(String key, String text) async {
    final prefs = await SharedPreferences.getInstance();
    if (text.isEmpty) {
      await prefs.remove('memo_$key');
    } else {
      await prefs.setString('memo_$key', text);
    }
  }

  Future<void> saveTags(String key, List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    if (tags.isEmpty) {
      await prefs.remove('tag_$key');
    } else {
      await prefs.setStringList('tag_$key', tags);
    }
  }

  Future<String?> getDefaultImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(defaultWallpaperKey);
  }
}
