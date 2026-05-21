# encoding: utf-8
#
# Constraint: error and edge case scenarios
#
# 测试范围:
#   - 在不存在的属性上创建约束 -> 成功（约束为 schema 级别）
#   - DROP CONSTRAINT 使用错误名称 -> 报错
#   - 无效语法创建约束 -> SyntaxError
#   - UNIQUE 约束后再创建同属性索引 -> 报错（索引已自动存在）
#   - 直接删除约束的自动索引 -> 报错
#   - 超长约束名 -> 应正常工作
#
# Neo4j 参考:
#   约束为 schema 级别，可在属性尚不存在时创建。
#   Unique 约束自动创建底层索引，不允许重复创建索引。
#   从属索引不能被直接删除，需通过删除约束间接删除。
#
@constraint @ddl
Feature: Constraint error and edge cases

  # ---------------------------------------------------------------------------
  # 1. 在不存在的属性上创建约束 -> 成功（约束为 schema 级别）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Error-01] create constraint on non-existent property - <entityType>
    Given an empty graph
    When executing query:
      """
      <createConstraint>
      """
    Then the side effects should be:
      | +constraints | 1 |

    Examples:
      | entityType | createConstraint                                                                                          |
      | node       | CREATE CONSTRAINT onMissingProp FOR (n:NoPropNode) REQUIRE n.futureProp IS UNIQUE                         |
      | rel        | CREATE CONSTRAINT onMissingPropRel FOR ()-[r:NO_PROP_REL]-() REQUIRE r.futureProp IS UNIQUE               |

  # ---------------------------------------------------------------------------
  # 2. DROP CONSTRAINT 使用错误名称 -> 报错
  # ---------------------------------------------------------------------------

  Scenario: [Error-02] DROP CONSTRAINT with wrong name
    Given an empty graph
    And having executed:
      """
      CREATE CONSTRAINT realConstraint FOR (n:WrongNameNode) REQUIRE n.code IS UNIQUE
      """
    When executing query:
      """
      DROP CONSTRAINT wrongConstraintName
      """
    Then an error should be raised

  # ---------------------------------------------------------------------------
  # 3. 无效语法创建约束 -> SyntaxError
  # ---------------------------------------------------------------------------

  Scenario: [Error-03] CREATE CONSTRAINT with invalid syntax
    Given an empty graph
    When executing query:
      """
      CREATE CONSTRAINT FOR (n:BadSyntax) REQUIRE n.prop UNIQUE
      """
    Then an error should be raised

  # ---------------------------------------------------------------------------
  # 4. UNIQUE 约束后再创建同属性索引 -> 报错（索引已自动存在）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Error-04] create index on same property after unique constraint - <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing query:
      """
      <createIndex>
      """
    Then an error should be raised

    Examples:
      | entityType | createConstraint                                                                                    | createIndex                                                                        |
      | node       | CREATE CONSTRAINT uniqWithIdx FOR (n:UniqIdxNode) REQUIRE n.code IS UNIQUE                         | CREATE INDEX FOR (n:UniqIdxNode) ON (n.code)                                       |
      | rel        | CREATE CONSTRAINT uniqWithIdxRel FOR ()-[r:UNIQ_IDX_REL]-() REQUIRE r.code IS UNIQUE               | CREATE INDEX FOR ()-[r:UNIQ_IDX_REL]-() ON (r.code)                                |

  # ---------------------------------------------------------------------------
  # 5. 直接删除约束的自动索引 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Error-05] drop auto-created backing index directly - <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing query:
      """
      DROP INDEX <backingIndexName>
      """
    Then an error should be raised

    Examples:
      | entityType | createConstraint                                                                                      | backingIndexName     |
      | node       | CREATE CONSTRAINT protectedIdx FOR (n:ProtIdxNode) REQUIRE n.code IS UNIQUE                          | protectedIdx         |
      | rel        | CREATE CONSTRAINT protectedIdxRel FOR ()-[r:PROT_IDX_REL]-() REQUIRE r.code IS UNIQUE                 | protectedIdxRel      |

  # ---------------------------------------------------------------------------
  # 6. 超长约束名 -> 应正常工作
  # ---------------------------------------------------------------------------

  Scenario Outline: [Error-06] very long constraint name - <entityType>
    Given an empty graph
    When executing query:
      """
      <createConstraint>
      """
    Then the side effects should be:
      | +constraints | 1 |
    When executing query without error:
      """
      DROP CONSTRAINT <longName> IF EXISTS
      """

    Examples:
      | entityType | createConstraint                                                                                                                                                                         | longName                                                                                                                                                                                 |
      | node       | CREATE CONSTRAINT a_very_long_constraint_name_that_tests_the_boundary_of_the_system_naming_limits_2024 FOR (n:LongNameNode) REQUIRE n.code IS UNIQUE                                     | a_very_long_constraint_name_that_tests_the_boundary_of_the_system_naming_limits_2024                                                                                                     |
      | rel        | CREATE CONSTRAINT a_very_long_constraint_name_that_tests_the_boundary_of_the_system_naming_limits_rel_2024 FOR ()-[r:LONG_NAME_REL]-() REQUIRE r.code IS UNIQUE                         | a_very_long_constraint_name_that_tests_the_boundary_of_the_system_naming_limits_rel_2024                                                                                                 |
