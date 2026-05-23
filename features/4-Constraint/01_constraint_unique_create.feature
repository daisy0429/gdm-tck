# encoding: utf-8
#
# Constraint: Unique - create scenarios
#
# 测试范围:
#   - 节点/关系单属性 Unique 约束创建（Scenario Outline 合并 node/rel）
#   - 命名约束 vs 不命名约束
#   - 创建后约束生效验证（合规数据写入成功、违反数据写入失败）
#   - 同 Label 多属性约束共存
#   - 复合属性组合值唯一性验证
#   - 重复创建同名/同语义约束报错
#   - IF NOT EXISTS 幂等创建
#   - 存量合规/违反数据上创建约束
#   - 底层索引联动验证
#   - 多数据类型覆盖（string/int/float/bool/time/point/list/vector）
#
# Neo4j 参考:
#   CREATE CONSTRAINT [name] FOR (n:Label)        REQUIRE n.prop       IS UNIQUE
#   CREATE CONSTRAINT [name] FOR ()-[r:TYPE]-()   REQUIRE r.prop IS UNIQUE
#   Unique 约束自动创建底层唯一索引，允许多个 NULL 值存在。
#
@constraint @ddl
Feature: Constraint unique - create

  # ---------------------------------------------------------------------------
  # 1. 基本创建：节点 + 关系合并验证
  #    利用 Scenario Outline 的 Examples 区分 entityType，一份逻辑覆盖两种实体
  #    创建约束后，通过 SHOW CONSTRAINTS 验证约束元数据（名称、类型、实体类型、属性）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-01] single property unique constraint on <entityType>
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
    #   | '<constraintName>' | 'UNIQUENESS' | '<entityTypeExpected>' | '<labelsOrTypes>' | '<properties>' |

    Examples:
      | entityType | setupData                                                              | createCypher                                                                  | constraintName | entityTypeExpected | labelsOrTypes    | properties |
      | node       | CREATE (:UniquePerson {email: 'a@b.com'})                              | CREATE CONSTRAINT uniqueEmail FOR (n:UniquePerson) REQUIRE n.email IS UNIQUE  | 'uniqueEmail'  | 'NODE'             | ['UniquePerson'] | ['email']  |
      | rel        | CREATE (a:SentBySrc), (b:SentByDst), (a)-[:SENT_BY {stamp: 'x'}]->(b); | CREATE CONSTRAINT uniqueStamp FOR ()-[r:SENT_BY]-() REQUIRE r.stamp IS UNIQUE | 'uniqueStamp'  | 'RELATIONSHIP'     | ['SENT_BY']      | ['stamp']  |

  # ---------------------------------------------------------------------------
  # 2. 不命名的约束（由系统自动生成名称）/支持在不存在的标签表关系表属性上提前创建约束。
  #    验证省略约束名时系统能自动命名并正确创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-02] unnamed unique constraint on <entityType>
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
    #   | 'UNIQUENESS' | '<entityTypeExpected>' | '<labelsOrTypes>' | '<properties>' |

    Examples:
      | entityType | createCypher                                                        | entityTypeExpected | labelsOrTypes      | properties |
      | node       | CREATE CONSTRAINT FOR (n:UniqueAutoNode) REQUIRE n.code IS UNIQUE   | 'NODE'             | ['UniqueAutoNode'] | ['code']   |
      | rel        | CREATE CONSTRAINT FOR ()-[r:LINKED_BY]-() REQUIRE r.token IS UNIQUE | 'RELATIONSHIP'     | ['LINKED_BY']      | ['token']  |

  # ---------------------------------------------------------------------------
  # 3. 创建约束后，验证约束生效
  #    约束创建成功后，合规数据写入应成功，违反唯一性的数据写入应失败
  #    即：约束不仅是元数据，还要实际拦截非法写入
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-03] created constraint enforces uniqueness on <entityType>
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
      <insertViolating>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                     | insertCompliant                                                             | insertViolating                                                            | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT enforceNode FOR (n:EnforcedNode) REQUIRE n.code IS UNIQUE      | CREATE (:EnforcedNode {code: 'VALID1'})                                     | CREATE (:EnforcedNode {code: 'VALID1'})                                    | 1              | 0             |
      | rel        | CREATE CONSTRAINT enforceRel FOR ()-[r:ENFORCED_REL]-() REQUIRE r.code IS UNIQUE | CREATE (a:EnfSrc1), (b:EnfDst1) , (a)-[:ENFORCED_REL {code: 'VALID1'}]->(b) | CREATE (a:EnfSrc2), (b:EnfDst2), (a)-[:ENFORCED_REL {code: 'VALID1'}]->(b) | 2              | 1             |


  # todo 04和05有啥区别
  # ---------------------------------------------------------------------------
  # 4. 同一 Label/Type 上多个不同属性的 Unique 约束共存
  #    验证同一实体上不同属性各自创建 Unique 约束，互不冲突
  #    并验证：约束生效时违规写入失败、合规写入成功；删除约束后违规写入成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-04] multiple unique constraints on same <entityType>
    Given an empty graph
    When executing query without error:
      """
      CREATE CONSTRAINT uniqProdSku FOR (n:Product) REQUIRE n.sku IS UNIQUE
      """
    And executing query without error:
      """
      CREATE CONSTRAINT uniqProdBarcode FOR (n:Product) REQUIRE n.barcode IS UNIQUE
      """
    # TODO: GDM 暂不支持 SHOW CONSTRAINTS YIELD 语法，待产品支持后取消注释
    # When executing query:
    #   """
    #   SHOW CONSTRAINTS YIELD name, type, properties
    #   """
    # Then the result should contain:
    #   | name | type | properties |
    #   | 'uniqProdSku' | 'UNIQUENESS' | ['sku'] |
    #   | 'uniqProdBarcode' | 'UNIQUENESS' | ['barcode'] |

    # ---- 约束生效：写入合规数据成功 ----
    When executing queries without error:
      """
      CREATE (:Product{name:"商品1",sku:"sku0001",barcode:"barcode0001"});
      CREATE (:Product{name:"商品2",sku:"sku0002",barcode:"barcode0002"});
      CREATE (:Product{name:"商品3",sku:"sku0003",barcode:"barcode0003"})
      """

    # ---- 约束生效：SKU 重复 -> 报错 ----
    When executing query:
      """
      CREATE (:Product{name:"重复SKU商品",sku:"sku0001",barcode:"barcode0009"})
      """
    Then a ConstraintValidationFailed should be raised at any time

    # ---- 约束生效：barcode 重复 -> 报错 ----
    When executing query:
      """
      CREATE (:Product{name:"重复条码商品",sku:"sku0009",barcode:"barcode0001"})
      """
    Then a ConstraintValidationFailed should be raised at any time

    # ---- 约束生效：sku 和 barcode 均重复 -> 报错 ----
    When executing query:
      """
      CREATE (:Product{name:"全重复商品",sku:"sku0001",barcode:"barcode0001"})
      """
    Then a ConstraintValidationFailed should be raised at any time

    # ---- 约束生效：sku 和 barcode 均不重复 -> 写入成功 ----
    When executing query without error:
      """
      CREATE (:Product{name:"不重复商品",sku:"sku0004",barcode:"barcode0004"})
      """

    # ---- 验证最终数据量 = 4 ----
    When executing query:
      """
      MATCH (n:Product) RETURN count(n) AS cnt
      """
    Then the result should be:
      4

    # ---- 删除约束后，原违规数据可以写入 ----
    When executing queries without error:
      """
      DROP CONSTRAINT uniqProdSku IF EXISTS;
      DROP CONSTRAINT uniqProdBarcode IF EXISTS
      """
    When executing query without error:
      """
      CREATE (:Product{name:"约束删除后-重复SKU",sku:"sku0001",barcode:"barcode0099"})
      """
    When executing query:
      """
      MATCH (n:Product) RETURN count(n) AS cnt
      """
    Then the result should be:
      5

    Examples:
      | entityType |
      | node       |

  # ---------------------------------------------------------------------------
  # 5. 复合属性组合值唯一性验证
  #    单属性 Unique 约束只看单个属性值，两个属性各自 Unique 不等于组合唯一。
  #    本场景验证：属性 A 和 B 各自有 Unique 约束时，(A, B) 组合值的唯一性
  #    由各自约束独立保证，而非组合约束。用于区分 Unique 与 Node Key 语义。
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-05] composite property uniqueness - separate constraints on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher1>;
      <createCypher2>
      """
    When executing query without error:
      """
      <insertDistinctCombo>
      """
    Then the side effects should be:
      | +nodes | <compliantNodes> |
      | +relationships | <compliantRels> |

    Examples:
      | entityType | createCypher1                                                                         | createCypher2                                                                       | insertDistinctCombo                                                                         | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT uniqFirstName FOR (n:CompositePerson) REQUIRE n.firstName IS UNIQUE | CREATE CONSTRAINT uniqLastName FOR (n:CompositePerson) REQUIRE n.lastName IS UNIQUE | CREATE (:CompositePerson {firstName: 'Alice', lastName: 'Smith'})                           | 1              | 0             |
      | rel        | CREATE CONSTRAINT uniqSrc FOR ()-[r:COMPOSITE_REL]-() REQUIRE r.src IS UNIQUE         | CREATE CONSTRAINT uniqDst FOR ()-[r:COMPOSITE_REL]-() REQUIRE r.dst IS UNIQUE       | CREATE (a:CompRelSrc), (b:CompRelDst), (a)-[:COMPOSITE_REL {src: 'A', dst: 'X'}]->(b) | 2              | 1             |

  # ---------------------------------------------------------------------------
  # 6. 重复创建同名约束应报错（不带 IF NOT EXISTS）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-06] duplicate named constraint raises error - <entityType>
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
      | entityType | createCypher                                                                        |
      | node       | CREATE CONSTRAINT dupNameConstraint FOR (n:UniqueDup) REQUIRE n.id IS UNIQUE        |
      | rel        | CREATE CONSTRAINT dupNameConstraint FOR ()-[r:UNIQUE_DUP]-() REQUIRE r.id IS UNIQUE |

  # ---------------------------------------------------------------------------
  # 7. 重复创建同语义约束（不同名称，相同 Label+Property）应报错
  #    首次创建用 having executed（Given 前置），第二次用 executing query（When 触发错误）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-07] same semantics different name raises error - <entityType>
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
      | entityType | firstCreate                                                                    | secondCreate                                                                    |
      | node       | CREATE CONSTRAINT uniqFirst FOR (n:SemanticOverlap) REQUIRE n.code IS UNIQUE   | CREATE CONSTRAINT uniqSecond FOR (n:SemanticOverlap) REQUIRE n.code IS UNIQUE   |
      | rel        | CREATE CONSTRAINT uniqFirst FOR ()-[r:SEM_OVERLAP]-() REQUIRE r.code IS UNIQUE | CREATE CONSTRAINT uniqSecond FOR ()-[r:SEM_OVERLAP]-() REQUIRE r.code IS UNIQUE |

  # ---------------------------------------------------------------------------
  # 8. IF NOT EXISTS 幂等创建：约束已存在时不报错，不重复创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-08] idempotent create with IF NOT EXISTS - <entityType>
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
      | entityType | createCypher                                                                          | createCypherIdempotent                                                                                     |
      | node       | CREATE CONSTRAINT idempotentUniq FOR (n:IdempotentNode) REQUIRE n.key IS UNIQUE       | CREATE CONSTRAINT idempotentUniq IF NOT EXISTS FOR (n:IdempotentNode) REQUIRE n.key IS UNIQUE              |
      | rel        | CREATE CONSTRAINT idempotentUniq FOR ()-[r:IDEMPOTENT_REL]-() REQUIRE r.key IS UNIQUE | CREATE CONSTRAINT idempotentUniq IF NOT EXISTS FOR ()-[r:IDEMPOTENT_REL]-() REQUIRE r.key IS UNIQUE        |

  # ---------------------------------------------------------------------------
  # 9. 在已有满足唯一性数据上创建 Unique 约束 — 应成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-09] create on existing compliant data - <entityType>
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
      | entityType | setupData                                                                                                                             | createCypher                                                         |
      | node       | CREATE (:CompliantNode {serialNo: 'SN001'}), (:CompliantNode {serialNo: 'SN002'})                                                     | CREATE CONSTRAINT FOR (n:CompliantNode) REQUIRE n.serialNo IS UNIQUE |
      | rel        | CREATE (a:TrkSrc1),(b:TrkDst1),(c:TrkSrc2),(d:TrkDst2) , (a)-[:TRACKED {traceId: 'T1'}]->(b),(c)-[:TRACKED {traceId: 'T2'}]->(d) | CREATE CONSTRAINT FOR ()-[r:TRACKED]-() REQUIRE r.traceId IS UNIQUE  |

  # ---------------------------------------------------------------------------
  # 10. 在已有违反唯一性数据上创建 Unique 约束 — 应失败
  #     重复值已存在于图中，创建约束时需要验证存量数据
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-10] create on existing violating data - <entityType>
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
      | entityType | setupData                                                                                                                       | createCypher                                                      |
      | node       | CREATE (:ViolateNode {dupCode: 'A'}), (:ViolateNode {dupCode: 'A'})                                                             | CREATE CONSTRAINT FOR (n:ViolateNode) REQUIRE n.dupCode IS UNIQUE |
      | rel        | CREATE (a:DupSrc1),(b:DupDst1),(c:DupSrc2),(d:DupDst2) , (a)-[:DUPLICATE {ref: 'X'}]->(b),(c)-[:DUPLICATE {ref: 'X'}]->(d) | CREATE CONSTRAINT FOR ()-[r:DUPLICATE]-() REQUIRE r.ref IS UNIQUE |

  # ---------------------------------------------------------------------------
  # 11. 创建 Unique 约束后，底层自动创建关联索引 — 联动验证
  #    验证点:
  #    a) 创建约束后从属索引自动存在
  #    b) 主动删从属索引应报错拦截
  #    c) 删约束后从属索引同步被删除
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-11] unique constraint auto-creates backing index - <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |

    # ---- a) 验证从属索引已自动创建 ----
    When executing query:
      """
      SHOW INDEXES YIELD name, type, entityType, labelsOrTypes, properties
      """
    Then the result should not be empty

    # ---- b) 主动删除从属索引应报错拦截 ----
    When executing query:
      """
      DROP INDEX <backingIndexName>
      """
    Then an error should be raised

    # ---- c) 删除约束后，从属索引同步被删除 ----
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
      | entityType | createCypher                                                                      | backingIndexName   | dropConstraintCypher                                    | expectedIndexCountAfterDrop |
      | node       | CREATE CONSTRAINT backingIdxNode FOR (n:BackingNode) REQUIRE n.uid IS UNIQUE      | backingIdxNode     | DROP CONSTRAINT backingIdxNode IF EXISTS                | 2                           |
      | rel        | CREATE CONSTRAINT backingIdxRel FOR ()-[r:BACKING_REL]-() REQUIRE r.uid IS UNIQUE | backingIdxRel      | DROP CONSTRAINT backingIdxRel IF EXISTS                 | 2                           |

  # ---------------------------------------------------------------------------
  # 12. 基本数据类型属性的 Unique 约束 — string/int/float/bool
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-12] unique constraint on basic <datatype> property
    Given an empty graph
    And having executed:
      """
      CREATE (:TypedUnique {prop: <sampleValue>})
      """
    When executing query:
      """
      CREATE CONSTRAINT typedUniqProp FOR (n:TypedUnique) REQUIRE n.prop IS UNIQUE
      """
    Then the side effects should be:
      | +constraints | 1 |
    # ---- 验证约束生效：写入不重复值成功 ----
    When executing query without error:
      """
      CREATE (:TypedUnique {prop: <sampleValue2>})
      """
    Then the side effects should be:
      | +nodes | 1 |
    # ---- 验证约束生效：写入重复值失败 ----
    When executing query:
      """
      CREATE (:TypedUnique {prop: <sampleValue>})
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | datatype | sampleValue | sampleValue2 |
      | string   | 'hello'     | 'world'      |
      | int      | 42          | 99           |
      | float    | 3.14        | 2.71         |
      | bool     | true        | false        |

  # ---------------------------------------------------------------------------
  # 13. 时间类型属性的 Unique 约束 — date/time/datetime/localtime/localdatetime/duration
  # ---------------------------------------------------------------------------
  Scenario Outline: [Create-Unique-13] unique constraint on time <datatype> property
    Given an empty graph
    And having executed:
      """
      CREATE (:TimeUnique {prop: <sampleValue>})
      """
    When executing query:
      """
      CREATE CONSTRAINT timeUniqProp FOR (n:TimeUnique) REQUIRE n.prop IS UNIQUE
      """
    Then the side effects should be:
      | +constraints | 1 |
    # ---- 验证约束生效：写入不重复值成功 ----
    When executing query without error:
      """
      CREATE (:TimeUnique {prop: <sampleValue2>})
      """
    Then the side effects should be:
      | +nodes | 1 |
    # ---- 验证约束生效：写入重复值失败 ----
    When executing query:
      """
      CREATE (:TimeUnique {prop: <sampleValue>})
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | datatype      | sampleValue                          | sampleValue2                         |
      | date          | date('2024-01-15')                   | date('2025-02-20')                   |
      | time          | time('12:30:00')                     | time('18:45:00')                     |
      | datetime      | datetime('2024-01-15T12:30:00Z')     | datetime('2025-06-01T08:00:00Z')     |
      | localtime     | localtime('12:30:00')                | localtime('23:59:59')                |
      | localdatetime | localdatetime('2024-01-15T12:30:00') | localdatetime('2025-06-01T08:00:00') |
      | duration      | duration('P1DT2H')                   | duration('P3DT4H')                   |

  # ---------------------------------------------------------------------------
  # 14. 空间类型(Point)属性的 Unique 约束
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-14] unique constraint on point <datatype> property
    Given an empty graph
    And having executed:
      """
      CREATE (:PointUnique {prop: <sampleValue>})
      """
    When executing query:
      """
      CREATE CONSTRAINT pointUniqProp FOR (n:PointUnique) REQUIRE n.prop IS UNIQUE
      """
    Then the side effects should be:
      | +constraints | 1 |
    # ---- 验证约束生效：写入不重复值成功 ----
    When executing query without error:
      """
      CREATE (:PointUnique {prop: <sampleValue2>})
      """
    Then the side effects should be:
      | +nodes | 1 |
    # ---- 验证约束生效：写入重复值失败 ----
    When executing query:
      """
      CREATE (:PointUnique {prop: <sampleValue>})
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | datatype | sampleValue                     | sampleValue2                      |
      | point-2d | point({x: 1.0, y: 2.0})         | point({x: 5.0, y: 6.0})          |
      | point-3d | point({x: 1.0, y: 2.0, z: 3.0}) | point({x: 7.0, y: 8.0, z: 9.0})  |

  # ---------------------------------------------------------------------------
  # 15. 列表类型属性的 Unique 约束
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-15] unique constraint on list <datatype> property
    Given an empty graph
    And having executed:
      """
      CREATE (:ListUnique {prop: <sampleValue>})
      """
    When executing query:
      """
      CREATE CONSTRAINT listUniqProp FOR (n:ListUnique) REQUIRE n.prop IS UNIQUE
      """
    Then the side effects should be:
      | +constraints | 1 |
    # ---- 验证约束生效：写入不重复值成功 ----
    When executing query without error:
      """
      CREATE (:ListUnique {prop: <sampleValue2>})
      """
    Then the side effects should be:
      | +nodes | 1 |
    # ---- 验证约束生效：写入重复值失败 ----
    When executing query:
      """
      CREATE (:ListUnique {prop: <sampleValue>})
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | datatype    | sampleValue     | sampleValue2   |
      | list-int    | [1, 2, 3]       | [4, 5, 6]      |
      | list-string | ['a', 'b', 'c'] | ['x', 'y', 'z'] |

  # ---------------------------------------------------------------------------
  # 16. 向量类型属性的 Unique 约束 （也就是列表类型）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Unique-16] unique constraint on vector <datatype> property
    Given an empty graph
    And having executed:
      """
      CREATE (:VectorUnique {prop: <sampleValue>})
      """
    When executing query:
      """
      CREATE CONSTRAINT vectorUniqProp FOR (n:VectorUnique) REQUIRE n.prop IS UNIQUE
      """
    Then the side effects should be:
      | +constraints | 1 |
    # ---- 验证约束生效：写入不重复值成功 ----
    When executing query without error:
      """
      CREATE (:VectorUnique {prop: <sampleValue2>})
      """
    Then the side effects should be:
      | +nodes | 1 |
    # ---- 验证约束生效：写入重复值失败 ----
    When executing query:
      """
      CREATE (:VectorUnique {prop: <sampleValue>})
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | datatype      | sampleValue          | sampleValue2           |
      | vector-float  | [0.1, 0.2, 0.3]      | [0.4, 0.5, 0.6]        |
      | vector-single | [1.0, 0.0, 0.0, 0.0] | [0.0, 1.0, 0.0, 0.0]  |
