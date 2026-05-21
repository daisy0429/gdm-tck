# encoding: utf-8
#
# Constraint: Existence - violation scenarios
#
# 测试范围:
#   - CREATE node/rel without the required property -> error
#   - SET property to NULL on node/rel -> error
#   - REMOVE the required property -> error
#   - Update removing property via SET to null equivalent -> error
#
# Neo4j 参考:
#   Existence 约束要求属性值不为 NULL。
#   CREATE 时缺少属性、SET 为 NULL、REMOVE 属性均违反约束。
#
@constraint @ddl
Feature: Constraint existence - violation

  # ---------------------------------------------------------------------------
  # 1. CREATE node/rel without the required property -> error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Exist-01] create without required property on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>
      """
    When executing query:
      """
      <createWithoutProp>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createConstraint                                                                                    | createWithoutProp                                                       |
      | node       | CREATE CONSTRAINT existName FOR (n:MustHaveName) REQUIRE n.name IS NOT NULL                         | CREATE (:MustHaveName)                                                  |
      | rel        | CREATE CONSTRAINT existRef FOR ()-[r:REF_REL]-() REQUIRE r.ref IS NOT NULL                          | CREATE (a:RefSrc), (b:RefDst), (a)-[:REF_REL]->(b)                      |

  # ---------------------------------------------------------------------------
  # 2. SET property to NULL on node/rel -> error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Exist-02] set required property to NULL on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>;
      <insertWithProp>
      """
    When executing query:
      """
      <setToNull>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createConstraint                                                                                      | insertWithProp                                                                                      | setToNull                                                        |
      | node       | CREATE CONSTRAINT existTitle FOR (n:NullSetNode) REQUIRE n.title IS NOT NULL                          | CREATE (:NullSetNode {title: 'original'})                                                           | MATCH (n:NullSetNode) SET n.title = NULL                         |
      | rel        | CREATE CONSTRAINT existTag FOR ()-[r:TAGGED_REL]-() REQUIRE r.tag IS NOT NULL                         | CREATE (a:TagSrc),(b:TagDst), (a)-[:TAGGED_REL {tag: 'keep'}]->(b)                                  | MATCH ()-[r:TAGGED_REL]->() SET r.tag = NULL                     |

  # ---------------------------------------------------------------------------
  # 3. REMOVE the required property -> error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Exist-03] remove required property on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>;
      <insertWithProp>
      """
    When executing query:
      """
      <removeProp>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createConstraint                                                                                       | insertWithProp                                                                                    | removeProp                                                    |
      | node       | CREATE CONSTRAINT existField FOR (n:RemoveNode) REQUIRE n.field IS NOT NULL                            | CREATE (:RemoveNode {field: 'present'})                                                           | MATCH (n:RemoveNode) REMOVE n.field                           |
      | rel        | CREATE CONSTRAINT existRole FOR ()-[r:ROLE_REL]-() REQUIRE r.role IS NOT NULL                          | CREATE (a:RoleSrc),(b:RoleDst), (a)-[:ROLE_REL {role: 'admin'}]->(b)                              | MATCH ()-[r:ROLE_REL]->() REMOVE r.role                       |

  # ---------------------------------------------------------------------------
  # 4. Update removing property via SET to null equivalent -> error
  #    使用 SET n.prop = null 等价于 REMOVE，同样违反 Existence 约束
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Exist-04] update removing property via SET null on <entityType>
    Given an empty graph
    And having executed:
      """
      <createConstraint>;
      <insertWithProp>
      """
    When executing query:
      """
      <setNull>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createConstraint                                                                                      | insertWithProp                                                                                          | setNull                                                       |
      | node       | CREATE CONSTRAINT existVal FOR (n:SetNullNode) REQUIRE n.val IS NOT NULL                              | CREATE (:SetNullNode {val: 'hello'})                                                                    | MATCH (n:SetNullNode) SET n.val = null                        |
      | rel        | CREATE CONSTRAINT existKey FOR ()-[r:KEY_REL]-() REQUIRE r.key IS NOT NULL                            | CREATE (a:KeySrc),(b:KeyDst), (a)-[:KEY_REL {key: 'secret'}]->(b)                                       | MATCH ()-[r:KEY_REL]->() SET r.key = null                     |
