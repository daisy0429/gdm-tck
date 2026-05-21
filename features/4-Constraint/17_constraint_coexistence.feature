# encoding: utf-8
#
# Constraint: coexistence scenarios
#
# 测试范围:
#   - 同属性同时具有 UNIQUE 和 NOT NULL 约束 -> 两者都生效
#   - 同属性具有 UNIQUE + NOT NULL + 属性类型约束 -> 三者都生效
#   - 同 Label 不同属性具有不同约束类型 -> 互不干扰
#   - 删除一个约束不影响同 Label/属性上的其他约束
#
# Neo4j 参考:
#   同一属性可以同时拥有多种约束（如 UNIQUE + NOT NULL），各自独立生效。
#   删除其中一个约束不会影响其他约束的执行。
#
@constraint @ddl
Feature: Constraint coexistence

  # ---------------------------------------------------------------------------
  # 1. 同属性同时具有 UNIQUE 和 NOT NULL 约束 -> 两者都生效
  # ---------------------------------------------------------------------------

  Scenario Outline: [Coexist-01] same property with UNIQUE and NOT NULL on <entityType>
    Given an empty graph
    And having executed:
      """
      <createUnique>;
      <createNotNull>
      """
    # ---- 合规数据写入成功 ----
    When executing query without error:
      """
      <insertCompliant>
      """
    Then the side effects should be:
      | +nodes | <compliantNodes> |
      | +relationships | <compliantRels> |
    # ---- 违反唯一性 -> 报错 ----
    When executing query:
      """
      <insertDuplicate>
      """
    Then a ConstraintValidationFailed should be raised at any time
    # ---- 违反 NOT NULL (NULL 值) -> 报错 ----
    When executing query:
      """
      <insertNull>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createUnique                                                                                      | createNotNull                                                                                      | insertCompliant                                                          | insertDuplicate                                                          | insertNull                                                               | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT coexistUniq FOR (n:CoexistNode) REQUIRE n.code IS UNIQUE                       | CREATE CONSTRAINT coexistNN FOR (n:CoexistNode) REQUIRE n.code IS NOT NULL                         | CREATE (:CoexistNode {code: 'VALID'})                                    | CREATE (:CoexistNode {code: 'VALID'})                                    | CREATE (:CoexistNode {code: NULL})                                       | 1              | 0             |
      | rel        | CREATE CONSTRAINT coexistUniqRel FOR ()-[r:COEXIST_REL]-() REQUIRE r.code IS UNIQUE              | CREATE CONSTRAINT coexistNNRel FOR ()-[r:COEXIST_REL]-() REQUIRE r.code IS NOT NULL               | CREATE (a:CxSrc),(b:CxDst), (a)-[:COEXIST_REL {code:'OK'}]->(b)          | CREATE (c:CxSrc2),(d:CxDst2), (c)-[:COEXIST_REL {code:'OK'}]->(d)        | CREATE (e:CxSrc3),(f:CxDst3), (e)-[:COEXIST_REL {code:NULL}]->(f)        | 2              | 1             |

  # ---------------------------------------------------------------------------
  # 2. 同属性具有 UNIQUE + NOT NULL + 属性类型约束 -> 三者都生效
  # ---------------------------------------------------------------------------

  Scenario: [Coexist-02] same property with UNIQUE + NOT NULL + property type on node
    Given an empty graph
    And having executed:
      """
      CREATE CONSTRAINT tripleUniq FOR (n:TripleNode) REQUIRE n.email IS UNIQUE;
      CREATE CONSTRAINT tripleNN FOR (n:TripleNode) REQUIRE n.email IS NOT NULL;
      CREATE CONSTRAINT tripleType FOR (n:TripleNode) REQUIRE n.email IS :: STRING
      """
    # ---- 合规数据写入成功 ----
    When executing query without error:
      """
      CREATE (:TripleNode {email: 'user@test.com'})
      """
    Then the side effects should be:
      | +nodes | 1 |
    # ---- 违反唯一性 -> 报错 ----
    When executing query:
      """
      CREATE (:TripleNode {email: 'user@test.com'})
      """
    Then a ConstraintValidationFailed should be raised at any time
    # ---- 违反 NOT NULL -> 报错 ----
    When executing query:
      """
      CREATE (:TripleNode {email: NULL})
      """
    Then a ConstraintValidationFailed should be raised at any time
    # ---- 违反属性类型 -> 报错 ----
    When executing query:
      """
      CREATE (:TripleNode {email: 42})
      """
    Then a ConstraintValidationFailed should be raised at any time

  # ---------------------------------------------------------------------------
  # 3. 同 Label 不同属性具有不同约束类型 -> 互不干扰
  # ---------------------------------------------------------------------------

  Scenario: [Coexist-03] different properties with different constraint types on same label
    Given an empty graph
    And having executed:
      """
      CREATE CONSTRAINT diffUniq FOR (n:DiffPropNode) REQUIRE n.sku IS UNIQUE;
      CREATE CONSTRAINT diffNN FOR (n:DiffPropNode) REQUIRE n.name IS NOT NULL
      """
    # ---- sku 唯一, name 非 NULL -> 合规 ----
    When executing query without error:
      """
      CREATE (:DiffPropNode {sku: 'SKU001', name: 'Widget'})
      """
    Then the side effects should be:
      | +nodes | 1 |
    # ---- sku 重复 -> 报错 ----
    When executing query:
      """
      CREATE (:DiffPropNode {sku: 'SKU001', name: 'Other'})
      """
    Then a ConstraintValidationFailed should be raised at any time
    # ---- name 为 NULL -> 报错 ----
    When executing query:
      """
      CREATE (:DiffPropNode {sku: 'SKU002', name: NULL})
      """
    Then a ConstraintValidationFailed should be raised at any time
    # ---- sku 不同, name 非 NULL -> 合规 ----
    When executing query without error:
      """
      CREATE (:DiffPropNode {sku: 'SKU002', name: 'Gadget'})
      """
    Then the side effects should be:
      | +nodes | 1 |

  # ---------------------------------------------------------------------------
  # 4. 删除一个约束不影响同 Label/属性上的其他约束
  # ---------------------------------------------------------------------------

  Scenario: [Coexist-04] drop one constraint does not affect others
    Given an empty graph
    And having executed:
      """
      CREATE CONSTRAINT dropOneUniq FOR (n:DropOneNode) REQUIRE n.code IS UNIQUE;
      CREATE CONSTRAINT dropOneNN FOR (n:DropOneNode) REQUIRE n.code IS NOT NULL
      """
    # ---- 删除 UNIQUE 约束 ----
    When executing query without error:
      """
      DROP CONSTRAINT dropOneUniq
      """
    # ---- NOT NULL 约束仍然生效: NULL 值写入应报错 ----
    When executing query:
      """
      CREATE (:DropOneNode {code: NULL})
      """
    Then a ConstraintValidationFailed should be raised at any time
    # ---- UNIQUE 已删除: 重复值可写入（NOT NULL 通过） ----
    When executing query without error:
      """
      CREATE (:DropOneNode {code: 'A'});
      CREATE (:DropOneNode {code: 'A'})
      """
    Then the side effects should be:
      | +nodes | 2 |
