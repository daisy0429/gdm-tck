#encoding: utf-8

Feature: 删除图模型-存在的图模型、不存在的图模型、被图引用的图模型

  Background:
    Given drop all graph
    Given drop all graphType

  # ============================================================
  # 1. 删除图模型基础功能
  # ============================================================

  Scenario: [1-1] 删除图模型-存在的图模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (person:Person{name string, age int64}),
        (animal:Animal{name string, age int64}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name            | gql |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:Animal {name string,age int64}),(:Person {name string,age int64}),(:Person)-[:Likes {year datetime}]->(:Animal) };' |
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    Then executing query:
      """
      SHOW GRAPH TYPE WHERE name = 'my_graph_type';
      """
    Then the result should be empty
    Then drop all graphType

  Scenario: [1-2] 删除图模型-不存在的图模型
    When executing query:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    Then the error should be contain:
      """
      graph type 'my_graph_type' is not exists
      """
    Then drop all graphType

  Scenario: [1-3] 删除图模型-重复删除
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string})
      };
      """
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    When executing query:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    Then the error should be contain:
      """
      graph type 'my_graph_type' is not exists
      """
    Then drop all graphType

  Scenario: [1-4] 删除图模型-删除后重新创建同名图模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string})
      };
      """
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:User{id string})
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE WHERE name = 'my_graph_type';
      """
    And the result should be, in any order:
      | name            | gql |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:User {id string}) };' |
    Then drop all graphType

  Scenario: [1-5] 删除图模型-删除不同名称的多个图模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE graph_type01 {
        (:A{id string})
      };
      CREATE GRAPH TYPE graph_type02 {
        (:B{id string})
      };
      CREATE GRAPH TYPE graph_type03 {
        (:C{id string})
      };
      """
    When executing queries without error:
      """
      DROP GRAPH TYPE graph_type01;
      DROP GRAPH TYPE graph_type02;
      DROP GRAPH TYPE graph_type03;
      """
    When executing query:
      """
      SHOW GRAPH TYPE;
      """
    Then the result should be empty
    Then drop all graphType

  # ============================================================
  # 2. 删除被图引用的图模型
  # ============================================================

  Scenario: [2-1] 删除图模型-已被引用的图模型（空图）
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (person:Person{name string, age int64}),
        (animal:Animal{name string, age int64}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph my_graph_type;
      """
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
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
    When executing queries without error:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'Likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Likes' | 'year'         | ['datetime']  | true     |
    Then drop all graph
    Then drop all graphType

  Scenario: [2-2] 删除图模型-已被引用的图模型（有业务数据）
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (person:Person{name string, age int64}),
        (animal:Animal{name string, age int64}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph my_graph_type;
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
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    When executing queries without error:
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
    Then drop all graph
    Then drop all graphType

  Scenario: [2-3] 删除图模型-被多个图引用的图模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string, age int64})
      };
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph01 my_graph_type;
      CREATE GRAPH my_graph02 my_graph_type;
      CREATE GRAPH my_graph03 my_graph_type;
      """
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
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
    Given an already exist graph:
      """
      my_graph03
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
    Then drop all graph
    Then drop all graphType

  Scenario: [2-4] 删除图模型-被引用的图模型删除后，图仍可正常使用
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string, age int64})
      };
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph my_graph_type;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"张三", age:25});
      """
    When executing query:
      """
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | '张三' |
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (b:Person{name:"李四", age:30});
      """
    When executing query:
      """
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | '张三' |
      | '李四' |
    Then drop all graph
    Then drop all graphType

  Scenario: [2-5] 删除图模型-被引用的图模型删除后，可以创建新图使用原图模型名
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string})
      };
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph01 my_graph_type;
      """
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Product{sku string})
      };
      """
    Then executing queries without error:
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
      | schema    | propertyName   | propertyTypes | nullable |
      | 'Product' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Product' | 'sku'          | ['string']    | true     |
    Then drop all graph
    Then drop all graphType

  Scenario: [2-6] 删除图模型-被引用的图模型删除后，原图结构保持不变
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string, age int64})
      };
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph my_graph_type;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"测试", age:20});
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
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
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
    When executing query:
      """
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | '测试' |
    Then drop all graph
    Then drop all graphType

  Scenario: [2-7] 删除图模型-被引用的图模型删除后，无法基于原图模型创建新图
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string})
      };
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph01 my_graph_type;
      """
    When executing queries without error:
      """
      DROP GRAPH TYPE my_graph_type;
      """
    When executing query:
      """
      CREATE GRAPH my_graph02 my_graph_type;
      """
    Then the error should be contain:
      """
      [2790]Graph type 'my_graph_type' is not exists
      """
    Then drop all graph
    Then drop all graphType