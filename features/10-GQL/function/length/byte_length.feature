#encoding: utf-8

Feature: BYTE_length


  Scenario Outline: all-positive-cases-<备注>
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | len      |
      | <result> |
    Examples:
      | GQL                                                               | result |  备注                |
      | LET len = BYTE_LENGTH('abc') RETURN len;                          | 3      |  普通ASCII字符        |
      | LET len = BYTE_LENGTH('你好') RETURN len;                          | 6      |  中文汉字             |
      | LET len = BYTE_LENGTH('a你b好c') RETURN len;                       | 9      |  混合字符集           |
      | LET len = BYTE_LENGTH('') RETURN len;                             | 0      |  空字符串             |
      | LET len = BYTE_LENGTH('αβγ') RETURN len;                          | 6      |  基本多文种平面(BMP)字符 |
      | LET len = BYTE_LENGTH('😀🎉') RETURN len;                        | 8       |  辅助平面字符(如emoji)  |
      | LET len = BYTE_LENGTH('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa') RETURN len;| 100 | 长ASCII字符串 |
      | LET len = BYTE_LENGTH('中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文') RETURN len;                                   | 120  | 长中文字符串   |
      | LET len = BYTE_LENGTH('a中b文c混d合e字f符g串h测试i') RETURN len;     | 36     |  混合长字符串          |
      | LET len = BYTE_LENGTH(' \t\n\r') RETURN len;                     | 4       |  各种空白字符          |
      | LET len = BYTE_LENGTH('ＡＢＣ') RETURN len;                       | 9       |  全角字符             |
      | LET len = BYTE_LENGTH(SUBSTRING('hello世界', 1, 7)) RETURN len;   | 6       |  字符串函数组合         |
      | LET len = BYTE_LENGTH(SUBSTRING('hello world', 1, 5)) RETURN len; | 5      |  子字符串表达式         |
      | LET len = BYTE_LENGTH('hello world') RETURN len;                  | 11     |  包含空格的字符串       |
      | LET len = BYTE_LENGTH(NULL) RETURN len;                           | null   |  NULL参数             |

  Scenario Outline: castToFloat-negative-cases-<备注>
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                                                  | error                                                  | 备注             |
      | LET len = BYTE_LENGTH(123) RETURN len;               | [2725]Type mismatch: expected String but was Integer   | 数字类型参数       |
      | LET len = BYTE_LENGTH(TRUE) RETURN len;              | [2725]Type mismatch: expected String but was Boolean.  | 布尔类型参数       |
      | LET len = BYTE_LENGTH(date('2023-11-02')) RETURN len;| unsupported value.type in ByteLengthFunction           | 时间类型参数       |
      | LET len = BYTE_LENGTH() RETURN len;                  | unsupported value type in FunctionInvocation           | 缺少参数          |
      | LET len = BYTE_LENGTH('abc', 'def') RETURN len;      | unsupported value type in FunctionInvocation           | 参数数量过多       |
      | LET len = BYTE_LENGTH 'abc') RETURN len;             | [2700]Invalid input                                    | 语法错误          |
