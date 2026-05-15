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
      | GQL | result |
      | LET x = TRIM(BOTH ' ' FROM ' HELLO GQL ') RETURN x; | 'HELLO GQL' |
      | LET x = TRIM(BOTH 'X' FROM 'XXXHELLOXXX') RETURN x; | 'HELLO' |
      | LET x = TRIM(BOTH 'AB' FROM 'ABAHELLOABAB') RETURN x; | 'HELLO' |
      | LET x = TRIM(BOTH ' ' FROM '     HELLO     ') RETURN x; | 'HELLO' |
      | LET x = TRIM(BOTH '' FROM 'HELLO GQL') RETURN x; | 'HELLO GQL' |
      | LET x = TRIM(BOTH ' ' FROM '') RETURN x; | '' |
      | LET x = TRIM(BOTH '0' FROM '00012345000') RETURN x; | '12345' |
      | LET x = TRIM(BOTH NULL FROM 'HELLO GQL') RETURN x; | null |
      | LET x = TRIM(BOTH ' ' FROM NULL) RETURN x; | null |


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
      | GQL | error |
      | LET x = TRIM(BOTH 123 FROM 'HELLO GQL') RETURN x; | Type mismatch: expected String but was Integer |
      | LET x = TRIM(BOTH ' ' FROM 12345) RETURN x; | Type mismatch: expected String but was Integer |
      | LET x = TRIM(BOTH ' ' FROM TRUE) RETURN x; | Type mismatch: expected String but was Boolean |
      | LET x = TRIM(BOTH ' ' FROM 'HELLO GQL') INVALID; | [2700]Invalid input 'INVALID' |
