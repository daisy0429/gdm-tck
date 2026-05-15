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
      | GQL                                                                                                                          | result                     | 备注                          |
      | UNWIND [1, NULL, 3, NULL] AS val RETURN COLLECT(val IS NULL) AS x;                                                           | [false, true, false, true] | 验证 IS NULL 正确标识 NULL 值      |
      | UNWIND [1, NULL, 3, NULL] AS val RETURN COLLECT(val IS NOT NULL) AS x;                                                       | [true, false, true, false] | 验证 IS NOT NULL 正确过滤非 NULL 值 |
      | UNWIND [true, false, NULL, 3, 'test'] AS val WITH val, NOT (val IN [true, false]) AS not_bool RETURN COLLECT(not_bool) AS x; | [false, false, true, true] | 验证 IS NOT 类型过滤              |

