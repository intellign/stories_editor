import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_gif_picker/modal_gif_picker.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:stories_editor/src/domain/models/editable_items.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/text_editing_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/scroll_notifier.dart';
import 'package:stories_editor/src/domain/sevices/save_as_image.dart';
import 'package:stories_editor/src/domain/sevices/downloadMedia.dart';
import 'package:stories_editor/src/presentation/utils/Extensions/hexColor.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/circularButtonDesign.dart';

/// create item of type GIF
Future createGiphyItem(
    {required BuildContext context,
    required String giphyKey,
    required Widget? addMediaTopWidget,
    String? giphyRating,
    String? giphyLanguage}) async {
  final _editableItem =
      Provider.of<DraggableWidgetNotifier>(context, listen: false);
  _editableItem.giphy = await ModalGifPicker.pickModalSheetGif(
    context: context,
    apiKey: giphyKey,
    rating: giphyRating ?? GiphyRating.r,
    lang: giphyLanguage ?? GiphyLanguage.english,
    sticker: true,
    backDropColor: Colors.black,
    crossAxisCount: 3,
    childAspectRatio: 1.2,
    topDragColor: Colors.white.withOpacity(0.2),
    //
    addMediaTopWidget: addMediaTopWidget,
  );

  /// create item of type GIF
  if (_editableItem.giphy != null) {
    int index = _editableItem.draggableWidget.isEmpty
        ? 0
        : _editableItem.draggableWidget.length - 1;

    _editableItem.draggableWidget.add(EditableItem()
      ..type = ItemType.gif
      ..gif = _editableItem.giphy!
      ..position = const Offset(0.0, 0.0));

    Duration? duration;
    String gifUrl = "";
    if (_editableItem.giphy!.images.original!.webp != null) {
      gifUrl = _editableItem.giphy!.images.original!.webp!;
      DownloadMedia.downloadFile(gifUrl, callback: (file) async {
        duration = await extractGifDuration(file.path);

        if (gifUrl.isNotEmpty) {
          DownloadMedia.removeFile(gifUrl);
        }
        if (duration != null) {
          _editableItem.draggableWidget[index].duration = duration;
        }
      });
    }
  }
}

//TODO - do!
////---add GifView package
/*
GifView.asset(
                'assets/onBoarding1-2.gif',
                onFrame: (value) =>  duration = ((value/15)*pow(10, 3)).round(),
                onFinish: () => defaultDuration = duration;
              ),
*/
Future<Duration> extractGifDuration(String path) async {
  ////final gifPath = "assets/gif_path.gif";
  Duration duration = Duration.zero;
  // ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromAsset(path);
  ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromFilePath(path);
  ui.Codec codec =
      await PaintingBinding.instance.instantiateImageCodecWithSize(buffer);
  for (var i = 0; i < codec.frameCount; i++) {
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    duration += frameInfo.duration;
  }
  return duration;
}

double GetRandomNumber(double minimum, double maximum) {
  math.Random random = new math.Random();
  return random.nextDouble() * (maximum - minimum) + minimum;
}

showAddMoreMedia(BuildContext context, ScrollNotifier scrollNotifier,
    {required Widget addMediaTopWidget, required bool whiteTheme}) async {
  await showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.3,
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 1,
            minChildSize: 0.9,
            expand: true,
            builder: (BuildContext context, ScrollController scrollController) {
              return Center(
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(16),
                          topLeft: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 10,
                            spreadRadius: 16,
                            color: (whiteTheme ? Colors.white : Colors.black)
                                .withOpacity(0.3),
                            offset: const Offset(0, 16))
                      ]),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        topLeft: Radius.circular(16)),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(
                        sigmaX: 40.0,
                        sigmaY: 40.0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                            color: (whiteTheme ? Colors.white : Colors.black)
                                .withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                topLeft: Radius.circular(16)),
                            border: Border.all(
                              width: 1.5,
                              color: Colors.transparent,
                            )),
                        child: Center(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  decoration: BoxDecoration(
                                      color: whiteTheme
                                          ? Colors.grey
                                          : Colors.white54,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(10))),
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              addMediaTopWidget,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      });
}

/// custom exit dialog
Future<bool> exitDialog({
  required context,
  required contentKey,
  bool? showSaveDraftOption,
  Function(String draftPath)? saveDraftCallback,
  Function(int? duration, bool doneCallbackBool, bool saveToGallery)?
      recordCallback,
}) async {
  return (await showDialog(
        context: context,
        barrierColor: Colors.black38,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          insetAnimationDuration: const Duration(milliseconds: 300),
          insetAnimationCurve: Curves.ease,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              padding: const EdgeInsets.only(
                  top: 25, bottom: 5, right: 15, left: 15),
              alignment: Alignment.center,
              height: 280,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: HexColor.fromHex('#262626'),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.white10,
                        offset: Offset(0, 1),
                        blurRadius: 4),
                  ]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Discard Edits?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    "If you go back now, you'll lose all the edits you've made.",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white54,
                        letterSpacing: 0.1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 40,
                  ),

                  /// discard
                  AnimatedOnTapButton(
                    onTap: () async {
                      _resetDefaults(context: context);
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: Text(
                      'Discard',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.redAccent.shade200,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.1),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                    child: Divider(
                      color: Colors.white10,
                    ),
                  ),

                  /// save and exit
                  showSaveDraftOption == false
                      ? SizedBox()
                      : AnimatedOnTapButton(
                          onTap: () async {
                            final _paintingProvider =
                                Provider.of<PaintingNotifier>(context,
                                    listen: false);
                            final _widgetProvider =
                                Provider.of<DraggableWidgetNotifier>(context,
                                    listen: false);
                            if (_paintingProvider.lines.isNotEmpty ||
                                _widgetProvider.draggableWidget.isNotEmpty) {
                              if (recordCallback != null &&
                                  (_widgetProvider.draggableWidget.indexWhere(
                                          (element) =>
                                              element.animationType !=
                                                  TextAnimationType.none ||
                                              element.type == ItemType.gif ||
                                              element.type == ItemType.video ||
                                              element.type == ItemType.audio) >
                                      -1)) {
                                await recordCallback!(null, false, false);
                                _dispose(
                                    context: dialogContext,
                                    message:
                                        'Successfully saved'); //add error- check response
                              } else {
                                /// save image
                                var response = await takePicture(
                                    contentKey: contentKey,
                                    context: context,
                                    saveToGallery: saveDraftCallback != null
                                        ? false
                                        : true);
                                if (response) {
                                  _dispose(
                                      context: dialogContext,
                                      message: 'Successfully saved');
                                  if (saveDraftCallback != null &&
                                      response is String) {
                                    saveDraftCallback(response);
                                  }
                                } else {
                                  _dispose(
                                      context: dialogContext, message: 'Error');
                                }
                              }
                            } else {
                              _dispose(
                                  context: dialogContext,
                                  message: 'Draft Empty');
                            }
                          },
                          child: Text(
                            'Save Draft',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5),
                            textAlign: TextAlign.center,
                          ),
                        ),
                  showSaveDraftOption == false
                      ? SizedBox()
                      : SizedBox(
                          height: 22,
                          child: Divider(
                            color: Colors.white10,
                          ),
                        ),

                  ///cancel
                  AnimatedOnTapButton(
                    onTap: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )) ??
      false;
}

_resetDefaults({required BuildContext context}) {
  final _paintingProvider =
      Provider.of<PaintingNotifier>(context, listen: false);
  final _widgetProvider =
      Provider.of<DraggableWidgetNotifier>(context, listen: false);
  final _controlProvider = Provider.of<ControlNotifier>(context, listen: false);
  final _editingProvider =
      Provider.of<TextEditingNotifier>(context, listen: false);
  _paintingProvider.lines.clear();
  _widgetProvider.draggableWidget.clear();
  _widgetProvider.setDefaults();
  _paintingProvider.resetDefaults();
  _editingProvider.setDefaults();
  _controlProvider.mediaPath = '';
}

_dispose({required context, required message}) {
  _resetDefaults(context: context);
  Fluttertoast.showToast(msg: message);
  Navigator.of(context).pop(true);
}
