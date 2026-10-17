import 'package:flutter/material.dart';

/// An image that supports pinch-to-zoom, drag-to-pan, and double-tap zoom.
///
/// Use this in place of a plain [Image] when displaying an image that users
/// may want to inspect in more detail. The surrounding layout should provide
/// a bounded size (for example, by using [AspectRatio] or [SizedBox]).
class ZoomableImage extends StatefulWidget {
  const ZoomableImage({
    super.key,
    required this.image,
    this.fit = BoxFit.contain,
    this.minScale = 1,
    this.maxScale = 5,
    this.semanticsLabel,
    this.backgroundColor,
  })  : assert(minScale > 0),
        assert(maxScale >= minScale);

  final ImageProvider image;
  final BoxFit fit;
  final double minScale;
  final double maxScale;
  final String? semanticsLabel;
  final Color? backgroundColor;

  @override
  State<ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<ZoomableImage> {
  late final TransformationController _transformationController;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _zoomed = !_zoomed;
      _transformationController.value = _zoomed
          ? Matrix4.diagonal3Values(
              widget.maxScale.clamp(widget.minScale, 2.5),
              widget.maxScale.clamp(widget.minScale, 2.5),
              1,
            )
          : Matrix4.identity();
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomed = false;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor ?? Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label: widget.semanticsLabel,
            child: GestureDetector(
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: widget.minScale,
                maxScale: widget.maxScale,
                panEnabled: true,
                scaleEnabled: true,
                boundaryMargin: const EdgeInsets.all(80),
                clipBehavior: Clip.hardEdge,
                child: Image(
                  image: widget.image,
                  fit: widget.fit,
                  width: double.infinity,
                  height: double.infinity,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Zoom in',
                    color: Colors.white,
                    onPressed: () {
                      final currentScale =
                          _transformationController.value.getMaxScaleOnAxis();
                      final nextScale =
                          (currentScale * 1.25).clamp(widget.minScale, widget.maxScale);
                      setState(() {
                        _zoomed = nextScale > widget.minScale;
                        _transformationController.value =
                            Matrix4.diagonal3Values(nextScale, nextScale, 1);
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Zoom out',
                    color: Colors.white,
                    onPressed: () {
                      final currentScale =
                          _transformationController.value.getMaxScaleOnAxis();
                      final nextScale =
                          (currentScale / 1.25).clamp(widget.minScale, widget.maxScale);
                      setState(() {
                        _zoomed = nextScale > widget.minScale;
                        _transformationController.value = nextScale == widget.minScale
                            ? Matrix4.identity()
                            : Matrix4.diagonal3Values(nextScale, nextScale, 1);
                      });
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    tooltip: 'Reset zoom',
                    color: Colors.white,
                    onPressed: _resetZoom,
                    icon: const Icon(Icons.fit_screen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
