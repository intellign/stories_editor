import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/painting_notifier.dart';
import 'package:stories_editor/src/domain/sevices/save_as_image.dart';
import 'package:stories_editor/src/presentation/utils/modal_sheets.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/tool_button.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';

class TopTools extends StatefulWidget {
  final GlobalKey contentKey;
  final BuildContext context;
  final bool? showSaveDraftOption;
  final String? giphyRating;
  final String? giphyLanguage;
  final Function(String draftPath)? saveDraftCallback;
  final Function(int? duration, bool doneCallbackBool, bool saveToGallery)?
      recordCallback;
  final Widget? addMediaTopWidget;

  const TopTools({
    Key? key,
    required this.contentKey,
    required this.context,
    this.showSaveDraftOption,
    this.saveDraftCallback,
    this.giphyRating,
    this.recordCallback,
    this.giphyLanguage,
    this.addMediaTopWidget,
  }) : super(key: key);

  @override
  _TopToolsState createState() => _TopToolsState();
}

class _TopToolsState extends State<TopTools> {
  @override
  Widget build(BuildContext context) {
    return Consumer3<ControlNotifier, PaintingNotifier,
        DraggableWidgetNotifier>(
      builder: (_, controlNotifier, paintingNotifier, itemNotifier, __) {
        return SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20.w),
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// close button
                ToolButton(
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () async {
                      if (paintingNotifier.lines.isEmpty &&
                          itemNotifier.draggableWidget.isEmpty) {
                        Navigator.pop(context);
                      } else {
                        var res = await exitDialog(
                          context: widget.context,
                          contentKey: widget.contentKey,
                          showSaveDraftOption: widget.showSaveDraftOption,
                          saveDraftCallback: widget.saveDraftCallback,
                          recordCallback: widget.recordCallback,
                        );
                        if (res) {
                          Navigator.pop(context);
                        }
                      }
                    }),
                if (controlNotifier.mediaPath.isEmpty)
                  _selectColor(
                      controlProvider: controlNotifier,
                      onLongPress: () {
                        HapticFeedback.heavyImpact();

                        setState(() {
                          controlNotifier.gradientIndex = 0;
                        });
                      },
                      onTap: () {
                        if (controlNotifier.gradientIndex >=
                            controlNotifier.gradientColors!.length - 1) {
                          setState(() {
                            controlNotifier.gradientIndex = 0;
                          });
                        } else {
                          setState(() {
                            controlNotifier.gradientIndex += 1;
                          });
                        }
                      }),
                ToolButton(
                    child: const ImageIcon(
                      AssetImage('assets/icons/download.png',
                          package: 'stories_editor'),
                      color: Colors.white,
                      size: 20,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () async {
                      if (paintingNotifier.lines.isNotEmpty ||
                          itemNotifier.draggableWidget.isNotEmpty) {
                        if (widget.recordCallback != null &&
                            (itemNotifier.draggableWidget.indexWhere(
                                    (element) =>
                                        element.animationType !=
                                            TextAnimationType.none ||
                                        element.type == ItemType.gif ||
                                        element.type == ItemType.video ||
                                        element.type == ItemType.audio) >
                                -1)) {
                          widget.recordCallback!(null, false, true);
                        } else {
                          var response = await takePicture(
                              contentKey: widget.contentKey,
                              context: context,
                              saveToGallery: true);

                          if (response) {
                            Fluttertoast.showToast(
                                msg: '👍'); //'Successfully saved'
                          } else {
                            Fluttertoast.showToast(msg: '⚠️⚠️'); //'Error'
                          }
                        }
                      }
                    }),
                ToolButton(
                    child: const ImageIcon(
                      AssetImage('assets/icons/stickers.png',
                          package: 'stories_editor'),
                      color: Colors.white,
                      size: 20,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () => createGiphyItem(
                          context: context,
                          giphyKey: controlNotifier.giphyKey,
                          giphyRating:
                              widget.giphyRating, //controlNotifier.giphyRating,
                          giphyLanguage: widget
                              .giphyLanguage, //controlNotifier.giphyLanguage,
                          addMediaTopWidget: widget.addMediaTopWidget,
                        )),
                ToolButton(
                    child: const ImageIcon(
                      AssetImage('assets/icons/draw.png',
                          package: 'stories_editor'),
                      color: Colors.white,
                      size: 20,
                    ),
                    backGroundColor: Colors.black12,
                    onTap: () {
                      controlNotifier.isPainting = true;
                      //createLinePainting(context: context);
                    }),
                // ToolButton(
                //   child: ImageIcon(
                //     const AssetImage('assets/icons/photo_filter.png',
                //         package: 'stories_editor'),
                //     color: controlNotifier.isPhotoFilter ? Colors.black : Colors.white,
                //     size: 20,
                //   ),
                //   backGroundColor:  controlNotifier.isPhotoFilter ? Colors.white70 : Colors.black12,
                //   onTap: () => controlNotifier.isPhotoFilter =
                //   !controlNotifier.isPhotoFilter,
                // ),
                ToolButton(
                  child: const ImageIcon(
                    AssetImage('assets/icons/text.png',
                        package: 'stories_editor'),
                    color: Colors.white,
                    size: 20,
                  ),
                  backGroundColor: Colors.black12,
                  onTap: () => controlNotifier.isTextEditing =
                      !controlNotifier.isTextEditing,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// gradient color selector
  Widget _selectColor({onTap, onLongPress, controlProvider}) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, top: 8),
      child: AnimatedOnTapButton(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: controlProvider
                      .gradientColors![controlProvider.gradientIndex]),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
