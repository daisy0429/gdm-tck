#encoding: utf-8
#作用: 返回字符串左侧指定长度的子字符串。
#参数:
#string: 输入字符串，类型为 String。
#length: 子字符串的长度，类型为 Integer。
#返回结果: 截取的子字符串，长度范围为 [0, length(string)]。

Feature: string-left

  Scenario Outline: string-left
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | let x = LEFT('HELLO GQL', 5) return x; | 'HELLO' |
      | let x = LEFT('HELLO GQL', 9) return x; | 'HELLO GQL' |
      | let x = LEFT('Hello', 0) return x; | '' |
      | let x = LEFT('Example', NULL) return x; | null |
      | let x = LEFT('', 3) return x; | '' |
      | let x = LEFT(null,1) return x; | null |
      | let x = LEFT('abc', 5) return x; | 'abc' |

  Scenario Outline: string-left-异常参数
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
      | let x = LEFT(2, 3) return x; | Type mismatch: expected String but was Integer |
      | let x = LEFT('Hello', -2) return x; | Cannot handle negative start index nor negative length |
      | let x = LEFT('Hello', 'two') return x; | Type mismatch: expected Integer but was String |
      | let x = LEFT('Test', 2.5) return x; | Type mismatch: expected Integer but was Float |
      | let x = LEFT('Test', true) return x; | Type mismatch: expected Integer but was Boolean |


