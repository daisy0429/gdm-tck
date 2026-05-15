#encoding: utf-8

Feature: IS NOT BOOL

  Scenario Outline: 验证 IS NOT BOOL 操作符的正确性
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | UNWIND [1, true, 3, 'false'] AS val filter val IS NOT ::BOOL  RETURN COLLECT(val)  AS x; | [1, 3, 'false'] |
      | UNWIND [1, true, 3, NULL] AS val filter val IS ::BOOL  RETURN COLLECT(val)  AS x; | [true] |
      | UNWIND [1, true, 3, 'false'] AS val filter val IS NOT ::BOOLEAN  RETURN COLLECT(val)  AS x; | [1, 3, 'false'] |
      | UNWIND [1, true, 3, NULL] AS val filter val IS ::BOOLEAN  RETURN COLLECT(val)  AS x; | [true] |

