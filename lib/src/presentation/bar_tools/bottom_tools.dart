import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_media_picker/gallery_media_picker.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/scroll_notifier.dart';
import 'package:stories_editor/src/domain/sevices/save_as_image.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/color_selector.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';

class BottomTools extends StatelessWidget {
  final GlobalKey contentKey;
  final Function(String imageUri) onDone;
  final Widget? onDoneButtonStyle;
  final Widget? permissionWidget;
  final Function() showAddMoreMediaF;
  final Function(int? duration, bool doneCallbackBool, bool saveToGallery)?
      recordCallback;

  /// editor background color
  final Color? editorBackgroundColor;
  const BottomTools(
      {Key? key,
      required this.contentKey,
      required this.onDone,
      required this.showAddMoreMediaF,
      this.onDoneButtonStyle,
      this.permissionWidget,
      this.recordCallback,
      this.editorBackgroundColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer3<ControlNotifier, ScrollNotifier, DraggableWidgetNotifier>(
      builder: (_, controlNotifier, scrollNotifier, itemNotifier, __) {
        return Container(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 40.h),
            child: controlNotifier.isPainting
                ? Padding(
                    padding: EdgeInsets.only(bottom: 30),
                    child: const ColorSelector(),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// preview gallery
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            child: _preViewContainer(
                              /// if [model.imagePath] is null/empty return preview image
                              child: controlNotifier.mediaPath.isEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: GestureDetector(
                                        onTap: () {
                                          /// scroll to gridView page
                                          scrollNotifier.pageController
                                              .animateToPage(1,
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  curve: Curves.ease);
                                        },
                                        child: scrollNotifier
                                                    .pageController.page ==
                                                null
                                            ? Container(
                                                height: 45,
                                                width: 45,
                                                // color: Colors.transparent,

                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.file(
                                                    File(controlNotifier
                                                        .mediaPath),
                                                    fit: BoxFit.fill,
                                                  ),
                                                ))
                                            : CoverThumbnail(
                                                permissionWidget:
                                                    permissionWidget,
                                                thumbnailQuality: 150,
                                                viewIndex: scrollNotifier
                                                    .pageController.page!
                                                    .round(),
                                              ),
                                      ))

                                  /// return clear [imagePath] provider
                                  : GestureDetector(
                                      onVerticalDragStart: controlNotifier
                                              .mediaPath.isNotEmpty
                                          ? (details) {
                                              /// scroll to gridView page
                                              scrollNotifier.pageController
                                                  .animateToPage(1,
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      curve: Curves.ease);
                                            }
                                          : null,
                                      onVerticalDragCancel: controlNotifier
                                              .mediaPath.isNotEmpty
                                          ? () {
                                              /// scroll to gridView page
                                              scrollNotifier.pageController
                                                  .animateToPage(0,
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      curve: Curves.ease);
                                            }
                                          : null,
                                      onTap: () {
                                        /// clear image url variable
                                        controlNotifier.mediaPath = '';
                                        if (itemNotifier
                                            .draggableWidget.isNotEmpty) {
                                          itemNotifier.draggableWidget
                                              .removeAt(0);
                                        }
                                      },
                                      child: true
                                          ? Stack(
                                              alignment:
                                                  AlignmentDirectional.center,
                                              children: [
                                                  Container(
                                                      height: 45,
                                                      width: 45,
                                                      // color: Colors.transparent,

                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: Image.file(
                                                          File(controlNotifier
                                                              .mediaPath),
                                                          fit: BoxFit.fill,
                                                        ),
                                                      )),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.5),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8)),
                                                  ),
                                                  Transform.scale(
                                                    scale: 0.7,
                                                    child: const Icon(
                                                      Icons.delete,
                                                      size: 29,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ])
                                          : Container(
                                              height: 45,
                                              width: 45,
                                              // color: Colors.transparent,

                                              child: Container(
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      /// center logo
                      if (controlNotifier.middleBottomWidget != null)
                        Expanded(
                          child: Center(
                            child: Container(
                                alignment: Alignment.bottomCenter,
                                child: GestureDetector(
                                  onVerticalDragStart:
                                      controlNotifier.mediaPath.isNotEmpty
                                          ? (details) {
                                              /// scroll to gridView page
                                              scrollNotifier.pageController
                                                  .animateToPage(1,
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      curve: Curves.ease);
                                            }
                                          : null,
                                  onVerticalDragCancel:
                                      controlNotifier.mediaPath.isNotEmpty
                                          ? () {
                                              /// scroll to gridView page
                                              scrollNotifier.pageController
                                                  .animateToPage(0,
                                                      duration: const Duration(
                                                          milliseconds: 300),
                                                      curve: Curves.ease);
                                            }
                                          : null,
                                  onTap: () {
                                    showAddMoreMediaF();
                                  },
                                  child: controlNotifier.middleBottomWidget,
                                  //Icon(Icons.add_box_rounded,color: Colors.white,size: 17,)
                                )),
                          ),
                        )
                      else
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/instagram_logo.png',
                                  package: 'stories_editor',
                                  color: Colors.white,
                                  height: 42,
                                ),
                                const Text(
                                  'Stories Creator',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      letterSpacing: 1.5,
                                      fontSize: 9.2,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),

                      /// save final image to gallery
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: Transform.scale(
                            scale: 0.9,
                            child: AnimatedOnTapButton(
                                onTap: () async {
                                  String pngUri;
                                  if (recordCallback != null &&
                                      (itemNotifier.draggableWidget.indexWhere(
                                              (element) =>
                                                  element.animationType !=
                                                      TextAnimationType.none ||
                                                  element.type ==
                                                      ItemType.gif ||
                                                  element.type ==
                                                      ItemType.video ||
                                                  element.type ==
                                                      ItemType.audio) >
                                          -1)) {
                                    recordCallback!(null, true, false);
                                  } else {
                                    await takePicture(
                                            contentKey: contentKey,
                                            context: context,
                                            saveToGallery: false)
                                        .then((bytes) {
                                      if (bytes != null) {
                                        pngUri = bytes;
                                        onDone(pngUri);
                                      } else {}
                                    });
                                  }
                                },
                                child: onDoneButtonStyle ??
                                    Container(
                                      padding: const EdgeInsets.only(
                                          left: 12,
                                          right: 5,
                                          top: 4,
                                          bottom: 4),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                              color: Colors.white, width: 1.5)),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Text(
                                              'Share',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  letterSpacing: 1.5,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(left: 5),
                                              child: Icon(
                                                Icons.arrow_forward_ios,
                                                color: Colors.white,
                                                size: 15,
                                              ),
                                            ),
                                          ]),
                                    )),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _preViewContainer({child}) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(width: 1.4, color: Colors.white)),
      child: child,
    );
  }
}
