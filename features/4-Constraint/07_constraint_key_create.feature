# encoding: utf-8
#
# Constraint: Node Key / Relationship Key - create scenarios
#
# 测试范围:
#   - 节点/关系单属性 Node Key / Relationship Key 约束创建
#   - 多属性复合 Node Key / Relationship Key 约束创建
#   - 命名约束 vs 不命名约束
#   - 创建后约束生效验证（合规数据写入成功、重复/NULL 写入失败）
#   - 重复创建同名约束报错
#   - IF NOT EXISTS 幂等创建
#   - 存量合规数据上创建约束 -> 成功
#   - 存量违反数据（重复值/NULL）上创建约束 -> 失败
#   - 底层索引自动创建
#
# Neo4j 参考:
#   CREATE CONSTRAINT [name] FOR (n:Label) REQUIRE (n.prop1, n.prop2) IS NODE KEY
#   CREATE CONSTRAINT [name] FOR ()-[r:TYPE]-() REQUIRE (r.prop1, r.prop2) IS RELATIONSHIP KEY
#   Node Key = 复合 UNIQUE + NOT NULL，不允许 NULL 值，属性组合必须唯一
#
@constraint @ddl
Feature: Constraint node key / relationship key - create

  # ---------------------------------------------------------------------------
  # 1. 单属性 Node Key / Relationship Key 约束创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-01] single property node key / relationship key on <entityType>
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
    #   | '<constraintName>' | 'NODE_KEY' | '<entityTypeExpected>' | '<labelsOrTypes>' | '<properties>' |

    Examples:
      | entityType | setupData                                                                   | createCypher                                                                                 | constraintName | entityTypeExpected | labelsOrTypes    | properties |
      | node       | CREATE (:KeyPerson {email: 'a@b.com'})                                      | CREATE CONSTRAINT keyEmail FOR (n:KeyPerson) REQUIRE (n.email) IS NODE KEY                   | 'keyEmail'     | 'NODE'             | ['KeyPerson']    | ['email']  |
      | rel        | CREATE (a:SrcKey1), (b:DstKey1), (a)-[:KEY_REL {stamp: 'x'}]->(b)           | CREATE CONSTRAINT keyStamp FOR ()-[r:KEY_REL]-() REQUIRE (r.stamp) IS RELATIONSHIP KEY       | 'keyStamp'     | 'RELATIONSHIP'     | ['KEY_REL']      | ['stamp']  |

  # ---------------------------------------------------------------------------
  # 2. 多属性（2 个属性）复合 Node Key / Relationship Key 约束创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-02] multi-property node key / relationship key on <entityType>
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
    #   | '<constraintName>' | 'NODE_KEY' | '<entityTypeExpected>' | '<labelsOrTypes>' | '<properties>' |

    Examples:
      | entityType | setupData                                                                                      | createCypher                                                                                              | constraintName | entityTypeExpected | labelsOrTypes     | properties          |
      | node       | CREATE (:CompKeyPerson {firstName: 'Alice', lastName: 'Smith'})                                | CREATE CONSTRAINT compKey FOR (n:CompKeyPerson) REQUIRE (n.firstName, n.lastName) IS NODE KEY             | 'compKey'      | 'NODE'             | ['CompKeyPerson'] | ['firstName','lastName'] |
      | rel        | CREATE (a:CompKeySrc), (b:CompKeyDst), (a)-[:COMP_KEY_REL {src: 'A', dst: 'X'}]->(b)          | CREATE CONSTRAINT compKeyRel FOR ()-[r:COMP_KEY_REL]-() REQUIRE (r.src, r.dst) IS RELATIONSHIP KEY       | 'compKeyRel'   | 'RELATIONSHIP'     | ['COMP_KEY_REL']  | ['src','dst'] |

  # ---------------------------------------------------------------------------
  # 3. 命名 Node Key / Relationship Key 约束
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-03] named node key / relationship key on <entityType>
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
    #   SHOW CONSTRAINTS YIELD name, type, entityType
    #   """
    # Then the result should contain:
    #   | name | type | entityType |
    #   | '<constraintName>' | 'NODE_KEY' | '<entityTypeExpected>' |

    Examples:
      | entityType | createCypher                                                                                     | constraintName    | entityTypeExpected |
      | node       | CREATE CONSTRAINT namedKeyNode FOR (n:NamedKeyNode) REQUIRE (n.code) IS NODE KEY                 | 'namedKeyNode'    | 'NODE'             |
      | rel        | CREATE CONSTRAINT namedKeyRel FOR ()-[r:NAMED_KEY_REL]-() REQUIRE (r.token) IS RELATIONSHIP KEY  | 'namedKeyRel'     | 'RELATIONSHIP'     |

  # ---------------------------------------------------------------------------
  # 4. 创建后验证约束生效：合规数据写入成功，重复值/NULL 写入失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-04] created key constraint enforces on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query without error:
      """
      <insertCompliant>
      """
    Then the side effects should be:
      | +nodes | <compliantNodes> |
      | +relationships | <compliantRels> |
    When executing query:
      """
      <insertDuplicate>
      """
    Then a ConstraintValidationFailed should be raised at any time
    When executing query:
      """
      <insertNull>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                    | insertCompliant                                                                | insertDuplicate                                                               | insertNull                                                                    | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT enforceKey FOR (n:EnforcedKeyNode) REQUIRE (n.code) IS NODE KEY               | CREATE (:EnforcedKeyNode {code: 'VALID1'})                                     | CREATE (:EnforcedKeyNode {code: 'VALID1'})                                    | CREATE (:EnforcedKeyNode {code: null})                                        | 1              | 0             |
      | rel        | CREATE CONSTRAINT enforceKeyRel FOR ()-[r:ENFORCED_KEY]-() REQUIRE (r.code) IS RELATIONSHIP KEY | CREATE (a:EKSrc1), (b:EKDst1), (a)-[:ENFORCED_KEY {code: 'VALID1'}]->(b)       | CREATE (a:EKSrc2), (b:EKDst2), (a)-[:ENFORCED_KEY {code: 'VALID1'}]->(b)     | CREATE (a:EKSrc3), (b:EKDst3), (a)-[:ENFORCED_KEY {code: null}]->(b)         | 2              | 1             |

  # ---------------------------------------------------------------------------
  # 5. 重复创建同名约束应报错（不带 IF NOT EXISTS）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-05] duplicate named constraint raises error - <entityType>
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
      | node       | CREATE CONSTRAINT dupKeyConstraint FOR (n:KeyDup) REQUIRE (n.id) IS NODE KEY                    |
      | rel        | CREATE CONSTRAINT dupKeyConstraint FOR ()-[r:KEY_DUP]-() REQUIRE (r.id) IS RELATIONSHIP KEY     |

  # ---------------------------------------------------------------------------
  # 6. IF NOT EXISTS 幂等创建：约束已存在时不报错，不重复创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-06] idempotent create with IF NOT EXISTS - <entityType>
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
    # TODO: GDM 暂不支持 SHOW CONSTRAINTS YIELD 语法，待产品支持后取消注释
    # When executing query:
    #   """
    #   SHOW CONSTRAINTS YIELD name, type
    #   """
    # Then the result count should be [1]

    Examples:
      | entityType | createCypher                                                                                          | createCypherIdempotent                                                                                                          |
      | node       | CREATE CONSTRAINT idempotentKey FOR (n:IdempotentKeyNode) REQUIRE (n.key) IS NODE KEY                 | CREATE CONSTRAINT idempotentKey IF NOT EXISTS FOR (n:IdempotentKeyNode) REQUIRE (n.key) IS NODE KEY                             |
      | rel        | CREATE CONSTRAINT idempotentKey FOR ()-[r:IDEMPOTENT_KEY_REL]-() REQUIRE (r.key) IS RELATIONSHIP KEY  | CREATE CONSTRAINT idempotentKey IF NOT EXISTS FOR ()-[r:IDEMPOTENT_KEY_REL]-() REQUIRE (r.key) IS RELATIONSHIP KEY              |

  # ---------------------------------------------------------------------------
  # 7. 在已有满足 Key 约束数据上创建约束 — 应成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-07] create on existing compliant data - <entityType>
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
    #   SHOW CONSTRAINTS YIELD type
    #   """
    # Then the result count should be [1]

    Examples:
      | entityType | setupData                                                                                                                              | createCypher                                                                      |
      | node       | CREATE (:CompliantKeyNode {serialNo: 'SN001'}), (:CompliantKeyNode {serialNo: 'SN002'})                                                | CREATE CONSTRAINT FOR (n:CompliantKeyNode) REQUIRE (n.serialNo) IS NODE KEY       |
      | rel        | CREATE (a:TrkKSrc1),(b:TrkKDst1),(c:TrkKSrc2),(d:TrkKDst2), (a)-[:TRACKED_KEY {traceId: 'T1'}]->(b),(c)-[:TRACKED_KEY {traceId: 'T2'}]->(d) | CREATE CONSTRAINT FOR ()-[r:TRACKED_KEY]-() REQUIRE (r.traceId) IS RELATIONSHIP KEY |

  # ---------------------------------------------------------------------------
  # 8. 在已有重复值数据上创建 Key 约束 — 应失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-08] create on existing data with duplicate values - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createCypher>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | setupData                                                                                                                                     | createCypher                                                                       |
      | node       | CREATE (:DupKeyNode {dupCode: 'A'}), (:DupKeyNode {dupCode: 'A'})                                                                             | CREATE CONSTRAINT FOR (n:DupKeyNode) REQUIRE (n.dupCode) IS NODE KEY               |
      | rel        | CREATE (a:DupKSrc1),(b:DupKDst1),(c:DupKSrc2),(d:DupKDst2), (a)-[:DUP_KEY {ref: 'X'}]->(b),(c)-[:DUP_KEY {ref: 'X'}]->(d)                   | CREATE CONSTRAINT FOR ()-[r:DUP_KEY]-() REQUIRE (r.ref) IS RELATIONSHIP KEY        |

  # ---------------------------------------------------------------------------
  # 9. 在已有 NULL 值数据上创建 Key 约束 — 应失败
  #    Node Key 要求 NOT NULL，存量数据中有 NULL 则创建失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-09] create on existing data with NULL in key property - <entityType>
    Given an empty graph
    And having executed:
      """
      <setupData>
      """
    When executing query:
      """
      <createCypher>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | setupData                                                                                                                                  | createCypher                                                                           |
      | node       | CREATE (:NullKeyNode {code: 'OK'}), (:NullKeyNode {code: null})                                                                            | CREATE CONSTRAINT FOR (n:NullKeyNode) REQUIRE (n.code) IS NODE KEY                     |
      | rel        | CREATE (a:NullKSrc1),(b:NullKDst1),(c:NullKSrc2),(d:NullKDst2), (a)-[:NULL_KEY {code: 'OK'}]->(b),(c)-[:NULL_KEY {code: null}]->(d)       | CREATE CONSTRAINT FOR ()-[r:NULL_KEY]-() REQUIRE (r.code) IS RELATIONSHIP KEY          |

  # ---------------------------------------------------------------------------
  # 10. Node Key / Relationship Key 约束创建后底层自动创建关联索引
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Key-10] key constraint auto-creates backing index - <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |

    # ---- 验证从属索引已自动创建 ----
    When executing query:
      """
      SHOW INDEXES YIELD name, type, entityType, labelsOrTypes, properties
      """
    Then the result should not be empty

    # ---- 主动删除从属索引应报错拦截 ----
    When executing query:
      """
      DROP INDEX <backingIndexName>
      """
    Then an error should be raised

    # ---- 删除约束后，从属索引同步被删除 ----
    When executing query without error:
      """
      <dropConstraintCypher>
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, type
      """
    Then the result count should be [<expectedIndexCountAfterDrop>]

    Examples:
      | entityType | createCypher                                                                                  | backingIndexName | dropConstraintCypher                                       | expectedIndexCountAfterDrop |
      | node       | CREATE CONSTRAINT backingKeyNode FOR (n:BackingKeyNode) REQUIRE (n.uid) IS NODE KEY           | backingKeyNode   | DROP CONSTRAINT backingKeyNode IF EXISTS                   | 2                           |
      | rel        | CREATE CONSTRAINT backingKeyRel FOR ()-[r:BACKING_KEY_REL]-() REQUIRE (r.uid) IS RELATIONSHIP KEY | backingKeyRel | DROP CONSTRAINT backingKeyRel IF EXISTS                    | 2                           |
