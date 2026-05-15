#encoding: utf-8
#作用: 返回字符串右侧指定长度的子字符串。
#参数:
#string: 输入字符串，类型为 String。
#length: 子字符串的长度，类型为 Integer。
#返回结果: 截取的子字符串，长度范围为 [0, length(string)]。


Feature: string-right

  Scenario Outline: string-RIGHT
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                     | result      | 备注                |
      | LET x = RIGHT('HELLO GQL', 3) RETURN x; | 'GQL'       | 返回最后 3 个字符        |
      | LET x = RIGHT('HELLO', 0) RETURN x;     | ''          | 参数2 - 特殊值 0       |
      | LET x = RIGHT('HELLO GQL', 9) RETURN x; | 'HELLO GQL' | 参数2 等于字符串长度       |
      | LET x = RIGHT('Example', 100) RETURN x; | 'Example'   | 参数2 大于字符串长度       |
      | LET x = RIGHT('', 5) RETURN x;          | ''          | 参数1为空字符串          |
      | LET x = RIGHT(NULL, 2) RETURN x;        | null        | 参数1为 NULL         |
      | LET x = RIGHT('中文字符串', 3) RETURN x;     | '字符串'       | 参数1为中文，返回最后3个字符   |
      | LET x = RIGHT('12345', 2) RETURN x;     | '45'        | 参数1为纯数字字符串        |
      | LET x = RIGHT('😊HELLO', 5) RETURN x;   | 'HELLO'     | 参数1包含表情符号，表情不计入长度 |

  Scenario Outline: string-RIGHT 异常参数
    When executing queries:
  """
  <GQL>
  """
    Then the error should be contain:
  """
  <error>
  """
    Examples:
      | GQL                                       | error                                                         | 备注         |
      | LET x = RIGHT(12345, 3) RETURN x;         | Type mismatch: expected String but was Integer         | 参数1-非字符串参数 |
      | LET x = RIGHT('HELLO', -2) RETURN x;      | Cannot handle negative start index nor negative length | 参数2-负数     |
      | LET x = RIGHT('HELLO', 'three') RETURN x; | Type mismatch: expected Integer but was String         | 参数2-非整数参数  |
      | LET x = RIGHT('HELLO', 2.5) RETURN x;     | Type mismatch: expected Integer but was Float          | 参数2-非整数参数  |
      | LET x = RIGHT('HELLO', true) RETURN x;    | Type mismatch: expected Integer but was Boolean        | 参数2-非整数参数  |

