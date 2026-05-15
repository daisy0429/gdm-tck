#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/syntax/operators/#query-operators-boolean
#逻辑/bool操作符

Feature: xor

  Scenario Outline: xor-operator-cases
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | LET x = TRUE XOR TRUE RETURN x; | false |
      | LET x = TRUE XOR FALSE RETURN x; | true |
      | LET x = FALSE XOR TRUE RETURN x; | true |
      | LET x = FALSE XOR FALSE RETURN x; | false |
      | LET x = TRUE XOR NULL RETURN x; | null |
      | LET x = NULL XOR TRUE RETURN x; | null |
      | LET x = FALSE XOR NULL RETURN x; | null |
      | LET x = NULL XOR FALSE RETURN x; | null |
      | LET x = NULL XOR NULL RETURN x; | null |

  Scenario Outline: xor-operator-negative-cases
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
      | LET x = 'string' XOR TRUE RETURN x; | Type mismatch: expected Boolean but was String |
      | LET x = 123 XOR FALSE RETURN x; | Type mismatch: expected Boolean but was Integer |
      | LET x = NULL XOR 'string' RETURN x; | Type mismatch: expected Boolean but was String |
