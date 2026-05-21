# encoding: utf-8
#
# Constraint: Existence - drop scenarios
#
# 测试范围:
#   - DROP CONSTRAINT by name -> success
#   - DROP CONSTRAINT IF EXISTS when exists -> success
#   - DROP CONSTRAINT IF EXISTS when not exists -> no error
#   - DROP CONSTRAINT without IF EXISTS on non-existent -> error
#   - After dropping, insert without property succeeds
#
# Neo4j 参考:
#   DROP CONSTRAINT name
#   DROP CONSTRAINT name IF EXISTS
#   删除 Existence 约束后，属性不再是必须的。
#
@constraint @ddl
Feature: Constraint existence - drop

  # ---------------------------------------------------------------------------
  # 1. DROP CONSTRAINT by name -> success
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Exist-01] drop constraint by name on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing query:
      """
      DROP CONSTRAINT <constraintName>
      """
    Then the side effects should be:
      | +constraints | -1 |

    Examples:
      | entityType | createConstraint                                                                                    | constraintName    |
      | node       | CREATE CONSTRAINT dropExistNode FOR (n:DropExistNode) REQUIRE n.code IS NOT NULL                    | dropExistNode     |
      | rel        | CREATE CONSTRAINT dropExistRel FOR ()-[r:DROP_EXIST_REL]-() REQUIRE r.code IS NOT NULL              | dropExistRel      |

  # ---------------------------------------------------------------------------
  # 2. DROP CONSTRAINT IF EXISTS when exists -> success
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Exist-02] drop constraint IF EXISTS when exists on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing query without error:
      """
      DROP CONSTRAINT <constraintName> IF EXISTS
      """
    Then the side effects should be:
      | +constraints | -1 |

    Examples:
      | entityType | createConstraint                                                                                        | constraintName      |
      | node       | CREATE CONSTRAINT dropIfExistNode FOR (n:DropIfExistNode) REQUIRE n.code IS NOT NULL                    | dropIfExistNode     |
      | rel        | CREATE CONSTRAINT dropIfExistRel FOR ()-[r:DROP_IF_EXIST_REL]-() REQUIRE r.code IS NOT NULL             | dropIfExistRel      |

  # ---------------------------------------------------------------------------
  # 3. DROP CONSTRAINT IF EXISTS when not exists -> no error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Exist-03] drop constraint IF EXISTS when not exists - <entityType>
    Given an empty graph
    When executing query without error:
      """
      DROP CONSTRAINT nonexistentExist IF EXISTS
      """

    Examples:
      | entityType |
      | node       |
      | rel        |

  # ---------------------------------------------------------------------------
  # 4. DROP CONSTRAINT without IF EXISTS on non-existent -> error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Exist-04] drop non-existent constraint without IF EXISTS - <entityType>
    Given an empty graph
    When executing query:
      """
      DROP CONSTRAINT totallyUnknownExist
      """
    Then an error should be raised

    Examples:
      | entityType |
      | node       |
      | rel        |

  # ---------------------------------------------------------------------------
  # 5. After dropping, insert without property succeeds
  #    删除约束后，缺少属性的写入不再报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Exist-05] after drop, insert without property succeeds on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing query without error:
      """
      DROP CONSTRAINT <constraintName>
      """
    When executing query without error:
      """
      <insertWithoutProp>
      """
    Then the side effects should be:
      | +nodes | <expectedNodes> |
      | +relationships | <expectedRels> |

    Examples:
      | entityType | createConstraint                                                                                     | constraintName     | insertWithoutProp                                                    | expectedNodes | expectedRels |
      | node       | CREATE CONSTRAINT freeExist FOR (n:FreeExistNode) REQUIRE n.code IS NOT NULL                         | freeExist          | CREATE (:FreeExistNode)                                              | 1             | 0            |
      | rel        | CREATE CONSTRAINT freeExistRel FOR ()-[r:FREE_EXIST_REL]-() REQUIRE r.code IS NOT NULL               | freeExistRel       | CREATE (a:FreeSrc),(b:FreeDst), (a)-[:FREE_EXIST_REL]->(b)           | 2             | 1            |
