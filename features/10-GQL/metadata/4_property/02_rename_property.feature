#encoding: utf-8

Feature: 属性列重命名--基础重命名功能，关联影响（有数据、无数据、索引、属性约束等）

  Background:
    Given drop all graph

  # ============================================================
  # 1. 基础重命名功能
  # ============================================================

  Scenario Outline: [1-1] 属性列重命名-正确重命名-<property>
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
        (:person)-[:likes{year FLOAT32}]->(:person)
      };
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'name'         | ['string']    | false    |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'likes' | 'year'         | ['float32']   | true     |
    When executing queries without error:
      """
      ALTER NODE person name RENAME TO <property>;
      ALTER EDGE likes year RENAME TO <property>;
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | '<property>'   | ['string']    | false    |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'likes' | '<property>'   | ['float32']   | true     |
    Then drop all graph
    Examples:
      | property      |
      | test01        |
      | test标签       |
      | 测试标签test01  |
      | 测试标签01      |
      | aa            |
      | AA            |
      | test_abc      |

  Scenario: [1-2] 属性列重命名-重命名不存在的属性列
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
        (:person)-[:likes{year FLOAT32}]->(:person)
      };
      """
    When executing query:
      """
      ALTER NODE person username RENAME TO un;
      """
    Then the error should be contain:
      """
      [1609]Column does not exist. Column name: 'username'
      """
    When executing query:
      """
      ALTER EDGE likes since RENAME TO sc;
      """
    Then the error should be contain:
      """
      [1609]Column does not exist. Column name: 'since'
      """
    Then drop all graph

  Scenario: [1-3] 属性列重命名-重命名为已存在的属性列
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
        (:person {name STRING NOT NULL, age INT64}),
        (:person)-[:likes{year FLOAT32}]->(:person)
      };
      """
    When executing query:
      """
      ALTER NODE person name RENAME TO age;
      """
    Then the error should be contain:
      """
      [1610]Column already exists. Column name: 'age'
      """
    When executing query:
      """
      ALTER EDGE likes year RENAME TO year;
      """
    Then the error should be contain:
      """
      [1610]Column already exists. Column name: 'year'
      """
    Then drop all graph

  Scenario: [1-4] 属性列重命名-重命名为空属性
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
        (:person)-[:likes{year FLOAT32}]->(:person)
      };
      """
    When executing query:
      """
      ALTER NODE person name RENAME TO ` `;
      """
    Then the error should be contain:
      """
      [1503]Illegal name
      """
    When executing query:
      """
      ALTER EDGE likes year RENAME TO ` `;
      """
    Then the error should be contain:
      """
      [1503]Illegal name
      """
    Then drop all graph

  Scenario Outline: [1-5] 属性列重命名-重命名为特殊字符-<property>
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
        (:person)-[:likes{year FLOAT32}]->(:person)
      };
      """
    When executing query:
      """
      ALTER NODE person name RENAME TO <property>v;
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    When executing query:
      """
      ALTER EDGE likes year RENAME TO <property>e;
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Then drop all graph
    Examples:
      | property    |
      | ！          |
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
      | '           |
      | ;           |
      | ,           |
      | .           |
      | /           |
      | ?           |
      | \|undefined |
      | ￥          |
      | ……          |
      | `           |
      | ·           |
      | ~           |
      | 【          |
      | 】          |
      | '           |

  Scenario: [1-6] 属性列重命名-长度限制
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
        (:person)-[:likes{since LOCALDATETIME}]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person name RENAME TO bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      ALTER EDGE likes since RENAME TO bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    When executing query:
      """
      ALTER NODE person name RENAME TO aabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    When executing query:
      """
      ALTER EDGE likes since RENAME TO aabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    Then drop all graph

  Scenario: [1-7] 属性列重命名-连续重命名
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
        (:person {name STRING NOT NULL})
      };
      """
    Then executing query:
      """
      CREATE (a:person { name:"李明"});
      """
    When executing query:
      """
      ALTER NODE person name RENAME TO name01;
      """
    Then executing query:
      """
      CREATE (a:person { name01:"张三"});
      """
    When executing query:
      """
      ALTER NODE person name01 RENAME TO name02;
      """
    When executing query:
      """
      MATCH (n:person) RETURN n;
      """
    Then the result should be, in any order:
      | n                         |
      | (:person {name02: '张三'}) |
      | (:person {name02: '李明'}) |
    Then drop all graph

  Scenario: [1-8] 属性列重命名-重命名后数据类型保持不变
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
        (:person {name STRING NOT NULL, age INT64}),
        (:person)-[:likes{weight FLOAT64}]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person age RENAME TO user_age;
      ALTER EDGE likes weight RENAME TO like_weight;
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'name'         | ['string']    | false    |
      | 'person' | 'user_age'     | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'likes' | 'like_weight'  | ['float64']   | true     |
    Then drop all graph

  Scenario: [1-9] 属性列重命名-重命名后数据值保持不变
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
        (:person {name STRING, score FLOAT64})
      };
      """
    Then executing query:
      """
      CREATE (a:person { name:"张三", score:95.5});
      """
    When executing query:
      """
      ALTER NODE person score RENAME TO exam_score;
      """
    When executing query:
      """
      MATCH (n:person) RETURN n.name, n.exam_score;
      """
    Then the result should contain:
      | n.name | n.exam_score |
      | '张三'  | 95.5         |
    Then drop all graph

  Scenario: [1-10] 属性列重命名-批量重命名多个属性
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
        (:person {name STRING, age INT64, email STRING})
      };
      """
    When executing queries without error:
      """
      ALTER NODE person name RENAME TO user_name;
      ALTER NODE person age RENAME TO user_age;
      ALTER NODE person email RENAME TO user_email;
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'user_name'    | ['string']    | true     |
      | 'person' | 'user_age'     | ['int64']     | true     |
      | 'person' | 'user_email'   | ['string']    | true     |
    Then drop all graph

  Scenario: [1-11] 属性列重命名-重命名后查询语句兼容性
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
        (:person {name STRING, city STRING})
      };
      """
    Then executing query:
      """
      CREATE (a:person { name:"张三", city:"北京"});
      """
    When executing query:
      """
      ALTER NODE person city RENAME TO location;
      """
    When executing query:
      """
      MATCH (n:person) WHERE n.location = '北京' RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | '张三' |
    When executing query:
      """
      MATCH (n:person) WHERE n.city = '北京' RETURN n.name;
      """
    Then the result should be empty
    Then drop all graph

  # ============================================================
  # 2. 关联影响
  # ============================================================

  Scenario: [2-1] 属性列重命名-关联影响-无业务数据
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
        (:person)-[:likes{since DATETIME}]->(:person)
      };
      """
    Then executing queries without error:
      """
      ALTER NODE person name RENAME TO name01;
      ALTER EDGE likes since RENAME TO since01;
      """
    When executing query:
      """
      CREATE (a:person { name01:"张三"}),(b:person {name01:"李明"}),(a)-[:likes {since01:datetime('2023-06-01T12:30:00Z')}]->(b);
      """
    When executing query:
      """
      MATCH (n:person) RETURN n;
      """
    Then the result should be, in any order:
      | n                          |
      | (:person {name01: '张三'})  |
      | (:person {name01: '李明'})  |
    When executing query:
      """
      MATCH ()-[r]->() RETURN r;
      """
    Then the result should be, in any order:
      | r                                        |
      | [:likes {since01: '2023-06-01T12:30Z'}]  |
    Then drop all graph

  Scenario: [2-2] 属性列重命名-关联影响-有业务数据
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
        (:person)-[:likes{since DATETIME}]->(:person)
      };
      """
    Then executing query:
      """
      CREATE (a:person { name:"张三"}),(b:person {name:"李明"}),(a)-[:likes {since:datetime('2023-06-01T12:30:00Z')}]->(b);
      """
    Then executing queries without error:
      """
      ALTER NODE person name RENAME TO name01;
      ALTER EDGE likes since RENAME TO since01;
      """
    When executing query:
      """
      CREATE (a:person { name01:"李四"}),(b:person {name01:"王五"}),(a)-[:likes {since01:datetime('2025-06-01T12:30:00Z')}]->(b);
      """
    When executing query:
      """
      MATCH (n:person) RETURN n;
      """
    Then the result should be, in any order:
      | n                          |
      | (:person {name01: '张三'})  |
      | (:person {name01: '李明'})  |
      | (:person {name01: '李四'})  |
      | (:person {name01: '王五'})  |
    When executing query:
      """
      MATCH ()-[r]->() RETURN r;
      """
    Then the result should be, in any order:
      | r                                        |
      | [:likes {since01: '2023-06-01T12:30Z'}]  |
      | [:likes {since01: '2025-06-01T12:30Z'}]  |
    Then drop all graph

  Scenario: [2-3] 属性列重命名-关联影响-索引（不支持重命名，需先删除索引）
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
        (:person)-[:likes{since DATETIME}]->(:person)
      };
      """
    When executing queries without error:
      """
      CREATE INDEX indexP ON NODE person (name) OPTIONS {indexConfig: {unique: true}};
      """
    Then executing query:
      """
      CREATE (a:person { name:"张三"}),(b:person {name:"李明"}),(a)-[:likes {since:datetime('2023-06-01T12:30:00Z')}]->(b);
      """
    # 设置了索引的属性名称不支持重命名
    When executing query:
      """
      ALTER NODE person name RENAME TO name01;
      """
    Then the error should be contain:
      """
      [1639]Col is used by index
      """
    # 删除索引后再次重命名，再次创建索引
    When executing queries without error:
      """
      DROP INDEX indexP;
      """
    Then executing queries without error:
      """
      ALTER NODE person name RENAME TO name01;
      """
    When executing queries without error:
      """
      CREATE INDEX indexP ON NODE person (name01) OPTIONS {indexConfig: {unique: false}};
      """
    When executing queries without error:
      """
      SHOW INDEXES YIELD labelsOrTypes, properties, uniqueness WHERE labelsOrTypes = 'person';
      """
    Then the result should be, in any order:
      | labelsOrTypes | properties        | uniqueness  |
      | 'person'      | ['_PRIMARY_KEY']  | 'UNIQUE'    |
      | 'person'      | ['name01']        | 'NONUNIQUE' |
    When executing query:
      """
      MATCH (n:person) RETURN n;
      """
    Then the result should be, in any order:
      | n                          |
      | (:person {name01: '张三'})  |
      | (:person {name01: '李明'})  |
    Then drop all graph

  Scenario: [2-4] 属性列重命名-关联影响-属性约束NOT NULL保持不变
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
        (:person)-[:likes{since DATETIME}]->(:person)
      };
      """
    Then executing query:
      """
      CREATE (a:person { name:"张三"}),(b:person {name:"李明"}),(a)-[:likes {since:datetime('2023-06-01T12:30:00Z')}]->(b);
      """
    When executing query:
      """
      ALTER NODE person name RENAME TO name01;
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
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'name01'       | ['string']    | false    |
    When executing query:
      """
      MATCH (n:person) RETURN n;
      """
    Then the result should be, in any order:
      | n                          |
      | (:person {name01: '张三'})  |
      | (:person {name01: '李明'})  |
    Then drop all graph

  Scenario: [2-5] 属性列重命名-关联影响-主键列不允许重命名
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
        (:person)-[:likes{since DATETIME}]->(:person)
      };
      """
    Then executing query:
      """
      CREATE (a:person { name:"张三"}),(b:person {name:"李明"}),(a)-[:likes {since:datetime('2023-06-01T12:30:00Z')}]->(b);
      """
    When executing query:
      """
      ALTER NODE person _PRIMARY_KEY RENAME TO key;
      """
    Then the error should be contain:
      """
      [1639]Col is used by index
      """
    Then drop all graph