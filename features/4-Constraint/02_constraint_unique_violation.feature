# encoding: utf-8
#
# Constraint: Unique - violation scenarios
#
# 测试范围:
#   - INSERT duplicate property value on node/rel after constraint created
#   - UPDATE (SET) property to duplicate value
#   - Multiple NULL values are allowed (NULL != NULL)
#   - Empty string '' treated as real value, duplicate violates constraint
#   - Violation in batch: one bad statement in multi-statement batch
#
# Neo4j 参考:
#   Unique 约束允许多个 NULL 值存在（NULL != NULL）。
#   空字符串 '' 是合法属性值，重复空字符串违反唯一约束。
#
@constraint @ddl
Feature: Constraint unique - violation

  # ---------------------------------------------------------------------------
  # 1. INSERT duplicate property value after constraint created
  #    约束已存在，插入重复属性值应报 ConstraintValidationFailed
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Unique-01] insert duplicate property on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>;
      <insertFirst>
      """
    When executing query:
      """
      <insertDuplicate>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createConstraint                                                              | insertFirst                                                                 | insertDuplicate                                                                |
      | node       | CREATE CONSTRAINT uniqEmail FOR (n:UniquePerson) REQUIRE n.email IS UNIQUE   | CREATE (:UniquePerson {email: 'alice@test.com'})                            | CREATE (:UniquePerson {email: 'alice@test.com'})                               |
      | rel        | CREATE CONSTRAINT uniqStamp FOR ()-[r:STAMPED]-() REQUIRE r.stamp IS UNIQUE   | CREATE (a:StampSrc), (b:StampDst), (a)-[:STAMPED {stamp: 'S001'}]->(b)      | CREATE (c:StampSrc2), (d:StampDst2), (c)-[:STAMPED {stamp: 'S001'}]->(d)      |

  # ---------------------------------------------------------------------------
  # 2. UPDATE (SET) property to duplicate value
  #    约束已存在，通过 SET 将属性修改为已有值应报 ConstraintValidationFailed
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Unique-02] set property to duplicate value on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>;
      <insertData>
      """
    When executing query:
      """
      <updateDuplicate>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createConstraint                                                               | insertData                                                                                                     | updateDuplicate                                                                      |
      | node       | CREATE CONSTRAINT uniqCode FOR (n:SetTestNode) REQUIRE n.code IS UNIQUE       | CREATE (:SetTestNode {code: 'AAA'}), (:SetTestNode {code: 'BBB'})                                              | MATCH (n:SetTestNode {code: 'BBB'}) SET n.code = 'AAA'                               |
      | rel        | CREATE CONSTRAINT uniqToken FOR ()-[r:SET_REL]-() REQUIRE r.token IS UNIQUE   | CREATE (a:SetSrc1),(b:SetDst1),(c:SetSrc2),(d:SetDst2), (a)-[:SET_REL {token: 'T1'}]->(b),(c)-[:SET_REL {token: 'T2'}]->(d) | MATCH ()-[r:SET_REL {token: 'T2'}]->() SET r.token = 'T1'                |

  # ---------------------------------------------------------------------------
  # 3. Multiple NULL values are allowed by Unique constraint (NULL != NULL)
  #    多个 NULL 属性值不违反唯一约束，因为 NULL != NULL
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Unique-03] multiple NULL values allowed on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>;
      <insertFirstNull>
      """
    When executing query without error:
      """
      <insertSecondNull>
      """
    Then the side effects should be:
      | +nodes | <expectedNodes> |
      | +relationships | <expectedRels> |

    Examples:
      | entityType | createConstraint                                                                      | insertFirstNull                                                                      | insertSecondNull                                                                     | expectedNodes | expectedRels |
      | node       | CREATE CONSTRAINT nullableUniq FOR (n:NullTestNode) REQUIRE n.code IS UNIQUE         | CREATE (:NullTestNode {code: NULL})                                                  | CREATE (:NullTestNode {code: NULL})                                                  | 2             | 0            |
      | rel        | CREATE CONSTRAINT nullableRelUniq FOR ()-[r:NULL_REL]-() REQUIRE r.code IS UNIQUE    | CREATE (a:NullSrc1), (b:NullDst1), (a)-[:NULL_REL {code: NULL}]->(b)                 | CREATE (c:NullSrc2), (d:NullDst2), (c)-[:NULL_REL {code: NULL}]->(d)                 | 2             | 1            |

  # ---------------------------------------------------------------------------
  # 4. Empty string '' is treated as a real value, duplicate empty strings violate constraint
  #    空字符串 '' 是有效属性值，重复空字符串应违反唯一约束
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Unique-04] duplicate empty string violates constraint on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>;
      <insertEmpty>
      """
    When executing query:
      """
      <insertEmptyAgain>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createConstraint                                                                         | insertEmpty                                                                         | insertEmptyAgain                                                                    |
      | node       | CREATE CONSTRAINT emptyStrUniq FOR (n:EmptyStrNode) REQUIRE n.val IS UNIQUE              | CREATE (:EmptyStrNode {val: ''})                                                    | CREATE (:EmptyStrNode {val: ''})                                                    |
      | rel        | CREATE CONSTRAINT emptyRelStrUniq FOR ()-[r:EMPTY_REL]-() REQUIRE r.val IS UNIQUE        | CREATE (a:EmptySrc), (b:EmptyDst), (a)-[:EMPTY_REL {val: ''}]->(b)                  | CREATE (c:EmptySrc2), (d:EmptyDst2), (c)-[:EMPTY_REL {val: ''}]->(d)                |

  # ---------------------------------------------------------------------------
  # 5. Violation in batch: one bad statement in a multi-statement batch
  #    多语句批量执行中包含一条违反约束的语句，整个批次应失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Unique-05] violation in batch on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing queries:
      """
      <goodStatement>;
      <badStatement>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createConstraint                                                                      | goodStatement                                                        | badStatement                                                                 |
      | node       | CREATE CONSTRAINT batchUniq FOR (n:BatchNode) REQUIRE n.code IS UNIQUE               | CREATE (:BatchNode {code: 'OK1'})                                    | CREATE (:BatchNode {code: 'OK1'})                                            |
      | rel        | CREATE CONSTRAINT batchRelUniq FOR ()-[r:BATCH_REL]-() REQUIRE r.code IS UNIQUE      | CREATE (a:BtSrc),(b:BtDst), (a)-[:BATCH_REL {code: 'OK1'}]->(b)      | CREATE (c:BtSrc2),(d:BtDst2), (c)-[:BATCH_REL {code: 'OK1'}]->(d)            |
