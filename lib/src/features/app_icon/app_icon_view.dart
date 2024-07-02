import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor/image_editor.dart' hide ImageSource;
import 'package:extended_image/extended_image.dart';

class IconGeneratorPage extends StatefulWidget {
  @override
  _IconGeneratorPageState createState() => _IconGeneratorPageState();
}

class _IconGeneratorPageState extends State<IconGeneratorPage> {
  final TextEditingController _controller = TextEditingController();
  bool _imageSelected = false;
  bool _iconsGenerated = false;
  late File _imageFile;
  final TransformationController _transformationController =
      TransformationController();
  double _rotation = 0;
  bool _flipped = false;
  final GlobalKey _imageKey = GlobalKey();

  Future<Size> _getImageSize(File imageFile) {
    final Completer<Size> completer = Completer();
    final image = Image.file(imageFile);
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          completer.complete(Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          ));
        },
      ),
    );
    return completer.future;
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      developer.log('The pick file is null');
      return;
    }
    developer.log(image.path);
    setState(() {
      _imageFile = File(image.path);
      _imageSelected = true;
      _rotation = 0;
      _flipped = false;
      _transformationController.value = Matrix4.identity();
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<void> _editImage(bool isRounded) async {
      // 获取图片的原始尺寸
      final Size imageSize = await _getImageSize(_imageFile);

      // 获取 InteractiveViewer 的大小
      final RenderBox renderBox =
          _imageKey.currentContext!.findRenderObject() as RenderBox;
      final Size viewportSize = renderBox.size;

      // 从变换矩阵中提取缩放和平移信息
      final Matrix4 transform = _transformationController.value;
      final double scale = transform.getMaxScaleOnAxis();
      final Offset translation =
          Offset(transform.getTranslation().x, transform.getTranslation().y);

      // 计算裁剪区域
      final double viewportAspectRatio =
          viewportSize.width / viewportSize.height;
      final double imageAspectRatio = imageSize.width / imageSize.height;

      late double scaledWidth;
      late double scaledHeight;

      if (viewportAspectRatio > imageAspectRatio) {
        scaledHeight = viewportSize.height;
        scaledWidth = scaledHeight * imageAspectRatio;
      } else {
        scaledWidth = viewportSize.width;
        scaledHeight = scaledWidth / imageAspectRatio;
      }

      final double scaleX = imageSize.width / scaledWidth;
      final double scaleY = imageSize.height / scaledHeight;

      int x = max(0, ((-translation.dx / scale) * scaleX).round());
      int y = max(0, ((-translation.dy / scale) * scaleY).round());
      int width = min(imageSize.width.round(),
          (viewportSize.width / scale * scaleX).round());
      int height = min(imageSize.height.round(),
          (viewportSize.height / scale * scaleY).round());

      // 确保裁剪区域不超出图片边界
      if (x + width > imageSize.width) {
        width = (imageSize.width - x).round();
      }
      if (y + height > imageSize.height) {
        height = (imageSize.height - y).round();
      }

      final editorOption = ImageEditorOption();
      editorOption.addOption(RotateOption(_rotation.toInt()));
      if (_flipped) {
        editorOption.addOption(FlipOption(horizontal: true, vertical: false));
      }
      editorOption.addOption(ClipOption(
        x: x,
        y: y,
        width: width,
        height: height,
      ));
      editorOption.outputFormat = const OutputFormat.png(88);

      var image = await ImageEditor.editFileImage(
          file: _imageFile, imageEditorOption: editorOption);

      if (image != null) {
        final tempDir = await Directory.systemTemp.createTemp();
        final tempFile = File('${tempDir.path}/temp_image.png');
        await tempFile.writeAsBytes(image);

        if (isRounded) {
          // 如果需要圆角，我们在这里进行额外的处理
          final ui.Image originalImage = await decodeImageFromList(image);
          final pictureRecorder = ui.PictureRecorder();
          final canvas = Canvas(pictureRecorder);
          final paint = Paint()..isAntiAlias = true;

          final rect = Rect.fromLTWH(0, 0, originalImage.width.toDouble(),
              originalImage.height.toDouble());
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(40)),
            paint,
          );

          paint.blendMode = BlendMode.srcIn;
          canvas.drawImage(originalImage, Offset.zero, paint);

          final roundedImage = await pictureRecorder.endRecording().toImage(
                originalImage.width,
                originalImage.height,
              );
          final roundedImageData =
              await roundedImage.toByteData(format: ui.ImageByteFormat.png);
          if (roundedImageData != null) {
            await tempFile.writeAsBytes(roundedImageData.buffer.asUint8List());
          }
        }

        setState(() {
          _imageFile = tempFile;
          _rotation = 0;
          _flipped = false;
          _transformationController.value = Matrix4.identity();
        });
      }
    }

    Widget _buildImageEditor() {
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
                        child: _imageSelected
                            ? Transform.rotate(
                                angle: _rotation * pi / 180,
                                child: Transform.flip(
                                  flipX: _flipped,
                                  child: InteractiveViewer(
                                    key: _imageKey,
                                    transformationController:
                                        _transformationController,
                                    boundaryMargin: EdgeInsets.all(20.0),
                                    minScale: 0.1,
                                    maxScale: 4.0,
                                    child: Image.file(
                                      _imageFile,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              )
                            : Placeholder(
                                color: Colors.blue,
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _imageSelected
                    ? () {
                        setState(() {
                          _rotation += 90;
                          if (_rotation >= 360) _rotation = 0;
                        });
                      }
                    : null,
                child: Text('Rotate'),
              ),
              ElevatedButton(
                onPressed: _imageSelected
                    ? () {
                        setState(() {
                          _flipped = !_flipped;
                        });
                      }
                    : null,
                child: Text('Flip'),
              ),
              ElevatedButton(
                onPressed: _imageSelected ? () => _editImage(false) : null,
                child: Text('Confirm'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                onPressed: _imageSelected ? () => _editImage(true) : null,
                child: Text('Rounded'),
              ),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Icon Generator')),
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
                  Expanded(child: _buildImageEditor()),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Select Image'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _imageSelected
                        ? () {
                            setState(() {
                              _iconsGenerated = true;
                            });
                          }
                        : null,
                    child: Text('Generate Icons'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _iconsGenerated
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Icons saved successfully!')),
                            );
                          }
                        : null,
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
                            if (_iconsGenerated)
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [16, 32, 64, 128, 256, 512, 1024]
                                    .map((size) {
                                  return Column(
                                    children: [
                                      Placeholder(
                                        fallbackHeight: 50,
                                        fallbackWidth: 50,
                                        color: Colors.green,
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

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }
}
