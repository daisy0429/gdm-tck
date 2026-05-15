#encoding: utf-8

Feature: 添加点边标签属性列-属性名称校验、基础添加、属性类型与约束、关联影响等

  Background:
    Given drop all graph

  # ============================================================
  # 1. 属性名称校验
  # ============================================================

  Scenario Outline: [1-1] 添加属性列-属性名校验-混合名称-<property>
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {username STRING NOT NULL}),
        (:person)-[:likes{since LOCALDATETIME}]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {<property> INT64};
      ALTER EDGE likes ADD PROPERTY {<property> FLOAT32};
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'username'     | ['string']    | false    |
      | 'person' | '<property>'   | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes     | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'likes' | 'since'        | ['localdatetime'] | true     |
      | 'likes' | '<property>'   | ['float32']       | true     |
    Then drop all graph
    Examples:
      | property |
      | test01   |
      | test测试   |
      | 测试test01 |
      | 测试01     |
      | aa       |
      | AA       |
      | test_abc |

  Scenario Outline: [1-2] 添加属性列-属性名校验-关键字-<property>
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {username STRING NOT NULL}),
        (:person)-[:likes{since LOCALDATETIME}]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {<property> INT64};
      ALTER EDGE likes ADD PROPERTY {<property> FLOAT32};
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'username'     | ['string']    | false    |
      | 'person' | '<property>'   | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes     | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'likes' | 'since'        | ['localdatetime'] | true     |
      | 'likes' | '<property>'   | ['float32']       | true     |
    Then drop all graph
    Examples:
      | property    |
      | func        |
      | select      |
      | case        |
      | chan        |
      | interface   |
      | const       |
      | continue    |
      | defer       |
      | go          |
      | map         |
      | struct      |
      | switch      |
      | if          |
      | else        |
      | goto        |
      | package     |
      | fallthrough |
      | var         |
      | return      |
      | sys         |

  Scenario Outline: [1-3] 添加属性列-属性名校验-特殊字符-<property>
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {username STRING NOT NULL}),
        (:person)-[:likes{since LOCALDATETIME}]->(:person)
      };
      """
    When executing query:
      """
      ALTER NODE person ADD PROPERTY {<property>v INT64};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    When executing query:
      """
      ALTER EDGE likes ADD PROPERTY {<property>e FLOAT32};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Then drop all graph
    Examples:
      | property    |
      | ！           |
      | @           |
      | #           |
      | %           |
      | $           |
      | &           |
      | ^           |
      | *           |
      | (           |
      | )           |
      | +           |
      | -           |
      | =           |
      | {           |
      | }           |
      | [           |
      | ]           |
      | :           |
      | "           |
      | ;           |
      | ,           |
      | .           |
      | /           |
      | ?           |
      | \|undefined |
      | ￥           |
      | ……          |
      | `           |
      | ·           |
      | ~           |
      | 【           |
      | 】           |
      | '           |
      | 123         |

  Scenario: [1-4] 添加属性列-属性名校验-唯一性
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {username STRING NOT NULL}),
        (:person)-[:likes{since LOCALDATETIME}]->(:person)
      };
      """
    # 属性名称相同，属性类型不同，报错
    When executing query:
      """
      ALTER NODE person ADD PROPERTY {username INT64};
      """
    Then the error should be contain:
      """
      [2910]Column type mismatch
      """
    When executing query:
      """
      ALTER EDGE likes ADD PROPERTY {since FLOAT32};
      """
    Then the error should be contain:
      """
      [2910]Column type mismatch
      """
    # 属性名称相同，类型相同，约束不同，报错
    When executing query:
      """
      ALTER NODE person ADD PROPERTY {username STRING};
      """
    Then the error should be contain:
      """
      [2911]Column null constraint mismatch
      """
    # 属性名称类型约束完全相同，相同跳过，新增的增加
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {username STRING NOT NULL, age INT64};
      """
    Then executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties WHERE name = 'person';
      """
    Then the result should be, in any order:
      | name     | properties                          |
      | 'person' | ['_PRIMARY_KEY', 'username', 'age'] |
    # 重复添加相同属性（类型约束相同），应跳过
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {username STRING NOT NULL};
      """
    Then executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties WHERE name = 'person';
      """
    Then the result should be, in any order:
      | name     | properties                          |
      | 'person' | ['_PRIMARY_KEY', 'username', 'age'] |
    Then drop all graph

  Scenario: [1-5] 添加属性列-属性名校验-长度限制
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {username STRING NOT NULL}),
        (:person)-[:likes{since LOCALDATETIME}]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb INT64};
      ALTER EDGE likes ADD PROPERTY {bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb FLOAT32};
      """
    When executing query:
      """
      ALTER NODE person ADD PROPERTY {abbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb INT64};
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    Then drop all graph

  Scenario: [1-6] 添加属性列-属性名校验-向不存在的标签添加属性
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing query:
      """
      ALTER NODE person ADD PROPERTY {name STRING};
      """
    Then the error should be contain:
      """
      [1613]Label does not exist
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person)
      };
      """
    When executing query:
      """
      ALTER EDGE likes ADD PROPERTY {since LOCALDATETIME};
      """
    Then the error should be contain:
      """
      [1615]Relation does not exist
      """
    Then drop all graph

  # ============================================================
  # 2. 基础添加功能
  # ============================================================

  Scenario: [2-1] 添加属性列-单个属性
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:person)-[:likes]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {username STRING NOT NULL};
      ALTER EDGE likes ADD PROPERTY {since LOCALDATETIME};
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'username'     | ['string']    | false    |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes     | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'likes' | 'since'        | ['localdatetime'] | true     |
    Then drop all graph

  Scenario: [2-2] 添加属性列-多个属性
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:person)-[:likes]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {username STRING NOT NULL, age INT64};
      ALTER EDGE likes ADD PROPERTY {since LOCALDATETIME, year FLOAT32};
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'username'     | ['string']    | false    |
      | 'person' | 'age'          | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes     | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'likes' | 'since'        | ['localdatetime'] | true     |
      | 'likes' | 'year'         | ['float32']       | true     |
    Then drop all graph

  Scenario: [2-3] 添加属性列-向多个标签添加相同属性
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:animal),
        (:person)-[:likes]->(:person),
        (:person)-[:knows]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {name STRING};
      ALTER NODE animal ADD PROPERTY {name STRING};
      ALTER EDGE likes ADD PROPERTY {since LOCALDATETIME};
      ALTER EDGE knows ADD PROPERTY {since LOCALDATETIME};
      """
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'name'         | ['string']    | true     |
      | 'animal' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'animal' | 'name'         | ['string']    | true     |
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes     | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'likes' | 'since'        | ['localdatetime'] | true     |
      | 'knows' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'knows' | 'since'        | ['localdatetime'] | true     |
    Then drop all graph

  Scenario: [2-4] 添加属性列-添加大量属性（边界测试）
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {
        p1 STRING, p2 STRING, p3 STRING, p4 STRING, p5 STRING,
        p6 INT64, p7 INT64, p8 INT64, p9 INT64, p10 INT64,
        p11 BOOL, p12 BOOL, p13 BOOL, p14 BOOL, p15 BOOL,
        p16 FLOAT, p17 FLOAT, p18 FLOAT, p19 FLOAT, p20 FLOAT
      };
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result count should be [21]
    Then drop all graph

  Scenario: [2-5] 添加属性列-属性描述信息-COMMENT
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:person)-[:likes]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {username STRING NOT NULL COMMENT "this is username"};
      ALTER EDGE likes ADD PROPERTY {since LOCALDATETIME COMMENT "this is since"};
      """
    Then drop all graph

  # ============================================================
  # 3. 属性类型与约束
  # ============================================================

  Scenario Outline: [3-1] 添加属性列-属性类型-多种类型-<type>
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:person)-[:likes]->(:person)
      };
      """
    Then executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {p1 <type>};
      ALTER EDGE likes ADD PROPERTY {k1 <type>};
      """
    When executing queries without error:
      """
      CREATE (n:person{p1:<value>});
      MATCH (a:person) WHERE a.p1 = <value>
      CREATE (a)-[r:likes { k1: <value> }]->(a)
      RETURN r;
      """
    When executing query:
      """
      MATCH (n:person) RETURN n.p1;
      """
    Then the result should be, in any order:
      | n.p1     |
      | <result> |
    When executing query:
      """
      MATCH (n)-[r:likes]->(m) RETURN r.k1;
      """
    Then the result should be, in any order:
      | r.k1     |
      | <result> |
    Then drop all graph
    Examples:
      | type          | value                                | result                                                       |
      | string        | '1'                                  | '1'                                                          |
      | int64         | 1                                    | 1                                                            |
      | float32       | 3.14                                 | 3.14                                                         |
      | float64       | 3.141592653589793                    | 3.141592653589793                                            |
      | bool          | true                                 | true                                                         |
      | date          | date('2010-01-01')                   | '2010-01-01'                                                 |
      | time          | time('16:00:00')                     | '16:00Z'                                                     |
      | localtime     | localtime('16:00:00')                | '16:00'                                                      |
      | datetime      | datetime('2010-01-01T16:00:00Z')     | '2010-01-01T16:00Z'                                          |
      | localdatetime | localdatetime('2010-01-01T16:00:00') | '2010-01-01T16:00'                                           |
      | duration      | duration('P3DT3H3M3S')               | 'P3DT3H3M3S'                                                 |
      | point2d       | point({x:1.0, y:2.0})                | Point{SpatialRefId=7203, X=1.000000, Y=2.000000}             |
      | point3d       | point({x:1.0, y:2.0, z:3.0})         | Point{SpatialRefId=9157, X=1.000000, Y=2.000000, Z=3.000000} |
      | list<string>  | ['aa', 'bb', 'cc']                   | ['aa', 'bb', 'cc']                                           |

  Scenario: [3-2] 添加属性列-属性类型-未知类型
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:person)-[:likes]->(:person)
      };
      """
    Then executing query:
      """
      ALTER NODE person ADD PROPERTY {p1 unknowType};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Then drop all graph

  Scenario: [3-3] 添加属性列-属性约束-NOT NULL
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:person)-[:likes]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {username STRING NOT NULL};
      ALTER EDGE likes ADD PROPERTY {since LOCALDATETIME NOT NULL};
      """
    When executing query:
      """
      CREATE (a:person);
      """
    Then the error should be contain:
      """
      [1645]Col is null
      """
    When executing query:
      """
      CREATE (a:person { name:"张三"}),(b:person {name:"李四"}),(a)-[:likes]->(b);
      """
    Then the error should be contain:
      """
      [1645]Col is null
      """
    Then drop all graph

  Scenario: [3-4] 添加属性列-添加PRIMARY_KEY属性（不允许）
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person)
      };
      """
    When executing query:
      """
      ALTER NODE person ADD PROPERTY {_PRIMARY_KEY INT64};
      """
    Then the error should be contain:
      """
      [2911]Column null constraint mismatch
      """
    Then drop all graph

  Scenario: [3-5] 添加属性列-修改已存在属性的NOT NULL约束（不允许）
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {name STRING})
      };
      """
    When executing query:
      """
      ALTER NODE person ADD PROPERTY {name STRING NOT NULL};
      """
    Then the error should be contain:
      """
      [2911]Column null constraint mismatch
      """
    Then drop all graph

  # ============================================================
  # 4. 关联影响
  # ============================================================

  Scenario: [4-1] 添加属性列-属性隔离-不同标签添加相同属性
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:animal),
        (:person)-[:likes]->(:person),
        (:person)-[:have]->(:animal)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {username STRING NOT NULL};
      ALTER NODE animal ADD PROPERTY {username STRING NOT NULL};
      ALTER EDGE likes ADD PROPERTY {since LOCALDATETIME};
      ALTER EDGE have ADD PROPERTY {since LOCALDATETIME};
      """
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'username'     | ['string']    | false    |
      | 'animal' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'animal' | 'username'     | ['string']    | false    |
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes     | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'likes' | 'since'        | ['localdatetime'] | true     |
      | 'have'  | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'have'  | 'since'        | ['localdatetime'] | true     |
    Then drop all graph

  Scenario: [4-2] 添加属性列-属性隔离-点边标签添加相同属性
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:person)-[:likes]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {p1 STRING NOT NULL};
      ALTER EDGE likes ADD PROPERTY {p1 LOCALDATETIME};
      """
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'p1'           | ['string']    | false    |
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes     | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'likes' | 'p1'           | ['localdatetime'] | true     |
    Then drop all graph

  Scenario: [4-3] 添加属性列-新增属性后创建索引-唯一索引
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {age INT64}),
        (:person)-[:likes]->(:person)
      };
      """
    Then executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {name STRING};
      CREATE INDEX indexP ON NODE person (name) OPTIONS {indexConfig: {unique: true}};
      """
    Then executing query:
      """
      CREATE (a:person { name:"李明",age:27});
      """
    When executing query:
      """
      CREATE (a:person { name:"李明",age:27});
      """
    Then the error should be contain:
      """
      [1600]Duplicate index key value
      """
    Then drop all graph

  Scenario: [4-4] 添加属性列-新增属性后创建索引-复合索引
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {age INT64}),
        (:person)-[:likes]->(:person)
      };
      """
    Then executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {name STRING};
      CREATE INDEX indexP ON NODE person (name, age);
      """
    When executing queries without error:
      """
      SHOW INDEXES YIELD labelsOrTypes, properties, uniqueness;
      """
    Then the result should be, in any order:
      | labelsOrTypes | properties       | uniqueness  |
      | 'person'      | ['_PRIMARY_KEY'] | 'UNIQUE'    |
      | 'likes'       | ['_PRIMARY_KEY'] | 'UNIQUE'    |
      | 'person'      | ['name', 'age']  | 'NONUNIQUE' |
    Then drop all graph

  Scenario: [4-5] 添加属性列-新增属性后检查已有数据
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {age INT64}),
        (:person)-[:likes]->(:person)
      };
      """
    When executing query:
      """
      CREATE (a:person { age:27});
      """
    Then executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {name STRING};
      """
    When executing queries without error:
      """
      CREATE (a:person { name:"张三",age:25});
      """
    When executing query:
      """
      MATCH (n:person) RETURN n;
      """
    Then the result should be, in any order:
      | n                               |
      | (:person {name: '张三', age: 25}) |
      | (:person {age: 27})             |
    Then drop all graph

  Scenario: [4-6] 添加属性列-新增属性后检查已有数据-属性约束
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {name STRING NOT NULL}),
        (:person)-[:likes]->(:person)
      };
      """
    Then executing query:
      """
      CREATE (a:person {name:"李明"});
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {age INT64};
      """
    Then executing query:
      """
      CREATE (a:person {age:45});
      """
    Then the error should be contain:
      """
      [1645]Col is null
      """
    Then drop all graph

  Scenario: [4-7] 添加属性列-添加属性后插入数据并查询（端到端验证）
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person),
        (:person)-[:likes]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {name STRING, age INT64};
      ALTER EDGE likes ADD PROPERTY {weight FLOAT64};
      """
    When executing queries without error:
      """
      CREATE (a:person {name:"张三", age:25}), (b:person {name:"李四", age:30}), (a)-[:likes {weight:0.8}]->(b);
      """
    When executing query:
      """
      MATCH (p:person)-[r:likes]->(q:person) RETURN p.name, r.weight, q.name;
      """
    Then the result should contain:
      | p.name | r.weight | q.name |
      | '张三'  | 0.8      | '李四'  |
    Then drop all graph