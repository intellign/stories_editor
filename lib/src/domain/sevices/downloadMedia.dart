import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
////import 'dart:dio/dio.dart';

class DownloadMedia {
  static downloadFile(String url,
      {required Function(File file) callback}) async {
    DefaultCacheManager().downloadFile(url).then((value) {
      callback(value.file);
    });
  }

  static removeFile(String url) async {
    await DefaultCacheManager().removeFile(url).then((value) {
      if (kDebugMode) {
        debugPrint('File removed');
      }
    }).onError((error, stackTrace) {
      if (kDebugMode) {
        debugPrint(error?.toString());
      }
    });
  }
}

/*
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class DownloadMedia {
  static downloadFile(String url,
      {required String extension,
      required Function(File file) callback}) async {
    Directory? directory;
    directory = await getApplicationDocumentsDirectory();

    File saveFile = File(
        "${directory.path}/stories_cache/${DateTime.now().millisecondsSinceEpoch}${extension}");

    var dio = Dio();
    // dio.options.headers['Content-Type'] = 'application/ld+json';
    //  dio.options.headers['Authorization'] = 'Token if present';
    try {
      await dio.download(url, saveFile.path,
          onReceiveProgress: (received, total) {
        int progress = (((received / total) * 100).toInt());

        print(progress);
      }).then((value) {
        callback(saveFile);
      });
    } on DioError catch (e) {
      return null;
    }
  }

  static removeFile(String url) async {
    await DefaultCacheManager().removeFile(url).then((value) {
      if (kDebugMode) {
        print('File removed');
      }
    }).onError((error, stackTrace) {
      if (kDebugMode) {
        print(error);
      }
    });
  }
}
*/