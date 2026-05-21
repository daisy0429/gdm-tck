# encoding: utf-8
#
# Constraint: creating on existing data scenarios
#
# 测试范围:
#   - 在已有重复数据上创建 UNIQUE 约束 -> 失败
#   - 在无重复数据上创建 UNIQUE 约束 -> 成功
#   - 在有 NULL 值的数据上创建 NOT NULL 约束 -> 失败
#   - 在无 NULL 值的数据上创建 NOT NULL 约束 -> 成功
#   - 在 key 属性含 NULL 的数据上创建 NODE KEY -> 失败
#   - 在 key 属性有重复的数据上创建 NODE KEY -> 失败
#   - 在类型不匹配的数据上创建 PROPERTY TYPE -> 失败
#   - 在类型匹配的数据上创建 PROPERTY TYPE -> 成功
#
# Neo4j 参考:
#   创建约束时需验证存量数据是否满足约束条件，不满足则创建失败。
#
@constraint @ddl
Feature: Constraint on existing data

  # ---------------------------------------------------------------------------
  # 1. 在已有重复数据上创建 UNIQUE 约束 -> 失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Existing-01] create UNIQUE on data with duplicates - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createConstraint>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | setupData                                                                                                                | createConstraint                                                                   |
      | node       | CREATE (:ExistDupNode {code: 'DUP'}), (:ExistDupNode {code: 'DUP'})                                                      | CREATE CONSTRAINT FOR (n:ExistDupNode) REQUIRE n.code IS UNIQUE                    |
      | rel        | CREATE (a:EDSrc1),(b:EDDst1),(c:EDSrc2),(d:EDDst2), (a)-[:EXIST_DUP {code:'DUP'}]->(b),(c)-[:EXIST_DUP {code:'DUP'}]->(d) | CREATE CONSTRAINT FOR ()-[r:EXIST_DUP]-() REQUIRE r.code IS UNIQUE                 |

  # ---------------------------------------------------------------------------
  # 2. 在无重复数据上创建 UNIQUE 约束 -> 成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Existing-02] create UNIQUE on data without duplicates - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createConstraint>
      """
    Then the side effects should be:
      | +constraints | 1 |

    Examples:
      | entityType | setupData                                                                                                                         | createConstraint                                                                        |
      | node       | CREATE (:ExistOkNode {code: 'A'}), (:ExistOkNode {code: 'B'})                                                                     | CREATE CONSTRAINT FOR (n:ExistOkNode) REQUIRE n.code IS UNIQUE                          |
      | rel        | CREATE (a:EOKSrc1),(b:EOKDst1),(c:EOKSrc2),(d:EOKDst2), (a)-[:EXIST_OK {code:'X'}]->(b),(c)-[:EXIST_OK {code:'Y'}]->(d)           | CREATE CONSTRAINT FOR ()-[r:EXIST_OK]-() REQUIRE r.code IS UNIQUE                       |

  # ---------------------------------------------------------------------------
  # 3. 在有 NULL 值的数据上创建 NOT NULL 约束 -> 失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Existing-03] create NOT NULL on data with NULL values - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createConstraint>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | setupData                                                                                                   | createConstraint                                                                      |
      | node       | CREATE (:ExistNullNode {name: NULL})                                                                         | CREATE CONSTRAINT FOR (n:ExistNullNode) REQUIRE n.name IS NOT NULL                    |
      | rel        | CREATE (a:ENSrc),(b:ENDst), (a)-[:EXIST_NULL {name: NULL}]->(b)                                              | CREATE CONSTRAINT FOR ()-[r:EXIST_NULL]-() REQUIRE r.name IS NOT NULL                 |

  # ---------------------------------------------------------------------------
  # 4. 在无 NULL 值的数据上创建 NOT NULL 约束 -> 成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Existing-04] create NOT NULL on data without NULL values - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createConstraint>
      """
    Then the side effects should be:
      | +constraints | 1 |

    Examples:
      | entityType | setupData                                                                                                    | createConstraint                                                                         |
      | node       | CREATE (:ExistNNNode {name: 'Alice'})                                                                        | CREATE CONSTRAINT FOR (n:ExistNNNode) REQUIRE n.name IS NOT NULL                         |
      | rel        | CREATE (a:ENNSrc),(b:ENNDst), (a)-[:EXIST_NN {name: 'Link'}]->(b)                                            | CREATE CONSTRAINT FOR ()-[r:EXIST_NN]-() REQUIRE r.name IS NOT NULL                      |

  # ---------------------------------------------------------------------------
  # 5. 在 key 属性含 NULL 的数据上创建 NODE KEY -> 失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Existing-05] create NODE KEY on data with NULL in key property - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createConstraint>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | setupData                                                                                                              | createConstraint                                                                                    |
      | node       | CREATE (:ExistNullKeyNode {k1: 'A', k2: NULL})                                                                         | CREATE CONSTRAINT FOR (n:ExistNullKeyNode) REQUIRE (n.k1, n.k2) IS NODE KEY                         |
      | rel        | CREATE (a:ENKSrc),(b:ENKDst), (a)-[:EXIST_NULL_KEY {k1: 'A', k2: NULL}]->(b)                                           | CREATE CONSTRAINT FOR ()-[r:EXIST_NULL_KEY]-() REQUIRE (r.k1, r.k2) IS NODE KEY                     |

  # ---------------------------------------------------------------------------
  # 6. 在 key 属性有重复的数据上创建 NODE KEY -> 失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Existing-06] create NODE KEY on data with duplicate key - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createConstraint>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | setupData                                                                                                                                        | createConstraint                                                                                      |
      | node       | CREATE (:ExistDupKeyNode {k1: 'X', k2: 'Y'}), (:ExistDupKeyNode {k1: 'X', k2: 'Y'})                                                              | CREATE CONSTRAINT FOR (n:ExistDupKeyNode) REQUIRE (n.k1, n.k2) IS NODE KEY                           |
      | rel        | CREATE (a:EDKSrc1),(b:EDKDst1),(c:EDKSrc2),(d:EDKDst2), (a)-[:EXIST_DUP_KEY {k1:'X',k2:'Y'}]->(b),(c)-[:EXIST_DUP_KEY {k1:'X',k2:'Y'}]->(d)      | CREATE CONSTRAINT FOR ()-[r:EXIST_DUP_KEY]-() REQUIRE (r.k1, r.k2) IS NODE KEY                       |

  # ---------------------------------------------------------------------------
  # 7. 在类型不匹配的数据上创建 PROPERTY TYPE -> 失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Existing-07] create PROPERTY TYPE on data with wrong type - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createConstraint>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | setupData                                                                                              | createConstraint                                                                          |
      | node       | CREATE (:ExistWrongTypeNode {score: 'not-a-number'})                                                   | CREATE CONSTRAINT FOR (n:ExistWrongTypeNode) REQUIRE n.score IS :: INTEGER                |
      | rel        | CREATE (a:EWTASrc),(b:EWTADst), (a)-[:EXIST_WRONG_TYPE {score: 'not-a-number'}]->(b)                    | CREATE CONSTRAINT FOR ()-[r:EXIST_WRONG_TYPE]-() REQUIRE r.score IS :: INTEGER            |

  # ---------------------------------------------------------------------------
  # 8. 在类型匹配的数据上创建 PROPERTY TYPE -> 成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Existing-08] create PROPERTY TYPE on data with correct type - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createConstraint>
      """
    Then the side effects should be:
      | +constraints | 1 |

    Examples:
      | entityType | setupData                                                                                         | createConstraint                                                                              |
      | node       | CREATE (:ExistOkTypeNode {score: 100})                                                             | CREATE CONSTRAINT FOR (n:ExistOkTypeNode) REQUIRE n.score IS :: INTEGER                       |
      | rel        | CREATE (a:EOTSrc),(b:EOTDst), (a)-[:EXIST_OK_TYPE {score: 100}]->(b)                               | CREATE CONSTRAINT FOR ()-[r:EXIST_OK_TYPE]-() REQUIRE r.score IS :: INTEGER                   |
