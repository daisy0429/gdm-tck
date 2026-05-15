#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/syntax/operators/#query-operators-boolean
#逻辑/布尔操作符

Feature: not

  Scenario Outline: not-operator-positive-cases
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                         | result | 备注                |
      | LET x = NOT TRUE RETURN x;  | false  | 取反 true 应返回 false |
      | LET x = NOT FALSE RETURN x; | true   | 取反 false 应返回 true |
      | LET x = NOT NULL RETURN x;  | null   |                   |

  Scenario Outline: not-operator-negative-cases
    When executing queries:
  """
  <GQL>
  """
    Then the error should be contain:
  """
  <error>
  """
    Examples:
      | GQL                            | error                                          | 备注                |
      | LET x = NOT 'string' RETURN x; | Type mismatch: expected Boolean but was String | 类型错误：NOT 只接受布尔值输入 |


