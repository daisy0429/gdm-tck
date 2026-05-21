# encoding: utf-8
#
# Constraint: Property Type - create scenarios
#
# 测试范围:
#   - 节点/关系 STRING 类型约束创建
#   - 节点/关系 INTEGER 类型约束创建
#   - 节点/关系 FLOAT 类型约束创建
#   - 节点/关系 BOOLEAN 类型约束创建
#   - 节点/关系 DATE 类型约束创建
#   - 命名属性类型约束
#   - 重复创建同名约束报错
#   - IF NOT EXISTS 幂等创建
#   - 创建后验证：正确类型写入成功、错误类型写入失败
#   - 存量正确类型数据上创建约束 -> 成功
#   - 存量错误类型数据上创建约束 -> 失败
#
# Neo4j 参考:
#   CREATE CONSTRAINT [name] FOR (n:Label)        REQUIRE n.prop IS :: STRING
#   CREATE CONSTRAINT [name] FOR ()-[r:TYPE]-()   REQUIRE r.prop IS :: INTEGER
#   支持类型: STRING, INTEGER, FLOAT, BOOLEAN, DATE, LOCALTIME, ZONED_TIME,
#            LOCAL_DATETIME, ZONED_DATETIME, DURATION, POINT
#
@constraint @ddl
Feature: Constraint property type - create

  # ---------------------------------------------------------------------------
  # 1. STRING 类型约束创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-01] create STRING type constraint on <entityType>
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
    #   | '<constraintName>' | 'PROPERTY_TYPE' | '<entityTypeExpected>' | '<labelsOrTypes>' | '<properties>' |

    Examples:
      | entityType | setupData                                                        | createCypher                                                                          | constraintName | entityTypeExpected | labelsOrTypes     | properties |
      | node       | CREATE (:TypeStrNode {name: 'hello'})                            | CREATE CONSTRAINT typeStr FOR (n:TypeStrNode) REQUIRE n.name IS :: STRING             | 'typeStr'      | 'NODE'             | ['TypeStrNode']   | ['name']   |
      | rel        | CREATE (a:StrSrc), (b:StrDst), (a)-[:TYPED_STR {val: 'x'}]->(b)  | CREATE CONSTRAINT typeStrRel FOR ()-[r:TYPED_STR]-() REQUIRE r.val IS :: STRING       | 'typeStrRel'   | 'RELATIONSHIP'     | ['TYPED_STR']     | ['val']    |

  # ---------------------------------------------------------------------------
  # 2. INTEGER 类型约束创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-02] create INTEGER type constraint on <entityType>
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

    Examples:
      | entityType | setupData                                                      | createCypher                                                                            |
      | node       | CREATE (:TypeIntNode {age: 30})                                | CREATE CONSTRAINT typeInt FOR (n:TypeIntNode) REQUIRE n.age IS :: INTEGER               |
      | rel        | CREATE (a:IntSrc), (b:IntDst), (a)-[:TYPED_INT {val: 42}]->(b) | CREATE CONSTRAINT typeIntRel FOR ()-[r:TYPED_INT]-() REQUIRE r.val IS :: INTEGER        |

  # ---------------------------------------------------------------------------
  # 3. FLOAT 类型约束创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-03] create FLOAT type constraint on <entityType>
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

    Examples:
      | entityType | setupData                                                         | createCypher                                                                             |
      | node       | CREATE (:TypeFloatNode {score: 3.14})                             | CREATE CONSTRAINT typeFloat FOR (n:TypeFloatNode) REQUIRE n.score IS :: FLOAT            |
      | rel        | CREATE (a:FloatSrc), (b:FloatDst), (a)-[:TYPED_FLOAT {val: 2.5}]->(b) | CREATE CONSTRAINT typeFloatRel FOR ()-[r:TYPED_FLOAT]-() REQUIRE r.val IS :: FLOAT |

  # ---------------------------------------------------------------------------
  # 4. BOOLEAN 类型约束创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-04] create BOOLEAN type constraint on <entityType>
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

    Examples:
      | entityType | setupData                                                          | createCypher                                                                              |
      | node       | CREATE (:TypeBoolNode {active: true})                              | CREATE CONSTRAINT typeBool FOR (n:TypeBoolNode) REQUIRE n.active IS :: BOOLEAN            |
      | rel        | CREATE (a:BoolSrc), (b:BoolDst), (a)-[:TYPED_BOOL {val: false}]->(b) | CREATE CONSTRAINT typeBoolRel FOR ()-[r:TYPED_BOOL]-() REQUIRE r.val IS :: BOOLEAN  |

  # ---------------------------------------------------------------------------
  # 5. DATE 类型约束创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-05] create DATE type constraint on <entityType>
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

    Examples:
      | entityType | setupData                                                                          | createCypher                                                                             |
      | node       | CREATE (:TypeDateNode {birthday: date('2024-01-15')})                              | CREATE CONSTRAINT typeDate FOR (n:TypeDateNode) REQUIRE n.birthday IS :: DATE            |
      | rel        | CREATE (a:DateSrc), (b:DateDst), (a)-[:TYPED_DATE {val: date('2024-06-01')}]->(b)  | CREATE CONSTRAINT typeDateRel FOR ()-[r:TYPED_DATE]-() REQUIRE r.val IS :: DATE         |

  # ---------------------------------------------------------------------------
  # 6. 命名属性类型约束
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-06] named property type constraint on <entityType>
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
    #   | '<constraintName>' | 'PROPERTY_TYPE' | '<entityTypeExpected>' |

    Examples:
      | entityType | createCypher                                                                                          | constraintName    | entityTypeExpected |
      | node       | CREATE CONSTRAINT namedTypeNode FOR (n:NamedTypeNode) REQUIRE n.code IS :: STRING                     | 'namedTypeNode'   | 'NODE'             |
      | rel        | CREATE CONSTRAINT namedTypeRel FOR ()-[r:NAMED_TYPE_REL]-() REQUIRE r.code IS :: STRING               | 'namedTypeRel'    | 'RELATIONSHIP'     |

  # ---------------------------------------------------------------------------
  # 7. 重复创建同名约束应报错（不带 IF NOT EXISTS）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-07] duplicate named constraint raises error - <entityType>
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
      | entityType | createCypher                                                                                      |
      | node       | CREATE CONSTRAINT dupTypeConstraint FOR (n:TypeDup) REQUIRE n.id IS :: STRING                     |
      | rel        | CREATE CONSTRAINT dupTypeConstraint FOR ()-[r:TYPE_DUP]-() REQUIRE r.id IS :: STRING              |

  # ---------------------------------------------------------------------------
  # 8. IF NOT EXISTS 幂等创建：约束已存在时不报错，不重复创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-08] idempotent create with IF NOT EXISTS - <entityType>
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
      | entityType | createCypher                                                                                      | createCypherIdempotent                                                                                                            |
      | node       | CREATE CONSTRAINT idempotentType FOR (n:IdempTypeNode) REQUIRE n.key IS :: STRING                | CREATE CONSTRAINT idempotentType IF NOT EXISTS FOR (n:IdempTypeNode) REQUIRE n.key IS :: STRING                                   |
      | rel        | CREATE CONSTRAINT idempotentType FOR ()-[r:IDEMP_TYPE_REL]-() REQUIRE r.key IS :: STRING         | CREATE CONSTRAINT idempotentType IF NOT EXISTS FOR ()-[r:IDEMP_TYPE_REL]-() REQUIRE r.key IS :: STRING                            |

  # ---------------------------------------------------------------------------
  # 9. 创建后验证约束生效：正确类型写入成功，错误类型写入失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-09] created type constraint enforces on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query without error:
      """
      <insertCorrectType>
      """
    Then the side effects should be:
      | +nodes | <compliantNodes> |
      | +relationships | <compliantRels> |
    When executing query:
      """
      <insertWrongType>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                      | insertCorrectType                                                                   | insertWrongType                                                                        | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT enforceType FOR (n:EnforcedTypeNode) REQUIRE n.code IS :: STRING               | CREATE (:EnforcedTypeNode {code: 'hello'})                                          | CREATE (:EnforcedTypeNode {code: 123})                                                 | 1              | 0             |
      | rel        | CREATE CONSTRAINT enforceTypeRel FOR ()-[r:ENFORCED_TYPE]-() REQUIRE r.code IS :: STRING         | CREATE (a:ETSrc1), (b:ETDst1), (a)-[:ENFORCED_TYPE {code: 'hello'}]->(b)            | CREATE (c:ETSrc2), (d:ETDst2), (c)-[:ENFORCED_TYPE {code: 123}]->(d)                  | 2              | 1             |

  # ---------------------------------------------------------------------------
  # 10. 在已有满足类型约束数据上创建约束 — 应成功
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-10] create on existing correctly typed data - <entityType>
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
      | entityType | setupData                                                                                                    | createCypher                                                                          |
      | node       | CREATE (:CompliantTypeNode {code: 'SN001'}), (:CompliantTypeNode {code: 'SN002'})                             | CREATE CONSTRAINT FOR (n:CompliantTypeNode) REQUIRE n.code IS :: STRING               |
      | rel        | CREATE (a:CTSrc1),(b:CTDst1),(c:CTSrc2),(d:CTDst2), (a)-[:TYPED_TRK {code: 'T1'}]->(b),(c)-[:TYPED_TRK {code: 'T2'}]->(d) | CREATE CONSTRAINT FOR ()-[r:TYPED_TRK]-() REQUIRE r.code IS :: STRING  |

  # ---------------------------------------------------------------------------
  # 11. 在已有错误类型数据上创建约束 — 应失败
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Type-11] create on existing wrongly typed data - <entityType>
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
      | entityType | setupData                                                                                                                              | createCypher                                                                      |
      | node       | CREATE (:WrongTypeNode {code: 'OK'}), (:WrongTypeNode {code: 42})                                                                      | CREATE CONSTRAINT FOR (n:WrongTypeNode) REQUIRE n.code IS :: STRING               |
      | rel        | CREATE (a:WTSrc1),(b:WTDst1),(c:WTSrc2),(d:WTDst2), (a)-[:WRONG_TYPE {code: 'OK'}]->(b),(c)-[:WRONG_TYPE {code: 42}]->(d)              | CREATE CONSTRAINT FOR ()-[r:WRONG_TYPE]-() REQUIRE r.code IS :: STRING            |
