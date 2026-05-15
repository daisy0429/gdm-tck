#encoding: utf-8
#作用: 将字符串中所有字母转换为小写。
#参数:
#string: 输入字符串，类型为 String。
#返回结果: 全部小写的字符串，类型为 String。

Feature: string-lower

  Scenario Outline: string-LOWER-正向用例-LET
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | LET x = LOWER('HELLO GQL') RETURN x; | 'hello gql' |
      | LET x = LOWER('Hello World') RETURN x; | 'hello world' |
      | LET x = LOWER('hello world') RETURN x; | 'hello world' |
      | LET x = LOWER('123 ABC') RETURN x; | '123 abc' |
      | LET x = LOWER('') RETURN x; | '' |
      | LET x = LOWER(NULL) RETURN x; | null |
      | LET x = LOWER('中文 ENGLISH') RETURN x; | '中文 english' |
      | LET x = LOWER('!@#$%^&*()') RETURN x; | '!@#$%^&*()' |
      | LET x = LOWER('HELLO123') RETURN x; | 'hello123' |
      | LET x = LOWER('a B C D') RETURN x; | 'a b c d' |
      | LET x = LOWER('MULTIPLE  SPACES') RETURN x; | 'multiple  spaces' |
      | LET x = LOWER('😊HELLO') RETURN x; | '😊hello' |
      | LET x = LOWER('  Leading Space') RETURN x; | '  leading space' |
      | LET x = LOWER('Trailing Space  ') RETURN x; | 'trailing space  ' |
      | LET x = LOWER(NULL) RETURN x; | null |

  Scenario Outline: string-LOWER-正向用例-RETURN
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL | result |
      | RETURN LOWER('HELLO GQL') as result; | 'hello gql' |
      | RETURN LOWER('Hello World') as result; | 'hello world' |
      | RETURN LOWER('hello world') as result; | 'hello world' |
      | RETURN LOWER('123 ABC') as result; | '123 abc' |
      | RETURN LOWER('') as result; | '' |
      | RETURN LOWER(NULL) as result; | null |
      | RETURN LOWER('中文 ENGLISH') as result; | '中文 english' |
      | RETURN LOWER('!@#$%^&*()') as result; | '!@#$%^&*()' |
      | RETURN LOWER('HELLO123') as result; | 'hello123' |
      | RETURN LOWER('a B C D') as result; | 'a b c d' |
      | RETURN LOWER('MULTIPLE  SPACES') as result; | 'multiple  spaces' |
      | RETURN LOWER('😊HELLO') as result; | '😊hello' |
      | RETURN LOWER('  Leading Space') as result; | '  leading space' |
      | RETURN LOWER('Trailing Space  ') as result; | 'trailing space  ' |
      | RETURN LOWER(NULL) as result; | null |


  Scenario: LOWER('TAB\tCHARACTER')-已手动验证pass
    When executing queries without error:
      """
      LET x = LOWER('TAB\tCHARACTER') RETURN x;
      RETURN LOWER('TAB\tCHARACTER');
      """


  Scenario: LOWER('Line\nBreak')-已手动验证pass
    When executing queries without error:
      """
      LET x = LOWER('Line\nBreak') RETURN x;
      RETURN LOWER('Line\nBreak');
      """


  Scenario Outline: string-LOWER-异常参数
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
      | LET x = LOWER(123) RETURN x; | Type mismatch: expected String but was Integer |
      | LET x = LOWER(true) RETURN x; | Type mismatch: expected String but was Boolean |
