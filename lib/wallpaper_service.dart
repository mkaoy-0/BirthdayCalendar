import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class WallpaperService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> pickAndCrop(String title) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 9, ratioY: 16),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
      ],
    );
    return croppedFile?.path;
  }

  Future<void> setWallpaper({
    required String path,
    required bool goToHome,
  }) async {
    await AsyncWallpaper.setWallpaper(
      WallpaperRequest(
        target: WallpaperTarget.home,
        sourceType: WallpaperSourceType.file,
        source: path,
        goToHome: goToHome,
      ),
    );
  }
}
