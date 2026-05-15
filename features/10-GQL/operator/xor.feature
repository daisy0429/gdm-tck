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
      | GQL                               | result | 备注                            |
      | LET x = TRUE XOR TRUE RETURN x;   | false  | `TRUE XOR TRUE` 应返回 `FALSE`   |
      | LET x = TRUE XOR FALSE RETURN x;  | true   | `TRUE XOR FALSE` 应返回 `TRUE`   |
      | LET x = FALSE XOR TRUE RETURN x;  | true   | `FALSE XOR TRUE` 应返回 `TRUE`   |
      | LET x = FALSE XOR FALSE RETURN x; | false  | `FALSE XOR FALSE` 应返回 `FALSE` |
      | LET x = TRUE XOR NULL RETURN x;   | null   | `TRUE XOR NULL` 应返回 `NULL`    |
      | LET x = NULL XOR TRUE RETURN x;   | null   | `NULL XOR TRUE` 应返回 `NULL`    |
      | LET x = FALSE XOR NULL RETURN x;  | null   | `FALSE XOR NULL` 应返回 `NULL`   |
      | LET x = NULL XOR FALSE RETURN x;  | null   | `NULL XOR FALSE` 应返回 `NULL`   |
      | LET x = NULL XOR NULL RETURN x;   | null   | `NULL XOR NULL` 应返回 `NULL`    |

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
      | GQL                                   | error                                                                | 备注                   |
      | LET x = 'string' XOR TRUE RETURN x;   | Type mismatch: expected Boolean but was String                | 不支持的类型（字符串）         |
      | LET x = 123 XOR FALSE RETURN x;       | Type mismatch: expected Boolean but was Integer               | 不支持的类型（整数）           |
      | LET x = NULL XOR 'string' RETURN x;   | Type mismatch: expected Boolean but was String                | 不支持的类型（字符串）         |
