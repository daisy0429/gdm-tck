# encoding: utf-8
#
# Constraint: Composite Property - verify behavior
#
# 测试范围:
#   - 复合属性约束允许重复组合值（非唯一约束）
#   - 查询可使用复合索引（通过查询计划或数据检索验证）
#   - NULL 值在复合属性组合中的行为
#
# Neo4j 参考:
#   Composite Property 约束为索引型约束，不强制唯一性，允许重复 (prop1, prop2) 组合。
#   NULL 值参与复合属性组合时的行为：GDM 允许包含 NULL 的组合存在。
#
@constraint @ddl
Feature: Constraint composite property - verify behavior

  # ---------------------------------------------------------------------------
  # 1. 重复 (prop1, prop2) 组合可插入 -> 不报错（非唯一约束）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Verify-Composite-01] duplicate composite values allowed on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertFirst>
      """
    When executing query without error:
      """
      <insertDuplicate>
      """
    When executing query without error:
      """
      <insertDuplicateAgain>
      """
    When executing query:
      """
      <countQuery>
      """
    Then the result should be:
      3

    Examples:
      | entityType | createCypher                                                                                          | insertFirst                                                              | insertDuplicate                                                          | insertDuplicateAgain                                                     | countQuery                                                 |
      | node       | CREATE CONSTRAINT verifyDup FOR (n:VerifyDupNode) REQUIRE (n.k1, n.k2) IS COMPOSITE PROPERTY         | CREATE (:VerifyDupNode {k1: 'A', k2: 'X'})                               | CREATE (:VerifyDupNode {k1: 'A', k2: 'X'})                               | CREATE (:VerifyDupNode {k1: 'A', k2: 'X'})                               | MATCH (n:VerifyDupNode) RETURN count(n) AS cnt            |
      | rel        | CREATE CONSTRAINT verifyDupRel FOR ()-[r:VERIFY_DUP]-() REQUIRE (r.k1, r.k2) IS COMPOSITE PROPERTY   | CREATE (a:VDSrc),(b:VDDst), (a)-[:VERIFY_DUP {k1:'A',k2:'X'}]->(b)       | CREATE (c:VDSrc2),(d:VDDst2), (c)-[:VERIFY_DUP {k1:'A',k2:'X'}]->(d)     | CREATE (e:VDSrc3),(f:VDDst3), (e)-[:VERIFY_DUP {k1:'A',k2:'X'}]->(f)     | MATCH ()-[r:VERIFY_DUP]->() RETURN count(r) AS cnt        |

  # ---------------------------------------------------------------------------
  # 2. 查询可利用复合索引（验证数据正确检索）
  #    通过 MATCH 查询复合属性条件，验证索引支持下的数据检索正确性
  # ---------------------------------------------------------------------------

  Scenario Outline: [Verify-Composite-02] query with composite index retrieves correct data on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertData>
      """
    When executing query:
      """
      <matchQuery>
      """
    Then the result should be, in any order:
      | result |
      | '<expected1>' |
      | '<expected2>' |

    Examples:
      | entityType | createCypher                                                                                              | insertData                                                                                                                                | matchQuery                                                                     | expected1 | expected2 |
      | node       | CREATE CONSTRAINT queryComp FOR (n:QueryCompNode) REQUIRE (n.city, n.zip) IS COMPOSITE PROPERTY          | CREATE (:QueryCompNode {city:'Beijing',zip:'100000',name:'n1'}), (:QueryCompNode {city:'Shanghai',zip:'200000',name:'n2'})               | MATCH (n:QueryCompNode {city: 'Beijing', zip: '100000'}) RETURN n.name AS result | 'n1'      | 'n2'      |
      | rel        | CREATE CONSTRAINT queryCompRel FOR ()-[r:QUERY_COMP]-() REQUIRE (r.src, r.dst) IS COMPOSITE PROPERTY     | CREATE (a:QCSrc1),(b:QCDst1),(c:QCSrc2),(d:QCDst2), (a)-[:QUERY_COMP {src:'A',dst:'B',tag:'r1'}]->(b),(c)-[:QUERY_COMP {src:'C',dst:'D',tag:'r2'}]->(d) | MATCH ()-[r:QUERY_COMP {src: 'A', dst: 'B'}]->() RETURN r.tag AS result | 'r1'      | 'r2'      |

  # ---------------------------------------------------------------------------
  # 3. NULL 值在复合属性组合中的行为
  #    复合属性中一个属性为 NULL，另一个不为 NULL -> 允许插入
  #    复合属性中两个属性均为 NULL -> 允许插入
  # ---------------------------------------------------------------------------

  Scenario Outline: [Verify-Composite-03] NULL values in composite property combination on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing queries without error:
      """
      <insertPartialNull>;
      <insertBothNull>
      """
    When executing query:
      """
      <countQuery>
      """
    Then the result should be:
      <expectedCount>

    Examples:
      | entityType | createCypher                                                                                         | insertPartialNull                                                     | insertBothNull                                                    | countQuery                                              | expectedCount |
      | node       | CREATE CONSTRAINT nullCombo FOR (n:NullComboNode) REQUIRE (n.x, n.y) IS COMPOSITE PROPERTY          | CREATE (:NullComboNode {x: NULL, y: 'V'})                             | CREATE (:NullComboNode {x: NULL, y: NULL})                        | MATCH (n:NullComboNode) RETURN count(n) AS cnt          | 2             |
      | rel        | CREATE CONSTRAINT nullComboRel FOR ()-[r:NULL_COMBO]-() REQUIRE (r.x, r.y) IS COMPOSITE PROPERTY    | CREATE (a:NBSrc1),(b:NBDst1), (a)-[:NULL_COMBO {x:NULL, y:'V'}]->(b)  | CREATE (c:NBSrc2),(d:NBDst2), (c)-[:NULL_COMBO {x:NULL, y:NULL}]->(d) | MATCH ()-[r:NULL_COMBO]->() RETURN count(r) AS cnt  | 2             |
