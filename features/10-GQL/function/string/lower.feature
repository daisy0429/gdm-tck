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
      | GQL                                         | result             | 备注                 |
      | LET x = LOWER('HELLO GQL') RETURN x;        | 'hello gql'        | 全部大写转小写            |
      | LET x = LOWER('Hello World') RETURN x;      | 'hello world'      | 部分大写转小写            |
      | LET x = LOWER('hello world') RETURN x;      | 'hello world'      | 全部小写保持不变           |
      | LET x = LOWER('123 ABC') RETURN x;          | '123 abc'          | 字符串包含数字，数字不变       |
      | LET x = LOWER('') RETURN x;                 | ''                 | 空字符串               |
      | LET x = LOWER(NULL) RETURN x;               | null               | NULL 值             |
      | LET x = LOWER('中文 ENGLISH') RETURN x;       | '中文 english'       | 中英文混合，英文转小写        |
      | LET x = LOWER('!@#$%^&*()') RETURN x;       | '!@#$%^&*()'       | 非字母字符不变            |
      | LET x = LOWER('HELLO123') RETURN x;         | 'hello123'         | 混合数字和字母，字母转小写，数字不变 |
      | LET x = LOWER('a B C D') RETURN x;          | 'a b c d'          | 大小写混合字符串           |
      | LET x = LOWER('MULTIPLE  SPACES') RETURN x; | 'multiple  spaces' | 字符串中有多个空格          |
      | LET x = LOWER('😊HELLO') RETURN x;          | '😊hello'          | 包含表情符号的字符串         |
      | LET x = LOWER('  Leading Space') RETURN x;  | '  leading space'  | 带前导空格的字符串          |
      | LET x = LOWER('Trailing Space  ') RETURN x; | 'trailing space  ' | 带尾随空格的字符串          |
      | LET x = LOWER(NULL) RETURN x;               | null               | null               |

  Scenario Outline: string-LOWER-正向用例-RETURN
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                         | result             | 备注                    |
      | RETURN LOWER('HELLO GQL') as result;        | 'hello gql'        | 全部大写转小写            |
      | RETURN LOWER('Hello World') as result;      | 'hello world'      | 部分大写转小写            |
      | RETURN LOWER('hello world') as result;       | 'hello world'      | 全部小写保持不变           |
      | RETURN LOWER('123 ABC') as result;           | '123 abc'          | 字符串包含数字，数字不变     |
      | RETURN LOWER('') as result;                  | ''                 | 空字符串                  |
      | RETURN LOWER(NULL) as result;                | null               | NULL 值                  |
      | RETURN LOWER('中文 ENGLISH') as result;        | '中文 english'    | 中英文混合，英文转小写       |
      | RETURN LOWER('!@#$%^&*()') as result;        | '!@#$%^&*()'       | 非字母字符不变             |
      | RETURN LOWER('HELLO123') as result;          | 'hello123'         | 混合数字和字母，字母转小写，数字不变 |
      | RETURN LOWER('a B C D') as result;           | 'a b c d'          | 大小写混合字符串           |
      | RETURN LOWER('MULTIPLE  SPACES') as result;  | 'multiple  spaces' | 字符串中有多个空格          |
      | RETURN LOWER('😊HELLO') as result;           | '😊hello'          | 包含表情符号的字符串        |
      | RETURN LOWER('  Leading Space') as result;   | '  leading space'  | 带前导空格的字符串          |
      | RETURN LOWER('Trailing Space  ') as result;  | 'trailing space  ' | 带尾随空格的字符串          |
      | RETURN LOWER(NULL) as result;                | null               | null                     |


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
      | GQL                           | error                                          | 备注         |
      | LET x = LOWER(123) RETURN x;  | Type mismatch: expected String but was Integer | 参数1-非字符串参数 |
      | LET x = LOWER(true) RETURN x; | Type mismatch: expected String but was Boolean | 参数1-布尔值参数  |
