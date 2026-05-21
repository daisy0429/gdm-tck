# encoding: utf-8
#
# Constraint: SHOW CONSTRAINTS scenarios
#
# 测试范围:
#   - 无约束时 SHOW CONSTRAINTS 返回空
#   - 创建约束后 SHOW CONSTRAINTS 返回对应记录
#   - SHOW CONSTRAINTS YIELD 指定列
#   - SHOW CONSTRAINTS WHERE 过滤
#   - SHOW CONSTRAINTS RETURN 语法
#   - 多种约束类型共存时按类型过滤
#
# Neo4j 参考:
#   SHOW CONSTRAINTS
#   SHOW CONSTRAINTS YIELD name, type ...
#   SHOW CONSTRAINTS WHERE type = 'UNIQUENESS'
#   SHOW CONSTRAINTS RETURN name, type
#
@constraint @ddl
Feature: Show constraints

  # ---------------------------------------------------------------------------
  # 1. 无约束时 SHOW CONSTRAINTS 返回空
  # ---------------------------------------------------------------------------

  Scenario: [Show-01] SHOW CONSTRAINTS returns empty when no constraints
    Given an empty graph
    When executing query:
      """
      SHOW CONSTRAINTS YIELD name, type
      """
    Then the result count should be [0]

  # ---------------------------------------------------------------------------
  # 2. 创建约束后 SHOW CONSTRAINTS 返回对应记录
  # ---------------------------------------------------------------------------

  Scenario Outline: [Show-02] SHOW CONSTRAINTS returns created constraints on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing query:
      """
      SHOW CONSTRAINTS YIELD name, type
      """
    Then the result should not be empty

    Examples:
      | entityType | createConstraint                                                                      |
      | node       | CREATE CONSTRAINT showNode FOR (n:ShowNode) REQUIRE n.code IS UNIQUE                  |
      | rel        | CREATE CONSTRAINT showRel FOR ()-[r:SHOW_REL]-() REQUIRE r.code IS UNIQUE             |

  # ---------------------------------------------------------------------------
  # 3. SHOW CONSTRAINTS YIELD name, type (指定列)
  #    TODO: GDM 暂不支持 SHOW CONSTRAINTS YIELD 语法，待产品支持后取消注释
  # ---------------------------------------------------------------------------

  # Scenario: [Show-03] SHOW CONSTRAINTS YIELD specific columns
  #   Given an empty graph
  #   And having executed:
  #     """
  #     CREATE CONSTRAINT showYield FOR (n:ShowYieldNode) REQUIRE n.email IS UNIQUE
  #     """
  #   When executing query:
  #     """
  #     SHOW CONSTRAINTS YIELD name, type
  #     """
  #   Then the result should contain:
  #     | name | type |
  #     | 'showYield' | 'UNIQUENESS' |

  # ---------------------------------------------------------------------------
  # 4. SHOW CONSTRAINTS WHERE type = 'UNIQUENESS'
  #    TODO: GDM 暂不支持 SHOW CONSTRAINTS YIELD 语法，待产品支持后取消注释
  # ---------------------------------------------------------------------------

  # Scenario: [Show-04] SHOW CONSTRAINTS WHERE filter by type
  #   Given an empty graph
  #   And having executed:
  #     """
  #     CREATE CONSTRAINT showWhere FOR (n:ShowWhereNode) REQUIRE n.code IS UNIQUE
  #     """
  #   When executing query:
  #     """
  #     SHOW CONSTRAINTS YIELD name, type WHERE type = 'UNIQUENESS' RETURN name, type
  #     """
  #   Then the result should contain:
  #     | name | type |
  #     | 'showWhere' | 'UNIQUENESS' |

  # ---------------------------------------------------------------------------
  # 5. SHOW CONSTRAINTS RETURN name, type (alternate syntax)
  #    TODO: GDM 暂不支持 SHOW CONSTRAINTS YIELD 语法，待产品支持后取消注释
  # ---------------------------------------------------------------------------

  # Scenario: [Show-05] SHOW CONSTRAINTS RETURN alternate syntax
  #   Given an empty graph
  #   And having executed:
  #     """
  #     CREATE CONSTRAINT showReturn FOR (n:ShowReturnNode) REQUIRE n.code IS UNIQUE
  #     """
  #   When executing query:
  #     """
  #     SHOW CONSTRAINTS YIELD name, type RETURN name, type
  #     """
  #   Then the result should contain:
  #     | name | type |
  #     | 'showReturn' | 'UNIQUENESS' |

  # ---------------------------------------------------------------------------
  # 6. 多种约束类型共存时按类型过滤
  #    TODO: GDM 暂不支持 SHOW CONSTRAINTS YIELD 语法，待产品支持后取消注释
  # ---------------------------------------------------------------------------

  # Scenario: [Show-06] multiple constraint types filter by type
  #   Given an empty graph
  #   And having executed:
  #     """
  #     CREATE CONSTRAINT showUnique FOR (n:ShowMultiNode) REQUIRE n.code IS UNIQUE;
  #     CREATE CONSTRAINT showNotNull FOR (n:ShowMultiNode) REQUIRE n.name IS NOT NULL
  #     """
  #   When executing query:
  #     """
  #     SHOW CONSTRAINTS YIELD name, type WHERE type = 'UNIQUENESS' RETURN name, type
  #     """
  #   Then the result should contain:
  #     | name | type |
  #     | 'showUnique' | 'UNIQUENESS' |
  #   When executing query:
  #     """
  #     SHOW CONSTRAINTS YIELD name, type WHERE type = 'NODE_PROPERTY_EXISTENCE' RETURN name, type
  #     """
  #   Then the result should contain:
  #     | name | type |
  #     | 'showNotNull' | 'NODE_PROPERTY_EXISTENCE' |
