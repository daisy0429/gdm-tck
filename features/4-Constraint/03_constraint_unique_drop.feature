# encoding: utf-8
#
# Constraint: Unique - drop scenarios
#
# 测试范围:
#   - DROP CONSTRAINT by name on node/rel -> success
#   - DROP CONSTRAINT IF EXISTS when exists -> success
#   - DROP CONSTRAINT IF EXISTS when NOT exists -> no error
#   - DROP CONSTRAINT without IF EXISTS on non-existent name -> error
#   - After dropping constraint, previously violating data can be inserted
#   - After dropping unique constraint, backing index is also removed
#
# Neo4j 参考:
#   DROP CONSTRAINT name
#   DROP CONSTRAINT name IF EXISTS
#   删除 Unique 约束后，底层唯一索引同步被删除。
  # todo: 测试场景和验证点已验证无问题。待调试测试脚本。
#
@constraint @ddl
Feature: Constraint unique - drop

  # ---------------------------------------------------------------------------
  # 1. DROP CONSTRAINT by name -> success, constraint removed
  # ---------------------------------------------------------------------------
 # todo需要增加校验点。确实删成功了：show constraint where ..返回0
  Scenario Outline: [Drop-Unique-01] drop constraint by name on <entityType>
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
      | entityType | createConstraint                                                                      | constraintName   |
      | node       | CREATE CONSTRAINT dropByName FOR (n:DropNode) REQUIRE n.code IS UNIQUE                | dropByName       |
      | rel        | CREATE CONSTRAINT dropByNameRel FOR ()-[r:DROP_REL]-() REQUIRE r.code IS UNIQUE       | dropByNameRel    |

  # ---------------------------------------------------------------------------
  # 2. DROP CONSTRAINT IF EXISTS when constraint exists -> success
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Unique-02] drop constraint IF EXISTS when exists on <entityType>
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
      | entityType | createConstraint                                                                          | constraintName     |
      | node       | CREATE CONSTRAINT dropIfExists FOR (n:DropExistsNode) REQUIRE n.code IS UNIQUE            | dropIfExists       |
      | rel        | CREATE CONSTRAINT dropIfExistsRel FOR ()-[r:DROP_EXISTS_REL]-() REQUIRE r.code IS UNIQUE  | dropIfExistsRel    |

  # ---------------------------------------------------------------------------
  # 3. DROP CONSTRAINT IF EXISTS when constraint NOT exists -> no error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Unique-03] drop constraint IF EXISTS when not exists - <entityType>
    Given an empty graph
    When executing query without error:
      """
      DROP CONSTRAINT nonexistentUniq IF EXISTS
      """

    Examples:
      | entityType |
      | node       |
      | rel        |

  # ---------------------------------------------------------------------------
  # 4. DROP CONSTRAINT without IF EXISTS on non-existent name -> error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Unique-04] drop non-existent constraint without IF EXISTS - <entityType>
    Given an empty graph
    When executing query:
      """
      DROP CONSTRAINT totallyUnknownUniq
      """
    Then an error should be raised

    Examples:
      | entityType |
      | node       |
      | rel        |

  # ---------------------------------------------------------------------------
  # 5. After dropping constraint, previously violating data can be inserted
  #    删除约束后，原本违反约束的数据可以正常插入
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Unique-05] after drop, previously violating data can be inserted on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>;
      <insertFirst>
      """
    When executing query without error:
      """
      DROP CONSTRAINT <constraintName>
      """
    When executing query without error:
      """
      <insertDuplicate>
      """
    Then the side effects should be:
      | +nodes | <expectedNodes> |
      | +relationships | <expectedRels> |

    Examples:
      | entityType | createConstraint                                                                      | constraintName    | insertFirst                                                                    | insertDuplicate                                                                   | expectedNodes | expectedRels |
      | node       | CREATE CONSTRAINT dropFree FOR (n:FreeNode) REQUIRE n.code IS UNIQUE                  | dropFree          | CREATE (:FreeNode {code: 'DUP'})                                               | CREATE (:FreeNode {code: 'DUP'})                                                  | 1             | 0            |
      | rel        | CREATE CONSTRAINT dropFreeRel FOR ()-[r:FREE_REL]-() REQUIRE r.code IS UNIQUE         | dropFreeRel       | CREATE (a:FreeSrc),(b:FreeDst), (a)-[:FREE_REL {code: 'DUP'}]->(b)             | CREATE (c:FreeSrc2),(d:FreeDst2), (c)-[:FREE_REL {code: 'DUP'}]->(d)              | 2             | 1            |

  # ---------------------------------------------------------------------------
  # 6. After dropping unique constraint, backing index is also removed
  #    删除 Unique 约束后，底层唯一索引同步被删除（SHOW INDEXES 为空）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Drop-Unique-06] backing index removed after drop on <entityType>
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
      | entityType | createConstraint                                                                          | constraintName      |
      | node       | CREATE CONSTRAINT backingDropNode FOR (n:BackingDropNode) REQUIRE n.uid IS UNIQUE         | backingDropNode     |
      | rel        | CREATE CONSTRAINT backingDropRel FOR ()-[r:BACKING_DROP_REL]-() REQUIRE r.uid IS UNIQUE   | backingDropRel      |
