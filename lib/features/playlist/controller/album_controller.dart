import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playback/models/video_audio_item.dart';
import 'package:rein_player/utils/constants/rp_keys.dart';
import 'package:rein_player/utils/constants/rp_text.dart';
import 'package:rein_player/utils/helpers/media_helper.dart';
import 'package:rein_player/utils/local_storage/rp_local_storage.dart';

import '../models/album.dart';
import 'album_content_controller.dart';

class AlbumController extends GetxController {
  static AlbumController get to => Get.find();

  final storage = RpLocalStorage();

  RxList<Album> albums = <Album>[].obs;

  RxInt selectedAlbumIndex = 0.obs;

  @override
  onInit() async {
    super.onInit();
    Get.put(AlbumContentController());
    await loadAllAlbumsFromStorage();
    await loadDefaultAlbumPlaylistContentAndPlay();
  }

  Future<void> updateSelectedAlbumIndex(int index) async {
    if (index == selectedAlbumIndex.value) return;
    AlbumContentController.to.clearNavigationStack();
    selectedAlbumIndex.value = index;
    AlbumContentController.to.currentContent.value = [];
    if (index == 0) {
      await loadDefaultAlbumPlaylistContent();
    } else {
      await AlbumContentController.to.loadDirectory(albums[index].location);
    }
  }

  Future<void> setDefaultAlbum(String filePath,
      {String currentItemToPlay = "", makeDirectoryPath = true}) async {
    final location = makeDirectoryPath?  path.dirname(filePath) : filePath;
    AlbumController.to.albums.value = AlbumController.to.albums.map(
      (album) {
        if (album.id == 'default_album') {
          return Album(
              name: album.name,
              location: location,
              id: album.id,
              currentItemToPlay: currentItemToPlay.isEmpty
                  ? album.currentItemToPlay
                  : currentItemToPlay);
        }
        return album;
      },
    ).toList();
    await dumpAllAlbumsToStorage();
  }

  Future<void> dumpAllAlbumsToStorage() async {
    final albumJson = albums.map((album) => album.toJson()).toList();
    await storage.saveData(RpKeysConstants.allAlbumsKey, albumJson);
  }

  Future<void> loadAllAlbumsFromStorage() async {
    List<dynamic> albumJson =
        storage.readData(RpKeysConstants.allAlbumsKey) ?? [];
    final loadedAlbums = albumJson.map((el) => Album.fromJson(el)).toList();

    albums([
      if (!(loadedAlbums
          .any((item) => item.id == RpKeysConstants.defaultAlbumKey)))
        Album(
          name: RpText.defaultAlbumName,
          location: "",
          id: RpKeysConstants.defaultAlbumKey,
        ),
      ...loadedAlbums
    ]);

    if (albumJson.isEmpty) {
      await dumpAllAlbumsToStorage();
    }
  }

  bool isMediaInDefaultAlbumLocation() {
    List<dynamic> albumJson =
        storage.readData(RpKeysConstants.allAlbumsKey) ?? [];
    final albums = albumJson.map((el) => Album.fromJson(el)).toList();
    final defaultAlbum = albums
        .where((album) => album.id == RpKeysConstants.defaultAlbumKey)
        .firstOrNull;
    return defaultAlbum == null;
  }

  Future<void> loadDefaultAlbumPlaylistContentAndPlay() async {
    final defaultAlbum = albums
        .where((album) => album.id == RpKeysConstants.defaultAlbumKey)
        .firstOrNull;
    if (defaultAlbum == null || defaultAlbum.location.isEmpty || defaultAlbum.location == ".") return;

    AlbumContentController.to.clearNavigationStack();
    AlbumContentController.to.currentContent.value = [];
    final mediaInDirectory =
        await RpMediaHelper.getMediaFilesInDirectory(defaultAlbum.location);
    final currentItemToPlay = mediaInDirectory.firstWhereOrNull(
        (media) => media.location == defaultAlbum.currentItemToPlay);
    if (currentItemToPlay != null) {
      final media =
          VideoOrAudioItem(currentItemToPlay.name, currentItemToPlay.location);
      await VideoAndControlController.to.loadVideoFromUrl(media, play: false);
      await AlbumContentController.to.loadSimilarContentInDefaultAlbum(
          path.basename(defaultAlbum.currentItemToPlay), defaultAlbum.location,
          excludeCurrentFile: false);
    } else {
      await AlbumContentController.to.loadDirectory(defaultAlbum.location);
    }
  }

  Future<void> loadDefaultAlbumPlaylistContent() async {
    final defaultAlbum = albums
        .where((album) => album.id == RpKeysConstants.defaultAlbumKey)
        .firstOrNull;
    if (defaultAlbum == null || defaultAlbum.location.isEmpty || defaultAlbum.location == ".") return;

    AlbumContentController.to.clearNavigationStack();
    AlbumContentController.to.currentContent.value = [];
    await AlbumContentController.to.loadDirectory(defaultAlbum.location);
  }

  void removeAlbumFromList(Album albumToRemove) async {
    final albumIndex = albums.indexWhere((album) => album.location == albumToRemove.location);
    if (albumIndex == -1) return;

    final filteredAlbums = albums
        .where((album) =>
            album.id == RpKeysConstants.defaultAlbumKey ||
            album.location != albumToRemove.location)
        .toList();

    if(albumIndex == selectedAlbumIndex.value || filteredAlbums.length == 1) {
      await updateSelectedAlbumIndex(0);
    }else {
      await updateSelectedAlbumIndex(selectedAlbumIndex.value - 1);
    }
    albums(filteredAlbums);

    await storage.removeData(RpKeysConstants.allAlbumsKey);
    await dumpAllAlbumsToStorage();
  }

  void updateAlbumCurrentItemToPlay(String currentMediaUrl) {
    final currentAlbum = albums[selectedAlbumIndex.value];
    currentAlbum.currentItemToPlay = currentMediaUrl;

    albums.value = albums.map((album) {
      if (album.location == currentAlbum.location) {
        album.currentItemToPlay = currentMediaUrl;
        return album;
      }
      return album;
    }).toList();
  }
}
