#encoding: utf-8
#作用: 删除字符串右侧指定字符。
#参数:
#string: 输入字符串，类型为 String。
#characters: 要删除的字符集合，类型为 String，默认为空格。
#返回结果: 删除右侧指定字符后的字符串，类型为 String。

Feature: string-rtrim

  Scenario Outline: string-RTRIM
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                  | result    | 备注                 |
      | LET x = RTRIM('HELLO   ') RETURN x;  | 'HELLO'   | 去除右侧空格             |
      | LET x = RTRIM('HELLO\t') RETURN x;   | 'HELLO'   | 去除右侧制表符            |
      | LET x = RTRIM('HELLO😊  ') RETURN x; | 'HELLO😊' | 右侧有空格，表情符号不受影响     |
      | LET x = RTRIM('HELLO') RETURN x;     | 'HELLO'   | 无右侧空格，返回原字符串       |
      | LET x = RTRIM('') RETURN x;          | ''        | 参数1为空字符串，返回空串      |
      | LET x = RTRIM(NULL) RETURN x;        | null      | 参数1为 NULL，返回 NULL  |
      | LET x = RTRIM('   中文   ') RETURN x;  | '   中文'   | 去除右侧空格，保留左侧空格和中文字符 |

  Scenario: RTRIM('HELLO\n')
    When executing queries without error:
  """
  LET x = RTRIM('HELLO\n') RETURN x;
  """
    Then the result should be, in any order:
      | x       |
      | 'HELLO' |

  Scenario Outline: string-RTRIM 异常参数
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                            | error                                          | 备注         |
      | LET x = RTRIM(12345) RETURN x; | Type mismatch: expected String but was Integer | 参数1-非字符串参数 |
      | LET x = RTRIM(TRUE) RETURN x;  | Type mismatch: expected String but was Boolean | 参数1-布尔值参数  |

