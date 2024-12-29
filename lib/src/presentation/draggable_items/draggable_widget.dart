import 'dart:io';

import 'package:extended_image/extended_image.dart';

import 'package:align_positioned/align_positioned.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'package:modal_gif_picker/modal_gif_picker.dart';
import 'package:provider/provider.dart';
import 'package:stories_editor/src/domain/models/editable_items.dart';
import 'package:stories_editor/src/domain/providers/notifiers/control_provider.dart';
import 'package:stories_editor/src/domain/providers/notifiers/draggable_widget_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/gradient_notifier.dart';
import 'package:stories_editor/src/domain/providers/notifiers/text_editing_notifier.dart';
import 'package:stories_editor/src/presentation/utils/constants/app_enums.dart';
import 'package:stories_editor/src/presentation/widgets/animated_onTap_button.dart';
import 'package:stories_editor/src/presentation/widgets/file_image_bg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DraggableWidget extends StatelessWidget {
  final EditableItem draggableWidget;
  final Function(PointerDownEvent)? onPointerDown;
  final Function(PointerUpEvent)? onPointerUp;
  final Function(PointerMoveEvent)? onPointerMove;
  final BuildContext context;
  const DraggableWidget({
    Key? key,
    required this.context,
    required this.draggableWidget,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerMove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScreenUtil screenUtil = ScreenUtil();
    var _colorProvider =
        Provider.of<GradientNotifier>(this.context, listen: false);
    var _controlProvider =
        Provider.of<ControlNotifier>(this.context, listen: false);
    Widget? overlayWidget;

    switch (draggableWidget.type) {
      case ItemType.text:
        overlayWidget = IntrinsicWidth(
          child: IntrinsicHeight(
            child: Container(
              constraints: BoxConstraints(
                minHeight: 50,
                minWidth: 50,
                maxWidth: screenUtil.screenWidth - 240.w,
              ),
              width: draggableWidget.deletePosition ? 100 : null,
              height: draggableWidget.deletePosition ? 100 : null,
              child: AnimatedOnTapButton(
                onTap: () => _onTap(context, draggableWidget, _controlProvider),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _controlProvider.isTextShadow != true
                        ? SizedBox()
                        : Center(
                            child: _text(
                                background: true,
                                paintingStyle: PaintingStyle.fill,
                                controlNotifier: _controlProvider),
                          ),
                    _controlProvider.isTextShadow != true
                        ? SizedBox()
                        : IgnorePointer(
                            ignoring: true,
                            child: Center(
                              child: _text(
                                  background: true,
                                  paintingStyle: PaintingStyle.stroke,
                                  controlNotifier: _controlProvider),
                            ),
                          ),
                    Padding(
                      padding: const EdgeInsets.only(right: 2.5, top: 2),
                      child: Stack(
                        children: [
                          Center(
                            child: _text(
                                paintingStyle: PaintingStyle.fill,
                                controlNotifier: _controlProvider),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
        break;

      /// image [file_image_gb.dart]
      case ItemType.image:
        //   if (_controlProvider.mediaPath.isNotEmpty) {
        overlayWidget = AnimatedOnTapButton(
            onTap: () =>
                _onTapOther(context, draggableWidget, _controlProvider),
            child: SizedBox(
              width: screenUtil.screenWidth - 144.w,
              child: FileImageBG(
                filePath: File(draggableWidget.url),
                generatedGradient: (color1, color2) {
                  if (draggableWidget.isStoriesBackground) {
                    _colorProvider.color1 = color1;
                    _colorProvider.color2 = color2;
                  }
                },
              ),
            ));
        //  } else { overlayWidget = Container(); }

        break;

      case ItemType.gif:
        overlayWidget = SizedBox(
          width: 150,
          height: 150,
          child: AnimatedOnTapButton(
              onTap: () =>
                  _onTapOther(context, draggableWidget, _controlProvider),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  /// create Gif widget
                  Center(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.transparent),
                      child:
                          //stopped using modal_gif
                          gifWidget(),
                      /* true
                          ? GiphyRenderImage.fixedWidth(
                              gif: draggableWidget.gif,
                              useUrlToSaveMemory: true,
                            )
                          : GiphyRenderImage.original(gif: draggableWidget.gif),
                          */
                    ),
                  ),
                ],
              )),
        );
        break;

      case ItemType.video:
        overlayWidget = const Center();
        break;
      case ItemType.audio:
        overlayWidget = const Center();
        break;
    }

    /// set widget data position on main screen
    return AnimatedAlignPositioned(
      duration: const Duration(milliseconds: 50),
      dy: (draggableWidget.deletePosition
          ? _deleteTopOffset()
          : (draggableWidget.position.dy * screenUtil.screenHeight)),
      dx: (draggableWidget.deletePosition
          ? 0
          : (draggableWidget.position.dx * screenUtil.screenWidth)),
      alignment: Alignment.center,
      child: Transform.scale(
        scale: draggableWidget.deletePosition
            ? _deleteScale()
            : draggableWidget.scale,
        child: Transform.rotate(
          angle: draggableWidget.rotation,
          child: Listener(
            onPointerDown: onPointerDown,
            onPointerUp: onPointerUp,
            onPointerMove: onPointerMove,

            /// show widget
            child: overlayWidget,
          ),
        ),
      ),
    );
  }

  Widget loading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget gifWidget() {
    double _aspectRatio = 0.0;
    if (draggableWidget.gif.images != null) {
      _aspectRatio =
          (double.parse(draggableWidget.gif.images!.fixedWidth.width) /
              double.parse(draggableWidget.gif.images!.fixedWidth.height));
    }
    return true
        ? ExtendedImage.network(
            draggableWidget.gif.images!.fixedWidth.webp!,
            semanticLabel: draggableWidget.gif.title,
            cache: true,
            gaplessPlayback: true,
            fit: BoxFit.fill,
            headers: const {'accept': 'image/*'},
            loadStateChanged: (state) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: draggableWidget.gif.images == null
                  ? Container()
                  : case2(
                      state.extendedImageLoadState,
                      {
                        LoadState.loading: AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.transparent,
                            height: 30,
                            width: 30,
                            child: const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white54),
                              strokeWidth: 1,
                            ),
                          ),
                        ),
                        LoadState.completed: AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: ExtendedRawImage(
                            fit: BoxFit.fill,
                            image: state.extendedImageInfo?.image,
                          ),
                        ),
                        LoadState.failed: AspectRatio(
                          aspectRatio: _aspectRatio,
                          child: Container(
                            color: Theme.of(context).cardColor,
                          ),
                        ),
                      },
                      AspectRatio(
                        aspectRatio: _aspectRatio,
                        child: Container(
                          color: Theme.of(context).cardColor,
                        ),
                      ),
                    ),
            ),
          )
        : draggableWidget.gif.images != null &&
                draggableWidget.gif.images!.fixedWidth.webp != null
            ? true
                ? CachedNetworkImage(
                    imageUrl: draggableWidget.gif.images!.fixedWidth.webp!,
                    placeholder: (context, url) => loading(),
                    errorWidget: (context, url, error) => loading(),
                    imageBuilder: (context, imageProvider) => Container(
                          //     width: w,
                          //   height: w / 1.2,
                          decoration: BoxDecoration(
                            //     shape: BoxShape.circle,
                            //  borderRadius: BorderRadius.all( Radius.circular(10)),
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.fill),
                          ),
                        ))
                : Image.network(
                    draggableWidget.gif.images!.fixedWidth.webp!,
                    gaplessPlayback: true,
                    fit: BoxFit.fill,
                    loadingBuilder: (context, child, loadingProgress) =>
                        loading(),
                    errorBuilder: (context, error, stackTrace) => loading(),
                  )
            : loading();
  }

  /// text widget
  Widget _text(
      {required ControlNotifier controlNotifier,
      required PaintingStyle paintingStyle,
      bool background = false}) {
    if (draggableWidget.animationType == TextAnimationType.none) {
      return Text(draggableWidget.text,
          textAlign: draggableWidget.textAlign,
          style: _textStyle(
              controlNotifier: controlNotifier,
              paintingStyle: paintingStyle,
              background: background));
    } else {
      return DefaultTextStyle(
        style: _textStyle(
            controlNotifier: controlNotifier,
            paintingStyle: paintingStyle,
            background: background),
        child: AnimatedTextKit(
          repeatForever: true,
          onTap: () => _onTap(context, draggableWidget, controlNotifier),
          animatedTexts: [
            if (draggableWidget.animationType == TextAnimationType.scale)
              ScaleAnimatedText(draggableWidget.text,
                  duration: const Duration(milliseconds: 1200)),
            if (draggableWidget.animationType == TextAnimationType.fade)
              ...draggableWidget.textList.map((item) => FadeAnimatedText(item,
                  duration: const Duration(milliseconds: 1200))),
            if (draggableWidget.animationType == TextAnimationType.typer)
              TyperAnimatedText(draggableWidget.text,
                  speed: const Duration(milliseconds: 500)),
            if (draggableWidget.animationType == TextAnimationType.typeWriter)
              TypewriterAnimatedText(
                draggableWidget.text,
                speed: const Duration(milliseconds: 500),
              ),
            if (draggableWidget.animationType == TextAnimationType.wavy)
              WavyAnimatedText(
                draggableWidget.text,
                speed: const Duration(milliseconds: 500),
              ),
            if (draggableWidget.animationType == TextAnimationType.flicker)
              FlickerAnimatedText(
                draggableWidget.text,
                speed: const Duration(milliseconds: 1200),
              ),
          ],
        ),
      );
    }
  }

  _textStyle(
      {required ControlNotifier controlNotifier,
      required PaintingStyle paintingStyle,
      bool background = false}) {
    return TextStyle(
            fontFamily: controlNotifier.fontList![draggableWidget.fontFamily],
            package: controlNotifier.isCustomFontList ? null : 'stories_editor',
            fontWeight: FontWeight.w500,
            shadows: controlNotifier.isTextShadow != true
                ? null
                : <Shadow>[
                    Shadow(
                        offset: const Offset(1.0, 1.0),
                        blurRadius: 3.0,
                        color: draggableWidget.textColor == Colors.black
                            ? Colors.white54
                            : Colors.black)
                  ])
        .copyWith(
      color: background ? Colors.black : draggableWidget.textColor,
      fontSize: draggableWidget.deletePosition ? 8 : draggableWidget.fontSize,
      /* background: controlNotifier.isTextShadow != true ? Paint() : Paint()
              ..strokeWidth = 20.0
              ..color = draggableWidget.backGroundColor
              ..style = paintingStyle
              ..strokeJoin = StrokeJoin.round
              ..filterQuality = FilterQuality.high
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1)
              */
    );
  }

  _deleteTopOffset() {
    double top = 0.0;
    final ScreenUtil screenUtil = ScreenUtil();
    if (draggableWidget.type == ItemType.text) {
      top = screenUtil.screenWidth / 1.2;
      return top;
    } else if (draggableWidget.type == ItemType.gif ||
        draggableWidget.type != ItemType.gif) {
      top = screenUtil.screenWidth / 1.18;
      return top;
    }
  }

  _deleteScale() {
    double scale = 0.0;
    if (draggableWidget.type == ItemType.text) {
      scale = 0.4;
      return scale;
    } else if (draggableWidget.type == ItemType.gif ||
        draggableWidget.type != ItemType.gif) {
      scale = 0.3;
      return scale;
    }
  }

  /// onTap text
  void _onTapOther(BuildContext context, EditableItem item,
      ControlNotifier controlNotifier) {
    var _itemProvider =
        Provider.of<DraggableWidgetNotifier>(this.context, listen: false);
    if (item != _itemProvider.draggableWidget.last) {
      _itemProvider.draggableWidget
          .removeAt(_itemProvider.draggableWidget.indexOf(item));
      _itemProvider.draggableWidget.add(EditableItem()
        ..type = item.type
        ..url = item.url
        ..position = item.position
        ..duration = item.duration
        ..scale = item.scale
        ..rotation = item.rotation
        ..gif = item.gif
        ..deletePosition = item.deletePosition
        ..backGroundColor = item.backGroundColor
        ..isStoriesBackground = item.isStoriesBackground
        ..text = item.text);
    }
  }

  /// onTap text
  void _onTap(BuildContext context, EditableItem item,
      ControlNotifier controlNotifier) {
    var _editorProvider =
        Provider.of<TextEditingNotifier>(this.context, listen: false);
    var _itemProvider =
        Provider.of<DraggableWidgetNotifier>(this.context, listen: false);

    /// load text attributes
    _editorProvider.textController.text = item.text.trim();
    _editorProvider.text = item.text.trim();
    _editorProvider.fontFamilyIndex = item.fontFamily;
    _editorProvider.textSize = item.fontSize;
    _editorProvider.backGroundColor = item.backGroundColor;
    _editorProvider.textAlign = item.textAlign;
    _editorProvider.textColor =
        controlNotifier.colorList!.indexOf(item.textColor);
    _editorProvider.animationType = item.animationType;
    _editorProvider.textList = item.textList;
    _editorProvider.fontAnimationIndex = item.fontAnimationIndex;
    _itemProvider.draggableWidget
        .removeAt(_itemProvider.draggableWidget.indexOf(item));
    _editorProvider.fontFamilyController = PageController(
      initialPage: item.fontFamily,
      viewportFraction: .1,
    );

    /// create new text item
    controlNotifier.isTextEditing = !controlNotifier.isTextEditing;
  }

//////////////////
  TValue? case2<TOptionType, TValue>(
    TOptionType selectedOption,
    Map<TOptionType, TValue> branches, [
    TValue? defaultValue = null,
  ]) {
    if (!branches.containsKey(selectedOption)) {
      return defaultValue;
    }

    return branches[selectedOption];
  }
}
