#encoding: utf-8

Feature: string-both

  Scenario Outline: BOTH 正向用例
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                     | result      | 备注                          |
      | LET x = TRIM(BOTH ' ' FROM ' HELLO GQL ') RETURN x;     | 'HELLO GQL' | 去除字符串两端的空格                  |
      | LET x = TRIM(BOTH 'X' FROM 'XXXHELLOXXX') RETURN x;     | 'HELLO'     | 去除指定字符 'X'                  |
      | LET x = TRIM(BOTH 'AB' FROM 'ABAHELLOABAB') RETURN x;   | 'HELLO'     | 去除指定多字符 'AB'                |
      | LET x = TRIM(BOTH ' ' FROM '     HELLO     ') RETURN x; | 'HELLO'     | 去除多余空格                      |
      | LET x = TRIM(BOTH '' FROM 'HELLO GQL') RETURN x;        | 'HELLO GQL' | 去除空字符串，原值不变                 |
      | LET x = TRIM(BOTH ' ' FROM '') RETURN x;                | ''          | 空字符串输入返回空字符串                |
      | LET x = TRIM(BOTH '0' FROM '00012345000') RETURN x;     | '12345'     | 去除数字字符 '0'                  |
      | LET x = TRIM(BOTH NULL FROM 'HELLO GQL') RETURN x;      | null        | trim null from string       |
      | LET x = TRIM(BOTH ' ' FROM NULL) RETURN x;              | null        | trim empty string from null |


  Scenario Outline: BOTH 反向用例
    When executing queries:
  """
  <GQL>
  """
    Then the error should be contain:
  """
  <error>
  """
    Examples:
      | GQL                                               | error                                          | 备注              |
      | LET x = TRIM(BOTH 123 FROM 'HELLO GQL') RETURN x; | Type mismatch: expected String but was Integer | 去除字符非字符串类型，抛出错误 |
      | LET x = TRIM(BOTH ' ' FROM 12345) RETURN x;       | Type mismatch: expected String but was Integer | 输入目标非字符串类型，抛出错误 |
      | LET x = TRIM(BOTH ' ' FROM TRUE) RETURN x;        | Type mismatch: expected String but was Boolean | 输入目标为布尔值，抛出错误   |
      | LET x = TRIM(BOTH ' ' FROM 'HELLO GQL') INVALID;  | [2700]Invalid input 'INVALID'                  | 语法错误            |
