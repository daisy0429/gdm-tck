#encoding: utf-8

Feature: 清空图：清空整图、清空点标签、清空边标签、关联影响等

  Background:
    Given drop all graph

  # ============================================================
  # 1. 清空整图
  # ============================================================

  Scenario: [1-1] 清空图-空图
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
      TRUNCATE my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      call db.meta.count();
      """
    Then the result should be, in any order:
      | type                      | count |
      | 'labels'                  | 0     |
      | 'relationshipTypes'       | 0     |
      | 'labelIndexes'            | 0     |
      | 'relationshipTypeIndexes' | 0     |
      | 'vertices'                | 0     |
      | 'edges'                   | 0     |
    Then drop all graph

  Scenario: [1-2] 清空图-有模型的图（无数据）
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string}),
        (animal:Animal{name string}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    Given an already exist graph:
      """
      my_graph
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
      | 'vertices'                | 0     |
      | 'edges'                   | 0     |
    When executing queries without error:
      """
      TRUNCATE my_graph;
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
      | 'vertices'                | 0     |
      | 'edges'                   | 0     |
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name;
      """
    Then the result should be, in any order:
      | name     |
      | 'Person' |
      | 'Animal' |
      | 'Likes'  |
    Then drop all graph

  Scenario: [1-3] 清空图-有数据的图
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
      """
      call db.meta.count();
      """
    Then the result should be, in any order:
      | type                      | count |
      | 'labels'                  | 4     |
      | 'relationshipTypes'       | 6     |
      | 'labelIndexes'            | 4     |
      | 'relationshipTypeIndexes' | 6     |
      | 'vertices'                | 15    |
      | 'edges'                   | 22    |
    When executing queries without error:
      """
      TRUNCATE my_graph;
      """
    When executing queries without error:
      """
      call db.meta.count();
      """
    Then the result should be, in any order:
      | type                      | count |
      | 'labels'                  | 4     |
      | 'relationshipTypes'       | 6     |
      | 'labelIndexes'            | 4     |
      | 'relationshipTypeIndexes' | 6     |
      | 'vertices'                | 0     |
      | 'edges'                   | 0     |
    When executing query:
      """
      MATCH (n:人)-[r:就读于]->(m) RETURN n, r, m;
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [1-4] 清空图-不存在的图
    When executing query:
      """
      TRUNCATE my_graph;
      """
    Then the error should be contain:
      """
      [1605]Database does not exist
      """
    Then drop all graph

  Scenario: [1-5] 清空图-系统图sys不允许清空
    When executing query:
      """
      TRUNCATE sys;
      """
    Then the error should be contain:
      """
      [2852]Truncating system graph is not allowed
      """
    Then drop all graph

  Scenario: [1-6] 清空图-系统图default允许清空
    Given an already exist graph:
      """
      default
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:person {name STRING, age INT64}),
          (:animal {id STRING, age INT64}),
          (:person)-[:likes {year INT64, since DateTime}]->(:animal)
      };
      """
    Then executing queries without error:
      """
      CREATE (a:person {name:"李明", age:27}),
        (b:animal {id:"哆哆", age:2}),
        (a)-[:likes {year:2, since:datetime('2023-08-01T12:30:00Z')}]->(b);
      """
    Then executing query:
      """
      MATCH (n)-[r]->(m) RETURN n, m, r;
      """
    And the result should be, in any order:
      | n                              | m                           | r                                              |
      | (:person {name: '李明', age:27}) | (:animal {id: '哆哆', age:2}) | [:likes {year: 2, since: '2023-08-01T12:30Z'}] |
    When executing queries without error:
      """
      TRUNCATE default;
      """
    Then executing query:
      """
      MATCH (n)-[r]->(m) RETURN n, m, r;
      """
    Then the result should be empty
    # 因为default无法删除，通过删除点边标签恢复到空图状态
    When executing queries without error:
      """
      DROP NODE person, animal;
      DROP EDGE likes;
      """
    Then drop all graph

  Scenario: [1-7] 清空图-offline状态的图不允许清空
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      TRUNCATE my_graph;
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph ONLINE;
      """
    Then drop all graph

  Scenario: [1-8] 清空图-多次连续清空后重新写入数据
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
      CREATE (a:Person{name:"张三"});
      CREATE (b:Person{name:"李四"});
      """
    When executing query:
      """
      MATCH (n:Person) RETURN count(n) as count;
      """
    Then the result should be, in any order:
      | count |
      | 2     |
    When executing queries without error:
      """
      TRUNCATE my_graph;
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"王五"});
      """
    When executing query:
      """
      MATCH (n:Person) RETURN count(n) as count;
      """
    Then the result should be, in any order:
      | count |
      | 1     |
    When executing queries without error:
      """
      TRUNCATE my_graph;
      """
    When executing query:
      """
      MATCH (n:Person) RETURN count(n) as count;
      """
    Then the result should be, in any order:
      | count |
      | 0     |
    Then drop all graph

  # ============================================================
  # 2. 清空点标签
  # ============================================================

  Scenario: [2-1] 清空点标签-单个标签
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 3     |
      | '同事'   | 1     |
    # 清空点标签会级联清空关联的边标签数据
    When executing queries without error:
      """
      TRUNCATE NODE 公司 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 0     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 0     |
      | '同事'   | 1     |
    Then drop all graph

  Scenario: [2-2] 清空点标签-多个标签
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 3     |
      | '同事'   | 1     |
    # 清空多个点标签
    When executing queries without error:
      """
      TRUNCATE NODE 公司, 学校 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 0     |
      | '学校'   | 0     |
      | '城市'   | 4     |
      | '就读于'  | 0     |
      | '朋友'   | 4     |
      | '所属城市' | 0     |
      | '籍贯'   | 5     |
      | '就职于'  | 0     |
      | '同事'   | 1     |
    Then drop all graph

  Scenario: [2-3] 清空点标签-所有点标签（清空整图）
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 3     |
      | '同事'   | 1     |
    # 清空所有点标签，级联清空所有边标签，相当于全图清空
    When executing queries without error:
      """
      TRUNCATE NODE * ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 0     |
      | '公司'   | 0     |
      | '学校'   | 0     |
      | '城市'   | 0     |
      | '就读于'  | 0     |
      | '朋友'   | 0     |
      | '所属城市' | 0     |
      | '籍贯'   | 0     |
      | '就职于'  | 0     |
      | '同事'   | 0     |
    Then drop all graph

  Scenario: [2-4] 清空点标签-标签不存在
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string}),
        (animal:Animal{name string}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    # 单标签清空-不存在
    When executing query:
      """
      TRUNCATE NODE 人 ON my_graph;
      """
    Then the error should be contain:
      """
      [1613]Label does not exist. Label name: '人'
      """
    # 多标签清空，均不存在
    When executing query:
      """
      TRUNCATE NODE 人, 动物 ON my_graph;
      """
    Then the error should be contain:
      """
      [1613]Label does not exist. Label name: '人'
      """
    # 多标签清空，只有部分不存在
    When executing query:
      """
      TRUNCATE NODE Person, 动物 ON my_graph;
      """
    Then the error should be contain:
      """
      [1613]Label does not exist. Label name: '动物'
      """
    Then drop all graph

  Scenario: [2-5] 清空点标签-清空后保留标签定义，并可重新插入数据
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
      CREATE (a:Person{name:"张三", age:25});
      """
    When executing query:
      """
      SHOW NODE Person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Person' | 'name'         | ['string']    | true     |
      | 'Person' | 'age'          | ['int64']     | true     |
    When executing query:
      """
      MATCH (n:Person) RETURN count(n) as count;
      """
    Then the result should be, in any order:
      | count |
      | 1     |
    When executing queries without error:
      """
      TRUNCATE NODE Person ON my_graph;
      """
    When executing query:
      """
      MATCH (n:Person) RETURN count(n) as count;
      """
    Then the result should be, in any order:
      | count |
      | 0     |
    When executing query:
      """
      SHOW NODE Person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Person' | 'name'         | ['string']    | true     |
      | 'Person' | 'age'          | ['int64']     | true     |
    # 清空后可以重新插入数据
    When executing queries without error:
      """
      CREATE (a:Person{name:"李四", age:30});
      """
    When executing query:
      """
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | '李四' |
    Then drop all graph

  # ============================================================
  # 3. 清空边标签
  # ============================================================

  Scenario: [3-1] 清空边标签-单个边标签
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 3     |
      | '同事'   | 1     |
    # 清空边标签不会影响点数据
    When executing queries without error:
      """
      TRUNCATE EDGE 籍贯 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 0     |
      | '就职于'  | 3     |
      | '同事'   | 1     |
    Then drop all graph

  Scenario: [3-2] 清空边标签-多个边标签
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 3     |
      | '同事'   | 1     |
    # 清空多个边标签
    When executing queries without error:
      """
      TRUNCATE EDGE 籍贯, 朋友 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 0     |
      | '所属城市' | 4     |
      | '籍贯'   | 0     |
      | '就职于'  | 3     |
      | '同事'   | 1     |
    Then drop all graph

  Scenario: [3-3] 清空边标签-所有边标签
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 3     |
      | '同事'   | 1     |
    # 清空所有边标签不会影响点数据
    When executing queries without error:
      """
      TRUNCATE EDGE * ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 0     |
      | '朋友'   | 0     |
      | '所属城市' | 0     |
      | '籍贯'   | 0     |
      | '就职于'  | 0     |
      | '同事'   | 0     |
    Then drop all graph

  Scenario: [3-4] 清空边标签-边标签不存在
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string}),
        (animal:Animal{name string}),
        (person)-[:Likes{year datetime}]->(animal)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    # 单边标签清空-不存在
    When executing query:
      """
      TRUNCATE EDGE 喜欢 ON my_graph;
      """
    Then the error should be contain:
      """
      [1615]Relation does not exist. Relation name: '喜欢'
      """
    # 多边标签清空，均不存在
    When executing query:
      """
      TRUNCATE EDGE 喜欢, 认识 ON my_graph;
      """
    Then the error should be contain:
      """
      [1615]Relation does not exist. Relation name: '喜欢'
      """
    # 多边标签清空，只有部分不存在
    When executing query:
      """
      TRUNCATE EDGE Likes, 认识 ON my_graph;
      """
    Then the error should be contain:
      """
      [1615]Relation does not exist. Relation name: '认识'
      """
    Then drop all graph

  Scenario: [3-5] 清空边标签-清空后保留边标签定义，并可重新插入数据
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string}),
        (:Person)-[:Knows{since date}]->(:Person)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person{name:"张三"}),
        (b:Person{name:"李四"}),
        (a)-[:Knows{since:date('2020-01-01')}]->(b);
      """
    When executing query:
      """
      SHOW EDGE Knows PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'Knows' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Knows' | 'since'        | ['date']      | true     |
    When executing query:
      """
      MATCH ()-[r:Knows]->() RETURN count(r) as count;
      """
    Then the result should be, in any order:
      | count |
      | 1     |
    When executing queries without error:
      """
      TRUNCATE EDGE Knows ON my_graph;
      """
    When executing query:
      """
      MATCH ()-[r:Knows]->() RETURN count(r) as count;
      """
    Then the result should be, in any order:
      | count |
      | 0     |
    When executing query:
      """
      SHOW EDGE Knows PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'Knows' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Knows' | 'since'        | ['date']      | true     |
    # 清空后可以重新插入边数据，点数据不受影响
    When executing queries without error:
      """
      CREATE (c:Person{name:"王五"}),
        (d:Person{name:"赵六"}),
        (c)-[:Knows{since:date('2022-01-01')}]->(d);
      """
    When executing query:
      """
      MATCH ()-[r:Knows]->() RETURN count(r) as count;
      """
    Then the result should be, in any order:
      | count |
      | 1     |
    When executing query:
      """
      MATCH (n:Person) RETURN count(n) as count;
      """
    Then the result should be, in any order:
      | count |
      | 4     |
    Then drop all graph

  Scenario: [3-6] 清空边标签-清空有属性的边标签
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:User{name string}),
        (:Product{sku string}),
        (:User)-[:PURCHASE{amount int64, purchase_time datetime}]->(:Product)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:User{name:"张三"}),
        (b:Product{sku:"P001"}),
        (a)-[:PURCHASE{amount:100, purchase_time:datetime('2024-01-01T00:00:00Z')}]->(b);
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name       | total |
      | 'User'     | 1     |
      | 'Product'  | 1     |
      | 'PURCHASE' | 1     |
    When executing queries without error:
      """
      TRUNCATE EDGE PURCHASE ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name       | total |
      | 'User'     | 1     |
      | 'Product'  | 1     |
      | 'PURCHASE' | 0     |
    When executing query:
      """
      SHOW EDGE PURCHASE PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName    | propertyTypes | nullable |
      | 'PURCHASE' | '_PRIMARY_KEY'  | ['int64']     | false    |
      | 'PURCHASE' | 'amount'        | ['int64']     | true     |
      | 'PURCHASE' | 'purchase_time' | ['datetime']  | true     |
    Then drop all graph

  # ============================================================
  # 4. 关联影响
  # ============================================================

  Scenario Outline: [4-1] 清空点标签-关联影响-索引保留
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE INDEX index01 FOR (n:公司) ON (n.名称) OPTIONS {indexConfig: {unique: <indexType>}};
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes, properties WHERE name CONTAINS 'index';
      """
    Then the result should be, in any order:
      | name      | labelsOrTypes | properties |
      | 'index01' | '公司'          | ['名称']     |
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
      """
      TRUNCATE NODE 公司 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 5     |
      | '公司'   | 0     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 0     |
      | '同事'   | 1     |
    # 索引仍然存在
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes, properties WHERE name CONTAINS 'index';
      """
    Then the result should be, in any order:
      | name      | labelsOrTypes | properties |
      | 'index01' | '公司'          | ['名称']     |
    Then drop all graph
    Examples:
      | indexType |
      | true      |
      | false     |

  Scenario: [4-2] 清空边标签-关联影响-索引保留
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE INDEX index01 FOR ()-[r:就职于]-() ON (r.入职时间);
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes, properties WHERE name CONTAINS 'index';
      """
    Then the result should be, in any order:
      | name      | labelsOrTypes | properties |
      | 'index01' | '就职于'         | ['入职时间']   |
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
      """
      TRUNCATE EDGE 就职于 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name  | total |
      | '人'   | 5     |
      | '公司'  | 2     |
      | '就职于' | 0     |
    # 索引仍然存在
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes, properties WHERE name CONTAINS 'index';
      """
    Then the result should be, in any order:
      | name      | labelsOrTypes | properties |
      | 'index01' | '就职于'         | ['入职时间']   |
    Then drop all graph

  Scenario: [4-3] 清空点标签-自引用关系级联清空
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:人)-[:朋友]->(:人)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明", 年龄:25, 性别:true}),
        (b:人{姓名:"张文", 年龄:35, 性别:true}),
        (c:人{姓名:"王武", 年龄:18, 性别:true}),
        (d:人{姓名:"陈阳", 年龄:21, 性别:true}),
        (e:人{姓名:"周萌", 年龄:22, 性别:false}),
        (a)-[:朋友]->(d),
        (a)-[:朋友]->(b),
        (c)-[:朋友]->(e),
        (e)-[:朋友]->(d);
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name | total |
      | '人'  | 5     |
      | '朋友' | 4     |
    When executing queries without error:
      """
      TRUNCATE NODE 人 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name | total |
      | '人'  | 0     |
      | '朋友' | 0     |
    Then drop all graph

  Scenario: [4-4] 清空点标签-被多个边引用的点标签清空
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:朋友]->(:人),
        (:学校)-[:所属城市]->(:城市),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
      """
      TRUNCATE NODE 人 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 0     |
      | '公司'   | 2     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 0     |
      | '朋友'   | 0     |
      | '所属城市' | 4     |
      | '籍贯'   | 0     |
      | '就职于'  | 0     |
      | '同事'   | 0     |
    Then drop all graph

  Scenario: [4-5] 清空点标签-多层依赖关系清空根标签
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:学校)-[:所属城市]->(:城市)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明", 年龄:25, 性别:true}),
        (b:城市{名称:"成都"}),
        (c:学校{名称:"四川大学", 创办时间:"1896年"}),
        (a)-[:就读于{入学时间:date('2018-09-01'),毕业时间:date('2022-06-30')}]->(c),
        (c)-[:所属城市]->(b);
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 1     |
      | '学校'   | 1     |
      | '城市'   | 1     |
      | '就读于'  | 1     |
      | '所属城市' | 1     |
    # 清空根标签只会清空关联的边数据，不会删除下级关联边数据
    When executing queries without error:
      """
      TRUNCATE NODE 人 ON my_graph;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    And the result should contain:
      | name   | total |
      | '人'    | 0     |
      | '学校'   | 1     |
      | '城市'   | 1     |
      | '就读于'  | 0     |
      | '所属城市' | 1     |
    Then drop all graph