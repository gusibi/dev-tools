// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';
// import 'package:file_picker/file_picker.dart';

// class IconGeneratorPage extends StatefulWidget {
//   @override
//   _IconGeneratorPageState createState() => _IconGeneratorPageState();
// }

// class _IconGeneratorPageState extends State<IconGeneratorPage> {
//   File? _image;
//   final _picker = ImagePicker();
//   final _controller = TextEditingController();
//   final List<int> _sizes = [16, 32, 64, 128, 256, 512, 1024];
//   List<File> _generatedIcons = [];

//   Future getImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//     setState(() {
//       if (pickedFile != null) {
//         _image = File(pickedFile.path);
//         _generatedIcons.clear();
//       }
//     });
//   }

//   Future<void> generateIcons() async {
//     if (_image == null) return;

//     final fileName = _controller.text.isNotEmpty ? _controller.text : 'icon';
//     final originalImage = img.decodeImage(await _image!.readAsBytes());

//     if (originalImage == null) return;

//     final tempDir = await getTemporaryDirectory();
//     _generatedIcons.clear();

//     for (int size in _sizes) {
//       final resized = img.copyResize(originalImage, width: size, height: size);
//       final output = File('${tempDir.path}/${fileName}_$size.png');
//       await output.writeAsBytes(img.encodePng(resized));
//       _generatedIcons.add(output);
//     }

//     setState(() {}); // Refresh the UI to show previews

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Icons generated successfully!')),
//     );
//   }

//   Future<void> saveIcons() async {
//     if (_generatedIcons.isEmpty) return;

//     final outputDir = await FilePicker.platform.getDirectoryPath();
//     if (outputDir == null) return;

//     for (File icon in _generatedIcons) {
//       final newFile = File('$outputDir/${icon.path.split('/').last}');
//       await icon.copy(newFile.path);
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Icons saved successfully!')),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Icon Generator')),
//       body: Row(
//         children: [
//           // Left side - Edit area
//           Expanded(
//             flex: 1,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   ElevatedButton(
//                     onPressed: getImage,
//                     child: Text('Select Image'),
//                   ),
//                   SizedBox(height: 16),
//                   TextField(
//                     controller: _controller,
//                     decoration: InputDecoration(
//                       labelText: 'File Name',
//                       hintText: 'Enter file name (default: icon)',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _image == null ? null : generateIcons,
//                     child: Text('Generate Icons'),
//                   ),
//                   SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _generatedIcons.isEmpty ? null : saveIcons,
//                     child: Text('Save Icons'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Right side - Preview area
//           Expanded(
//             flex: 2,
//             child: Container(
//               color: Colors.grey[200],
//               child: _image == null
//                   ? Center(child: Text('No image selected'))
//                   : SingleChildScrollView(
//                       child: Column(
//                         children: [
//                           Image.file(_image!, height: 200),
//                           SizedBox(height: 16),
//                           Wrap(
//                             spacing: 16,
//                             runSpacing: 16,
//                             children: _generatedIcons.map((file) {
//                               return Column(
//                                 children: [
//                                   Image.file(file),
//                                   Text(
//                                       '${file.path.split('_').last.split('.').first}px'),
//                                 ],
//                               );
//                             }).toList(),
//                           ),
//                         ],
//                       ),
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }
