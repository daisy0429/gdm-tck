#encoding: utf-8

Feature: 添加点边标签-添加单个点标签、添加单个边标签、批量添加点边标签、关联关系-点和边、关联关系-点边和图、关联关系-点边和属性

  Background:
    Given drop all graph

  # ============================================================
  # 1. 添加单个点标签
  # ============================================================

  Scenario Outline: [1-1] 添加点标签-标签名校验-混合标签名-<label>
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
      ALTER GRAPH ADD NODE { (:<label> {username STRING NOT NULL })};
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties WHERE name = '<label>';
      """
    Then the result should be, in any order:
      | name      | properties                   |
      | '<label>' | ['_PRIMARY_KEY', 'username'] |
    Then drop all graph
    Examples:
      | label      |
      | test01     |
      | test标签     |
      | 测试标签test01 |
      | 测试标签01     |
      | aa         |
      | AA         |
      | test_abc   |

  Scenario Outline: [1-2] 添加点标签-标签名校验-关键字-<label>
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
      ALTER GRAPH ADD NODE { (:<label> {username STRING NOT NULL })};
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties WHERE name = '<label>';
      """
    Then the result should be, in any order:
      | name      | properties                   |
      | '<label>' | ['_PRIMARY_KEY', 'username'] |
    Then drop all graph
    Examples:
      | label       |
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

  Scenario Outline: [1-3] 添加点标签-标签名校验-特殊字符-<label>
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
      ALTER GRAPH ADD NODE { (:<label>person {username STRING NOT NULL })};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Examples:
      | label       |
      | ！           |
      | 123         |
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
      | \ |
      | ￥           |
      | ……          |
      | `           |
      | ·           |
      | ~           |
      | 【           |
      | 】           |
      | '           |
      | per son     |

  Scenario: [1-4] 添加点标签-标签名校验-唯一性（重名添加属性）
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
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL })};
      """
    #属性类型冲突，报错
    When executing query:
      """
      ALTER GRAPH ADD NODE { (:person {username INT64 NOT NULL })};
      """
    Then the error should be contain:
      """
      [2910]Column type mismatch
      """
    #属性名不同，应该追加
    When executing queries without error:
      """
      ALTER GRAPH ADD NODE { (:person {name STRING NOT NULL })};
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties WHERE name = 'person';
      """
    Then the result should be, in any order:
      | name     | properties                           |
      | 'person' | ['_PRIMARY_KEY', 'username', 'name'] |
    Then drop all graph

  Scenario: [1-5] 添加点标签-标签名校验-长度限制-等于128
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
      ALTER GRAPH ADD NODE { (:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb {username STRING NOT NULL })};
      """
    When executing query:
      """
      ALTER GRAPH ADD NODE { (:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb {username STRING NOT NULL })};
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    Then drop all graph

  Scenario: [1-6] 添加点标签-描述信息-COMMENT
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
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL }) COMMENT "this is a node table"};
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, description WHERE name = 'person';
      """
    Then the result should be, in any order:
      | name     | description            |
      | 'person' | 'this is a node table' |
    Then drop all graph

  # ============================================================
  # 2. 添加单个边标签
  # ============================================================

  Scenario Outline: [2-1] 添加边标签-标签名校验-混合标签名-<label>
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
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL })};
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:<label>{since LOCALDATETIME}]->(:person)};
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, properties WHERE name = '<label>';
      """
    Then the result should be, in any order:
      | name      | properties                |
      | '<label>' | ['_PRIMARY_KEY', 'since'] |
    Then drop all graph
    Examples:
      | label      |
      | test01     |
      | test标签     |
      | 测试标签test01 |
      | 测试标签01     |
      | aa         |
      | AA         |
      | test_abc   |

  Scenario Outline: [2-2] 添加边标签-标签名校验-关键字-<label>
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
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL })};
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:<label>{since LOCALDATETIME}]->(:person)};
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, properties WHERE name = '<label>';
      """
    Then the result should be, in any order:
      | name      | properties                |
      | '<label>' | ['_PRIMARY_KEY', 'since'] |
    Then drop all graph
    Examples:
      | label       |
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

  Scenario Outline: [2-3] 添加边标签-标签名校验-特殊字符-<label>
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
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL })};
      """
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:<label>likes {since LOCALDATETIME}]->(:person)};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Examples:
      | label       |
      | ！           |
      | 123         |
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
      | \ |
      | ￥           |
      | ……          |
      | `           |
      | ·           |
      | ~           |
      | 【           |
      | 】           |
      | '           |
      | per son     |

  Scenario: [2-4] 添加边标签-标签名校验-唯一性（重名边标签添加属性）
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
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL })};
      ALTER GRAPH ADD NODE { (:animal {name STRING NOT NULL })};
      ALTER GRAPH ADD EDGE { (:person)-[:likes{since LOCALDATETIME}]->(:animal)};
      """
    #属性类型冲突，报错
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:likes{since INT64}]->(:animal)};
      """
    Then the error should be contain:
      """
      [2910]Column type mismatch
      """
    #属性列不同，应该追加
    When executing queries without error:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:likes{year INT64}]->(:animal)};
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, properties WHERE name = 'likes';
      """
    Then the result should be, in any order:
      | name    | properties                        |
      | 'likes' | ['_PRIMARY_KEY', 'since', 'year'] |
    #同名边可正常添加
    When executing queries without error:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:likes{year INT64}]->(:person)};
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, properties, mapping WHERE name = 'likes';
      """
    Then the result should be, in any order:
      | name    | properties                        | mapping                              |
      | 'likes' | ['_PRIMARY_KEY', 'since', 'year'] | ['person->animal', 'person->person'] |
    Then drop all graph

  Scenario: [2-5] 添加边标签-标签名校验-长度限制-等于128
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
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL })};
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb{since LOCALDATETIME}]->(:person)};
      """
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb{since LOCALDATETIME}]->(:person)};
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    Then drop all graph

  Scenario: [2-6] 添加边标签-描述信息-COMMENT
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
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL })};
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:likes{since LOCALDATETIME}]->(:person) COMMENT "this is a edge table"};
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, description WHERE name = 'likes';
      """
    Then the result should be, in any order:
      | name    | description            |
      | 'likes' | 'this is a edge table' |
    Then drop all graph

  # ============================================================
  # 3. 批量添加点边标签
  # ============================================================

  Scenario: [3-1] 批量添加标签-同时添加多个点标签
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
        (:Person {username STRING NOT NULL, gender STRING}),
        (:Company {name STRING NOT NULL, since INT64}),
        (:University)
      };
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name         | properties                             |
      | 'Person'     | ['_PRIMARY_KEY', 'username', 'gender'] |
      | 'Company'    | ['_PRIMARY_KEY', 'name', 'since']      |
      | 'University' | ['_PRIMARY_KEY']                       |
    Then drop all graph

  Scenario: [3-2] 批量添加标签-同时添加多个边标签
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
      ALTER GRAPH ADD NODE { (:Person {username STRING NOT NULL}), (:Company {name STRING NOT NULL}), (:University) };
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:Person)-[:WorkAt]->(:Company),
        (:Person)-[:StudyAt]->(:University),
        (:Person)-[:Knows]->(:Person)
      };
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name      | properties       |
      | 'WorkAt'  | ['_PRIMARY_KEY'] |
      | 'StudyAt' | ['_PRIMARY_KEY'] |
      | 'Knows'   | ['_PRIMARY_KEY'] |
    Then drop all graph

  Scenario: [3-3] 批量添加标签-同时添加点边标签
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
        (:Person {username STRING NOT NULL, gender STRING}),
        (:Company {name STRING NOT NULL, since INT64}),
        (:University),
        (:Person)-[:WorkAt]->(:Company),
        (:Person)-[:StudyAt]->(:University),
        (:Person)-[:Knows]->(:Person)
      };
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name         | properties                             |
      | 'Person'     | ['_PRIMARY_KEY', 'username', 'gender'] |
      | 'Company'    | ['_PRIMARY_KEY', 'name', 'since']      |
      | 'University' | ['_PRIMARY_KEY']                       |
      | 'WorkAt'     | ['_PRIMARY_KEY']                       |
      | 'StudyAt'    | ['_PRIMARY_KEY']                       |
      | 'Knows'      | ['_PRIMARY_KEY']                       |
    Then drop all graph

  Scenario: [3-4] 批量添加标签-重名点标签添加属性
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
        (:Person {username STRING NOT NULL})
      };
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:Person {gender STRING})
      };
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties WHERE name = 'Person';
      """
    Then the result should be, in any order:
      | name     | properties                             |
      | 'Person' | ['_PRIMARY_KEY', 'username', 'gender'] |
    Then drop all graph

  Scenario: [3-5] 批量添加标签-重名边标签添加属性
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
      ALTER GRAPH ADD NODE { (:Person {username STRING NOT NULL}) };
      ALTER GRAPH ADD BATCH {
        (:Person)-[:Knows{since DATETIME}]->(:Person)
      };
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:Person)-[:Knows{year INT64}]->(:Person)
      };
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, properties WHERE name = 'Knows';
      """
    Then the result should be, in any order:
      | name    | properties                        |
      | 'Knows' | ['_PRIMARY_KEY', 'since', 'year'] |
    Then drop all graph

  # ============================================================
  # 4. 关联关系-点和边
  # ============================================================

  Scenario: [4-1] 添加边标签-点标签不存在时创建边标签
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
      ALTER GRAPH ADD EDGE { (:person)-[:likes{since LOCALDATETIME}]->(:person)};
      """
    Then the error should be contain:
      """
      [1613]Label does not exist
      """
    Then drop all graph

  Scenario: [4-2] 添加边标签-点标签为空时创建边标签
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
      ALTER GRAPH ADD EDGE { ()-[:likes{since LOCALDATETIME}]->()};
      """
    Then the error should be contain:
      """
      [2851]Mapping relation is invalid, startNodeTableName or endNodeTableName is empty
      """
    Then drop all graph

  Scenario: [4-3] 添加边标签-边的方向性（只支持有向边）
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
      ALTER GRAPH ADD NODE { (:person {name STRING, age INT64})};
      ALTER GRAPH ADD EDGE { (:person)-[:knows]->(:person)};
      ALTER GRAPH ADD EDGE { (:person)<-[:knows1]-(:person)};
      """
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:knows]-(:person)};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Then drop all graph

  Scenario: [4-4] 添加标签-标签个数上限
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When repeating query in (100):
      """
      ALTER GRAPH ADD NODE { (:person${n} {name STRING, age INT64})};
      ALTER GRAPH ADD EDGE { (:person${n})-[:knows${n}]->(:person${n})};
      """
    When executing query:
      """
      call db.meta.count();
      """
    Then the result should be, in any order:
      | type                      | count |
      | 'labels'                  | 100   |
      | 'relationshipTypes'       | 100   |
      | 'labelIndexes'            | 100   |
      | 'relationshipTypeIndexes' | 100   |
      | 'vertices'                | 0     |
      | 'edges'                   | 0     |
    Then drop all graph

  # ============================================================
  # 5. 关联关系-点边和图
  # ============================================================

  Scenario: [5-1] 点边标签在不同图中的独立性
    When executing queries without error:
      """
      CREATE GRAPH my_graph01;
      CREATE GRAPH my_graph02;
      """
    Given an already exist graph:
      """
      my_graph01
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL})};
      CREATE (:person {username: 'alice'});
      """
    When executing query:
      """
      MATCH (n) RETURN n.username;
      """
    Then the result should contain:
      | n.username |
      | 'alice'    |
    Given an already exist graph:
      """
      my_graph02
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD NODE { (:person {user_id INTEGER NOT NULL, email STRING})};
      CREATE (:person {user_id: 1, email: 'alice@example.com'});
      """
    When executing query:
      """
      MATCH (n) RETURN n.user_id;
      """
    Then the result should contain:
      | n.user_id |
      | 1         |
    Then drop all graph

  Scenario: [5-2] 跨图引用标签（不支持）
    When executing queries without error:
      """
      CREATE GRAPH my_graph01;
      CREATE GRAPH my_graph02;
      """
    Given an already exist graph:
      """
      my_graph01
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD NODE { (:person {username STRING NOT NULL})};
      """
    Given an already exist graph:
      """
      my_graph02
      """
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:likes]->(:person)};
      """
    Then the error should be contain:
      """
      [1613]Label does not exist
      """
    Then drop all graph

  Scenario: [5-3] 删除图同时清理标签
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
      ALTER GRAPH ADD NODE { (:person {name STRING, age INT64}), (:animal {name STRING, age INT64})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {year DATETIME}]->(:animal)};
      CREATE (a:person{name:"李明", age:25}),
        (b:person{name:"张文", age:35}),
        (c:person{name:"王武", age:18}),
        (d:animal{name:"哆哆", age:1}),
        (e:animal{name:"萌萌", age:3}),
        (a)-[:likes{year:datetime('2023-08-01T12:30:00Z')}]->(d),
        (b)-[:likes{year:datetime('2025-03-30T16:00:00Z')}]->(d),
        (c)-[:likes{year:datetime('2018-05-03T13:00:00Z')}]->(d),
        (c)-[:likes{year:datetime('2024-01-01T16:00:00Z')}]->(e);
      """
    When executing query:
      """
      call db.meta.count();
      """
    Then the result should be, in any order:
      | type                      | count |
      | 'labels'                  | 2     |
      | 'relationshipTypes'       | 1     |
      | 'labelIndexes'            | 2     |
      | 'relationshipTypeIndexes' | 1     |
      | 'vertices'                | 5     |
      | 'edges'                   | 4     |
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing query:
      """
      SHOW ALL SCHEMA;
      """
    Then the result should be empty
    Then drop all graph

  # ============================================================
  # 6. 关联关系-点边和属性
  # ============================================================

  Scenario Outline: [6-1] 属性名称校验-混合名称-<property>
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
      ALTER GRAPH ADD NODE { (:person {<property> STRING NOT NULL})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes{<property> LOCALDATETIME}]->(:person)};
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties WHERE name = 'person';
      """
    Then the result should be, in any order:
      | name     | properties                     |
      | 'person' | ['_PRIMARY_KEY', '<property>'] |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, properties WHERE name = 'likes';
      """
    Then the result should be, in any order:
      | name    | properties                     |
      | 'likes' | ['_PRIMARY_KEY', '<property>'] |
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

  Scenario Outline: [6-2] 属性名称校验-特殊字符-<property>
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
      ALTER GRAPH ADD NODE { (:person {<property>abc STRING})};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:likes{<property>abc DATETIME}]->(:person)};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Examples:
      | property    |
      | ！           |
      | 123         |
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
      | \ |
      | ￥           |
      | ……          |
      | `           |
      | ·           |
      | ~           |
      | 【           |
      | 】           |
      | '           |
      | per son     |

  Scenario: [6-3] 属性名称校验-唯一性
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
      ALTER GRAPH ADD NODE { (:person {name STRING, name INT64})};
      """
    Then the error should be contain:
      """
      [1501]Illegal parameter
      """
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:likes {year DATETIME, year INT64}]->(:person)};
      """
    Then the error should be contain:
      """
      [1501]Illegal parameter
      """
    Then drop all graph

  Scenario: [6-4] 属性名称校验-长度限制-大于128
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
      ALTER GRAPH ADD NODE { (:person {bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb STRING})};
      """
    When executing query:
      """
      ALTER GRAPH ADD NODE { (:person {bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb STRING})};
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    Then drop all graph

  Scenario: [6-5] 属性结构-无属性
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
      ALTER GRAPH ADD NODE { (:person), (:animal)};
      ALTER GRAPH ADD EDGE { (:person)-[:likes]->(:animal)};
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should contain:
      | name     | properties       |
      | 'person' | ['_PRIMARY_KEY'] |
      | 'animal' | ['_PRIMARY_KEY'] |
      | 'likes'  | ['_PRIMARY_KEY'] |
    Then drop all graph

  Scenario: [6-6] 属性结构-单个属性
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
      ALTER GRAPH ADD NODE { (:person {name STRING}), (:animal {id STRING})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {year INT64}]->(:animal)};
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name;
      """
    Then the result should be, in any order:
      | name     |
      | 'person' |
      | 'animal' |
      | 'likes'  |
    Then drop all graph

  Scenario: [6-7] 属性结构-多个属性
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
      ALTER GRAPH ADD NODE { (:person {name STRING, age INT64}), (:animal {id STRING, age INT64})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {year INT64, since DATETIME}]->(:animal)};
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name;
      """
    Then the result should be, in any order:
      | name     |
      | 'person' |
      | 'animal' |
      | 'likes'  |
    Then drop all graph

  Scenario: [6-8] 属性结构-大量属性（25个属性）
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
      ALTER GRAPH ADD NODE {
        (:property_limit_test {
          p1 STRING, p2 STRING, p3 STRING, p4 STRING, p5 STRING,
          p6 INTEGER, p7 INTEGER, p8 INTEGER, p9 INTEGER, p10 INTEGER,
          p11 BOOLEAN, p12 BOOLEAN, p13 BOOLEAN, p14 BOOLEAN, p15 BOOLEAN,
          p16 FLOAT, p17 FLOAT, p18 FLOAT, p19 FLOAT, p20 FLOAT,
          p21 LOCALDATETIME, p22 LOCALDATETIME, p23 LOCALDATETIME, p24 LOCALDATETIME, p25 LOCALDATETIME
        })
      };
      """
    When executing query:
      """
      SHOW NODE property_limit_test PROPERTY;
      """
    Then the result count should be [26]
    Then drop all graph

  Scenario Outline: [6-9] 属性类型-<typeName>
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
      ALTER GRAPH ADD NODE { (:person {typeName <typeName>})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {typeName <typeName>}]->(:person)};
      """
    When executing query:
      """
      SHOW NODE person PROPERTY YIELD propertyName, propertyTypes;
      """
    Then the result should contain:
      | propertyName   | propertyTypes  |
      | '_PRIMARY_KEY' | ['int64']      |
      | 'typeName'     | ['<typeName>'] |
    When executing query:
      """
      SHOW EDGE likes PROPERTY YIELD propertyName, propertyTypes;
      """
    Then the result should contain:
      | propertyName   | propertyTypes  |
      | '_PRIMARY_KEY' | ['int64']      |
      | 'typeName'     | ['<typeName>'] |
    Then drop all graph
    Examples:
      | typeName      |
      | string        |
      | int64         |
      | float64       |
      | date          |
      | time          |
      | datetime      |
      | localtime     |
      | localdatetime |
      | duration      |
      | point2d       |
      | point3d       |
      | bool          |
      | float32       |
      | list<string>  |

  Scenario: [6-10] 属性类型-未知类型
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
      ALTER GRAPH ADD NODE { (:person {name STR})};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:person)-[:likes {year DaTime}]->(:person)};
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Then drop all graph

  Scenario: [6-11] 属性约束-NOT NULL
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
      ALTER GRAPH ADD NODE { (:person {name STRING NOT NULL})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {year INT64 NOT NULL}]->(:person)};
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
      CREATE (a:person {name:"张三"}),(b:person {name:"李四"}),(a)-[:likes]->(b);
      """
    Then the error should be contain:
      """
      [1645]Col is null
      """
    Then drop all graph

  Scenario: [6-12] 属性约束-PRIMARY_KEY
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
      ALTER GRAPH ADD NODE { (:person {_PRIMARY_KEY STRING})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {_PRIMARY_KEY STRING}]->(:person)};
      """
    When executing query:
      """
      CREATE (a:person);
      """
    Then the error should be contain:
      """
      [2743]The primary key column type of person must be string
      """
    When executing queries without error:
      """
      CREATE (a:person {_PRIMARY_KEY:"person100"});
      """
    When executing query:
      """
      CREATE (a:person{_PRIMARY_KEY:"person100"}),(a)-[:likes]->(a);
      """
    Then the error should be contain:
      """
      [2743]The primary key column type of likes must be string
      """
    When executing queries without error:
      """
      CREATE (a:person{_PRIMARY_KEY:"person100"}),(a)-[:likes{_PRIMARY_KEY:"likes200"}]->(a);
      """
    Then drop all graph

  Scenario: [6-13] 属性隔离-在不同标签中同名
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
      ALTER GRAPH ADD NODE { (:person {name STRING}), (:animal {name STRING})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {year INT64}]->(:person)};
      ALTER GRAPH ADD EDGE { (:person)-[:knows {year INT64}]->(:animal)};
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name     | properties               |
      | 'person' | ['_PRIMARY_KEY', 'name'] |
      | 'animal' | ['_PRIMARY_KEY', 'name'] |
      | 'likes'  | ['_PRIMARY_KEY', 'year'] |
      | 'knows'  | ['_PRIMARY_KEY', 'year'] |
    Then drop all graph

  Scenario: [6-14] 属性隔离-在点边标签中同名
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
      ALTER GRAPH ADD NODE { (:person {id STRING})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {id INT64}]->(:person)};
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name     | properties             |
      | 'person' | ['_PRIMARY_KEY', 'id'] |
      | 'likes'  | ['_PRIMARY_KEY', 'id'] |
    Then drop all graph

  Scenario: [6-15] 属性描述信息-COMMENT
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
      ALTER GRAPH ADD NODE { (:person {name STRING COMMENT "this is a node property"})};
      ALTER GRAPH ADD EDGE { (:person)-[:likes {year INT64 COMMENT "this is an edge property"}]->(:person)};
      """
    #备注信息无法查询出来
    Then drop all graph