import 'dart:async';

import 'package:commet/cache/file_provider.dart';
import 'package:commet/config/build_config.dart';
import 'package:commet/config/layout_config.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/atoms/scaled_safe_area.dart';
import 'package:commet/ui/molecules/video_player/video_player.dart';
import 'package:commet/ui/molecules/video_player/video_player_controller.dart';
import 'package:commet/utils/image/lod_image.dart';
import 'package:flutter/material.dart';
import 'package:tiamat/atoms/popup_dialog.dart';
import 'dart:ui' as ui;

class Lightbox extends StatefulWidget {
  const Lightbox({
    this.image,
    this.video,
    this.thumbnail,
    this.aspectRatio,
    this.contentKey,
    this.customWidget,
    this.videoController,
    super.key,
  });
  final ImageProvider? image;
  final FileProvider? video;
  final ImageProvider? thumbnail;
  final VideoPlayerController? videoController;
  final Widget? customWidget;
  final double? aspectRatio;
  final Key? contentKey;

  @override
  State<Lightbox> createState() => _LightboxState();

  static Future<void> show(
    BuildContext context, {
    ImageProvider? image,
    ImageProvider? thumbnail,
    FileProvider? video,
    Widget? customWidget,
    VideoPlayerController? videoController,
    double? aspectRatio,
    Key? key,
  }) {
    return showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: "LIGHTBOX",
        barrierColor: PopupDialog.barrierColor,
        pageBuilder: (context, _, __) {
          return Lightbox(
            image: image,
            video: video,
            videoController: videoController,
            aspectRatio: aspectRatio,
            thumbnail: thumbnail,
            contentKey: key,
            customWidget: customWidget,
            key: GlobalKey(),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            SlideTransition(
              position:
                  Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
                      .animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            ));
  }
}

class _LightboxState extends State<Lightbox> with TickerProviderStateMixin {
  double aspectRatio = 1;
  bool dismissing = false;
  final controller = TransformationController();
  Size viewerSize = Size.zero;
  Matrix4? fitTransform;
  Size? fitImageSize;
  double viewerScale = 1.0;
  bool adjustingTransform = false;
  bool loadingHighQuality = false;

  StreamSubscription? onLodChanged;

  bool rotate = false;

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 850),
    vsync: this,
  );

  late final Animation<double> rotationAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  ).drive(Tween(begin: -0.25, end: 0.0));

  late final Animation<double> scaleAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  ).drive(Tween(begin: 0.6, end: 1.0));

  late final Animation<double> rotation =
      ConstantTween(0.0).animate(_controller);
  late final Animation<double> scale = ConstantTween(1.0).animate(_controller);

  void onTransformChanged() {
    if (adjustingTransform || fitImageSize == null || viewerSize == Size.zero) {
      return;
    }

    final matrix = controller.value;
    final nextScale = matrix.getMaxScaleOnAxis();
    final imageWidth = fitImageSize!.width * nextScale;
    final imageHeight = fitImageSize!.height * nextScale;

    // Keep the image centered on axes where it still fits. When it overflows,
    // constrain translation to the interval between its two edges and the
    // viewport edges. These limits are recalculated for every scale change.
    final minX = imageWidth > viewerSize.width
        ? viewerSize.width - imageWidth
        : (viewerSize.width - imageWidth) / 2;
    final maxX = imageWidth > viewerSize.width ? 0.0 : minX;
    final minY = imageHeight > viewerSize.height
        ? viewerSize.height - imageHeight
        : (viewerSize.height - imageHeight) / 2;
    final maxY = imageHeight > viewerSize.height ? 0.0 : minY;

    final nextX = matrix.entry(0, 3).clamp(minX, maxX).toDouble();
    final nextY = matrix.entry(1, 3).clamp(minY, maxY).toDouble();

    if ((nextX - matrix.entry(0, 3)).abs() > 0.001 ||
        (nextY - matrix.entry(1, 3)).abs() > 0.001) {
      final corrected = matrix.clone()
        ..[12] = nextX
        ..[13] = nextY;
      adjustingTransform = true;
      controller.value = corrected;
      adjustingTransform = false;
    }

    if ((nextScale - viewerScale).abs() > 0.001 && mounted) {
      setState(() {
        viewerScale = nextScale;
      });
    }
  }

  @override
  void dispose() {
    onLodChanged?.cancel();
    controller.removeListener(onTransformChanged);
    controller.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    controller.addListener(onTransformChanged);
    _controller.stop(canceled: true);

    if (widget.aspectRatio != null) {
      aspectRatio = widget.aspectRatio!;
    }

    if (widget.image != null) {
      getImageInfo();
    }

    if (widget.video != null) {
      getVideoInfo();
    }

    if (widget.image case LODImageProvider lod) {
      onLodChanged = lod.onLODChanged.listen((_) {
        getImageInfo();
      });

      loadingHighQuality = true;
      lod.fetchFullRes().then((_) {
        if (mounted) {
          getImageInfo();

          setState(() {
            loadingHighQuality = false;
          });
        }
      });
    }
  }

  void getImageInfo() async {
    var image = await getImage();
    setState(() {
      aspectRatio = image.width / image.height;
    });

    shouldRotate();
  }

  void getVideoInfo() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.aspectRatio != null) {
        shouldRotate();
      }

      var size = await widget.videoController?.getSize();
      print(size);
      if (size != null) {
        setState(() {
          aspectRatio = size.width / size.height;
        });
      }

      shouldRotate();
    });
  }

  double counterRotation = 0.25;

  void shouldRotate() {
    if (!MediaQuery.of(context).mobile) {
      return;
    }

    if (widget.image != null && preferences.autoRotateImages.value == false) {
      return;
    }

    if (widget.video != null && preferences.autoRotateVideos.value == false) {
      return;
    }

    var size = MediaQuery.sizeOf(context);
    var screenRatio = size.width / size.height;
    bool prevValue = rotate;
    setState(() {
      rotate = (aspectRatio < 1 && screenRatio > 1) ||
          (aspectRatio > 1 && screenRatio < 1);
    });

    if (rotate != prevValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.value = 0;
        _controller.animateTo(1);
      });
    }
  }

  Future<ui.Image> getImage() {
    Completer<ui.Image> completer = Completer<ui.Image>();

    widget.image!
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(info.image);
      }
    }));
    return completer.future;
  }

  void resetZoom() {
    controller.value = fitTransform?.clone() ?? Matrix4.identity();
  }

  void zoomBy(double factor) {
    final currentScale = controller.value.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(1.0, 3.5).toDouble();
    if (nextScale <= 1.0) {
      resetZoom();
      return;
    }

    // Scale around the viewport center, preserving the image's fitted offset.
    final scaleFactor = nextScale / currentScale;
    final centerX = viewerSize.width / 2;
    final centerY = viewerSize.height / 2;
    controller.value = Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(scaleFactor)
      ..translate(-centerX, -centerY)
      ..multiply(controller.value);
  }

  void toggleZoom() {
    if (controller.value.getMaxScaleOnAxis() > 1.0) {
      resetZoom();
    } else {
      zoomBy(2);
    }
  }

  void dismiss() {
    setState(() {
      dismissing = true;
    });
    Navigator.pop(context, widget.contentKey);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          dismiss();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: dismiss,
        child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(BuildConfig.MOBILE ? 2 : 20.0),
          child: ScaledSafeArea(
            child: RotatedBox(
              quarterTurns: rotate ? 1 : 0,
              child: ScaleTransition(
                scale: rotate ? scaleAnimation : scale,
                child: RotationTransition(
                  turns: rotate ? rotationAnimation : rotation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Keep the image at its natural aspect ratio, but
                            // let the viewer itself occupy the full lightbox.
                            // This way zooming can use the surrounding space,
                            // while zero boundary margin keeps the image edges
                            // from being panned past the viewport.
                            final availableRatio =
                                constraints.maxWidth / constraints.maxHeight;
                            // Fit the image inside the viewport without
                            // changing its aspect ratio. The viewer itself
                            // remains full-sized; with unconstrained=false the
                            // child would expand to the viewport and allow
                            // panning into empty space around smaller images.
                            final imageWidth = aspectRatio > availableRatio
                                ? constraints.maxWidth
                                : constraints.maxHeight * aspectRatio;
                            final imageHeight = aspectRatio > availableRatio
                                ? constraints.maxWidth / aspectRatio
                                : constraints.maxHeight;

                            final nextViewerSize = Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            final imageSize = Size(imageWidth, imageHeight);
                            final offsetX =
                                (constraints.maxWidth - imageWidth) / 2;
                            final offsetY =
                                (constraints.maxHeight - imageHeight) / 2;
                            final nextFitTransform = Matrix4.identity()
                              ..translate(offsetX, offsetY);

                            if (fitImageSize != imageSize ||
                                viewerSize != nextViewerSize) {
                              viewerSize = nextViewerSize;
                              fitImageSize = imageSize;
                              fitTransform = nextFitTransform;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted &&
                                    controller.value.getMaxScaleOnAxis() <=
                                        1.0001) {
                                  controller.value = fitTransform!.clone();
                                }
                              });
                            }

                            return SizedBox.expand(
                              child: InteractiveViewer(
                                // Keep the transformed child at the fitted
                                // image dimensions. With constrained=true the
                                // child fills the viewport, so the fit offset
                                // is applied on top of an already centered image.
                                constrained: false,
                                trackpadScrollCausesScale: true,
                                transformationController: controller,
                                minScale: 1.0,
                                maxScale: 3.5,
                                // Let the custom scale-aware clamp below own
                                // all pan limits. InteractiveViewer's zero
                                // margin otherwise applies a second, viewport-
                                // sized constraint that fights the fitted image.
                                boundaryMargin: const EdgeInsets.all(
                                  double.infinity,
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: SizedBox(
                                  width: imageWidth,
                                  height: imageHeight,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: GestureDetector(
                                      onTap: () {},
                                      onDoubleTap: toggleZoom,
                                      child: widget.customWidget ??
                                          (widget.image != null
                                              ? Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image(
                                                      fit: BoxFit.contain,
                                                      image: widget.image!,
                                                      isAntiAlias: true,
                                                      filterQuality:
                                                          FilterQuality.medium,
                                                    ),
                                                    if (loadingHighQuality)
                                                      Align(
                                                        alignment:
                                                            Alignment.bottomRight,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.all(8.0),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .surfaceContainer,
                                                              borderRadius:
                                                                  BorderRadius.circular(8),
                                                            ),
                                                            child: const Padding(
                                                              padding:
                                                                  EdgeInsets.all(8.0),
                                                              child: SizedBox(
                                                                width: 12,
                                                                height: 12,
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                )
                                              : widget.video != null
                                                  ? dismissing
                                                      ? widget.thumbnail != null
                                                          ? Image(
                                                              fit: BoxFit.cover,
                                                              image: widget.thumbnail!,
                                                            )
                                                          : Container(
                                                              color: Colors.black,
                                                            )
                                                      : VideoPlayer(
                                                          widget.video!,
                                                          controller:
                                                              widget.videoController,
                                                          showProgressBar: true,
                                                          canGoFullscreen: false,
                                                          thumbnail: widget.thumbnail,
                                                          key: widget.contentKey,
                                                        )
                                                  : const Placeholder()),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (widget.image != null)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(24),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: "Zoom in",
                                    visualDensity: VisualDensity.compact,
                                    color: Colors.white,
                                    onPressed: () => zoomBy(1.25),
                                    icon: const Icon(Icons.add),
                                  ),
                                  IconButton(
                                    tooltip: "Zoom out",
                                    visualDensity: VisualDensity.compact,
                                    color: Colors.white,
                                    onPressed: () => zoomBy(0.8),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  IconButton(
                                    tooltip: "Reset zoom",
                                    visualDensity: VisualDensity.compact,
                                    color: Colors.white,
                                    onPressed: () {
                                      resetZoom();
                                    },
                                    icon: const Icon(Icons.fit_screen),
                                  ),
                                ],
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
      ),
      ),
    );
  }
}
