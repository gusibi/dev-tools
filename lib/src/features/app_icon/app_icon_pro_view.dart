import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_editor/image_editor.dart' hide ImageSource;
import 'package:extended_image/extended_image.dart';
import 'package:oktoast/oktoast.dart';

class AppIconEditorPage extends StatefulWidget {
  @override
  _AppIconEditorPageState createState() => _AppIconEditorPageState();
}

class _AppIconEditorPageState extends State<AppIconEditorPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey();

  bool _imageSelected = false;
  bool _iconsGenerated = false;
  bool _isRounded = false;
  double sat = 1;
  double bright = 1;
  double con = 1;

  Uint8List? _editedImage;
  Map<int, Uint8List> _previewImages = {};

  ImageProvider provider = const ExtendedExactAssetImageProvider(
    "assets/images/3.0x/flutter_logo.png",
    cacheRawData: true,
  );

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
      _imageSelected = true;
      _isRounded = false;
    });
    _updatePreviewImages();
  }

  Future<void> _updatePreviewImages() async {
    if (!_imageSelected) return;

    final result = await crop(_isRounded);
    if (result != null) {
      setState(() {
        _editedImage = result;
        _previewImages = {};
      });

      for (int size in [16, 32, 64, 128, 256, 512, 1024]) {
        final resizedImage = await _resizeImage(result, size, size);
        setState(() {
          _previewImages[size] = resizedImage;
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
        initEditorConfigHandler: (_) => EditorConfig(
          maxScale: 8.0,
          cropRectPadding: const EdgeInsets.all(20.0),
          hitTestSize: 20.0,
          cropAspectRatio: 2 / 2,
        ),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: buildImageEditor()),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text('Select Image'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _imageSelected ? _updatePreviewImages : null,
                    child: Text('Generate Icons'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _previewImages.isNotEmpty ? _saveIcons : null,
                    child: Text('Save Icons'),
                  ),
                ],
              ),
            ),
          ),
          // Right side - Preview area
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                child: _imageSelected
                    ? SingleChildScrollView(
                        child: Column(
                          children: [
                            TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                labelText: 'File Name',
                                hintText: 'Enter file name (default: icon)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children:
                                  [16, 32, 64, 128, 256, 512, 1024].map((size) {
                                return Column(
                                  children: [
                                    _previewImages.containsKey(size)
                                        ? Image.memory(
                                            _previewImages[size]!,
                                            width: 100,
                                            height: 100,
                                          )
                                        : Placeholder(
                                            fallbackHeight: 100,
                                            fallbackWidth: 100,
                                            color: Colors.grey,
                                          ),
                                    Text('${size}px'),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      )
                    : Center(child: Text('No image selected')),
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
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(160));

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
    for (var entry in _previewImages.entries) {
      final File file = File('$selectedDirectory/${fileName}_${entry.key}.png');
      try {
        await file.writeAsBytes(entry.value);
        savedCount++;
      } catch (e) {
        print('Error saving file: $e');
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
