#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/analogous-cypher/
#GQ10, GQ11, GQ23, GQ24
#FOR statement: list value support, binding table support, WITH ORDINALITY, WITH OFFSET
#GQL的for等价cypher的unwind


Feature: for

  #循环遍历列表并返回元素
  Scenario: [1] 验证 FOR IN 循环的基本功能
    When executing query without error:
      """
      FOR x IN [1, 2] RETURN x
      """
    Then the result should be, in any order:
      | x |
      | 1 |
      | 2 |

  Scenario: [2] 验证 FOR IN WITH ORDINALITY 生成顺序号
    When executing query without error:
      """
      FOR x IN ["apple", "banana", "cherry"] WITH ORDINALITY index RETURN x, index
      """
    Then the result should be, in any order:
      | x        | index |
      | 'apple'  | 1     |
      | 'banana' | 2     |
      | 'cherry' | 3     |

    #WITH OFFSET index 表示在遍历过程中，记录当前元素的偏移量（即索引）,一般是从0开始
  Scenario: [3] 验证 FOR IN WITH OFFSET 的偏移功能-bug5375
    When executing query without error:
      """
      FOR x IN [10, 20, 30] WITH OFFSET index RETURN x, index
      """
    Then the result should be, in any order:
      | x  | index |
      | 10 | 1     |
      | 20 | 2     |
      | 30 | 3     |


  Scenario: [4] 验证 FOR IN RANGE 的范围遍历
    When executing query without error:
      """
      FOR a IN RANGE(2, 3) RETURN a;
      """
    Then the result should be, in any order:
      | a |
      | 2 |
      | 3 |

  Scenario: [5] 验证 FOR IN RANGE WITH ORDINALITY 的范围与顺序号结合功能
    When executing query without error:
      """
    FOR a IN RANGE(1, 3) WITH ORDINALITY index RETURN a, index
      """
    Then the result should be, in any order:
      | a | index |
      | 1 | 1     |
      | 2 | 2     |
      | 3 | 3     |

  Scenario: [6] 验证 FOR IN RANGE WITH OFFSET 的范围与偏移结合功能-bug5375
    When executing query without error:
      """
    FOR a IN RANGE(1, 3) WITH OFFSET index RETURN a, index
      """
    Then the result should be, in any order:
      | a | index |
      | 1 | 1     |
      | 2 | 2     |
      | 3 | 3     |

  Scenario: [7] 验证大范围数字的正确性
    When executing query without error:
      """
      FOR a IN RANGE(1, 10000) RETURN count(a);
      """
    Then the result should be, in any order:
      | count(a) |
      | 10000    |
























