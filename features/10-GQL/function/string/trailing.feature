#encoding: utf-8
#作用: 与 RTRIM 功能一致，表示移除字符串右侧的指定子字符串（尾部字符）
#参数:
#string: 输入字符串，类型为 String。
#characters: 要删除的字符集合，类型为 String，默认为空格。
#返回结果: 删除右侧指定字符后的字符串，类型为 String。

Feature: string-trailing

  Scenario Outline: string-TRAILING
    When executing queries without error:
      """
  <GQL>
  """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | LET x = TRIM(TRAILING '0' FROM '01230') RETURN x; | '0123' |
      | LET x = TRIM(TRAILING 'ab' FROM 'xxabab') RETURN x; | 'xx' |
      | LET x = TRIM(TRAILING ' ' FROM 'hello   ') RETURN x; | 'hello' |
      | LET x = TRIM(TRAILING '😊' FROM 'hello😊😊') RETURN x; | 'hello' |
      | LET x = TRIM(TRAILING 'xy' FROM 'test') RETURN x; | 'test' |
      | LET x = TRIM(TRAILING '' FROM 'hello') RETURN x; | 'hello' |
      | LET x = TRIM(TRAILING NULL FROM 'hello') RETURN x; | null |
      | LET x = TRIM(TRAILING ' ' FROM '') RETURN x; | '' |
      | LET x = TRIM(TRAILING ' ' FROM NULL) RETURN x; | null |
      | LET x = TRIM(TRAILING 'ab' FROM 'abababab') RETURN x; | '' |
      | LET x = TRIM(TRAILING '中' FROM '测试中中') RETURN x; | '测试' |
      | LET x = TRIM(TRAILING '0' FROM '000123') RETURN x; | '000123' |

  Scenario Outline: string-TRAILING 异常用例
    When executing queries:
      """
  <GQL>
  """
    Then the error should be contain:
      """
  <error>
  """
    Examples:
      | GQL | error |
      | LET x = TRIM(TRAILING 123 FROM 'abc') RETURN x; | Type mismatch: expected String but was Integer |
      | LET x = TRIM(TRAILING 'abc' FROM 123) RETURN x; | Type mismatch: expected String but was Integer |
      | LET x = TRIM(TRAILING TRUE FROM 'test') RETURN x; | Type mismatch: expected String but was Boolean |
      | LET x = TRIM(TRAILING 'test' FROM TRUE) RETURN x; | Type mismatch: expected String but was Boolean |
      | LET x = TRIM(TRAILING 'test' FROM 12.5) RETURN x; | Type mismatch: expected String but was Float |
