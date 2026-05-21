# encoding: utf-8
#
# Constraint: Node Key / Relationship Key - violation scenarios
#
# 测试范围:
#   - INSERT 重复组合值 -> 报错
#   - INSERT 含 NULL 的组合值 -> 报错（Node Key 要求 NOT NULL）
#   - UPDATE (SET) key 属性为重复值 -> 报错
#   - SET 任意 key 属性为 NULL -> 报错
#   - 同第一属性不同第二属性 -> 成功（组合唯一，非单独属性唯一）
#
# Neo4j 参考:
#   Node Key = 复合 UNIQUE + NOT NULL
#   与 Unique 的区别：Node Key 不允许 NULL，且是属性组合唯一
#
@constraint @ddl
Feature: Constraint node key / relationship key - violation

  # ---------------------------------------------------------------------------
  # 1. INSERT 重复组合值 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Key-01] insert duplicate combination on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertFirst>
      """
    When executing query:
      """
      <insertDuplicate>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                         | insertFirst                                                                                | insertDuplicate                                                                            |
      | node       | CREATE CONSTRAINT vkDup FOR (n:VKDupNode) REQUIRE (n.firstName, n.lastName) IS NODE KEY             | CREATE (:VKDupNode {firstName: 'Alice', lastName: 'Smith'})                                | CREATE (:VKDupNode {firstName: 'Alice', lastName: 'Smith'})                                |
      | rel        | CREATE CONSTRAINT vkDupRel FOR ()-[r:VK_DUP_REL]-() REQUIRE (r.src, r.dst) IS RELATIONSHIP KEY      | CREATE (a:VKSrc1), (b:VKDst1), (a)-[:VK_DUP_REL {src: 'A', dst: 'X'}]->(b)                | CREATE (c:VKSrc2), (d:VKDst2), (c)-[:VK_DUP_REL {src: 'A', dst: 'X'}]->(d)                |

  # ---------------------------------------------------------------------------
  # 2. INSERT 含 NULL 的组合值 -> 报错（Node Key 要求 NOT NULL）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Key-02] insert with NULL in key property on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertFirst>
      """
    When executing query:
      """
      <insertNull>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                       | insertFirst                                                                            | insertNull                                                                                     |
      | node       | CREATE CONSTRAINT vkNull FOR (n:VKNullNode) REQUIRE (n.firstName, n.lastName) IS NODE KEY         | CREATE (:VKNullNode {firstName: 'Alice', lastName: 'Smith'})                           | CREATE (:VKNullNode {firstName: 'Bob', lastName: null})                                        |
      | rel        | CREATE CONSTRAINT vkNullRel FOR ()-[r:VK_NULL_REL]-() REQUIRE (r.src, r.dst) IS RELATIONSHIP KEY  | CREATE (a:VKNSrc1), (b:VKNDst1), (a)-[:VK_NULL_REL {src: 'A', dst: 'X'}]->(b)         | CREATE (c:VKNSrc2), (d:VKNDst2), (c)-[:VK_NULL_REL {src: 'B', dst: null}]->(d)                |

  # ---------------------------------------------------------------------------
  # 3. UPDATE (SET) key 属性为重复值 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Key-03] update key property to duplicate on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertData>
      """
    When executing query:
      """
      <updateDuplicate>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                           | insertData                                                                                                                                                                  | updateDuplicate                                                                   |
      | node       | CREATE CONSTRAINT vkUpd FOR (n:VKUpdNode) REQUIRE (n.code, n.region) IS NODE KEY                      | CREATE (:VKUpdNode {code: 'C1', region: 'US'}), (:VKUpdNode {code: 'C2', region: 'EU'})                                                                                     | MATCH (n:VKUpdNode {code: 'C2'}) SET n.region = 'US'                               |
      | rel        | CREATE CONSTRAINT vkUpdRel FOR ()-[r:VK_UPD_REL]-() REQUIRE (r.code, r.region) IS RELATIONSHIP KEY    | CREATE (a:VKUSrc1), (b:VKUDst1), (c:VKUSrc2), (d:VKUDst2), (a)-[:VK_UPD_REL {code: 'C1', region: 'US'}]->(b), (c)-[:VK_UPD_REL {code: 'C2', region: 'EU'}]->(d)          | MATCH ()-[r:VK_UPD_REL {code: 'C2'}]->() SET r.region = 'US'                      |

  # ---------------------------------------------------------------------------
  # 4. SET 任意 key 属性为 NULL -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Key-04] set key property to NULL on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertData>
      """
    When executing query:
      """
      <setNull>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                           | insertData                                                                                                                              | setNull                                                                            |
      | node       | CREATE CONSTRAINT vkSetNull FOR (n:VKSetNullNode) REQUIRE (n.code, n.region) IS NODE KEY              | CREATE (:VKSetNullNode {code: 'C1', region: 'US'})                                                                                      | MATCH (n:VKSetNullNode) SET n.region = null                                        |
      | rel        | CREATE CONSTRAINT vkSetNullRel FOR ()-[r:VK_SETNULL_REL]-() REQUIRE (r.code, r.region) IS RELATIONSHIP KEY | CREATE (a:VKSNRrc), (b:VKSNRst), (a)-[:VK_SETNULL_REL {code: 'C1', region: 'US'}]->(b)                                            | MATCH ()-[r:VK_SETNULL_REL]->() SET r.region = null                               |

  # ---------------------------------------------------------------------------
  # 5. 同第一属性不同第二属性 -> 成功（组合唯一，非单独属性唯一）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Key-05] same first property different second property succeeds on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertFirst>
      """
    When executing query without error:
      """
      <insertDifferentSecond>
      """
    Then the side effects should be:
      | +nodes | <compliantNodes> |
      | +relationships | <compliantRels> |

    Examples:
      | entityType | createCypher                                                                                              | insertFirst                                                                              | insertDifferentSecond                                                                     | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT vkCombo FOR (n:VKComboNode) REQUIRE (n.firstName, n.lastName) IS NODE KEY              | CREATE (:VKComboNode {firstName: 'Alice', lastName: 'Smith'})                            | CREATE (:VKComboNode {firstName: 'Alice', lastName: 'Jones'})                             | 1              | 0             |
      | rel        | CREATE CONSTRAINT vkComboRel FOR ()-[r:VK_COMBO_REL]-() REQUIRE (r.src, r.dst) IS RELATIONSHIP KEY       | CREATE (a:VKCSrc1), (b:VKCDst1), (a)-[:VK_COMBO_REL {src: 'A', dst: 'X'}]->(b)          | CREATE (c:VKCSrc2), (d:VKCDst2), (c)-[:VK_COMBO_REL {src: 'A', dst: 'Y'}]->(d)           | 2              | 1             |
