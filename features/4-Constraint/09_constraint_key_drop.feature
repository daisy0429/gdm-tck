# encoding: utf-8
#
# Constraint: Node Key / Relationship Key - drop scenarios
#
# 测试范围:
#   - DROP CONSTRAINT by name -> 成功
#   - DROP CONSTRAINT IF EXISTS 存在时 -> 成功
#   - DROP CONSTRAINT IF EXISTS 不存在时 -> 无报错
#   - DROP CONSTRAINT 不带 IF EXISTS 不存在时 -> 报错
#   - 删除后先前违反约束的数据可以写入（重复值和 NULL）
#   - 删除后底层索引同步被删除
#
# Neo4j 参考:
#   DROP CONSTRAINT name
#   DROP CONSTRAINT name IF EXISTS
#
@constraint @ddl
Feature: Constraint node key / relationship key - drop

  # ---------------------------------------------------------------------------
  # 1. DROP by name -> 成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Key-01] drop key constraint by name - <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query:
      """
      <dropCypher>
      """
    Then the side effects should be:
      | +constraints | -1 |

    Examples:
      | entityType | createCypher                                                                                     | dropCypher                                    |
      | node       | CREATE CONSTRAINT dropKeyNode FOR (n:DropKeyNode) REQUIRE (n.code) IS NODE KEY                   | DROP CONSTRAINT dropKeyNode                   |
      | rel        | CREATE CONSTRAINT dropKeyRel FOR ()-[r:DROP_KEY_REL]-() REQUIRE (r.code) IS RELATIONSHIP KEY     | DROP CONSTRAINT dropKeyRel                    |

  # ---------------------------------------------------------------------------
  # 2. DROP IF EXISTS 约束存在时 -> 成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Key-02] drop key constraint IF EXISTS when exists - <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query without error:
      """
      <dropCypher>
      """
    Then the side effects should be:
      | +constraints | -1 |

    Examples:
      | entityType | createCypher                                                                                       | dropCypher                                            |
      | node       | CREATE CONSTRAINT dropIEKeyNode FOR (n:DropIEKeyNode) REQUIRE (n.code) IS NODE KEY                 | DROP CONSTRAINT dropIEKeyNode IF EXISTS               |
      | rel        | CREATE CONSTRAINT dropIEKeyRel FOR ()-[r:DROP_IE_KEY_REL]-() REQUIRE (r.code) IS RELATIONSHIP KEY  | DROP CONSTRAINT dropIEKeyRel IF EXISTS                |

  # ---------------------------------------------------------------------------
  # 3. DROP IF EXISTS 约束不存在时 -> 无报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Key-03] drop key constraint IF EXISTS when not exists - <entityType>
    Given an empty graph
    When executing query without error:
      """
      <dropCypher>
      """
    Then the side effects should be:
      | +constraints | 0 |

    Examples:
      | entityType | dropCypher                                     |
      | node       | DROP CONSTRAINT nonexistentKeyNode IF EXISTS    |
      | rel        | DROP CONSTRAINT nonexistentKeyRel IF EXISTS     |

  # ---------------------------------------------------------------------------
  # 4. DROP 不带 IF EXISTS 约束不存在时 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Key-04] drop key constraint without IF EXISTS on non-existent - <entityType>
    Given an empty graph
    When executing query:
      """
      <dropCypher>
      """
    Then an error should be raised

    Examples:
      | entityType | dropCypher                              |
      | node       | DROP CONSTRAINT missingKeyNode          |
      | rel        | DROP CONSTRAINT missingKeyRel           |

  # ---------------------------------------------------------------------------
  # 5. 删除后先前违反约束的数据可以写入（重复值和 NULL）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Key-05] after drop, previously violating data can be inserted - <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertFirst>
      """
    # ---- 删除约束 ----
    When executing query without error:
      """
      <dropCypher>
      """
    # ---- 写入重复值 -> 应成功 ----
    When executing query without error:
      """
      <insertDuplicate>
      """
    # ---- 写入 NULL 值 -> 应成功 ----
    When executing query without error:
      """
      <insertNull>
      """
    # ---- 验证最终数据量 ----
    When executing query:
      """
      <countQuery>
      """
    Then the result should be:
      <expectedCount>

    Examples:
      | entityType | createCypher                                                                                          | insertFirst                                                                           | dropCypher                        | insertDuplicate                                                                  | insertNull                                                                   | countQuery                                              | expectedCount |
      | node       | CREATE CONSTRAINT freeKeyNode FOR (n:FreeKeyNode) REQUIRE (n.code) IS NODE KEY                        | CREATE (:FreeKeyNode {code: 'V1'})                                                    | DROP CONSTRAINT freeKeyNode       | CREATE (:FreeKeyNode {code: 'V1'})                                               | CREATE (:FreeKeyNode {code: null})                                           | MATCH (n:FreeKeyNode) RETURN count(n) AS cnt            | 3             |
      | rel        | CREATE CONSTRAINT freeKeyRel FOR ()-[r:FREE_KEY_REL]-() REQUIRE (r.code) IS RELATIONSHIP KEY          | CREATE (a:FKSrc1), (b:FKDst1), (a)-[:FREE_KEY_REL {code: 'V1'}]->(b)                  | DROP CONSTRAINT freeKeyRel        | CREATE (c:FKSrc2), (d:FKDst2), (c)-[:FREE_KEY_REL {code: 'V1'}]->(d)             | CREATE (e:FKSrc3), (f:FKDst3), (e)-[:FREE_KEY_REL {code: null}]->(f)        | MATCH ()-[r:FREE_KEY_REL]->() RETURN count(r) AS cnt    | 3             |

  # ---------------------------------------------------------------------------
  # 6. 删除约束后底层索引同步被删除
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Key-06] after drop, backing index removed - <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    # ---- 验证索引存在 ----
    When executing query:
      """
      SHOW INDEXES YIELD name, type, entityType, labelsOrTypes, properties
      """
    Then the result should not be empty

    # ---- 删除约束 ----
    When executing query without error:
      """
      <dropCypher>
      """
    # ---- 验证索引已随约束删除 ----
    When executing query:
      """
      SHOW INDEXES YIELD name, type
      """
    Then the result count should be [<expectedIndexCountAfterDrop>]

    Examples:
      | entityType | createCypher                                                                                      | dropCypher                                    | expectedIndexCountAfterDrop |
      | node       | CREATE CONSTRAINT idxDropKeyNode FOR (n:IdxDropKeyNode) REQUIRE (n.uid) IS NODE KEY               | DROP CONSTRAINT idxDropKeyNode                | 2                           |
      | rel        | CREATE CONSTRAINT idxDropKeyRel FOR ()-[r:IDX_DROP_KEY_REL]-() REQUIRE (r.uid) IS RELATIONSHIP KEY | DROP CONSTRAINT idxDropKeyRel                 | 2                           |
