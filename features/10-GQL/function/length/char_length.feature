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
      | GQL | result |
      | LET len = CHAR_LENGTH('abc') RETURN len; | 3 |
      | LET len = CHAR_LENGTH('') RETURN len; | 0 |
      | LET len = CHAR_LENGTH('a') RETURN len; | 1 |
      | LET len = CHAR_LENGTH('hello world') RETURN len; | 11 |
      | LET len = CHAR_LENGTH('a@b#c$') RETURN len; | 6 |
      | LET len = CHAR_LENGTH('a\nb\tc') RETURN len; | 5 |
      | LET len = CHAR_LENGTH('中文') RETURN len; | 2 |
      | LET len = CHAR_LENGTH('a中文1') RETURN len; | 4 |
      | LET len = CHAR_LENGTH('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa') RETURN len; | 100 |
      | LET len = CHAR_LENGTH('     ') RETURN len; | 5 |
      | LET len = CHAR_LENGTH('\t\t') RETURN len; | 2 |
      | LET len = CHAR_LENGTH('abc' + 'def') RETURN len; | 6 |
      | LET len = CHAR_LENGTH(SUBSTRING('hello world', 1, 5)) RETURN len; | 5 |
      | LET len = CHAR_LENGTH(NULL) RETURN len; | null |

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
      | GQL | error |
      | LET len = CHAR_LENGTH(123) RETURN len; | [2725]Type mismatch: expected String but was Integer |
      | LET len = CHAR_LENGTH(TRUE) RETURN len; | [2725]Type mismatch: expected String but was Boolean. |
      | LET len = CHAR_LENGTH(date('2023-11-02')) RETURN len; | unsupported value.type in CharLengthFunction |
      | LET len = CHAR_LENGTH() RETURN len; | unsupported value type in FunctionInvocation |
      | LET len = CHAR_LENGTH('abc', 'def') RETURN len; | unsupported value type in FunctionInvocation |
      | LET len = CHAR_LENGTH 'abc') RETURN len; | [2700]Invalid input |





