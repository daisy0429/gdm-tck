#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/syntax/operators/#query-operators-boolean
#逻辑/bool操作符

Feature: or

  Scenario Outline: or-operator-cases
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | LET x = TRUE OR TRUE RETURN x; | true |
      | LET x = TRUE OR FALSE RETURN x; | true |
      | LET x = FALSE OR TRUE RETURN x; | true |
      | LET x = FALSE OR FALSE RETURN x; | false |
      | LET x = TRUE OR NULL RETURN x; | true |
      | LET x = NULL OR TRUE RETURN x; | true |
      | LET x = FALSE OR NULL RETURN x; | null |
      | LET x = NULL OR FALSE RETURN x; | null |
      | LET x = NULL OR NULL RETURN x; | null |

  Scenario Outline: or-operator-negative-cases
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
      | LET x = 'string' OR TRUE RETURN x; | Type mismatch: expected Boolean but was String |
      | LET x = 123 OR FALSE RETURN x; | Type mismatch: expected Boolean but was Integer |
      | LET x = NULL OR 'string' RETURN x; | Type mismatch: expected Boolean but was String |

