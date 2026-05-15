#encoding: utf-8

Feature: char_length


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
      | LET len = CHAR_LENGTH('abc') RETURN len;                          | 3      |  普通ASCII字符串      |
      | LET len = CHAR_LENGTH('') RETURN len;                             | 0      |  空字符串             |
      | LET len = CHAR_LENGTH('a') RETURN len;                            | 1      |  单个字符             |
      | LET len = CHAR_LENGTH('hello world') RETURN len;                  | 11     |  包含空格的字符串       |
      | LET len = CHAR_LENGTH('a@b#c$') RETURN len;                       | 6      |  包含特殊字符          |
      | LET len = CHAR_LENGTH('a\nb\tc') RETURN len;                      | 5      |  包含转义字符          |
      | LET len = CHAR_LENGTH('中文') RETURN len;                          | 2      |  Unicode字符         |
      | LET len = CHAR_LENGTH('a中文1') RETURN len;                        | 4      |  混合字符集           |
      | LET len = CHAR_LENGTH('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa') RETURN len; | 100   | 长字符串(100个字符) |
      | LET len = CHAR_LENGTH('     ') RETURN len;                        | 5      |  纯空格字符串          |
      | LET len = CHAR_LENGTH('\t\t') RETURN len;                         | 2      |  包含制表符           |
      | LET len = CHAR_LENGTH('abc' + 'def') RETURN len;                  | 6      |  字符串表达式          |
      | LET len = CHAR_LENGTH(SUBSTRING('hello world', 1, 5)) RETURN len; | 5      |  子字符串表达式         |
      | LET len = CHAR_LENGTH(NULL) RETURN len;                           | null   |  NULL参数             |

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
      | LET len = CHAR_LENGTH(123) RETURN len;               | [2725]Type mismatch: expected String but was Integer   | 数字类型参数       |
      | LET len = CHAR_LENGTH(TRUE) RETURN len;              | [2725]Type mismatch: expected String but was Boolean.  | 布尔类型参数       |
      | LET len = CHAR_LENGTH(date('2023-11-02')) RETURN len;| unsupported value.type in CharLengthFunction           | 时间类型参数       |
      | LET len = CHAR_LENGTH() RETURN len;                  | unsupported value type in FunctionInvocation           | 缺少参数          |
      | LET len = CHAR_LENGTH('abc', 'def') RETURN len;      | unsupported value type in FunctionInvocation           | 参数数量过多       |
      | LET len = CHAR_LENGTH 'abc') RETURN len;             | [2700]Invalid input                                    | 语法错误          |





