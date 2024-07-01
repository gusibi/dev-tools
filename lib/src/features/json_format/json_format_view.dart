import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_json_view/flutter_json_view.dart';
// import 'package:clipboard_watcher/clipboard_watcher.dart';

class CustomJsonDecoder extends Converter<String, dynamic> {
  @override
  dynamic convert(String input) {
    String fixedInput = input
        .replaceAll(r'\\', '\\')
        .replaceAll(r'\"', '"')
        .replaceAll(r"\'", "'");
    return json.decode(fixedInput);
  }
}

class JsonFormatView extends StatefulWidget {
  const JsonFormatView({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _JsonFormatViewState createState() => _JsonFormatViewState();
}

class _JsonFormatViewState extends State<JsonFormatView> {
  final TextEditingController _inputController = TextEditingController();
  String _formattedJson = '{}';
  bool _invalidJson = false;

  @override
  void initState() {
    _startListeningToClipboard();
    super.initState();
  }

  Future<String?> getClipBoardData() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  void _startListeningToClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    String? clipboardText = data?.text;
    if (clipboardText != null) {
      _checkAndFillClipboardContent(clipboardText);
    } else {
      // Handle the case where clipboard is empty or data is not a String
      developer.log("get data from clipboard fail");
    }
  }

  Future<void> _checkAndFillClipboardContent(String? clipboardContent) async {
    if (clipboardContent != null && clipboardContent.isNotEmpty) {
      try {
        // 尝试解析剪贴板内容为 JSON
        json.decode(clipboardContent);
        // 如果成功解析，更新输入框
        setState(() {
          _inputController.text = clipboardContent;
        });
        // 自动格式化
        _formatJson();
      } catch (e) {
        // 如果不是有效的 JSON，不做任何操作
        developer
            .log("[_checkAndFillClipboardContent] try format data fail:: $e");
      }
    }
  }

  void _formatJson() {
    setState(() {
      _invalidJson = false;
    });
    try {
      var decoder = CustomJsonDecoder();
      var parsedJson = decoder.convert(_inputController.text);
      // final dynamic parsedJson = json.decode(_inputController.text);
      if (parsedJson is Map || parsedJson is List) {
        final String prettyJson =
            const JsonEncoder.withIndent('  ').convert(parsedJson);
        setState(() {
          _formattedJson = prettyJson;
          _inputController.text = prettyJson;
        });
      } else {
        setState(() {
          _formattedJson = 'Invalid JSON: $parsedJson';
          _invalidJson = true;
        });
      }
    } catch (e) {
      developer.log("[_formatJson] try format data fail:: $e");
      setState(() {
        _formattedJson = 'Invalid JSON: ${e.toString()}';
        _invalidJson = true;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _formattedJson));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formatted JSON copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Formatter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧输入区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter JSON here',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _formatJson,
                    child: const Text('Format JSON'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 右侧显示区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width:
                            max(MediaQuery.of(context).size.width - 64, 600), //
                        child: _invalidJson
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SelectableText(_formattedJson),
                                  ),
                                ),
                              )
                            : JsonView.string(_formattedJson),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        _formattedJson.isNotEmpty ? _copyToClipboard : null,
                    child: const Text('Copy Formatted JSON'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // void onClipboardChanged() {}

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}
