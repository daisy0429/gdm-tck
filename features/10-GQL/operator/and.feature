#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/syntax/operators/#query-operators-boolean
#逻辑/布尔操作符

Feature: and

  Scenario Outline: and-operator-positive-cases
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                               | result | 备注                    |
      | LET x = TRUE AND TRUE RETURN x;   | true   | 两个布尔值均为 true，应返回 true |
      | LET x = TRUE AND FALSE RETURN x;  | false  | 一个为 false，应返回 false   |
      | LET x = FALSE AND TRUE RETURN x;  | false  | 一个为 false，应返回 false   |
      | LET x = FALSE AND FALSE RETURN x; | false  | 两个均为 false，应返回 false  |
      | LET x = TRUE AND NULL RETURN x;   | null   | NULL 参与运算             |

  Scenario Outline: and-operator-negative-cases
    When executing queries:
  """
  <GQL>
  """
    Then the error should be contain:
  """
  <error>
  """
    Examples:
      | GQL                                 | error                           | 备注        |
      | LET x = 'string' AND TRUE RETURN x; | Type mismatch: expected Boolean | 类型错误：非布尔值 |
