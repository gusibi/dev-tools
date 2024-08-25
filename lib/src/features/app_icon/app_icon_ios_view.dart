import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_editor/image_editor.dart' hide ImageSource;
import 'package:extended_image/extended_image.dart';
import 'package:oktoast/oktoast.dart';

const radiusSize = 200.0;
List<double> sizeList = [
  20,
  20,
  20,
  29,
  29,
  29,
  40,
  40,
  40,
  60,
  60,
  60,
  76,
  76,
  83.5,
  83.5,
  1024
];

class IOSAppIconEditorPage extends StatefulWidget {
  @override
  _iOSAppIconEditorPageState createState() => _iOSAppIconEditorPageState();
}

class _iOSAppIconEditorPageState extends State<IOSAppIconEditorPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey();
  BoxShape? boxShape;
  bool _imageSelected = false;
  bool _iconsGenerated = false;
  bool _isRounded = false;
  bool _isNewImageLoading = false;
  double sat = 1;
  double bright = 1;
  double con = 1;

  Uint8List? _editedImage;
  Map<int, Uint8List> _previewImages = {};

  ImageProvider provider = const ExtendedExactAssetImageProvider(
    "assets/images/3.0x/flutter_logo.png",
    cacheRawData: true,
  );
  @override
  void initState() {
    boxShape = BoxShape.rectangle;
    super.initState();
    _initializePreview();
  }

  void _initializePreview() async {
    final assetImage =
        await _getAssetImageBytes("assets/images/3.0x/flutter_logo.png");
    if (assetImage != null) {
      setState(() {
        _imageSelected = true;
        _editedImage = assetImage;
      });
      _updatePreviewImages();
    }
  }

  Color editorMaskColorHandler(BuildContext context, bool pointerDown) {
    return Colors.black.withOpacity(pointerDown ? 0.4 : 0.8);
  }

  Future<Uint8List?> _getAssetImageBytes(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      developer.log('The pick file is null');
      return;
    }
    developer.log(image.path);
    provider = ExtendedFileImageProvider(File(image.path), cacheRawData: true);
    setState(() {
      provider =
          ExtendedFileImageProvider(File(image.path), cacheRawData: true);
      _imageSelected = true;
      _isRounded = false;
      _previewImages = {}; // 清空之前的预览图
      _isNewImageLoading = true; // 设置标志表示正在加载新图片
    });
    // await _updatePreviewImages(); // 等待预览更新完成
  }

  Future<void> _updatePreviewImages() async {
    await Future.delayed(
        const Duration(milliseconds: 100)); //延迟执行裁剪操作; 让状态初始化完成
    final result = await crop(_isRounded);
    if (result != null) {
      setState(() {
        _editedImage = result;
        _previewImages = {};
      });

      int index = 1;
      double lastSize = 0;
      for (double size in sizeList) {
        if (size == lastSize) {
          index++;
        } else if (size != lastSize) {
          index = 1;
        }
        lastSize = size;
        final resizedImage = await _resizeImage(
            result, size.toInt() * index, size.toInt() * index);
        setState(() {
          _previewImages[size.toInt() * index] = resizedImage;
        });
      }
    }
  }

  Future<Uint8List?> crop(bool isRounded) async {
    final ExtendedImageEditorState? state = editorKey.currentState;
    if (state == null) {
      return null;
    }
    final Rect? rect = state.getCropRect();
    if (rect == null) {
      showToast('The crop rect is null.');
      return null;
    }
    final EditActionDetails action = state.editAction!;
    final double radian = action.rotateAngle;

    final bool flipHorizontal = action.flipY;
    final bool flipVertical = action.flipX;
    final Uint8List? img = state.rawImageData;

    if (img == null) {
      showToast('The img is null.');
      return null;
    }

    final ImageEditorOption option = ImageEditorOption();

    option.addOption(ClipOption.fromRect(rect));
    option.addOption(
        FlipOption(horizontal: flipHorizontal, vertical: flipVertical));
    if (action.hasRotateAngle) {
      option.addOption(RotateOption(radian.toInt()));
    }

    option.addOption(ColorOption.saturation(sat));
    option.addOption(ColorOption.brightness(bright));
    option.addOption(ColorOption.contrast(con));

    option.outputFormat = const OutputFormat.png(100);

    final Uint8List? result = await ImageEditor.editImage(
      image: img,
      imageEditorOption: option,
    );

    if (isRounded && result != null) {
      return _applyRoundCorners(result);
    }

    return result;
  }

  Future<Uint8List> _resizeImage(
      Uint8List imageData, int width, int height) async {
    final ui.Image image = await decodeImageFromList(imageData);
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTRB(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    final resizedImage =
        await pictureRecorder.endRecording().toImage(width, height);
    final byteData =
        await resizedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildImage() {
      return ExtendedImage(
        image: provider,
        height: 400,
        width: 400,
        extendedImageEditorKey: editorKey,
        mode: ExtendedImageMode.editor,
        fit: BoxFit.contain,
        shape: boxShape,
        // borderRadius: BorderRadius.circular(160),
        // clipBehavior: Clip.antiAlias,
        initEditorConfigHandler: (_) => EditorConfig(
          maxScale: 18.0,
          cropRectPadding: const EdgeInsets.all(20.0),
          hitTestSize: 80.0,
          cropAspectRatio: 2 / 2,
        ),
        loadStateChanged: (ExtendedImageState state) {
          if (state.extendedImageLoadState == LoadState.completed &&
              _isNewImageLoading) {
            // 图片加载完成后更新预览
            _isNewImageLoading = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updatePreviewImages();
            });
          }
          return null;
        },
      );
    }

    void flip() {
      editorKey.currentState?.flip();
      _updatePreviewImages();
    }

    void rotate(bool right) {
      editorKey.currentState?.rotate(right: right);
      _updatePreviewImages();
    }

    Widget buildImageEditor() {
      return Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = min(constraints.maxWidth, constraints.maxHeight);
                return Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: buildImage(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _imageSelected
                    ? () {
                        rotate(false);
                      }
                    : null,
                child: const Text('Rotate'),
              ),
              ElevatedButton(
                onPressed: _imageSelected
                    ? () {
                        flip();
                      }
                    : null,
                child: const Text('Flip'),
              ),
              ElevatedButton(
                onPressed: _imageSelected
                    ? () {
                        setState(() {
                          _isRounded = !_isRounded;
                          if (_isRounded) {
                            boxShape = BoxShape.rectangle;
                          } else {
                            boxShape = BoxShape.circle;
                          }
                        });
                        _updatePreviewImages();
                      }
                    : null,
                child: Text(_isRounded ? 'Square' : 'Round'),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Icon Generator')),
      body: Row(
        children: [
          // Left side - Edit area
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                // color: Colors.grey[200],
                // border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // const Icon(Icons.image, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  Expanded(child: buildImageEditor()),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Select Image'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _imageSelected ? _updatePreviewImages : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Icons'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _previewImages.isNotEmpty ? _saveIcons : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Icons'),
                  ),
                ],
              ),
            ),
          ),
          // Right side - Preview area
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                // color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'File Name',
                      hintText: 'Enter file name (default: icon)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.file_present),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: sizeList.map((size) {
                          return Column(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _previewImages.containsKey(size.toInt())
                                    ? Image.memory(
                                        _previewImages[size.toInt()]!,
                                        width: 100,
                                        height: 100,
                                      )
                                    : const Center(child: Text('Loading...')),
                              ),
                              Text('${size}px'),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _applyRoundCorners(Uint8List imageData) async {
    final ui.Image image = await decodeImageFromList(imageData);
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;

    final rect =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radiusSize));

    canvas.drawRRect(rrect, paint);

    paint.blendMode = BlendMode.srcIn;
    canvas.drawImage(image, Offset.zero, paint);

    final roundedImage = await pictureRecorder.endRecording().toImage(
          image.width,
          image.height,
        );
    final byteData =
        await roundedImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _saveIcons() async {
    final String fileName =
        _controller.text.isNotEmpty ? _controller.text : 'icon';

    // 让用户选择保存目录
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      // 用户取消了选择
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No directory selected. Icons not saved.')),
      );
      return;
    }

    int savedCount = 0;
    int index = 1;
    double lastSize = 0;
    for (var size in sizeList) {
      if (size == lastSize) {
        index++;
      } else if (size != lastSize) {
        index = 1;
      }
      lastSize = size;
      for (var entry in _previewImages.entries) {
        if (entry.key == size.toInt() * index) {
          File file = File(
              '$selectedDirectory/$fileName-${size}x${size}@${index}x.png');
          if (size == size.toInt()) {
            file = File(
                '$selectedDirectory/$fileName-${size.toInt()}x${size.toInt()}@${index}x.png');
          }
          try {
            await file.writeAsBytes(entry.value);
            savedCount++;
          } catch (e) {
            print('Error saving file: $e');
          }
          break;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '$savedCount icons saved successfully to $selectedDirectory')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
