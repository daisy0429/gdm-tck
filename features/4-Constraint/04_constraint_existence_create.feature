# encoding: utf-8
#
# Constraint: Existence - create scenarios
#
# 测试范围:
#   - 节点/关系单属性 Existence 约束创建
#   - 命名约束 vs 不命名约束（系统自动生成名称）
#   - 创建后约束生效验证（有属性成功、无属性失败）
#   - 同 Label 多属性 Existence 约束共存
#   - 重复创建同名/同语义约束报错
#   - IF NOT EXISTS 幂等创建
#
# Neo4j 参考:
#   CREATE CONSTRAINT [name] FOR (n:Label)        REQUIRE n.prop IS NOT NULL
#   CREATE CONSTRAINT [name] FOR ()-[r:TYPE]-()   REQUIRE r.prop IS NOT NULL
#   Existence 约束要求写入时属性值不能为 NULL（属性必须存在且非 NULL）。
#
@constraint @ddl
Feature: Constraint existence - create

  # ---------------------------------------------------------------------------
  # 1. 基本创建：节点 + 关系合并验证
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Exist-01] single property existence constraint on <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |
    # TODO: GDM 暂不支持 SHOW CONSTRAINTS YIELD 语法，待产品支持后取消注释
    # When executing query:
    #   """
    #   SHOW CONSTRAINTS YIELD name, type, entityType, labelsOrTypes, properties
    #   """
    # Then the result should contain:
    #   | name | type | entityType | labelsOrTypes | properties |
    #   | '<constraintName>' | 'NODE_PROPERTY_EXISTENCE' | '<entityTypeExpected>' | '<labelsOrTypes>' | '<properties>' |

    Examples:
      | entityType | setupData                                                                   | createCypher                                                                         | constraintName | entityTypeExpected | labelsOrTypes     | properties |
      | node       | CREATE (:MustHaveEmail {email: 'a@b.com'})                                  | CREATE CONSTRAINT existEmail FOR (n:MustHaveEmail) REQUIRE n.email IS NOT NULL       | 'existEmail'   | 'NODE'             | ['MustHaveEmail'] | ['email']  |
      | rel        | CREATE (a:RelSrc), (b:RelDst), (a)-[:SENT_BY {stamp: 'x'}]->(b)             | CREATE CONSTRAINT existStamp FOR ()-[r:SENT_BY]-() REQUIRE r.stamp IS NOT NULL      | 'existStamp'   | 'RELATIONSHIP'     | ['SENT_BY']       | ['stamp']  |

  # ---------------------------------------------------------------------------
  # 2. 不命名的约束（系统自动生成名称）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Exist-02] unnamed existence constraint on <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |
    # TODO: GDM 暂不支持 SHOW CONSTRAINTS YIELD 语法，待产品支持后取消注释
    # When executing query:
    #   """
    #   SHOW CONSTRAINTS YIELD type, entityType, labelsOrTypes, properties
    #   """
    # Then the result should contain:
    #   | type | entityType | labelsOrTypes | properties |
    #   | 'NODE_PROPERTY_EXISTENCE' | '<entityTypeExpected>' | '<labelsOrTypes>' | '<properties>' |

    Examples:
      | entityType | createCypher                                                                 | entityTypeExpected | labelsOrTypes       | properties |
      | node       | CREATE CONSTRAINT FOR (n:AutoExistNode) REQUIRE n.code IS NOT NULL           | 'NODE'             | ['AutoExistNode']   | ['code']   |
      | rel        | CREATE CONSTRAINT FOR ()-[r:AUTO_EXIST_REL]-() REQUIRE r.token IS NOT NULL   | 'RELATIONSHIP'     | ['AUTO_EXIST_REL']  | ['token']  |

  # ---------------------------------------------------------------------------
  # 3. 创建后约束生效：insert WITH property succeeds, insert WITHOUT fails
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Exist-03] created constraint enforces existence on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query without error:
      """
      <insertWithProp>
      """
    Then the side effects should be:
      | +nodes | <compliantNodes> |
      | +relationships | <compliantRels> |
    When executing query:
      """
      <insertWithoutProp>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                              | insertWithProp                                                                          | insertWithoutProp                                                    | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT enforceExist FOR (n:RequiredField) REQUIRE n.name IS NOT NULL            | CREATE (:RequiredField {name: 'VALID'})                                                 | CREATE (:RequiredField)                                              | 1              | 0             |
      | rel        | CREATE CONSTRAINT enforceExistRel FOR ()-[r:ENFORCED_EXIST]-() REQUIRE r.code IS NOT NULL  | CREATE (a:ExSrc),(b:ExDst), (a)-[:ENFORCED_EXIST {code: 'V1'}]->(b)                     | CREATE (c:ExSrc2),(d:ExDst2), (c)-[:ENFORCED_EXIST]->(d)             | 2              | 1             |

  # ---------------------------------------------------------------------------
  # 4. 同一 Label/Type 上多个不同属性的 Existence 约束共存
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Exist-04] multiple existence constraints on same <entityType>
    Given an empty graph
    When executing query without error:
      """
      CREATE CONSTRAINT existFirstName FOR (n:MultiExistPerson) REQUIRE n.firstName IS NOT NULL
      """
    And executing query without error:
      """
      CREATE CONSTRAINT existLastName FOR (n:MultiExistPerson) REQUIRE n.lastName IS NOT NULL
      """

    # ---- 合规数据：两个属性都提供 -> 成功 ----
    When executing query without error:
      """
      CREATE (:MultiExistPerson {firstName: 'Alice', lastName: 'Smith'})
      """

    # ---- 缺少 firstName -> 报错 ----
    When executing query:
      """
      CREATE (:MultiExistPerson {lastName: 'Jones'})
      """
    Then a ConstraintValidationFailed should be raised at any time

    # ---- 缺少 lastName -> 报错 ----
    When executing query:
      """
      CREATE (:MultiExistPerson {firstName: 'Bob'})
      """
    Then a ConstraintValidationFailed should be raised at any time

    # ---- 两个属性都缺少 -> 报错 ----
    When executing query:
      """
      CREATE (:MultiExistPerson)
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType |
      | node       |

  # ---------------------------------------------------------------------------
  # 5. 重复创建同名约束应报错
  # error: GDM-METADATA-INVALID: metadata apply fatal: state_machine_diverged: metadata: constraint 'dupExistName' already exists in graph 'type01'
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Exist-05] duplicate named constraint raises error - <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query:
      """
      <createCypher>
      """
    Then an error should be raised

    Examples:
      | entityType | createCypher                                                                                    |
      | node       | CREATE CONSTRAINT dupExistName FOR (n:ExistDupNode) REQUIRE n.id IS NOT NULL                    |
      | rel        | CREATE CONSTRAINT dupExistName FOR ()-[r:EXIST_DUP_REL]-() REQUIRE r.id IS NOT NULL             |

  # ---------------------------------------------------------------------------
  # 6. 同语义不同名称应报错（相同 Label+Property）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Exist-06] same semantics different name raises error - <entityType>
    Given an empty graph
    And having executed:
      """
      <firstCreate>
      """
    When executing query:
      """
      <secondCreate>
      """
    Then an error should be raised

    Examples:
      | entityType | firstCreate                                                                               | secondCreate                                                                               |
      | node       | CREATE CONSTRAINT existFirst FOR (n:SemanticExist) REQUIRE n.code IS NOT NULL             | CREATE CONSTRAINT existSecond FOR (n:SemanticExist) REQUIRE n.code IS NOT NULL             |
      | rel        | CREATE CONSTRAINT existFirst FOR ()-[r:SEM_EXIST]-() REQUIRE r.code IS NOT NULL           | CREATE CONSTRAINT existSecond FOR ()-[r:SEM_EXIST]-() REQUIRE r.code IS NOT NULL           |

  # ---------------------------------------------------------------------------
  # 7. IF NOT EXISTS 幂等创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Exist-07] idempotent create with IF NOT EXISTS - <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query:
      """
      <createCypherIdempotent>
      """
    Then the side effects should be:
      | +constraints | 0 |

    Examples:
      | entityType | createCypher                                                                                      | createCypherIdempotent                                                                                                   |
      | node       | CREATE CONSTRAINT idempotentExist FOR (n:IdempotentExistNode) REQUIRE n.key IS NOT NULL           | CREATE CONSTRAINT idempotentExist IF NOT EXISTS FOR (n:IdempotentExistNode) REQUIRE n.key IS NOT NULL                    |
      | rel        | CREATE CONSTRAINT idempotentExist FOR ()-[r:IDEMPOTENT_EXIST]-() REQUIRE r.key IS NOT NULL        | CREATE CONSTRAINT idempotentExist IF NOT EXISTS FOR ()-[r:IDEMPOTENT_EXIST]-() REQUIRE r.key IS NOT NULL                 |

  # ---------------------------------------------------------------------------
  # 8. Existence 约束不创建底层索引
  #    与 Unique/Key/Composite 不同，Existence 约束不产生关联索引
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Exist-08] existence constraint does NOT create backing index on <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |
    When executing query:
      """
      SHOW INDEXES YIELD name
      """
    Then the result count should be [0]

    Examples:
      | entityType | createCypher                                                                        |
      | node       | CREATE CONSTRAINT noIdxExist FOR (n:NoIdxExistNode) REQUIRE n.code IS NOT NULL      |
      | rel        | CREATE CONSTRAINT noIdxExistRel FOR ()-[r:NO_IDX_EXIST]-() REQUIRE r.code IS NOT NULL |
