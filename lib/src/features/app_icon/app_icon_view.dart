import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor/image_editor.dart' hide ImageSource;

class IconGeneratorPage extends StatefulWidget {
  @override
  _IconGeneratorPageState createState() => _IconGeneratorPageState();
}

class _IconGeneratorPageState extends State<IconGeneratorPage> {
  final TextEditingController _controller = TextEditingController();
  bool _imageSelected = false;
  bool _iconsGenerated = false;
  late File _imageFile;

  @override
  Widget build(BuildContext context) {
    void _editImage() async {
      final editorOption = ImageEditorOption();
      editorOption
          .addOption(const FlipOption(horizontal: true, vertical: false));
      editorOption
          .addOption(const ClipOption(x: 0, y: 0, width: 1024, height: 1024));
      // editorOption.addOption(const RotateOption());
      editorOption.outputFormat = const OutputFormat.png(88);
      // Edit the selected image using the ImageEditor class
      var image = await ImageEditor.editFileImageAndGetFile(
          file: _imageFile, imageEditorOption: editorOption);

      // Set the edited image to the state
      setState(() {
        _imageFile = image!;
      });
    }

    void _pickImage() async {
      final ImagePicker picker = ImagePicker();
      // Pick an image.
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        print('The pick file is null');
        return;
      }
      print(image.path);
      setState(() {
        _imageFile = File(image.path);
        _imageSelected = true;
      });
      _editImage();
    }

    return Scaffold(
      appBar: AppBar(title: Text('Icon Generator')),
      body: Row(
        children: [
          // Left side - Edit area
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _imageSelected
                      ? Image.file(_imageFile)
                      : Placeholder(
                          fallbackHeight: 200,
                          color: Colors.blue,
                        ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _pickImage();
                    },
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
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                // color: Colors.grey[200],
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
    super.dispose();
  }
}
