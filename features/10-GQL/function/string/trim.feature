#encoding: utf-8
#作用: 删除字符串首尾指定字符。
#参数:
#string: 输入字符串，类型为 String。
#characters: 要删除的字符集合，类型为 String，默认为空格。
#返回结果: 删除首尾指定字符后的字符串，类型为 String。
#https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/supported-mandatory/
# In GQL, TRIM() removes only space characters. In Cypher, trim() removes any whitespace character.
#空格字符（space char）
#仅指具体的 空格 字符，对应 Unicode 编码 U+0020。
#这是我们键盘上的普通空格键输入的字符，例如 " "。
#空白字符（whitespace char）
#指一类“空白”字符，范围比空格字符更广，包括多种不可见字符，例如：
#空格 (U+0020)
#制表符 (\t, Unicode U+0009)
#换行符 (\n, Unicode U+000A)
#回车符 (\r, Unicode U+000D)
#不换行空格 (\u00A0)
#其他空白字符

Feature: string-trim

  Scenario Outline: string-TRIM
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                   | result    | 备注             |
      | LET x = TRIM('   HELLO   ') RETURN x; | 'HELLO'   | 去除两侧空格         |
      | LET x = TRIM('HELLO😊   ') RETURN x;  | 'HELLO😊' | 表情符号保留，只去除两侧空格 |
      | LET x = TRIM('') RETURN x;            | ''        | 参数1为空字符串       |
      | LET x = TRIM(NULL) RETURN x;          | null      | 参数1为 NULL      |
      | LET x = TRIM('中文 字符') RETURN x;       | '中文 字符'   | 中间的空格保留，去除两侧空格 |

  Scenario: TRIM('\tHELLO\n')
    Given an empty graph
    And having executed:
      """
      LET x = TRIM('\tHELLO\n') RETURN x;
      """
    Then the result should be, in any order:
      | x           |
      | 'HELLO' |

  Scenario Outline: string-TRIM 异常参数
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
      | LET x = TRIM(12345) RETURN x; | Type mismatch: expected String but was Integer | 参数1-非字符串参数 |
      | LET x = TRIM(TRUE) RETURN x;  | Type mismatch: expected String but was Boolean | 参数1-布尔值参数  |

