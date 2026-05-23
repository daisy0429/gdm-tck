# encoding: utf-8
#
# Constraint: Property Type - violation scenarios
#
# 测试范围:
#   - 写入 STRING 到期望 INTEGER 的属性 -> 报错
#   - 写入 INTEGER 到期望 STRING 的属性 -> 报错
#   - 写入 BOOLEAN 到期望 FLOAT 的属性 -> 报错
#   - SET 属性为错误类型 -> 报错
#   - NULL 值通过类型约束（NULL 是允许的）
#
# Neo4j 参考:
#   Property Type 约束仅检查非 NULL 值的类型，NULL 值被视为合法
#
@constraint @ddl
Feature: Constraint property type - violation

  # ---------------------------------------------------------------------------
  # 1. 写入 STRING 到期望 INTEGER 的属性 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Type-01] insert STRING where INTEGER expected on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertCorrect>
      """
    When executing query:
      """
      <insertWrong>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                      | insertCorrect                                                                      | insertWrong                                                                             |
      | node       | CREATE CONSTRAINT vtInt FOR (n:VTIntNode) REQUIRE n.age IS :: INTEGER                            | CREATE (:VTIntNode {age: 30})                                                      | CREATE (:VTIntNode {age: 'thirty'})                                                     |
      | rel        | CREATE CONSTRAINT vtIntRel FOR ()-[r:VT_INT_REL]-() REQUIRE r.age IS :: INTEGER                  | CREATE (a:VISrc1), (b:VIDst1), (a)-[:VT_INT_REL {age: 30}]->(b)                    | CREATE (c:VISrc2), (d:VIDst2), (c)-[:VT_INT_REL {age: 'thirty'}]->(d)                  |

  # ---------------------------------------------------------------------------
  # 2. 写入 INTEGER 到期望 STRING 的属性 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Type-02] insert INTEGER where STRING expected on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertCorrect>
      """
    When executing query:
      """
      <insertWrong>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                      | insertCorrect                                                                      | insertWrong                                                                         |
      | node       | CREATE CONSTRAINT vtStr FOR (n:VTStrNode) REQUIRE n.name IS :: STRING                            | CREATE (:VTStrNode {name: 'Alice'})                                                | CREATE (:VTStrNode {name: 123})                                                    |
      | rel        | CREATE CONSTRAINT vtStrRel FOR ()-[r:VT_STR_REL]-() REQUIRE r.name IS :: STRING                  | CREATE (a:VSSrc1), (b:VSDst1), (a)-[:VT_STR_REL {name: 'Alice'}]->(b)              | CREATE (c:VSSrc2), (d:VSDst2), (c)-[:VT_STR_REL {name: 123}]->(d)                  |

  # ---------------------------------------------------------------------------
  # 3. 写入 BOOLEAN 到期望 FLOAT 的属性 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Type-03] insert BOOLEAN where FLOAT expected on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertCorrect>
      """
    When executing query:
      """
      <insertWrong>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                      | insertCorrect                                                                      | insertWrong                                                                            |
      | node       | CREATE CONSTRAINT vtFloat FOR (n:VTFloatNode) REQUIRE n.score IS :: FLOAT                        | CREATE (:VTFloatNode {score: 3.14})                                                | CREATE (:VTFloatNode {score: true})                                                    |
      | rel        | CREATE CONSTRAINT vtFloatRel FOR ()-[r:VT_FLOAT_REL]-() REQUIRE r.score IS :: FLOAT              | CREATE (a:VFSrc1), (b:VFDst1), (a)-[:VT_FLOAT_REL {score: 3.14}]->(b)              | CREATE (c:VFSrc2), (d:VFDst2), (c)-[:VT_FLOAT_REL {score: true}]->(d)                 |

  # ---------------------------------------------------------------------------
  # 4. SET 属性为错误类型 -> 报错
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Type-04] SET property to wrong type on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertData>
      """
    When executing query:
      """
      <setWrongType>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                      | insertData                                                                     | setWrongType                                                            |
      | node       | CREATE CONSTRAINT vtSet FOR (n:VTSetNode) REQUIRE n.code IS :: STRING                            | CREATE (:VTSetNode {code: 'VALID'})                                            | MATCH (n:VTSetNode) SET n.code = 999                                    |
      | rel        | CREATE CONSTRAINT vtSetRel FOR ()-[r:VT_SET_REL]-() REQUIRE r.code IS :: STRING                  | CREATE (a:VTSrc), (b:VTDst), (a)-[:VT_SET_REL {code: 'VALID'}]->(b)            | MATCH ()-[r:VT_SET_REL]->() SET r.code = 999                            |

  # ---------------------------------------------------------------------------
  # 5. NULL 值通过类型约束（NULL 是允许的）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Type-05] NULL value passes type constraint on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertCorrect>
      """
    When executing query without error:
      """
      <insertNull>
      """
    Then the side effects should be:
      | +nodes | <compliantNodes> |
      | +relationships | <compliantRels> |

    Examples:
      | entityType | createCypher                                                                                      | insertCorrect                                                                      | insertNull                                                                           | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT vtNull FOR (n:VTNullNode) REQUIRE n.code IS :: STRING                          | CREATE (:VTNullNode {code: 'OK'})                                                  | CREATE (:VTNullNode {code: null})                                                    | 1              | 0             |
      | rel        | CREATE CONSTRAINT vtNullRel FOR ()-[r:VT_NULL_REL]-() REQUIRE r.code IS :: STRING                | CREATE (a:VTNSrc1), (b:VTNDst1), (a)-[:VT_NULL_REL {code: 'OK'}]->(b)              | CREATE (c:VTNSrc2), (d:VTNDst2), (c)-[:VT_NULL_REL {code: null}]->(d)               | 2              | 1             |

  # ---------------------------------------------------------------------------
  # 6. INTEGER 值写入 FLOAT 约束列 -> 验证隐式转换行为
  #    Neo4j 中 INTEGER 可隐式转换为 FLOAT，应通过约束
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Type-06] INTEGER to FLOAT implicit conversion on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query without error:
      """
      <insertIntToFloat>
      """
    Then the side effects should be:
      | +nodes | <compliantNodes> |
      | +relationships | <compliantRels> |

    Examples:
      | entityType | createCypher                                                                                      | insertIntToFloat                                                                        | compliantNodes | compliantRels |
      | node       | CREATE CONSTRAINT vtIntToFloat FOR (n:VTIntFloatNode) REQUIRE n.score IS :: FLOAT                | CREATE (:VTIntFloatNode {score: 42})                                                    | 1              | 0             |
      | rel        | CREATE CONSTRAINT vtIntToFloatRel FOR ()-[r:VT_INT_FLOAT]-() REQUIRE r.score IS :: FLOAT         | CREATE (a:VIFSrc), (b:VIFDst), (a)-[:VT_INT_FLOAT {score: 42}]->(b)                     | 2              | 1             |

  # ---------------------------------------------------------------------------
  # 7. FLOAT 值写入 INTEGER 约束列 -> 应报错（不能隐式转换）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Violate-Type-07] FLOAT to INTEGER should fail on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query:
      """
      <insertFloatToInt>
      """
    Then a ConstraintValidationFailed should be raised at any time

    Examples:
      | entityType | createCypher                                                                                      | insertFloatToInt                                                                        |
      | node       | CREATE CONSTRAINT vtFloatToInt FOR (n:VTFloatIntNode) REQUIRE n.age IS :: INTEGER                | CREATE (:VTFloatIntNode {age: 3.14})                                                    |
      | rel        | CREATE CONSTRAINT vtFloatToIntRel FOR ()-[r:VT_FLOAT_INT]-() REQUIRE r.age IS :: INTEGER         | CREATE (a:VFISrc), (b:VFIDst), (a)-[:VT_FLOAT_INT {age: 3.14}]->(b)                     |
