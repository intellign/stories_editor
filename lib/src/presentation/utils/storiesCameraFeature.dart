import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/models/editable_items.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;

class StoriesCameraFeature {
  static int maxFileSizeAllowedInMB = 00;
  static int androidSDKVersion = -1;
  static File? cameraFile;
  static String? error;
  static ImagePicker picker = ImagePicker();

  static Future<bool> checkAndRequestPermission(Permission permission,
      {bool? justCheck}) async {
    bool isAndroid = Platform.isAndroid;

    Completer<bool> completer = new Completer<bool>();
    if (justCheck == true) {
      bool isGranted = false;
      if (isAndroid &&
          permission == Permission.storage &&
          androidSDKVersion >= 33) {
        bool videos = await Permission.videos.status.isGranted;
        bool photos = await Permission.photos.status.isGranted;
        bool audios = await Permission.audio.status.isGranted;
        if (videos && photos && audios) isGranted = true;
      } else {
        isGranted = await permission.isGranted;
      }
      return isGranted;
    } else {
      if (isAndroid &&
          permission == Permission.storage &&
          androidSDKVersion >= 33) {
        bool videos = false;
        bool photos = false;
        bool audios = false;
        List<Permission> ppList = [
          Permission.videos,
          Permission.photos,
          Permission.audio
        ];
        ppList.forEach((element) {
          doRequest() {
            element.request().then((_status) {
              bool granted = _status == PermissionStatus.granted;
              if (element == Permission.videos) videos = granted;
              if (element == Permission.photos) photos = granted;
              if (element == Permission.audio) audios = granted;
              if (videos && photos && audios) {
                completer.complete(granted);
              } else {
                completer.complete(true);
              }
            });
          }

          element.request().then((status) async {
            if (status != PermissionStatus.granted) {
              doRequest();
            } else {
              //All needed to be checked
              bool videos = await Permission.videos.status.isGranted;
              bool photos = await Permission.photos.status.isGranted;
              bool audios = await Permission.audio.status.isGranted;
              if (videos && photos && audios) {
                completer.complete(true);
                return completer.future; //break
              } else {
                //check all again
                doRequest();
              }
            }
          });
        });
      } else {
        permission.request().then((status) {
          if (status != PermissionStatus.granted) {
            permission.request().then((_status) {
              bool granted = _status == PermissionStatus.granted;
              completer.complete(granted);
            });
          } else
            completer.complete(true);
        });
      }
      return completer.future;
    }
  }

  static captureImage(ImageSource captureMode, BuildContext context,
      DraggableWidgetNotifier itemProvider) async {
    error = null;
    try {
      XFile? pickedImage = await (picker.pickImage(source: captureMode));
      if (pickedImage != null) {
        cameraFile = File(pickedImage.path);

        if (cameraFile!.lengthSync() / 1000000 > maxFileSizeAllowedInMB) {
          error = "File too big";

          cameraFile = null;
        } else {
          await processFile(cameraFile, context, itemProvider);
        }
      }
    } catch (e) {
      if (e.toString().contains("camera_access_denied")) {}
    }
  }

  static pickVideoFromCamera(
      BuildContext context, DraggableWidgetNotifier itemProvider) async {
    error = null;
    XFile? pickedFile = await (picker.pickVideo(source: ImageSource.camera));

    cameraFile = File(pickedFile!.path);

    if (cameraFile!.lengthSync() / 1000000 > maxFileSizeAllowedInMB) {
      error = "File too big";

      cameraFile = null;
      null;
    } else {
      await processFile(cameraFile, context, itemProvider);
    }
  }

  ////////
  static processFile(selectedMedia, BuildContext context,
      DraggableWidgetNotifier itemProvider) async {
    if (selectedMedia == null) {
    } else {
      addFile(bool isVideo) {
        //     var itemProvider =
        //       Provider.of<DraggableWidgetNotifier>(context, listen: false);
        if (cameraFile != null) {
          String path = cameraFile!.path;
          itemProvider.draggableWidget.add(EditableItem()
            ..type = isVideo ? ItemType.video : ItemType.image
            ..scale = 0.5
            //   ..rotation = 0.5
            ..url = path
            //   ..duration =...// TODO?...
            ..position = Offset(0.0, 0.0));
          itemProvider.updatedNeedsRefresh();
        } else {
          Fluttertoast.showToast(
              msg: '⚠️⚠️', //error
              gravity: ToastGravity.CENTER);
          HapticFeedback.heavyImpact();
        }
      }

      String fileExtension = p.extension(selectedMedia.path).toLowerCase();

      if (getDocumentType(selectedMedia.path).contains("image")) {
        final tempDir = await getTemporaryDirectory();
        File file = await File(fileExtension == ".png"
                ? '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png'
                : fileExtension == ".gif"
                    ? '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.gif'
                    : '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png')
            .create();
        file.writeAsBytesSync(selectedMedia.readAsBytesSync());

        //  onTakeFile(file, false, null);
        cameraFile = file;
        addFile(false);
      } else if (fileExtension == ".mp4" || fileExtension == ".mov") {
        final tempDir = await getTemporaryDirectory();
        File file = await File(
                '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4')
            .create();
        file.writeAsBytesSync(selectedMedia.readAsBytesSync());

        // onTakeFile(file, true, null);
        cameraFile = file;
        addFile(true);
      } else {
        Fluttertoast.showToast(
            msg: '⚠️⚠️', //fileNotSupported
            gravity: ToastGravity.CENTER);
        HapticFeedback.heavyImpact();
      }
    }
  }

  static Future<File?> onTakeVideo(
      BuildContext context, DraggableWidgetNotifier itemProvider) async {
    checkAndRequestPermission(Permission.camera).then((res) async {
      if (res) {
        await pickVideoFromCamera(context, itemProvider);
      } else {
        Fluttertoast.showToast(
            msg: '📷 ⚠️⚠️', //fileNotSupported
            gravity: ToastGravity.CENTER);

        HapticFeedback.heavyImpact();

        /*   showNotification(
          title: getTranslated(context, "pc00"),
          subtitle: getTranslated(context, "permNeededCam"),
          duration: 10,
          titleColor: Colors.red,
          onPressed: () {
            openAppSettings();
          },
          subtitleColor: themeColorGrey,
        );
        */
      }
    });
  }

  /////
  static onTakePictureButtonPressed(
      BuildContext context, DraggableWidgetNotifier itemProvider) async {
    checkAndRequestPermission(Permission.camera).then((res) async {
      if (res) {
        await captureImage(ImageSource.camera, context, itemProvider);
      } else {
        Fluttertoast.showToast(
            msg: '📷 ⚠️⚠️', //fileNotSupported
            gravity: ToastGravity.CENTER);

        HapticFeedback.heavyImpact();

        /*   showNotification(
          title: getTranslated(context, "pc00"),
          subtitle: getTranslated(context, "permNeededCam"),
          duration: 10,
          titleColor: Colors.red,
          onPressed: () {
            openAppSettings();
          },
          subtitleColor: themeColorGrey,
        );
        */
      }
    });
  }
}

//////////-----////////
String getDocumentType(fileName) {
  if (fileName is String) {
    String fileExtension = p.extension(fileName).toLowerCase();
    if (fileExtension == ".3gp") {
      return "video/3gpp";
    } else if (fileExtension == ".torrent") {
      return "application/x-bittorrent";
    } else if (fileExtension == ".kml") {
      return "application/vnd.google-earth.kml+xml";
    } else if (fileExtension == ".gpx") {
      return "application/gpx+xml";
    } else if (fileExtension == ".csv") {
      return "application/vnd.ms-excel";
    } else if (fileExtension == ".apk") {
      return "application/vnd.android.package-archive";
    } else if (fileExtension == ".asf") {
      return "video/x-ms-asf";
    } else if (fileExtension == ".avi") {
      return "video/x-msvideo";
    } else if (fileExtension == ".bin") {
      return "application/octet-stream";
    } else if (fileExtension == ".bmp") {
      return "image/bmp";
    } else if (fileExtension == ".c") {
      return "text/plain";
    } else if (fileExtension == ".class") {
      return "application/octet-stream";
    } else if (fileExtension == ".conf") {
      return "text/plain";
    } else if (fileExtension == ".cpp") {
      return "text/plain";
    } else if (fileExtension == ".doc") {
      return "application/msword";
    } else if (fileExtension == ".docx") {
      return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
    } else if (fileExtension == ".xls") {
      return "application/vnd.ms-excel";
    } else if (fileExtension == ".xslx") {
      return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    } else if (fileExtension == ".exe") {
      return "application/octet-stream";
    } else if (fileName.toString().toLowerCase().contains("giphy")) {
      //////
      return "image/gif";
    } else if (fileExtension == ".gif") {
      return "image/gif";
    } else if (fileExtension == ".gtar") {
      return "application/x-gtar";
    } else if (fileExtension == ".gz") {
      return "application/x-gzip";
    } else if (fileExtension == ".h") {
      return "text/plain";
    } else if (fileExtension == ".htm") {
      return "text/html";
    } else if (fileExtension == ".html") {
      return "text/html";
    } else if (fileExtension == ".jar") {
      return "application/java-archive";
    } else if (fileExtension == ".java") {
      return "text/plain";
    } else if (fileExtension == ".jpg") {
      return "image/jpeg";
    } else if (fileExtension == ".jpeg") {
      return "image/jpeg";
    } else if (fileExtension == ".js") {
      return "application/x-javascript";
    } else if (fileExtension == ".log") {
      return "text/plain";
    } else if (fileExtension == ".m3u") {
      return "audio/x-mpegurl";
    } else if (fileExtension == ".m4a") {
      return "audio/mp4a-latm";
    } else if (fileExtension == ".m4b") {
      return "audio/mp4a-latm";
    } else if (fileExtension == ".m4p") {
      return "audio/mp4a-latm";
    } else if (fileExtension == ".m4u") {
      return "video/vnd.mpegurl";
    } else if (fileExtension == ".m4v") {
      return "video/x-m4v";
    } else if (fileExtension == ".mov") {
      return "video/quicktime";
    } else if (fileExtension == ".mp2") {
      return "audio/x-mpeg";
    } else if (fileExtension == ".mp3") {
      return "audio/x-mpeg";
    } else if (fileExtension == ".mp4") {
      return "video/mp4";
    } else if (fileExtension == ".mpc") {
      return "application/vnd.mpohun.certificate";
    } else if (fileExtension == ".mpe") {
      return "video/mpeg";
    } else if (fileExtension == ".mpeg") {
      return "video/mpeg";
    } else if (fileExtension == ".mpg") {
      return "video/mpeg";
    } else if (fileExtension == ".mpg4") {
      return "video/mp4";
    } else if (fileExtension == ".mpga") {
      return "audio/mpeg";
    } else if (fileExtension == ".msg") {
      return "application/vnd.ms-outlook";
    } else if (fileExtension == ".ogg") {
      return "audio/ogg";
    } else if (fileExtension == ".pdf") {
      return "application/pdf";
    } else if (fileExtension == ".png") {
      return "image/png";
    } else if (fileExtension == ".pps") {
      return "application/vnd.ms-powerpoint";
    } else if (fileExtension == ".ppt") {
      return "application/vnd.ms-powerpoint";
    } else if (fileExtension == ".pptx") {
      return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
    } else if (fileExtension == ".prop") {
      return "text/plain";
    } else if (fileExtension == ".rc") {
      return "text/plain";
    } else if (fileExtension == ".rmvb") {
      return "audio/x-pn-realaudio";
    } else if (fileExtension == ".rtf") {
      return "application/rtf";
    } else if (fileExtension == ".sh") {
      return "text/plain";
    } else if (fileExtension == ".tar") {
      return "application/x-tar";
    } else if (fileExtension == ".tgz") {
      return "application/x-compressed";
    } else if (fileExtension == ".txt") {
      return "text/plain";
    } else if (fileExtension == ".wav") {
      return "audio/x-wav";
    } else if (fileExtension == ".wma") {
      return "audio/x-ms-wma";
    } else if (fileExtension == ".wmv") {
      return "audio/x-ms-wmv";
    } else if (fileExtension == ".wps") {
      return "application/vnd.ms-works";
    } else if (fileExtension == ".xml") {
      return "text/plain";
    } else if (fileExtension == ".z") {
      return "application/x-compress";
    } else if (fileExtension == ".zip") {
      return "application/x-zip-compressed";
    } else if (fileExtension == "") {
      return "*/*";
    } else {
      return "";
    }
  } else {
    return "";
  }
}
