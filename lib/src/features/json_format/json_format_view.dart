import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_json_view/flutter_json_view.dart';
// import 'package:clipboard_watcher/clipboard_watcher.dart';

// 定义错误类型枚举
enum JsonErrorType {
  missingQuotes, // 缺少引号
  invalidQuoteType, // 错误的引号类型（单引号）
  missingValue, // 缺少值
  invalidNumber, // 非法数字格式
  unclosedBracket, // 未闭合的括号
  invalidKey, // 非法的键名
  trailingComma, // 多余的逗号
  invalidValue, // 非法的值
}

// 定义错误记录类
class JsonError {
  final int startOffset; // 错误开始位置
  final int endOffset; // 错误结束位置
  final JsonErrorType type; // 错误类型
  final String message; // 错误描述
  final String snippet; // 错误代码片段

  JsonError({
    required this.startOffset,
    required this.endOffset,
    required this.type,
    required this.message,
    required this.snippet,
  });
}

// 格式化结果类
class FormatResult {
  final String formattedJson; // 格式化后的JSON
  final List<JsonError> errors; // 错误列表

  FormatResult(this.formattedJson, this.errors);
}

// 修改后的格式化函数
FormatResult formatInvalidJsonWithErrors(String input) {
  input = input.trim();

  StringBuffer result = StringBuffer();
  List<JsonError> errors = [];
  int indentLevel = 0;
  int pos = 0;
  int length = input.length;
  bool inString = false;
  String? quoteChar;
  int currentLineStart = 0;
  bool expectValue = false;

  String getIndent() {
    return '    ' * indentLevel;
  }

  void addNewLine() {
    result.write('\n');
    currentLineStart = result.length;
    result.write(getIndent());
  }

  void addError(JsonErrorType type, String message, int start, int end) {
    String snippet = input.substring(start, end);
    errors.add(JsonError(
      startOffset: start,
      endOffset: end,
      type: type,
      message: message,
      snippet: snippet,
    ));
  }

  while (pos < length) {
    String char = input[pos];
    int currentPos = pos;

    // 检查键值对格式
    if (!inString && char == ':') {
      // 检查前面的键是否合法
      int keyStart = result.toString().lastIndexOf('"');
      if (keyStart == -1 || !result.toString().endsWith('"')) {
        addError(
          JsonErrorType.invalidKey,
          "Key should be wrapped in double quotes",
          currentPos - 1,
          currentPos,
        );
      }
      expectValue = true;
    }

    // 检查单引号使用
    if (char == "'" && !inString) {
      addError(
        JsonErrorType.invalidQuoteType,
        "Single quotes are not allowed in JSON",
        currentPos,
        currentPos + 1,
      );
    }

    // 检查数字格式
    if (!inString && expectValue && RegExp(r'[0-9]').hasMatch(char)) {
      int numStart = currentPos;
      while (pos < length && RegExp(r'[0-9.]').hasMatch(input[pos])) {
        pos++;
      }
      pos--;
      String number = input.substring(numStart, pos + 1);
      if (number.startsWith('0') &&
          number.length > 1 &&
          !number.startsWith('0.')) {
        addError(
          JsonErrorType.invalidNumber,
          "Numbers cannot have leading zeros",
          numStart,
          pos + 1,
        );
      }
    }

    // 处理引号和字符串
    if ((char == '"' || char == "'") && !inString) {
      inString = true;
      quoteChar = char;
      result.write(char);
    } else if (inString && char == quoteChar && input[pos - 1] != '\\') {
      inString = false;
      quoteChar = null;
      result.write(char);
      expectValue = false;
    } else if (!inString) {
      switch (char) {
        case '{':
        case '[':
          result.write(char);
          indentLevel++;
          addNewLine();
          break;

        case '}':
        case ']':
          if (input[pos - 1] == ',') {
            addError(
              JsonErrorType.trailingComma,
              "Trailing comma is not allowed",
              pos - 1,
              pos,
            );
          }
          indentLevel--;
          addNewLine();
          result.write(char);
          break;

        case ',':
          result.write(char);
          addNewLine();
          break;

        case ':':
          result.write(char + ' ');
          break;

        case ' ':
        case '\n':
        case '\r':
        case '\t':
          break;

        default:
          result.write(char);
      }
    } else {
      result.write(char);
    }

    pos++;
  }

// 检查未闭合的括号
  int openBrackets = 0;
  String resultString = result.toString();
  for (int i = 0; i < resultString.length; i++) {
    if (resultString[i] == '{') openBrackets++;
    if (resultString[i] == '}') openBrackets--;
  }
  if (openBrackets != 0) {
    addError(
      JsonErrorType.unclosedBracket,
      "Unclosed brackets in JSON",
      0,
      input.length,
    );
  }

  return FormatResult(result.toString(), errors);
}

// 使用示例
// void main() {
//   String invalidJson = '''{
//     "a": 'b',"b": "c，d","c": "d","d": "e",
//     "dd": {
//         "1": 1,
//         "2": 2,"3": 3,"4": {
//             "a": 1,2: 3,
//             4: 5,"5": "\\"\\"","6": "\\\\"
//         }
//     },
//     "e": "1,2,4",
//     "ee": {
//         "1": 11,"2":
//     },"f": "1,2,""g": "1",
//     h: 1,''';

//   var result = formatInvalidJsonWithErrors(invalidJson);

//   // 打印格式化后的JSON
//   print('Formatted JSON:');
//   print(result.formattedJson);

//   // 打印错误信息
//   print('\nErrors found:');
//   for (var error in result.errors) {
//     print('Error at position ${error.startOffset}-${error.endOffset}: '
//           '${error.type.name} - ${error.message}');
//     print('Snippet: ${error.snippet}');
//   }
// }

// class CustomJsonDecoder extends Converter<String, dynamic> {
//   @override
//   dynamic convert(String input) {
//     String fixedInput = input
//         .replaceAll(r'\\', '\\')
//         .replaceAll(r'\"', '"')
//         .replaceAll(r"\'", "'");
//     return json.decode(fixedInput);
//   }
// }

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
  List<JsonError> _jsonErrors = []; // 添加错误信息状态

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
      _jsonErrors = [];
    });

    try {
      // 首先尝试标准的 JSON 解析
      final dynamic parsedJson = json.decode(_inputController.text);
      if (parsedJson is Map || parsedJson is List) {
        final String prettyJson =
            const JsonEncoder.withIndent('  ').convert(parsedJson);
        setState(() {
          _formattedJson = prettyJson;
          _inputController.text = prettyJson;
        });
      }
    } catch (e) {
      // JSON 解析失败时，使用自定义格式化器
      final FormatResult result =
          formatInvalidJsonWithErrors(_inputController.text);
      print(result.errors.length);
      setState(() {
        _invalidJson = true;
        _jsonErrors = result.errors;
        _inputController.text = result.formattedJson;
        _formattedJson = '发现以下错误：\n\n' +
            _jsonErrors
                .map((error) =>
                    '• ${error.type.name} (位置 ${error.startOffset}-${error.endOffset}):\n'
                    '  ${error.message}\n'
                    '  代码片段: ${error.snippet}\n')
                .join('\n');
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
            // 右侧显示区域根据状态显示不同内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: max(MediaQuery.of(context).size.width - 64, 600),
                        child: _invalidJson
                            ? Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.red),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: SelectableText(
                                      _formattedJson,
                                      style: const TextStyle(color: Colors.red),
                                    ),
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
