// ignore_for_file: must_be_immutable
library stories_editor;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/gradient_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/scroll_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/text_editing_notifier.dart';
import 'package:stories_editor/src/presentation/main_view/main_view.dart';
import 'package:giphy_get/giphy_get.dart';

export 'package:stories_editor/stories_editor.dart';

class StoriesEditor extends StatefulWidget {
  /// editor custom font families
  final List<String>? fontFamilyList;

  /// editor custom font families package
  final bool? isCustomFontList;

  /// giphy api key
  final Widget? permissionWidget;
  final String appname;
  final String giphyKey;
  final String? giphyRating;
  final String? giphyLanguage;

  /// editor custom color gradients
  final List<List<Color>>? gradientColors;

  /// editor custom logo
  final Widget? middleBottomWidget;

  /// on done
  final Function(String)? onDone;

  /// on done button Text
  final Widget? onDoneButtonStyle;

  /// on back pressed
  final Future<bool>? onBackPress;

  /// editor custom color palette list
  final List<Color>? colorList;

  /// editor background color
  final Color? editorBackgroundColor;

  /// gallery thumbnail quality
  final int? galleryThumbnailQuality;

  /// editor init file
  File? starterFile;

  /// editor init Gif
  GiphyGif? starterGif;

  /// maxFileSizeAllowedInMB
  final int maxFileSizeAllowedInMB;

  /// androidSDKVersion
  final int androidSDKVersion;

  /// showSaveDraft
  final bool? showSaveDraftOption;

  /// showSaveDraftCallback
  final Function(String draftPath)? saveDraftCallback;

  StoriesEditor({
    Key? key,
    required this.appname,
    required this.giphyKey,
    required this.onDone,
    required this.permissionWidget,
    this.giphyRating,
    this.giphyLanguage,
    this.middleBottomWidget,
    this.colorList,
    this.gradientColors,
    this.fontFamilyList,
    this.isCustomFontList,
    this.onBackPress,
    this.onDoneButtonStyle,
    this.editorBackgroundColor,
    this.galleryThumbnailQuality,
    this.starterFile,
    this.starterGif,
    this.showSaveDraftOption,
    this.saveDraftCallback,
    required this.maxFileSizeAllowedInMB,
    required this.androidSDKVersion,
  }) : super(key: key);

  @override
  _StoriesEditorState createState() => _StoriesEditorState();
}

class _StoriesEditorState extends State<StoriesEditor> {
  @override
  void initState() {
    //deprecated
    //Paint.enableDithering = true;
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    super.initState();
  }

  @override
  void dispose() {
    if (mounted) {
      super.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (overscroll) {
        overscroll.disallowIndicator();
        return false;
      },
      child: ScreenUtilInit(
        designSize: const Size(1080, 1920),
        builder: (_, __) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ControlNotifier()),
            ChangeNotifierProvider(create: (_) => ScrollNotifier()),
            ChangeNotifierProvider(create: (_) => DraggableWidgetNotifier()),
            ChangeNotifierProvider(create: (_) => GradientNotifier()),
            ChangeNotifierProvider(create: (_) => PaintingNotifier()),
            ChangeNotifierProvider(create: (_) => TextEditingNotifier()),
          ],
          child: MainView(
            appname: widget.appname,
            giphyKey: widget.giphyKey,
            giphyLanguage: widget.giphyLanguage,
            giphyRating: widget.giphyRating,
            onDone: widget.onDone,
            permissionWidget: widget.permissionWidget,
            fontFamilyList: widget.fontFamilyList,
            isCustomFontList: widget.isCustomFontList,
            middleBottomWidget: widget.middleBottomWidget,
            gradientColors: widget.gradientColors,
            colorList: widget.colorList,
            onDoneButtonStyle: widget.onDoneButtonStyle,
            onBackPress: widget.onBackPress,
            editorBackgroundColor: widget.editorBackgroundColor,
            galleryThumbnailQuality: widget.galleryThumbnailQuality,
            starterFile: widget.starterFile,
            starterGif: widget.starterGif,
            showSaveDraftOption: widget.showSaveDraftOption,
            saveDraftCallback: widget.saveDraftCallback,
            maxFileSizeAllowedInMB: widget.maxFileSizeAllowedInMB,
            androidSDKVersion: widget.androidSDKVersion,
          ),
        ),
      ),
    );
  }
}
