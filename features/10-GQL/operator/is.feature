#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/syntax/operators/#match-string-is-normalized

Feature: is

  #fixme test
  Scenario Outline: 验证 IS 操作符的正确性
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | UNWIND [1, NULL, 3, NULL] AS val RETURN COLLECT(val IS NULL) AS x; | [false, true, false, true] |
      | UNWIND [1, NULL, 3, NULL] AS val RETURN COLLECT(val IS NOT NULL) AS x; | [true, false, true, false] |
      | UNWIND [true, false, NULL, 3, 'test'] AS val WITH val, NOT (val IN [true, false]) AS not_bool RETURN COLLECT(not_bool) AS x; | [false, false, true, true] |

