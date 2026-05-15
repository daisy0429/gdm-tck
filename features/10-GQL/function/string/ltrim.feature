#encoding: utf-8
#作用: 删除字符串左侧指定字符。
#参数:
#string: 输入字符串，类型为 String。
#characters: 要删除的字符集合，类型为 String，默认为空格。
#返回结果: 删除左侧指定字符后的字符串，类型为 String


Feature: string-ltrim

  Scenario Outline: string-LTRIM-正向用例
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                           | result        | 备注                |
      | LET x = LTRIM('  hello gql') RETURN x;        | 'hello gql'   | 去掉左侧空格            |
      | LET x = LTRIM('hello gql') RETURN x;          | 'hello gql'   | 无空格保持不变           |
      | LET x = LTRIM('   ') RETURN x;                | ''            | 仅空格返回空字符串         |
      | LET x = LTRIM('中文   ') RETURN x;              | '中文   '       | 中英文混合，左侧无空格保持不变   |
      | LET x = LTRIM('123 abc') RETURN x;            | '123 abc'     | 字符串包含数字，无左侧空格保持不变 |
      | LET x = LTRIM(NULL) RETURN x;                 | null          | NULL 值            |
      | LET x = LTRIM('!@#   abc') RETURN x;          | '!@#   abc'   | 特殊字符无左侧空格保持不变     |
      | LET x = LTRIM('!!Hello World', '!') RETURN x; | 'Hello World' | 自定义修剪字符           |
      | LET x = LTRIM('123Hello', '123') RETURN x;    | 'Hello'       | 修剪左侧指定字符序列        |
      | LET x = LTRIM('') RETURN x;                   | ''            | 参数为空字符串           |
      | LET x = LTRIM(NULL) RETURN x;                 | null          |                   |
      | LET x = LTRIM('abc', NULL) RETURN x           | null             |                   |

  Scenario: LTRIM('\t\nHello GQL', '\t\n')-已手动验证pass
    #'Hello GQL'
    When executing queries without error:
      """
      LET x = LOWER('Line\nBreak') RETURN x;
      """

  Scenario Outline: string-LTRIM-异常参数
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                                  | error                                          | 备注         |
      | LET x = LTRIM(123) RETURN x;         | Type mismatch: expected String but was Integer | 参数1-非字符串参数 |
      | LET x = LTRIM('test', 123) RETURN x; | Type mismatch: expected String but was Integer | 参数2-非字符串参数 |
      | LET x = LTRIM(true) RETURN x;        | Type mismatch: expected String but was Boolean | 参数1-布尔值参数  |
