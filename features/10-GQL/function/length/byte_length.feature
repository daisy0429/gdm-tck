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
      | GQL | result |
      | LET len = BYTE_LENGTH('abc') RETURN len; | 3 |
      | LET len = BYTE_LENGTH('你好') RETURN len; | 6 |
      | LET len = BYTE_LENGTH('a你b好c') RETURN len; | 9 |
      | LET len = BYTE_LENGTH('') RETURN len; | 0 |
      | LET len = BYTE_LENGTH('αβγ') RETURN len; | 6 |
      | LET len = BYTE_LENGTH('😀🎉') RETURN len; | 8 |
      | LET len = BYTE_LENGTH('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa') RETURN len; | 100 |
      | LET len = BYTE_LENGTH('中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文中文') RETURN len; | 120 |
      | LET len = BYTE_LENGTH('a中b文c混d合e字f符g串h测试i') RETURN len; | 36 |
      | LET len = BYTE_LENGTH(' \t\n\r') RETURN len; | 4 |
      | LET len = BYTE_LENGTH('ＡＢＣ') RETURN len; | 9 |
      | LET len = BYTE_LENGTH(SUBSTRING('hello世界', 1, 7)) RETURN len; | 6 |
      | LET len = BYTE_LENGTH(SUBSTRING('hello world', 1, 5)) RETURN len; | 5 |
      | LET len = BYTE_LENGTH('hello world') RETURN len; | 11 |
      | LET len = BYTE_LENGTH(NULL) RETURN len; | null |

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
      | LET len = BYTE_LENGTH(123) RETURN len; | [2725]Type mismatch: expected String but was Integer |
      | LET len = BYTE_LENGTH(TRUE) RETURN len; | [2725]Type mismatch: expected String but was Boolean. |
      | LET len = BYTE_LENGTH(date('2023-11-02')) RETURN len; | unsupported value.type in ByteLengthFunction |
      | LET len = BYTE_LENGTH() RETURN len; | unsupported value type in FunctionInvocation |
      | LET len = BYTE_LENGTH('abc', 'def') RETURN len; | unsupported value type in FunctionInvocation |
      | LET len = BYTE_LENGTH 'abc') RETURN len; | [2700]Invalid input |
