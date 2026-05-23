# encoding: utf-8
#
# Constraint: Composite Property - create scenarios
#
# 测试范围:
#   - 2 属性复合属性约束创建（节点 + 关系）
#   - 3 属性复合属性约束创建
#   - 命名 / 不命名复合约束
#   - 重复创建同名约束报错
#   - IF NOT EXISTS 幂等创建
#   - 创建后插入数据允许重复（非唯一约束）
#   - NULL 值行为验证
#   - 底层索引自动创建联动验证
#
# Neo4j 参考:
#   CREATE CONSTRAINT [name] FOR (n:Label)        REQUIRE (n.prop1, n.prop2) IS COMPOSITE PROPERTY
#   CREATE CONSTRAINT [name] FOR ()-[r:TYPE]-()   REQUIRE (r.prop1, r.prop2) IS COMPOSITE PROPERTY
#   Composite Property 约束为非唯一、索引型约束，允许重复值，自动创建底层复合索引。
#
@constraint @ddl
Feature: Constraint composite property - create

  # ---------------------------------------------------------------------------
  # 1. 基本创建：2 属性复合属性约束 on node/rel -> success
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Composite-01] 2-property composite constraint on <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |

    Examples:
      | entityType | createCypher                                                                                                  |
      | node       | CREATE CONSTRAINT compAddr FOR (n:CompNode) REQUIRE (n.city, n.street) IS COMPOSITE PROPERTY                  |
      | rel        | CREATE CONSTRAINT compRoute FOR ()-[r:COMP_REL]-() REQUIRE (r.src, r.dst) IS COMPOSITE PROPERTY               |

  # ---------------------------------------------------------------------------
  # 2. 3 属性复合属性约束 on node/rel -> success
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Composite-02] 3-property composite constraint on <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |

    Examples:
      | entityType | createCypher                                                                                                                  |
      | node       | CREATE CONSTRAINT comp3Prop FOR (n:Comp3Node) REQUIRE (n.a, n.b, n.c) IS COMPOSITE PROPERTY                                  |
      | rel        | CREATE CONSTRAINT comp3PropRel FOR ()-[r:COMP3_REL]-() REQUIRE (r.x, r.y, r.z) IS COMPOSITE PROPERTY                         |

  # ---------------------------------------------------------------------------
  # 3. 命名复合属性约束 -> 验证约束名生效
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Composite-03] named composite constraint on <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |

    Examples:
      | entityType | createCypher                                                                                                         |
      | node       | CREATE CONSTRAINT myNamedComposite FOR (n:NamedCompNode) REQUIRE (n.p1, n.p2) IS COMPOSITE PROPERTY                 |
      | rel        | CREATE CONSTRAINT myNamedCompositeRel FOR ()-[r:NAMED_COMP_REL]-() REQUIRE (r.p1, r.p2) IS COMPOSITE PROPERTY       |

  # ---------------------------------------------------------------------------
  # 4. 重复创建同名约束 -> error
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Composite-04] duplicate named composite constraint raises error - <entityType>
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
      | entityType | createCypher                                                                                                |
      | node       | CREATE CONSTRAINT dupComposite FOR (n:DupCompNode) REQUIRE (n.a, n.b) IS COMPOSITE PROPERTY                |
      | rel        | CREATE CONSTRAINT dupComposite FOR ()-[r:DUP_COMP_REL]-() REQUIRE (r.a, r.b) IS COMPOSITE PROPERTY         |

  # ---------------------------------------------------------------------------
  # 5. IF NOT EXISTS 幂等创建：约束已存在时不报错，不重复创建
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Composite-05] idempotent create with IF NOT EXISTS - <entityType>
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
      | entityType | createCypher                                                                                                    | createCypherIdempotent                                                                                                                 |
      | node       | CREATE CONSTRAINT idemComp FOR (n:IdemCompNode) REQUIRE (n.x, n.y) IS COMPOSITE PROPERTY                       | CREATE CONSTRAINT idemComp IF NOT EXISTS FOR (n:IdemCompNode) REQUIRE (n.x, n.y) IS COMPOSITE PROPERTY                                |
      | rel        | CREATE CONSTRAINT idemCompRel FOR ()-[r:IDEM_COMP_REL]-() REQUIRE (r.x, r.y) IS COMPOSITE PROPERTY             | CREATE CONSTRAINT idemCompRel IF NOT EXISTS FOR ()-[r:IDEM_COMP_REL]-() REQUIRE (r.x, r.y) IS COMPOSITE PROPERTY                      |

  # ---------------------------------------------------------------------------
  # 6. 创建后插入重复数据成功（复合属性约束非唯一，允许重复）
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Composite-06] insert duplicate composite values allowed on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>;
      <insertFirst>
      """
    When executing query without error:
      """
      <insertDuplicate>
      """
    Then the side effects should be:
      | +nodes | <expectedNodes> |
      | +relationships | <expectedRels> |

    Examples:
      | entityType | createCypher                                                                                           | insertFirst                                                                      | insertDuplicate                                                                  | expectedNodes | expectedRels |
      | node       | CREATE CONSTRAINT allowDup FOR (n:AllowDupNode) REQUIRE (n.k1, n.k2) IS COMPOSITE PROPERTY           | CREATE (:AllowDupNode {k1: 'A', k2: 'X'})                                       | CREATE (:AllowDupNode {k1: 'A', k2: 'X'})                                        | 1             | 0            |
      | rel        | CREATE CONSTRAINT allowDupRel FOR ()-[r:ALLOW_DUP]-() REQUIRE (r.k1, r.k2) IS COMPOSITE PROPERTY     | CREATE (a:ADSrc), (b:ADDst), (a)-[:ALLOW_DUP {k1: 'A', k2: 'X'}]->(b)           | CREATE (c:ADSrc2), (d:ADDst2), (c)-[:ALLOW_DUP {k1: 'A', k2: 'X'}]->(d)         | 2             | 1            |

  # ---------------------------------------------------------------------------
  # 7. NULL 值行为：复合属性中包含 NULL 值的插入
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Composite-07] NULL values in composite properties on <entityType>
    Given an empty graph
    And having executed:
      """
      <createCypher>
      """
    When executing query without error:
      """
      <insertWithNull>
      """
    Then the side effects should be:
      | +nodes | <expectedNodes> |
      | +relationships | <expectedRels> |

    Examples:
      | entityType | createCypher                                                                                      | insertWithNull                                                                    | expectedNodes | expectedRels |
      | node       | CREATE CONSTRAINT nullComp FOR (n:NullCompNode) REQUIRE (n.p1, n.p2) IS COMPOSITE PROPERTY       | CREATE (:NullCompNode {p1: NULL, p2: 'X'})                                        | 1             | 0            |
      | rel        | CREATE CONSTRAINT nullCompRel FOR ()-[r:NULL_COMP]-() REQUIRE (r.p1, r.p2) IS COMPOSITE PROPERTY | CREATE (a:NCSrc), (b:NCDst), (a)-[:NULL_COMP {p1: NULL, p2: 'X'}]->(b)            | 2             | 1            |

  # ---------------------------------------------------------------------------
  # 8. 底层索引自动创建联动验证
  #    创建 Composite Property 约束后，自动创建关联复合索引
  # ---------------------------------------------------------------------------

  Scenario Outline: [Create-Composite-08] composite constraint auto-creates backing index - <entityType>
    Given an empty graph
    When executing query:
      """
      <createCypher>
      """
    Then the side effects should be:
      | +constraints | 1 |

    When executing query:
      """
      SHOW INDEXES YIELD name, type, entityType, labelsOrTypes, properties
      """
    Then the result should not be empty

    Examples:
      | entityType | createCypher                                                                                              |
      | node       | CREATE CONSTRAINT backingComp FOR (n:BackingCompNode) REQUIRE (n.f1, n.f2) IS COMPOSITE PROPERTY         |
      | rel        | CREATE CONSTRAINT backingCompRel FOR ()-[r:BACKING_COMP_REL]-() REQUIRE (r.f1, r.f2) IS COMPOSITE PROPERTY|
