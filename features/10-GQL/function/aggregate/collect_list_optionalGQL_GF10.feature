#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/analogous-cypher/
#GQL’s COLLECT_LIST() function is equivalent to Cypher’s collect() function.
#作用：将输入值收集为有序列表。
#参数范围: 可为任何类型的值，包括数值、字符串、节点、关系等。
#参数类型: 单个值或多值集合（如通过 UNWIND）
#返回值：返回一个 LIST，按输入值的顺序收集；如果集合为空，则返回空列表 []。

Feature: COLLECT_LIST

  Scenario Outline: collect-list-positive-cases
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                               | result          | 备注        |
      | UNWIND RANGE(1, 3) AS m LET x = COLLECT_LIST(ALL m) RETURN x;     | [1, 2, 3]       | 数值集合      |
      | UNWIND ['a', 'b', 'c'] AS m LET x = COLLECT_LIST(ALL m) RETURN x; | ['a', 'b', 'c'] | 字符串集合     |
      | UNWIND [] AS m LET x = COLLECT_LIST(ALL m) RETURN x;              | []              | 空集合，返回空列表 |


