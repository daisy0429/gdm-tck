# encoding: utf-8
# 测试范围：
# 数值类型溢出测试
# 覆盖整型(int)和浮点型(float/double)的边界写入与溢出场景
# 正向用例：合法边界值写入并验证
# 反向用例：溢出写入，占位待补充断言
  # fixme script: 待补充关系下测试数据

@dml
Feature: 数值类型溢出 - DataTypes Numeric Overflow

  # ========== 正向用例 ==========

  Scenario: [Overflow-01] 写入整型最大值，正常写入并验证
    Given an empty graph
    When executing query:
      """
      CREATE (n:OverflowNode {name: 'int_max', val: 9223372036854775807})
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes | 1 |
    When executing query:
      """
      MATCH (n:OverflowNode {name: 'int_max'}) RETURN n.val
      """
    Then the result should be:
      | n.val                |
      | 9223372036854775807  |
    And no side effects

  Scenario: [Overflow-02] 写入整型最小值，正常写入并验证
    Given an empty graph
    When executing query:
      """
      CREATE (n:OverflowNode {name: 'int_min', val: -9223372036854775808})
      """
    Then the result should be empty
    And the side effects should be:
      | +nodes | 1 |
    When executing query:
      """
      MATCH (n:OverflowNode {name: 'int_min'}) RETURN n.val
      """
    Then the result should be:
      | n.val                 |
      | -9223372036854775808  |
    And no side effects

  # ========== 反向用例（占位，待手动执行后补充断言） ==========
  # todo 增加校验点：执行报错。库中数据实际为0 （后续事务验证点）
  # 实测：error(CYPHER_EXECUTION): invalid integer: number too large to fit in target type
  Scenario: [Overflow-03] 节点属性int类型 - 整型最大值 +1 上溢
    Given an empty graph
    When executing query:
      """
      CREATE (n:OverflowNode {name: 'int_overflow_up', val: 9223372036854775808})
      """

    # todo 增加校验点：执行报错。库中数据实际为0 （后续事务验证点）
    # 实测：error(CYPHER_EXECUTION): invalid integer -9223372036854775809: number too small to fit in target type
  Scenario: [Overflow-04] 节点属性int类型 - 整型最小值 -1 下溢
    Given an empty graph
    When executing query:
      """
      CREATE (n:OverflowNode {name: 'int_overflow_down', val: -9223372036854775809})
      """

   # fixme code 实测写入成功
  # neo4j: 22003: data exception - numeric value out of range. The numeric value 1.7976931348623157E+309 is outside the required range. (line 1, column 58 (offset: 57))
  Scenario: [Overflow-05] 节点属性double类型 - 双精度浮点数正向溢出
    Given an empty graph
    When executing query:
      """
      CREATE (n:OverflowNode {name: 'float_overflow_pos', val: 1.7976931348623157E+309})
      """

  # fixme code 实测写入成功
  # neo4j: 22003: data exception - numeric value out of range. The numeric value -1.7976931348623157E+309 is outside the required range. (line 1, column 58 (offset: 57))
  Scenario: [Overflow-06] 节点属性double类型 - 双精度浮点数反向溢出
    Given an empty graph
    When executing query:
      """
      CREATE (n:OverflowNode {name: 'float_overflow_neg', val: -1.7976931348623157E+309})
      """

  Scenario: [Overflow-07] 节点属性float类型 - 浮点数极小值下溢（趋近于0）
    Given an empty graph
    When executing query:
      """
      CREATE (n:OverflowNode {name: 'float_underflow', val: 4.9406564584124654E-324})
      """

#  Scenario: [Overflow-08] 关系属性float类型 - 数值溢出
#    Given an empty graph
#    And having executed:
#      """
#      CREATE (a:OverflowNode {name: 'src'})
#      CREATE (b:OverflowNode {name: 'dst'})
#      """
#    When executing query:
#      """
#      MATCH (a:OverflowNode {name: 'src'}), (b:OverflowNode {name: 'dst'})
#      CREATE (a)-[r:OVERFLOW_REL {amount: 1.7976931348623157E+309}]->(b)
#      """
