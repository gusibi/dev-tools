class JsonFormatter {
  static const _indent = '  ';

  static String format(String input) {
    StringBuffer output = StringBuffer();
    int indent = 0;
    bool inString = false;

    for (int i = 0; i < input.length; i++) {
      String char = input[i];

      // 处理字符串
      if (char == '"' && (i == 0 || input[i - 1] != '\\')) {
        output.write(char);
        if (!inString) {
          inString = true;
        } else {
          inString = false;
        }
        continue;
      }

      if (inString) {
        // 修复点：直接写入字符，包括转义序列
        output.write(char);
        continue;
      }

      // 处理结构符号
      switch (char) {
        case '{':
          output.write(char);
          output.write('\n');
          indent++;
          output.write(_indent * indent);
          break;

        case '}':
          output.write('\n');
          indent--;
          output.write(_indent * indent);
          output.write(char);
          break;

        case ',':
          output.write(char);
          output.write('\n');
          output.write(_indent * indent);
          break;

        case ':':
          output.write(char + ' ');
          break;

        case ' ':
        case '\n':
        case '\r':
        case '\t':
          // 忽略空白字符
          break;

        default:
          output.write(char);
      }
    }

    return output.toString();
  }
}
