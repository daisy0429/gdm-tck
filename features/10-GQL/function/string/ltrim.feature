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
      | GQL | result |
      | LET x = LTRIM('  hello gql') RETURN x; | 'hello gql' |
      | LET x = LTRIM('hello gql') RETURN x; | 'hello gql' |
      | LET x = LTRIM('   ') RETURN x; | '' |
      | LET x = LTRIM('中文   ') RETURN x; | '中文   ' |
      | LET x = LTRIM('123 abc') RETURN x; | '123 abc' |
      | LET x = LTRIM(NULL) RETURN x; | null |
      | LET x = LTRIM('!@#   abc') RETURN x; | '!@#   abc' |
      | LET x = LTRIM('!!Hello World', '!') RETURN x; | 'Hello World' |
      | LET x = LTRIM('123Hello', '123') RETURN x; | 'Hello' |
      | LET x = LTRIM('') RETURN x; | '' |
      | LET x = LTRIM(NULL) RETURN x; | null |
      | LET x = LTRIM('abc', NULL) RETURN x | null |
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
      | GQL | error |
      | LET x = LTRIM(123) RETURN x; | Type mismatch: expected String but was Integer |
      | LET x = LTRIM('test', 123) RETURN x; | Type mismatch: expected String but was Integer |
      | LET x = LTRIM(true) RETURN x; | Type mismatch: expected String but was Boolean |
