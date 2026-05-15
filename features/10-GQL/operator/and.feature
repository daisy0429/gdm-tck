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
      | GQL | result |
      | LET x = TRUE AND TRUE RETURN x; | true |
      | LET x = TRUE AND FALSE RETURN x; | false |
      | LET x = FALSE AND TRUE RETURN x; | false |
      | LET x = FALSE AND FALSE RETURN x; | false |
      | LET x = TRUE AND NULL RETURN x; | null |

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
      | GQL | error |
      | LET x = 'string' AND TRUE RETURN x; | Type mismatch: expected Boolean |
