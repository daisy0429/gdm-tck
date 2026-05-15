#encoding: utf-8

Feature: 删除图-删除图、删除再重建、删除后的关联影响（图模型、图、数据）

  Background:
    Given drop all graph

  # ============================================================
  # 1. 删除图
  # ============================================================

  Scenario: [1-1] 删除图-空图
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing query:
      """
      show graph yield name;
      """
    And the result should contain:
      | name       |
      | 'my_graph' |
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
    When executing query:
      """
      show graph where name = 'my_graph';
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [1-2] 删除图-有模型的图
    When executing queries without error:
      """
      DROP GRAPH IF EXISTS my_graph
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string, age integer, p1 datetime, p2 date, p3 localdatetime,
        p4 time, p5 localtime, p6 point2d, p7 point3d, p8 bool, p9 float32, p10 float64})
      }
      """
    And executing queries without error:
      """
      DROP GRAPH my_graph;
      """
    When executing query:
      """
      show graph where name = 'my_graph';
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [1-3] 删除图-有模型且有索引的图
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string, age int64})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE INDEX person_name_index FOR (n:Person) ON (n.name);
      """
    When executing query:
      """
      SHOW INDEXES YIELD name;
      """
    And the result should contain:
      | name                |
      | 'person_name_index' |
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
    When executing query:
      """
      show graph where name = 'my_graph';
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [1-4] 删除图-有数据的图
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string, age int64}),
        (animal:Animal{name string, age int64}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"李明", age:25}),
        (b:Person{name:"张文", age:35}),
        (c:Person{name:"王武", age:18}),
        (d:Animal{name:"哆哆", age:1}),
        (e:Animal{name:"萌萌", age:3}),
        (a)-[:Likes{year:datetime('2023-08-01T12:30:00Z')}]->(d),
        (b)-[:Likes{year:datetime('2025-03-30T16:00:00Z')}]->(d),
        (c)-[:Likes{year:datetime('2018-05-03T13:00:00Z')}]->(d),
        (c)-[:Likes{year:datetime('2024-01-01T16:00:00Z')}]->(e);
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
      """
    When executing query:
      """
      show graph where name = 'my_graph';
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [1-5] 删除图-系统图-sys/default不允许删除
    When executing query:
      """
      DROP GRAPH sys
      """
    Then the error should be contain:
      """
      Deleting system graph is not allowed
      """
    When executing query:
      """
      DROP GRAPH default
      """
    Then the error should be contain:
      """
      Deleting system graph is not allowed
      """

  Scenario: [1-6] 删除图-不存在的图
    When executing query:
      """
      DROP GRAPH my_graph;
      """
    Then the error should be contain:
      """
      [1605]Database does not exist
      """
    Then drop all graph

  Scenario: [1-7] 删除图-使用IF EXISTS删除不存在的图
    When executing queries without error:
      """
      DROP GRAPH IF EXISTS my_graph;
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [1-8] 删除图-使用IF EXISTS删除已存在的图
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing queries without error:
      """
      DROP GRAPH IF EXISTS my_graph;
      """
    When executing query:
      """
      show graph where name = 'my_graph';
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [1-9] 删除图-offline状态的图需要先online才能删除
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      show graph yield name,status where name = 'my_graph';
      """
    And the result should contain:
      | name       | status    |
      | 'my_graph' | 'offline' |
    When executing query:
      """
      DROP GRAPH my_graph;
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph ONLINE;
      DROP GRAPH my_graph;
      """
    When executing query:
      """
      show graph where name = 'my_graph';
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [1-10] 删除图-批量删除多个图
    When executing queries without error:
      """
      CREATE GRAPH graph01;
      CREATE GRAPH graph02;
      CREATE GRAPH graph03;
      """
    When executing query:
      """
      show graph yield name;
      """
    Then the result should contain:
      | name      |
      | 'graph01' |
      | 'graph02' |
      | 'graph03' |
      | 'sys'     |
      | 'default' |
    When executing queries without error:
      """
      DROP GRAPH graph01;
      DROP GRAPH graph02;
      DROP GRAPH graph03;
      """
    When executing query:
      """
      show graph yield name;
      """
    Then the result should contain:
      | name      |
      | 'sys'     |
      | 'default' |
    Then drop all graph

  # ============================================================
  # 2. 删除再重建
  # ============================================================

  Scenario: [2-1] 删除图-再重建（空图）
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
      DROP GRAPH my_graph;
      """
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing query:
      """
      show graph yield name;
      """
    And the result should contain:
      | name       |
      | 'my_graph' |
    When executing query:
      """
      SHOW ALL SCHEMA;
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [2-2] 删除图-再重建（有模型的图）
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string, age int64})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"李明", age:25});
      """
    When executing query:
      """
      match (n) return n.name;
      """
    Then the result should contain:
      | n.name |
      | '李明'   |
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string, age int64})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"赵飞", age:25});
      """
    When executing query:
      """
      match (n) return n.name;
      """
    Then the result should contain:
      | n.name |
      | '赵飞'   |
    Then drop all graph

  Scenario: [2-3] 删除图-再重建（不同模型）
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:User{name string})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:User{name:"张三"});
      """
    When executing query:
      """
      match (n) return n.name;
      """
    Then the result should contain:
      | n.name |
      | '张三'   |
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Product{sku string, price float64})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Product{sku:"P001", price:99.9});
      """
    When executing query:
      """
      match (n) return n.sku;
      """
    Then the result should contain:
      | n.sku  |
      | 'P001' |
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema    | propertyName   | propertyTypes | nullable |
      | 'Product' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Product' | 'sku'          | ['string']    | true     |
      | 'Product' | 'price'        | ['float64']   | true     |
    Then drop all graph

  Scenario: [2-4] 删除图-再重建（有数据的图）
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"test"});
      """
    When executing query:
      """
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | 'test' |
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
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
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should be empty
    Then drop all graph

  # ============================================================
  # 3. 删除图关联影响
  # ============================================================

  Scenario: [3-1] 删除图-关联影响-引用图模型的图，不会删除图模型
    Given drop all graph
    Given drop all graphType
    And executing queries without error:
      """
      DROP GRAPH TYPE IF EXISTS my_graph_type;
      """
    Then executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (customer : Customer => {id STRING, name STRING}),
        (account : Account => {no STRING, type STRING}),
        (customer)<-[:HOLDS]-(account),
        (account)-[:TRANSFER {amount INTEGER}]->(account)
      };
      """
    And executing queries without error:
      """
      CREATE GRAPH my_graph my_graph_type;
      """
    When executing query:
      """
      SHOW GRAPH TYPE;
      """
    Then the result count should be [1]
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
    When executing query:
      """
      SHOW GRAPH TYPE;
      """
    Then the result count should be [1]
    Then drop all graphType
    Then drop all graph

  Scenario: [3-2] 删除图-关联影响-删除引用图模型的图后，可以用同一图模型创建新图
    Given drop all graph
    Given drop all graphType
    And executing queries without error:
      """
      DROP GRAPH TYPE IF EXISTS my_graph_type;
      """
    Then executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (person:Person{name string, age int64}),
        (person)-[:KNOWS]->(person)
      };
      """
    And executing queries without error:
      """
      CREATE GRAPH my_graph01 my_graph_type;
      """
    When executing queries without error:
      """
      DROP GRAPH my_graph01;
      """
    When executing queries without error:
      """
      CREATE GRAPH my_graph02 my_graph_type;
      """
    Given an already exist graph:
      """
      my_graph02
      """
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Person' | 'name'         | ['string']    | true     |
      | 'Person' | 'age'          | ['int64']     | true     |
    Then drop all graphType
    Then drop all graph

  Scenario: [3-3] 删除图-关联影响-删除复制图不影响原图
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string, age int64}),
        (animal:Animal{name string, age int64}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    When executing queries without error:
      """
      CREATE GRAPH my_graph01 LIKE my_graph;
      """
    Given an already exist graph:
      """
      my_graph01
      """
    When executing queries without error:
      """
      DROP GRAPH my_graph01;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Person' | 'name'         | ['string']    | true     |
      | 'Person' | 'age'          | ['int64']     | true     |
      | 'Animal' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Animal' | 'name'         | ['string']    | true     |
      | 'Animal' | 'age'          | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'Likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Likes' | 'year'         | ['datetime']  | true     |
    Then drop all graph

  Scenario: [3-4] 删除图-关联影响-删除原图不影响复制图
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string, age int64}),
        (animal:Animal{name string, age int64}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    When executing queries without error:
      """
      CREATE GRAPH my_graph01 LIKE my_graph;
      """
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph01
      """
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Person' | 'name'         | ['string']    | true     |
      | 'Person' | 'age'          | ['int64']     | true     |
      | 'Animal' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Animal' | 'name'         | ['string']    | true     |
      | 'Animal' | 'age'          | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'Likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Likes' | 'year'         | ['datetime']  | true     |
    Then drop all graph

  Scenario: [3-5] 删除图-关联影响-删除原图后复制图可以正常写入数据
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string, age int64}),
        (animal:Animal{name string, age int64}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    When executing queries without error:
      """
      CREATE GRAPH my_graph01 LIKE my_graph;
      """
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph01
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"张三", age:25}),
        (b:Animal{name:"小狗", age:2}),
        (a)-[:Likes{year:datetime('2024-01-01T00:00:00Z')}]->(b);
      """
    When executing query:
      """
      MATCH (p:Person)-[r:Likes]->(a:Animal) RETURN p.name, r.year, a.name;
      """
    Then the result should contain:
      | p.name | r.year              | a.name |
      | '张三'   | '2024-01-01T00:00Z' | '小狗'   |
    Then drop all graph

  Scenario: [3-6] 删除图-关联影响-删除后原数据不可访问
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"test"});
      """
    When executing query:
      """
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | 'test' |
    When executing queries without error:
      """
      DROP GRAPH my_graph;
      """
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
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should be empty
    Then drop all graph