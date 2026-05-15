#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/supported-mandatory/
#https://neo4j.com/docs/cypher-manual/current/clauses/skip/#offset-synonym
#OFFSET 是 SKIP 的同义词，用于跳过指定数量的结果。

Feature: offset

  Scenario Outline: offset-positive-cases
    When executing queries:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result         |
      | <expected> |

    Examples:
      | GQL                                                                                              | expected   | 备注                 |
      | UNWIND [1, 2, 3, 4, 5] AS n WITH n ORDER BY n OFFSET 2 LIMIT 2 RETURN COLLECT(n) AS result;      | [3, 4]     | 跳过前 2 个结果，限制返回 2 个 |
      | UNWIND [1, 2, 3, 4, 5] AS n WITH n ORDER BY n OFFSET 3 LIMIT 1 RETURN COLLECT(n) AS result;      | [4]        | 跳过前 3 个结果，限制返回 1 个 |
      | UNWIND [5, 4, 3, 2, 1] AS n WITH n ORDER BY n OFFSET 0 LIMIT 3 RETURN COLLECT(n) AS result;      | [1, 2, 3]  | 不跳过结果，限制返回前 3 个    |
      | UNWIND [1, 2, 3] AS n WITH n ORDER BY n OFFSET 3 LIMIT 1 RETURN COLLECT(n) AS result;            | []         | 偏移超出范围，返回空集        |
      | UNWIND ['a', 'b', 'c', 'd'] AS n WITH n ORDER BY n OFFSET 1 LIMIT 2 RETURN COLLECT(n) AS result; | ['b', 'c'] | 字符类型列表偏移           |
      | UNWIND [1, 2, 3, 4, 5] AS n WITH n ORDER BY n DESC OFFSET 1 LIMIT 3 RETURN COLLECT(n) AS result; | [4, 3, 2]  | 降序排序偏移             |


  Scenario Outline: offset-negative-cases
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                                                            | error                                                                      | 备注              |
      | UNWIND [1, 2, 3] AS n RETURN n ORDER BY n OFFSET 'a' LIMIT 2;  | Invalid input. 'a' is not a valid value. Must be a non-negative integer    | OFFSET 参数为非整数   |
      | UNWIND [1, 2, 3] AS n RETURN n ORDER BY n OFFSET NULL LIMIT 2; | Invalid input. 'NULL' is not a valid value. Must be a non-negative integer | OFFSET 参数为 NULL |
      | UNWIND [1, 2, 3] AS n RETURN n ORDER BY n OFFSET -1 LIMIT 2;   | Invalid input. '-1' is not a valid value. Must be a non-negative integer   | OFFSET 参数为负数    |
      | UNWIND [1, 2, 3] AS n RETURN n ORDER BY n OFFSET 2.5 LIMIT 2;  | Invalid input. '2.5' is not a valid value. Must be a non-negative integer              | OFFSET 参数为小数    |
      | UNWIND [1, 2, 3] AS n RETURN n ORDER BY n OFFSET 2 LIMIT -1;   | Invalid input. '-1' is not a valid value. Must be a non-negative integer   | LIMIT 参数为负数     |
