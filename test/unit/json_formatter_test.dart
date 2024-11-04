import 'package:test/test.dart';
import 'package:dev_tools/src/utils/json_formatter.dart'; // 根据实际路径调整

void main() {
  group('JsonFormatter Escape Characters Tests', () {
    test('各种转义字符测试', () {
      final cases = {
        '{"key": "\\\\"}': '{\n  "key": "\\\\"\n}',
        '{"key": "\\""}': '{\n  "key": "\\""\n}',
        '{"key": "\\n"}': '{\n  "key": "\\n"\n}',
        '{"key": "\\\\\\\""}': '{\n  "key": "\\\\\\\""\n}',
      };

      cases.forEach((input, expected) {
        print('Testing input: $input');
        final result = JsonFormatter.format(input);
        print('Result: $result');
        expect(result, expected, reason: 'Failed for input: $input');
      });
    });
    test('单个转义字符测试', () {
      expect(JsonFormatter.format('{"key": "\\\\"}'), '{\n  "key": "\\\\"\n}');
    });

    test('双引号转义测试', () {
      expect(JsonFormatter.format('{"key": "\\""}'), '{\n  "key": "\\""\n}');
    });

    test('完整转义序列测试', () {
      final input = '{"5": "\\"\\"","6": "\\\\"}';
      print('Input: $input'); // 调试输出
      final result = JsonFormatter.format(input);
      print('Result: $result'); // 调试输出
      expect(
          result,
          '''
{
  "5": "\\"\\"",
  "6": "\\\\"
}'''
              .trim());
    });
  });
  group('JsonFormatter Tests', () {
    test('应该正确处理转义字符', () {
      final input = '''{"5": "\\"\\"","6": "\\\\"}''';
      final expected = '''{
  "5": "\\"\\"",
  "6": "\\\\"
}''';
      expect(JsonFormatter.format(input), expected);
    });

    test('应该保持字符串中的逗号不换行', () {
      final input = '''{"e": "1,2,4"}''';
      final expected = '''{
  "e": "1,2,4"
}''';
      expect(JsonFormatter.format(input), expected);
    });

    test('应该正确处理嵌套对象', () {
      final input = '''{"dd": {"1": 1,"2": 2}}''';
      final expected = '''{
  "dd": {
    "1": 1,
    "2": 2
  }
}''';
      expect(JsonFormatter.format(input), expected);
    });

    test('应该保持错误JSON的可读性', () {
      final input = '''{"ee": {"1": 11,"2":},"f": "1,2,""g": "1"}''';
      final expected = '''{
  "ee": {
    "1": 11,
    "2":
  },
  "f": "1,2,""g": "1"
}''';
      expect(JsonFormatter.format(input), expected);
    });

    test('应该处理完整的错误JSON示例', () {
      final input = '''{
    "a": 'b',"b": "c，d","c": "d","d": "e",
    "dd": {
        "1": 1,
        "2": 2,"3": 3,"4": {
            "a": 1,2: 3,
            4: 5,"5": "\\"\\"","6": "\\\\"
        }
    },
    "e": "1,2,4",
    "ee": {
        "1": 11,"2":
    },"f": "1,2,""g": "1",
    h: 1
}''';
      final expected = '''{
  "a": 'b',
  "b": "c，d",
  "c": "d",
  "d": "e",
  "dd": {
    "1": 1,
    "2": 2,
    "3": 3,
    "4": {
      "a": 1,
      2: 3,
      4: 5,
      "5": "\\"\\"",
      "6": "\\\\"
    }
  },
  "e": "1,2,4",
  "ee": {
    "1": 11,
    "2":
  },
  "f": "1,2,""g": "1",
  h: 1
}''';
      expect(JsonFormatter.format(input), expected);
    });
  });
}
