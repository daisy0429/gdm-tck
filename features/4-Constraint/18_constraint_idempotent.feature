# encoding: utf-8
#
# Constraint: IF EXISTS / IF NOT EXISTS idempotent scenarios
#
# 测试范围:
#   - CREATE UNIQUE constraint IF NOT EXISTS - 已存在 -> 不报错
#   - CREATE UNIQUE constraint IF NOT EXISTS - 不存在 -> 创建成功
#   - CREATE existence constraint IF NOT EXISTS - 已存在 -> 不报错
#   - CREATE node key IF NOT EXISTS - 已存在 -> 不报错
#   - CREATE property type IF NOT EXISTS - 已存在 -> 不报错
#   - DROP CONSTRAINT IF EXISTS - 存在 -> 成功
#   - DROP CONSTRAINT IF EXISTS - 不存在 -> 不报错
#   - DROP CONSTRAINT without IF EXISTS - 不存在 -> 报错
#
# Neo4j 参考:
#   CREATE CONSTRAINT name IF NOT EXISTS FOR ... -> 幂等创建
#   DROP CONSTRAINT name IF EXISTS -> 幂等删除
#
@constraint @ddl
Feature: Constraint idempotent operations

  # ---------------------------------------------------------------------------
  # 1. CREATE UNIQUE constraint IF NOT EXISTS - 已存在 -> 不报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Idempotent-01] CREATE UNIQUE IF NOT EXISTS when already exists - <entityType>
    Given an empty graph
    And having executed:
      """
      <createFirst>
      """
    When executing query:
      """
      <createAgain>
      """
    Then the side effects should be:
      | +constraints | 0 |

    Examples:
      | entityType | createFirst                                                                                          | createAgain                                                                                                                  |
      | node       | CREATE CONSTRAINT idemUniq FOR (n:IdemUniqNode) REQUIRE n.code IS UNIQUE                             | CREATE CONSTRAINT idemUniq IF NOT EXISTS FOR (n:IdemUniqNode) REQUIRE n.code IS UNIQUE                                       |
      | rel        | CREATE CONSTRAINT idemUniqRel FOR ()-[r:IDEM_UNIQ_REL]-() REQUIRE r.code IS UNIQUE                   | CREATE CONSTRAINT idemUniqRel IF NOT EXISTS FOR ()-[r:IDEM_UNIQ_REL]-() REQUIRE r.code IS UNIQUE                             |

  # ---------------------------------------------------------------------------
  # 2. CREATE UNIQUE constraint IF NOT EXISTS - 不存在 -> 创建成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Idempotent-02] CREATE UNIQUE IF NOT EXISTS when not exists - <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |

    Examples:
      | entityType | createCypher                                                                                                |
      | node       | CREATE CONSTRAINT idemNewUniq IF NOT EXISTS FOR (n:IdemNewNode) REQUIRE n.code IS UNIQUE                    |
      | rel        | CREATE CONSTRAINT idemNewUniqRel IF NOT EXISTS FOR ()-[r:IDEM_NEW_REL]-() REQUIRE r.code IS UNIQUE          |

  # ---------------------------------------------------------------------------
  # 3. CREATE existence constraint IF NOT EXISTS - 已存在 -> 不报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Idempotent-03] CREATE existence IF NOT EXISTS when already exists - <entityType>
    Given an empty graph
    And having executed:
      """
      <createFirst>
      """
    When executing query:
      """
      <createAgain>
      """
    Then the side effects should be:
      | +constraints | 0 |

    Examples:
      | entityType | createFirst                                                                                                  | createAgain                                                                                                                            |
      | node       | CREATE CONSTRAINT idemExist FOR (n:IdemExistNode) REQUIRE n.name IS NOT NULL                                | CREATE CONSTRAINT idemExist IF NOT EXISTS FOR (n:IdemExistNode) REQUIRE n.name IS NOT NULL                                             |
      | rel        | CREATE CONSTRAINT idemExistRel FOR ()-[r:IDEM_EXIST_REL]-() REQUIRE r.name IS NOT NULL                      | CREATE CONSTRAINT idemExistRel IF NOT EXISTS FOR ()-[r:IDEM_EXIST_REL]-() REQUIRE r.name IS NOT NULL                                   |

  # ---------------------------------------------------------------------------
  # 4. CREATE node key IF NOT EXISTS - 已存在 -> 不报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Idempotent-04] CREATE node key IF NOT EXISTS when already exists - <entityType>
    Given an empty graph
    And having executed:
      """
      <createFirst>
      """
    When executing query:
      """
      <createAgain>
      """
    Then the side effects should be:
      | +constraints | 0 |

    Examples:
      | entityType | createFirst                                                                                                      | createAgain                                                                                                                                               |
      | node       | CREATE CONSTRAINT idemNodeKey FOR (n:IdemNodeKeyNode) REQUIRE (n.k1, n.k2) IS NODE KEY                          | CREATE CONSTRAINT idemNodeKey IF NOT EXISTS FOR (n:IdemNodeKeyNode) REQUIRE (n.k1, n.k2) IS NODE KEY                                                     |
      | rel        | CREATE CONSTRAINT idemRelKey FOR ()-[r:IDEM_KEY_REL]-() REQUIRE (r.k1, r.k2) IS NODE KEY                        | CREATE CONSTRAINT idemRelKey IF NOT EXISTS FOR ()-[r:IDEM_KEY_REL]-() REQUIRE (r.k1, r.k2) IS NODE KEY                                                   |

  # ---------------------------------------------------------------------------
  # 5. CREATE property type IF NOT EXISTS - 已存在 -> 不报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Idempotent-05] CREATE property type IF NOT EXISTS when already exists - <entityType>
    Given an empty graph
    And having executed:
      """
      <createFirst>
      """
    When executing query:
      """
      <createAgain>
      """
    Then the side effects should be:
      | +constraints | 0 |

    Examples:
      | entityType | createFirst                                                                                              | createAgain                                                                                                                                        |
      | node       | CREATE CONSTRAINT idemType FOR (n:IdemTypeNode) REQUIRE n.score IS :: FLOAT                             | CREATE CONSTRAINT idemType IF NOT EXISTS FOR (n:IdemTypeNode) REQUIRE n.score IS :: FLOAT                                                          |
      | rel        | CREATE CONSTRAINT idemTypeRel FOR ()-[r:IDEM_TYPE_REL]-() REQUIRE r.score IS :: FLOAT                   | CREATE CONSTRAINT idemTypeRel IF NOT EXISTS FOR ()-[r:IDEM_TYPE_REL]-() REQUIRE r.score IS :: FLOAT                                                |

  # ---------------------------------------------------------------------------
  # 6. DROP CONSTRAINT IF EXISTS - 存在 -> 成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Idempotent-06] DROP CONSTRAINT IF EXISTS when exists - <entityType>
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
      | entityType | createConstraint                                                                                      | constraintName    |
      | node       | CREATE CONSTRAINT idemDrop FOR (n:IdemDropNode) REQUIRE n.code IS UNIQUE                              | idemDrop          |
      | rel        | CREATE CONSTRAINT idemDropRel FOR ()-[r:IDEM_DROP_REL]-() REQUIRE r.code IS UNIQUE                    | idemDropRel       |

  # ---------------------------------------------------------------------------
  # 7. DROP CONSTRAINT IF EXISTS - 不存在 -> 不报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Idempotent-07] DROP CONSTRAINT IF EXISTS when not exists - <entityType>
    Given an empty graph
    When executing query without error:
      """
      DROP CONSTRAINT noSuchConstraint IF EXISTS
      """

    Examples:
      | entityType |
      | node       |
      | rel        |

  # ---------------------------------------------------------------------------
  # 8. DROP CONSTRAINT without IF EXISTS - 不存在 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Idempotent-08] DROP CONSTRAINT without IF EXISTS on non-existent - <entityType>
    Given an empty graph
    When executing query:
      """
      DROP CONSTRAINT totallyMissing
      """
    Then an error should be raised

    Examples:
      | entityType |
      | node       |
      | rel        |
