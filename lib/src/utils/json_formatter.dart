class JsonFormatter {
  static const _indent = '  ';

  static String format(String input) {
    StringBuffer output = StringBuffer();
    int indent = 0;
    bool inString = false;
    StringBuffer stringContent = StringBuffer();
    bool inError = false;

    for (int i = 0; i < input.length; i++) {
      String char = input[i];

      try {
        // 第一部分：字符串处理逻辑（同上一段代码）
        if (char == '"' && (i == 0 || input[i - 1] != '\\')) {
          if (!inString) {
            inString = true;
            stringContent.clear();
            output.write(char);
          } else {
            inString = false;
            output.write(stringContent.toString());
            output.write(char);
          }
          continue;
        }

        if (inString) {
          if (char == '\\') {
            stringContent.write(char);
            if (i + 1 < input.length) {
              stringContent.write(input[++i]);
            }
          } else {
            stringContent.write(char);
          }
          continue;
        }

        // 修复点3: 改进结构化处理逻辑
        switch (char) {
          case '{':
          case '[':
            output.write(char);
            output.write('\n');
            indent++;
            output.write(_indent * indent);
            break;

          case '}':
          case ']':
            output.write('\n');
            indent--;
            output.write(_indent * indent);
            output.write(char);
            break;

          case ',':
            output.write(char);
            // 修复点4: 检查下一个非空白字符，避免在错误的JSON片段中添加换行
            bool shouldAddNewLine = true;
            int nextIndex = i + 1;
            while (
                nextIndex < input.length && input[nextIndex].trim().isEmpty) {
              nextIndex++;
            }
            if (nextIndex < input.length && input[nextIndex] == '"') {
              // 检查是否是错误的JSON片段（比如 "1,2,""g"）
              int quoteCount = 0;
              for (int j = i - 1; j >= 0 && quoteCount < 2; j--) {
                if (input[j] == '"' && (j == 0 || input[j - 1] != '\\')) {
                  quoteCount++;
                }
              }
              if (quoteCount < 2) {
                shouldAddNewLine = false;
              }
            }

            if (shouldAddNewLine) {
              output.write('\n');
              output.write(_indent * indent);
            }
            break;

          case ':':
            output.write(char + ' ');
            break;

          case ' ':
          case '\n':
          case '\r':
          case '\t':
            // 修复点5: 只在非错误状态下忽略空白字符
            if (inError) {
              output.write(char);
            }
            break;

          default:
            output.write(char);
        }
      } catch (e) {
        // 修复点6: 改进错误处理
        if (!inError) {
          inError = true;
          output.write('\n/* ERROR: Invalid JSON structure */\n');
          output.write(_indent * indent);
        }
        output.write(char);
      }
    }

    return output.toString();
  }
}
