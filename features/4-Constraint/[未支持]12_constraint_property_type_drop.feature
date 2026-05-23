# encoding: utf-8
#
# Constraint: Property Type - drop scenarios
#
# 测试范围:
#   - DROP CONSTRAINT by name -> 成功
#   - DROP CONSTRAINT IF EXISTS 存在时 -> 成功
#   - DROP CONSTRAINT IF EXISTS 不存在时 -> 无报错
#   - DROP CONSTRAINT 不带 IF EXISTS 不存在时 -> 报错
#   - 删除后错误类型数据可以写入
#
# Neo4j 参考:
#   DROP CONSTRAINT name
#   DROP CONSTRAINT name IF EXISTS
#
@constraint @ddl
Feature: Constraint property type - drop

  # ---------------------------------------------------------------------------
  # 1. DROP by name -> 成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Type-01] drop property type constraint by name - <entityType>
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
      | entityType | createCypher                                                                                       | dropCypher                                    |
      | node       | CREATE CONSTRAINT dropTypeNode FOR (n:DropTypeNode) REQUIRE n.code IS :: STRING                   | DROP CONSTRAINT dropTypeNode                  |
      | rel        | CREATE CONSTRAINT dropTypeRel FOR ()-[r:DROP_TYPE_REL]-() REQUIRE r.code IS :: STRING             | DROP CONSTRAINT dropTypeRel                   |

  # ---------------------------------------------------------------------------
  # 2. DROP IF EXISTS 约束存在时 -> 成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Type-02] drop property type constraint IF EXISTS when exists - <entityType>
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
      | entityType | createCypher                                                                                         | dropCypher                                             |
      | node       | CREATE CONSTRAINT dropIETypeNode FOR (n:DropIETypeNode) REQUIRE n.code IS :: STRING                  | DROP CONSTRAINT dropIETypeNode IF EXISTS               |
      | rel        | CREATE CONSTRAINT dropIETypeRel FOR ()-[r:DROP_IE_TYPE_REL]-() REQUIRE r.code IS :: STRING           | DROP CONSTRAINT dropIETypeRel IF EXISTS                |

  # ---------------------------------------------------------------------------
  # 3. DROP IF EXISTS 约束不存在时 -> 无报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Type-03] drop property type constraint IF EXISTS when not exists - <entityType>
    Given an empty graph
    When executing query without error:
      """
      <dropCypher>
      """
    Then the side effects should be:
      | +constraints | 0 |

    Examples:
      | entityType | dropCypher                                        |
      | node       | DROP CONSTRAINT nonexistentTypeNode IF EXISTS      |
      | rel        | DROP CONSTRAINT nonexistentTypeRel IF EXISTS       |

  # ---------------------------------------------------------------------------
  # 4. DROP 不带 IF EXISTS 约束不存在时 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Type-04] drop property type constraint without IF EXISTS on non-existent - <entityType>
    Given an empty graph
    When executing query:
      """
      <dropCypher>
      """
    Then an error should be raised

    Examples:
      | entityType | dropCypher                                |
      | node       | DROP CONSTRAINT missingTypeNode           |
      | rel        | DROP CONSTRAINT missingTypeRel            |

  # ---------------------------------------------------------------------------
  # 5. 删除后错误类型数据可以写入
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Type-05] after drop, wrong type data can be inserted - <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertCorrect>
      """
    # ---- 删除约束 ----
    When executing query without error:
      """
      <dropCypher>
      """
    # ---- 写入错误类型数据 -> 应成功 ----
    When executing query without error:
      """
      <insertWrongType>
      """
    # ---- 验证最终数据量 ----
    When executing query:
      """
      <countQuery>
      """
    Then the result should be:
      <expectedCount>

    Examples:
      | entityType | createCypher                                                                                       | insertCorrect                                                     | dropCypher                      | insertWrongType                                                         | countQuery                                                   | expectedCount |
      | node       | CREATE CONSTRAINT freeTypeNode FOR (n:FreeTypeNode) REQUIRE n.code IS :: STRING                   | CREATE (:FreeTypeNode {code: 'OK'})                               | DROP CONSTRAINT freeTypeNode    | CREATE (:FreeTypeNode {code: 123})                                      | MATCH (n:FreeTypeNode) RETURN count(n) AS cnt                | 2             |
      | rel        | CREATE CONSTRAINT freeTypeRel FOR ()-[r:FREE_TYPE_REL]-() REQUIRE r.code IS :: STRING             | CREATE (a:FTSrc1), (b:FTDst1), (a)-[:FREE_TYPE_REL {code: 'OK'}]->(b) | DROP CONSTRAINT freeTypeRel | CREATE (c:FTSrc2), (d:FTDst2), (c)-[:FREE_TYPE_REL {code: 123}]->(d) | MATCH ()-[r:FREE_TYPE_REL]->() RETURN count(r) AS cnt        | 2             |
