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
      | GQL                              | result | 备注                           |
      | LET x = TRUE OR TRUE RETURN x;   | true   | `TRUE OR TRUE` 应返回 `TRUE`    |
      | LET x = TRUE OR FALSE RETURN x;  | true   | `TRUE OR FALSE` 应返回 `TRUE`   |
      | LET x = FALSE OR TRUE RETURN x;  | true   | `FALSE OR TRUE` 应返回 `TRUE`   |
      | LET x = FALSE OR FALSE RETURN x; | false  | `FALSE OR FALSE` 应返回 `FALSE` |
      | LET x = TRUE OR NULL RETURN x;   | true   | `TRUE OR NULL` 应返回 `TRUE`    |
      | LET x = NULL OR TRUE RETURN x;   | true   | `NULL OR TRUE` 应返回 `TRUE`    |
      | LET x = FALSE OR NULL RETURN x;  | null   | `FALSE OR NULL` 应返回 `NULL`   |
      | LET x = NULL OR FALSE RETURN x;  | null   | `NULL OR FALSE` 应返回 `NULL`   |
      | LET x = NULL OR NULL RETURN x;   | null   | `NULL OR NULL` 应返回 `NULL`    |

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
      | GQL                                | error                                                  | 备注          |
      | LET x = 'string' OR TRUE RETURN x; | Type mismatch: expected Boolean but was String  | 不支持的类型（字符串） |
      | LET x = 123 OR FALSE RETURN x;     | Type mismatch: expected Boolean but was Integer | 不支持的类型（整数）  |
      | LET x = NULL OR 'string' RETURN x; | Type mismatch: expected Boolean but was String  | 不支持的类型（字符串） |

