# encoding: utf-8
#
# Constraint: Composite Property - drop scenarios
#
# 测试范围:
#   - DROP CONSTRAINT by name -> success
#   - DROP CONSTRAINT IF EXISTS when exists -> success
#   - DROP CONSTRAINT IF EXISTS when not exists -> no error
#   - DROP CONSTRAINT without IF EXISTS on non-existent -> error
#   - 删除约束后底层索引同步移除
#
# Neo4j 参考:
#   DROP CONSTRAINT name
#   DROP CONSTRAINT name IF EXISTS
#   删除 Composite Property 约束后，底层复合索引同步被删除。
#
@constraint @ddl
Feature: Constraint composite property - drop

  # ---------------------------------------------------------------------------
  # 1. DROP CONSTRAINT by name -> success
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Composite-01] drop composite constraint by name on <entityType>
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
      | entityType | createConstraint                                                                                                    | constraintName  |
      | node       | CREATE CONSTRAINT dropCompNode FOR (n:DropCompNode) REQUIRE (n.a, n.b) IS COMPOSITE PROPERTY                       | dropCompNode    |
      | rel        | CREATE CONSTRAINT dropCompRel FOR ()-[r:DROP_COMP_REL]-() REQUIRE (r.a, r.b) IS COMPOSITE PROPERTY                  | dropCompRel     |

  # ---------------------------------------------------------------------------
  # 2. DROP CONSTRAINT IF EXISTS when exists -> success
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Composite-02] drop composite constraint IF EXISTS when exists on <entityType>
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
      | entityType | createConstraint                                                                                                            | constraintName    |
      | node       | CREATE CONSTRAINT dropCompExists FOR (n:DropExistsCompNode) REQUIRE (n.x, n.y) IS COMPOSITE PROPERTY                       | dropCompExists    |
      | rel        | CREATE CONSTRAINT dropCompExistsRel FOR ()-[r:DROP_EXISTS_COMP]-() REQUIRE (r.x, r.y) IS COMPOSITE PROPERTY                 | dropCompExistsRel |

  # ---------------------------------------------------------------------------
  # 3. DROP CONSTRAINT IF EXISTS when NOT exists -> no error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Composite-03] drop composite constraint IF EXISTS when not exists - <entityType>
    Given an empty graph
    When executing query without error:
      """
      DROP CONSTRAINT nonexistentComp IF EXISTS
      """

    Examples:
      | entityType |
      | node       |
      | rel        |

  # ---------------------------------------------------------------------------
  # 4. DROP CONSTRAINT without IF EXISTS on non-existent -> error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Composite-04] drop non-existent composite constraint without IF EXISTS - <entityType>
    Given an empty graph
    When executing query:
      """
      DROP CONSTRAINT totallyUnknownComp
      """
    Then an error should be raised

    Examples:
      | entityType |
      | node       |
      | rel        |

  # ---------------------------------------------------------------------------
  # 5. 删除约束后底层索引同步移除
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Composite-05] backing index removed after drop composite constraint on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, type, entityType, labelsOrTypes, properties
      """
    Then the result should not be empty
    When executing query without error:
      """
      DROP CONSTRAINT <constraintName>
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, type, entityType, labelsOrTypes, properties
      """
    Then the result count should be [0]

    Examples:
      | entityType | createConstraint                                                                                                      | constraintName       |
      | node       | CREATE CONSTRAINT backingCompDrop FOR (n:BackingCompDrop) REQUIRE (n.f1, n.f2) IS COMPOSITE PROPERTY                  | backingCompDrop      |
      | rel        | CREATE CONSTRAINT backingCompDropRel FOR ()-[r:BACKING_COMP_DROP]-() REQUIRE (r.f1, r.f2) IS COMPOSITE PROPERTY        | backingCompDropRel   |
