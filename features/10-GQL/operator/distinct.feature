#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/syntax/operators/#syntax-using-the-distinct-operator

Feature: distinct


  Scenario Outline: 验证 DISTINCT 操作符的正确性
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | UNWIND [1, 1, 2, 3, NULL, NULL] AS val WITH DISTINCT val AS unique_val RETURN COLLECT(DISTINCT unique_val) AS x; | [1, 2, 3] |
      | UNWIND [1, 1, 2, 3, NULL, NULL] AS val RETURN COLLECT(DISTINCT val) AS x; | [1, 2, 3] |
      | UNWIND [1, 1, 2, 3, NULL, NULL] AS val RETURN COUNT(DISTINCT val) AS x; | 3 |

