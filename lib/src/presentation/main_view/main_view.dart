// ignore_for_file: must_be_immutable

import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_media_picker/gallery_media_picker.dart';
import 'package:gallery_media_picker/src/core/functions.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:stories_editor/src/domain/models/editable_items.dart';
import 'package:stories_editor/src/domain/models/painting_model.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/gradient_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/scroll_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/text_editing_notifier.dart';
import 'package:stories_editor/src/presentation/bar_tools/bottom_tools.dart';
import 'package:stories_editor/src/presentation/bar_tools/top_tools.dart';
import 'package:stories_editor/src/presentation/draggable_items/delete_item.dart';
import 'package:stories_editor/src/presentation/draggable_items/draggable_widget.dart';
import 'package:stories_editor/src/presentation/painting_view/painting.dart';
import 'package:stories_editor/src/presentation/painting_view/widgets/sketcher.dart';
import 'package:stories_editor/src/presentation/text_editor_view/TextEditor.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';
import 'package:stories_editor/src/presentation/utils/modal_sheets.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/scrollable_pageView.dart';
import 'package:gallery_media_picker/src/presentation/pages/gallery_media_picker_controller.dart';
import 'package:stories_editor/src/presentation/widgets/circularButtonDesign.dart';
import 'package:giphy_get/giphy_get.dart';

import 'package:stories_editor/src/presentation/utils/storiesCameraFeature.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/rendering.dart';

import 'package:render/render.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
//import 'package:screen_recorder/screen_recorder.dart';
////import 'package:flutter_screen_recorder_ffmpeg/screen_recorder.dart';

class MainView extends StatefulWidget {
  /// editor custom font families
  final List<String>? fontFamilyList;

  /// editor custom font families package
  final bool? isCustomFontList;
  final Widget? permissionWidget;

  /// giphy api key
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

  /// editor background color
  Color? editorBackgroundColor;

  /// gallery thumbnail quality
  final int? galleryThumbnailQuality;

  /// editor custom color palette list
  List<Color>? colorList;

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

  MainView({
    Key? key,
    required this.appname,
    required this.giphyKey,
    required this.onDone,
    required this.permissionWidget,
    this.giphyRating,
    this.giphyLanguage,
    this.middleBottomWidget,
    this.colorList,
    this.isCustomFontList,
    this.fontFamilyList,
    this.gradientColors,
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
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  /// content container key
  final GlobalKey contentKey = GlobalKey();

  ///Editable item
  EditableItem? _activeItem;

  /// Gesture Detector listen changes
  Offset _initPos = const Offset(0, 0);
  Offset _currentPos = const Offset(0, 0);
  double _currentScale = 1;
  double _currentRotation = 0;

  /// delete position
  bool _isDeletePosition = false;
  bool _inAction = false;

  bool canAddMoreImages = true;
  bool canUseVideo = true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      var _control = Provider.of<ControlNotifier>(context, listen: false);

      /// initialize control variable provider
      _control.giphyKey = widget.giphyKey;
      _control.giphyRating = widget.giphyRating;
      _control.giphyLanguage = widget.giphyLanguage;

      _control.middleBottomWidget = widget.middleBottomWidget;
      _control.isCustomFontList = widget.isCustomFontList ?? false;
      if (widget.gradientColors != null) {
        _control.gradientColors = widget.gradientColors;
      }
      if (widget.fontFamilyList != null) {
        _control.fontList = widget.fontFamilyList;
      }
      if (widget.colorList != null) {
        _control.colorList = widget.colorList;
      }

      final GalleryMediaPickerController provider =
          GalleryMediaPickerController();

      var scrollProvider = Provider.of<ScrollNotifier>(context, listen: false);
      scrollProvider.pageController.addListener(scrollProvider_listener);

      if (widget.permissionWidget == null) {
        await GalleryFunctions.getPermission(setState, provider);
      }

      if (widget.starterFile != null) {
        Future.delayed(Duration(milliseconds: 1500), () async {
          _control.mediaPath = widget.starterFile!.path;
          var _itemProvider =
              Provider.of<DraggableWidgetNotifier>(context, listen: false);
          bool isVideo =
              !getDocumentType(widget.starterFile!.path).contains("image");
          Duration? duration;

          _itemProvider.draggableWidget.insert(
              0,
              EditableItem()
                ..type = isVideo ? ItemType.video : ItemType.image
                ..url = widget.starterFile!.path
                ..isStoriesBackground = true
                ..position = const Offset(0.0, 0.0));

          _itemProvider.updatedNeedsRefresh();
          if (isVideo) {
            VideoPlayerController vc =
                VideoPlayerController.file(widget.starterFile!);
            await vc.initialize();
            duration = vc.value.duration;
            vc.dispose();
            if (duration != null) {
              _itemProvider.draggableWidget[0].duration = duration;
            }
          }
        });
      } else if (widget.starterGif != null) {
        final _editableItem =
            Provider.of<DraggableWidgetNotifier>(context, listen: false);
        _editableItem.giphy = widget.starterGif!;
        addGif(_editableItem);
      }
    });
    super.initState();
  }

  void scrollProvider_listener() {
    var controlNotifier = Provider.of<ControlNotifier>(context, listen: false);
    var scrollProvider = Provider.of<ScrollNotifier>(context, listen: false);

    if (scrollProvider.pageController.position.userScrollDirection ==
        ScrollDirection.forward) {
      debugPrint('swiped to mainview');
      if (controlNotifier.multiForNow) controlNotifier.multiForNow = false;
    } else {
      debugPrint('swiped to gallery');
    }
  }

  @override
  void dispose() {
    var scrollProvider = Provider.of<ScrollNotifier>(context, listen: false);
    scrollProvider.pageController.removeListener(scrollProvider_listener);
    super.dispose();
  }

  ////////new
  bool _showDialog = false;
  bool hide4Record = false;
  bool _recording = false;
  bool _exporting = false;

  final controller = RenderController();

  // ScreenRecorderController controller = ScreenRecorderController(); //pixelRatio: 1.0, skipFramesBetweenCaptures: 1
  // bool get canExport => controller.exporter.hasFrames;

  int _timerStart = 5;

  // late Stream<RenderNotifier> stream;
  //Widget? wid;

  recordWidget(DraggableWidgetNotifier itemProvider, int? duration,
      bool doneCallbackBool, bool saveToGallery) async {
    setState(() {
      _showDialog = true;
    });
    if (duration == null) {
      int longestDuration = 0;
      itemProvider.draggableWidget.forEach((element) {
        if (element.duration != null &&
            element.duration!.inSeconds > longestDuration) {
          longestDuration = element.duration!.inSeconds;
        }
      });
      duration = longestDuration;
    }

    final stream = controller.captureMotionWithStream(
      Duration(seconds: duration ?? 5),
      settings: const MotionSettings(
          //  pixelRatio: 5,
          //frameRate: 20, //30
          // simultaneousCaptureHandlers: 6,
          ),
      logInConsole: true,
      format: Mp4Format(
          /*     // scale: RenderScale.fullHD,
          audio: [
            RenderAudio.url(
                 Uri.parse( "https://firebasestorage.googleapis.com/v0/b/facecard-759f9.appspot.com/o/%2B00_AUDIO_MEDIA%2FU934eF7Xw2ZJ9exQfWlnJauty7I3%2F1695893200311%2F1695893200311?alt=media&token=85bc77f0-10c6-4c9c-b33a-dc30322f7b9a.mp3"),
              startTime: 30,
              endTime: 35.4365,
            ),
          ]
          */
          ),
    );
    //   setState(() {
    //    functionController.attach(stream);
    // });
    final result = await stream
        .firstWhere((event) => event.isResult || event.isFatalError);
    if (result.isFatalError) {
      setState(() {
        _showDialog = false;
      });
      return;
    }
    saveResult0(result as RenderResult, doneCallbackBool, saveToGallery);

    /*   final result0 = await controller.captureMotion(
      Duration(seconds: duration ?? 5),
      settings: const MotionSettings(pixelRatio: 4),
      format: Mp4Format(
    /*
          audio: [
        RenderAudio.url( Uri.parse(
                                "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
                            startTime: 40,
                            endTime: 45.4365,),
     //   RenderAudio.file(file),
    ]
    */
          ),
    );
    */

//final controller = VideoPlayerController.file(result.output);
//await controller.initialize();
//await controller.play();

//VideoPlayer(snapshot.data!); // show result as video
  }

  saveResult0(
      RenderResult result, bool doneCallbackBool, bool saveToGallery) async {
    String path = result.output.path;
    if (saveToGallery) {
      await ImageGallerySaver.saveFile(path,
              name: "stories_creator${DateTime.now()}.mp4")
          .then((value) {
        if (value['isSuccess'] == true) {
          debugPrint(value['filePath']);

          if (!doneCallbackBool) {
            Fluttertoast.showToast(
                msg: '👍', gravity: ToastGravity.CENTER); //'Successfully saved'
          }

          if (widget.onDone != null && doneCallbackBool) {
            widget.onDone!(path);
          }
        } else {
          debugPrint(value['errorMessage']);
          Fluttertoast.showToast(
              msg: '⚠️⚠️', gravity: ToastGravity.CENTER); //'Error'
        }
      }).whenComplete(() {
        setState(() {
          _showDialog = false;
        });
      }).catchError((e) {
        setState(() {
          _showDialog = false;
        });
        Fluttertoast.showToast(
            msg: '⚠️⚠️', gravity: ToastGravity.CENTER); //'Error'
      });
    } else {
      if (!doneCallbackBool) {
        Fluttertoast.showToast(
            msg: '👍', gravity: ToastGravity.CENTER); //'Successfully saved'
      }

      if (widget.onDone != null && doneCallbackBool) {
        widget.onDone!(path);
      }
      setState(() {
        _showDialog = false;
      });
    }
  }

/*
  recordWidget(int? duration, bool doneCallbackBool, bool saveToGallery) async {
    controller.start();
    setState(() {
      _showDialog = true;
    });
    await startTimer(duration, doneCallbackBool, saveToGallery);
  }

  startTimer(int? duration, bool doneCallbackBool, bool saveToGallery) async {
    Duration oneSec = Duration(seconds: duration ?? 5);
    String path = "";

    Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (_timerStart == 0) {
          setState(() {
            controller.stop();

            timer.cancel();
          });

          var result = await controller.export(renderType: RenderType.video);
          if (result['success'] == true) {
            path = result['outPath'];

            if (saveToGallery) {
              await ImageGallerySaver.saveFile(path,
                      name: "stories_creator${DateTime.now()}.mp4")
                  .then((value) {
                if (value['isSuccess'] == true) {
                  debugPrint(value['filePath']);

                  if (!doneCallbackBool) {
                    Fluttertoast.showToast(
                        msg: '👍',
                        gravity: ToastGravity.CENTER); //'Successfully saved'
                  }

                  if (widget.onDone != null && doneCallbackBool) {
                    widget.onDone!(path);
                  }
                } else {
                  debugPrint(value['errorMessage']);
                  Fluttertoast.showToast(
                      msg: '⚠️⚠️', gravity: ToastGravity.CENTER); //'Error'
                }
              }).whenComplete(() {
                setState(() {
                  _showDialog = false;
                });
              }).catchError((e) {
                setState(() {
                  _showDialog = false;
                });
                Fluttertoast.showToast(
                    msg: '⚠️⚠️', gravity: ToastGravity.CENTER); //'Error'
              });
            } else {
              if (!doneCallbackBool) {
                Fluttertoast.showToast(
                    msg: '👍',
                    gravity: ToastGravity.CENTER); //'Successfully saved'
              }

              if (widget.onDone != null && doneCallbackBool) {
                widget.onDone!(path);
              }
              setState(() {
                _showDialog = false;
              });
            }
          } else {
            setState(() {
              path = result['msg'];
              _showDialog = false;
            });
            Fluttertoast.showToast(
                msg: '⚠️⚠️', gravity: ToastGravity.CENTER); //'Error'
          }
        } else {
          setState(() {
            _timerStart--;
          });
        }
      },
    );
  }
*/

  bool whiteTheme = false;

  Widget addMediaTopWidget(ScrollNotifier scrollProvider,
      DraggableWidgetNotifier itemProvider, ControlNotifier controlNotifier,
      {bool isVideo = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircularButtonDesign(
            onTap: () async {
              Navigator.of(context).pop();
              await Future.delayed(Duration(milliseconds: 200));

              StoriesCameraFeature.maxFileSizeAllowedInMB =
                  widget.maxFileSizeAllowedInMB;
              StoriesCameraFeature.androidSDKVersion = widget.androidSDKVersion;

              await (isVideo
                  ? StoriesCameraFeature.onTakeVideo(context, itemProvider)
                  : StoriesCameraFeature.onTakePictureButtonPressed(
                      context, itemProvider));
            },
            whiteTheme: !whiteTheme,
            icon: Icons.camera_alt_rounded),
        CircularButtonDesign(
          whiteTheme: !whiteTheme,
          icon: Icons.photo_rounded,
          onTap: () async {
            /// scroll to gridView page

            controlNotifier.multiForNow = true;

            Navigator.of(context).pop();
            await Future.delayed(Duration(milliseconds: 50));
            scrollProvider.pageController.animateToPage(1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease);
          },
        ),
        CircularButtonDesign(
            onTap: () {
              Fluttertoast.showToast(
                  msg: '⚠️⚠️', gravity: ToastGravity.CENTER); //'Error'
            },
            whiteTheme: !whiteTheme,
            icon: Icons.music_note_rounded),
      ],
    );
  }

  Widget leadingWidget(
      ScrollNotifier scrollProvider, ControlNotifier controlNotifier) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, right: 15),
      child: Align(
        alignment: Alignment.bottomRight,
        child: AnimatedOnTapButton(
          onTap: () {
            scrollProvider.pageController.animateToPage(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn);

            controlNotifier.multiForNow = false;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white,
                  width: 1.2,
                )),
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ScreenUtil screenUtil = ScreenUtil();

    return WillPopScope(
      onWillPop: _popScope,
      child: Material(
        color: widget.editorBackgroundColor == Colors.transparent
            ? Colors.black
            : widget.editorBackgroundColor ?? Colors.black,
        child: Consumer6<
            ControlNotifier,
            DraggableWidgetNotifier,
            ScrollNotifier,
            GradientNotifier,
            PaintingNotifier,
            TextEditingNotifier>(
          builder: (context, controlNotifier, itemProvider, scrollProvider,
              colorProvider, paintingProvider, editingProvider, child) {
            return Stack(children: [
              SafeArea(
                //top: false,
                child: ScrollablePageView(
                  scrollPhysics: controlNotifier.mediaPath.isEmpty &&
                      itemProvider.draggableWidget.isEmpty &&
                      !controlNotifier.isPainting &&
                      !controlNotifier.isTextEditing,
                  pageController: scrollProvider.pageController,
                  gridController: scrollProvider.gridController,
                  mainView: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ///gradient container
                            /// this container will contain all widgets(image/texts/draws/sticker)
                            /// wrap this widget with coloredFilter
                            Render(
                                controller: controller,
                                child: GestureDetector(
                                  onScaleStart: _onScaleStart,
                                  onScaleUpdate: _onScaleUpdate,
                                  onTap: () {
                                    controlNotifier.isTextEditing =
                                        !controlNotifier.isTextEditing;
                                  },
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: SizedBox(
                                        width: screenUtil.screenWidth,
                                        child: RepaintBoundary(
                                          key: contentKey,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            decoration: BoxDecoration(
                                                gradient: controlNotifier
                                                        .mediaPath.isEmpty
                                                    ? LinearGradient(
                                                        colors: controlNotifier
                                                                .gradientColors![
                                                            controlNotifier
                                                                .gradientIndex],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      )
                                                    : LinearGradient(
                                                        colors: [
                                                          colorProvider.color1,
                                                          colorProvider.color2
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      )),
                                            child: GestureDetector(
                                              onScaleStart: _onScaleStart,
                                              onScaleUpdate: _onScaleUpdate,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  /// in this case photo view works as a main background container to manage
                                                  /// the gestures of all movable items.
                                                  PhotoView.customChild(
                                                    child: Container(),
                                                    backgroundDecoration:
                                                        const BoxDecoration(
                                                            color: Colors
                                                                .transparent),
                                                  ),

                                                  ///list items
                                                  ...itemProvider
                                                      .draggableWidget
                                                      .map((editableItem) {
                                                    return DraggableWidget(
                                                      context: context,
                                                      draggableWidget:
                                                          editableItem,
                                                      onPointerDown: (details) {
                                                        _updateItemPosition(
                                                          editableItem,
                                                          details,
                                                        );
                                                      },
                                                      onPointerUp: (details) {
                                                        _deleteItemOnCoordinates(
                                                          editableItem,
                                                          details,
                                                          controlNotifier,
                                                        );
                                                      },
                                                      onPointerMove: (details) {
                                                        _deletePosition(
                                                          editableItem,
                                                          details,
                                                          controlNotifier,
                                                        );
                                                      },
                                                    );
                                                  }),

                                                  /// finger paint
                                                  IgnorePointer(
                                                    ignoring: true,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.topCenter,
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(25),
                                                        ),
                                                        child: RepaintBoundary(
                                                          child: SizedBox(
                                                            width: screenUtil
                                                                .screenWidth,
                                                            child: StreamBuilder<
                                                                List<
                                                                    PaintingModel>>(
                                                              stream: paintingProvider
                                                                  .linesStreamController
                                                                  .stream,
                                                              builder: (context,
                                                                  snapshot) {
                                                                return CustomPaint(
                                                                  painter:
                                                                      Sketcher(
                                                                    lines: paintingProvider
                                                                        .lines,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),

                            /// middle text
                            if (itemProvider.draggableWidget.isEmpty &&
                                !controlNotifier.isTextEditing &&
                                paintingProvider.lines.isEmpty)
                              IgnorePointer(
                                ignoring: true,
                                child: Align(
                                  alignment: const Alignment(0, -0.1),
                                  child: Text('Tap to type',
                                      style: TextStyle(
                                          fontFamily: 'Alegreya',
                                          package: 'stories_editor',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 30,
                                          color: Colors.white.withOpacity(0.5),
                                          shadows: <Shadow>[
                                            Shadow(
                                                offset: const Offset(1.0, 1.0),
                                                blurRadius: 3.0,
                                                color: Colors.black45
                                                    .withOpacity(0.3))
                                          ])),
                                ),
                              ),

                            /// top tools
                            Visibility(
                              visible: !controlNotifier.isTextEditing &&
                                  !controlNotifier.isPainting,
                              child: Align(
                                  alignment: Alignment.topCenter,
                                  child: TopTools(
                                    contentKey: contentKey,
                                    context: context,
                                    giphyLanguage: widget.giphyLanguage,
                                    giphyRating: widget.giphyRating,
                                    showSaveDraftOption:
                                        widget.showSaveDraftOption,
                                    saveDraftCallback: widget.saveDraftCallback,
                                    recordCallback: (duration, doneCallbackBool,
                                        saveToGallery) async {
                                      setState(() {
                                        hide4Record = true;
                                      });
                                      await recordWidget(itemProvider, duration,
                                          doneCallbackBool, saveToGallery);
                                      setState(() {
                                        hide4Record = false;
                                      });
                                    },
                                    addMediaTopWidget: addMediaTopWidget(
                                        scrollProvider,
                                        itemProvider,
                                        controlNotifier),
                                  )),
                            ),

                            /// delete item when the item is in position
                            DeleteItem(
                              activeItem: _activeItem,
                              animationsDuration:
                                  const Duration(milliseconds: 300),
                              isDeletePosition: _isDeletePosition,
                              controlNotifier: controlNotifier,
                              itemProvider: itemProvider,
                            ),

                            /// show text editor
                            Visibility(
                              visible: controlNotifier.isTextEditing,
                              child: TextEditor(
                                context: context,
                              ),
                            ),

                            /// show painting sketch
                            Visibility(
                              visible: controlNotifier.isPainting,
                              child: const Painting(),
                            ),
                          ],
                        ),
                      ),

                      /// bottom tools
                      if (!kIsWeb || controlNotifier.isPainting)
                        BottomTools(
                          permissionWidget: widget.permissionWidget,
                          contentKey: contentKey,
                          showAddMoreMediaF: () {
                            showAddMoreMedia(
                              context,
                              scrollProvider,
                              addMediaTopWidget: addMediaTopWidget(
                                  scrollProvider,
                                  itemProvider,
                                  controlNotifier),
                              whiteTheme: whiteTheme,
                            );
                          },
                          onDone: (bytes) {
                            setState(() {
                              widget.onDone!(bytes);
                            });
                          },
                          onDoneButtonStyle: widget.onDoneButtonStyle,
                          editorBackgroundColor: widget.editorBackgroundColor,
                          recordCallback: (duration, doneCallbackBool,
                              saveToGallery) async {
                            setState(() {
                              hide4Record = true;
                            });
                            await recordWidget(itemProvider, duration,
                                doneCallbackBool, saveToGallery);
                            setState(() {
                              hide4Record = false;
                            });
                          },
                        ),
                    ],
                  ),
                  gallery: widget.permissionWidget != null
                      ? Column(children: [
                          Container(
                              margin: EdgeInsets.only(top: 11),
                              //  height: 100,
                              child: leadingWidget(
                                  scrollProvider, controlNotifier)),
                          Container(
                              margin: EdgeInsets.only(top: 11),
                              height: MediaQuery.of(context).size.height / 1.25,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(23),
                                  child: widget.permissionWidget!)),
                        ])
                      : GalleryMediaPicker(
                          multiForNow: controlNotifier.multiForNow,
                          pathList: (List<PickedAssetModel> paths) {
                            if (!controlNotifier.multiForNow &&
                                controlNotifier.mediaPath.isEmpty) {
                              //  if (itemProvider.draggableWidget.isEmpty) {
                              //background
                              controlNotifier.mediaPath =
                                  paths.first.path.toString();
                              // }
                              // if (controlNotifier.mediaPath.isNotEmpty) {
                              itemProvider.draggableWidget.insert(
                                  0,
                                  EditableItem()
                                    ..type = paths.first.type == "video"
                                        ? ItemType.video
                                        : ItemType.image
                                    ..url = paths.first.path.toString()
                                    ..isStoriesBackground = true
                                    ..duration = paths.first.type == "video"
                                        ? paths.first.videoDuration
                                        : null
                                    ..position = const Offset(0.0, 0.0));
                            } else {
                              double randDouble = GetRandomNumber(-0.25, 0.25);

                              paths.forEach((element) {
                                itemProvider.draggableWidget.add(EditableItem()
                                  ..type = element.type == "video"
                                      ? ItemType.video
                                      : ItemType.image
                                  ..scale = paths.length == 1 ? 1.0 : 0.5
                                  //      ..rotation = 0.5
                                  ..url = element.path.toString()
                                  ..duration = element.type == "video"
                                      ? element.videoDuration
                                      : null
                                  ..position = paths.length == 1
                                      ? Offset(0.0, 0.0)
                                      : Offset(randDouble, randDouble));
                                randDouble = GetRandomNumber(randDouble,
                                    randDouble == 0.25 ? 0.2 : 0.25);
                              });
                            }
                            scrollProvider.pageController.animateToPage(0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeIn);
                            controlNotifier.multiForNow = false;
                          },
                          mediaPickerParams: MediaPickerParamsModel(
                            gridViewController: scrollProvider.gridController,
                            thumbnailQuality:
                                widget.galleryThumbnailQuality ?? 200,
                            maxPickImages:
                                controlNotifier.multiForNow == true ||
                                        controlNotifier.mediaPath.isNotEmpty
                                    ? 5
                                    : 1, //1
                            singlePick: controlNotifier.multiForNow == true
                                ? false
                                : controlNotifier.mediaPath.isEmpty, //true
                            onlyImages: !canUseVideo, //true
                            appBarColor:
                                widget.editorBackgroundColor ?? Colors.black,
                            gridViewPhysics:
                                itemProvider.draggableWidget.isEmpty
                                    ? const NeverScrollableScrollPhysics()
                                    : const ScrollPhysics(),
                            selectedCheckBackgroundColor: Colors.blue,
                            appBarHeight: 70,
                            appBarLeadingWidget:
                                leadingWidget(scrollProvider, controlNotifier),
                          ),
                        ),
                ),
              ),
              _showDialog
                  ? Container(
                      color: Colors.black.withOpacity(0.6),
                      child: const Center(
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.7,
                            color: Colors.blue,
                          ),
                        ),
                      ))
                  : SizedBox(),
            ]);
          },
        ),
      ),
    );
  }

  /// validate pop scope gesture
  Future<bool> _popScope() async {
    final controlNotifier =
        Provider.of<ControlNotifier>(context, listen: false);

    final itemProvider =
        Provider.of<DraggableWidgetNotifier>(context, listen: false);

    /// change to false text editing
    if (controlNotifier.isTextEditing) {
      controlNotifier.isTextEditing = !controlNotifier.isTextEditing;
      return false;
    }

    /// change to false painting
    else if (controlNotifier.isPainting) {
      controlNotifier.isPainting = !controlNotifier.isPainting;
      return false;
    }

    /// show close dialog
    else if (!controlNotifier.isTextEditing && !controlNotifier.isPainting) {
      return widget.onBackPress ??
          exitDialog(
            context: context,
            contentKey: contentKey,
            showSaveDraftOption: widget.showSaveDraftOption,
            saveDraftCallback: widget.saveDraftCallback,
            recordCallback: (duration, doneCallbackBool, saveToGallery) async {
              setState(() {
                hide4Record = true;
              });
              await recordWidget(
                  itemProvider, duration, doneCallbackBool, saveToGallery);
              setState(() {
                hide4Record = false;
              });
            },
          );
    }
    return false;
  }

  /// start item scale
  void _onScaleStart(ScaleStartDetails details) {
    if (_activeItem == null) {
      return;
    }
    _initPos = details.focalPoint;
    _currentPos = _activeItem!.position;
    _currentScale = _activeItem!.scale;
    _currentRotation = _activeItem!.rotation;
  }

  /// update item scale
  void _onScaleUpdate(ScaleUpdateDetails details) {
    final ScreenUtil screenUtil = ScreenUtil();
    if (_activeItem == null) {
      return;
    }
    final delta = details.focalPoint - _initPos;

    final left = (delta.dx / screenUtil.screenWidth) + _currentPos.dx;
    final top = (delta.dy / screenUtil.screenHeight) + _currentPos.dy;

    setState(() {
      _activeItem!.position = Offset(left, top);
      _activeItem!.rotation = details.rotation + _currentRotation;
      _activeItem!.scale = details.scale * _currentScale;
    });
  }

  /// active delete widget with offset position
  void _deletePosition(
      EditableItem item, PointerMoveEvent details, ControlNotifier controlP) {
    var _itemProvider =
        Provider.of<DraggableWidgetNotifier>(context, listen: false)
            .draggableWidget;
    if (item.type == ItemType.text &&
        item.position.dy >= 0.75.h &&
        item.position.dx >= -0.4.w &&
        item.position.dx <= 0.2.w) {
      if (!item.deletePosition) {
        HapticFeedback.heavyImpact();
      }
      setState(() {
        _isDeletePosition = true;
        item.deletePosition = true;
      });
    } else if (item.type == ItemType.gif &&
        item.position.dy >= 0.62.h &&
        item.position.dx >= -0.35.w &&
        item.position.dx <= 0.15) {
      if (!item.deletePosition) {
        HapticFeedback.heavyImpact();
      }
      setState(() {
        _isDeletePosition = true;
        item.deletePosition = true;
      });
    } else if (!item.isStoriesBackground &&
        (item.type == ItemType.image || item.type == ItemType.video) &&
        item.position.dy >= 0.52.h &&
        item.position.dx >= -0.2.w &&
        item.position.dx <= 0.10) {
      if (!item.deletePosition) {
        HapticFeedback.heavyImpact();
      }
      setState(() {
        _isDeletePosition = true;
        item.deletePosition = true;
      });
    } else {
      setState(() {
        _isDeletePosition = false;
        item.deletePosition = false;
      });
    }
  }

  /// delete item widget with offset position
  void _deleteItemOnCoordinates(
      EditableItem item, PointerUpEvent details, ControlNotifier controlP) {
    var _itemProvider =
        Provider.of<DraggableWidgetNotifier>(context, listen: false)
            .draggableWidget;
    _inAction = false;
    if (item.isStoriesBackground) {
    } else if (item.type == ItemType.text &&
            item.position.dy >= 0.75.h &&
            item.position.dx >= -0.4.w &&
            item.position.dx <= 0.2.w ||
        item.type == ItemType.gif &&
            item.position.dy >= 0.62.h &&
            item.position.dx >= -0.35.w &&
            item.position.dx <= 0.15 ||
        item.type == ItemType.image &&
            item.position.dy >= 0.52.h &&
            item.position.dx >= -0.20.w &&
            item.position.dx <= 0.10 ||
        item.type == ItemType.video &&
            item.position.dy >= 0.52.h &&
            item.position.dx >= -0.20.w &&
            item.position.dx <= 0.10) {
      setState(() {
        _itemProvider.removeAt(_itemProvider.indexOf(item));
        HapticFeedback.heavyImpact();
      });
    } else {
      setState(() {
        _activeItem = null;
      });
    }
    setState(() {
      _activeItem = null;
    });
  }

  /// update item position, scale, rotation
  void _updateItemPosition(EditableItem item, PointerDownEvent details) {
    if (_inAction) {
      return;
    }

    _inAction = true;
    _activeItem = item;
    _initPos = details.position;
    _currentPos = item.position;
    _currentScale = item.scale;
    _currentRotation = item.rotation;

    /// set vibrate
    HapticFeedback.lightImpact();
  }
}
