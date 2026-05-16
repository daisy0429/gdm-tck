#encoding: utf-8

Feature: 删除点边标签-基础删除功能、关联影响

  Background:
    Given drop all graph

  # ============================================================
  # 1. 基础删除功能
  # ============================================================

  Scenario: [1-1] 删除点边标签-不存在
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
    When executing query:
      """
      DROP NODE Person;
      """
    Then the error should be contain:
      """
      [1613]Label does not exist. Label name: 'Person'
      """
    When executing query:
      """
      DROP EDGE WorkAt;
      """
    Then the error should be contain:
      """
      [1615]Relation does not exist. Relation name: 'WorkAt'
      """
    # 多个标签删除，只有一个标签不存在
    When executing query:
      """
      DROP NODE 人, Company;
      """
    Then the error should be contain:
      """
      [1613]Label does not exist. Label name: 'Company'
      """
    When executing query:
      """
      DROP EDGE 就读于, Study;
      """
    Then the error should be contain:
      """
      [1615]Relation does not exist. Relation name: 'Study'
      """
    Then drop all graph

  Scenario: [1-2] 删除点边标签-单标签-无业务数据
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
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name;
      """
    Then the result should be, in any order:
      | name    |
      | '人'    |
      | '公司'   |
      | '学校'   |
      | '城市'   |
      | '就读于'  |
      | '朋友'   |
      | '所属城市' |
      | '籍贯'   |
      | '就职于'  |
      | '同事'   |
    When executing queries without error:
      """
      DROP NODE 学校;
      DROP EDGE 籍贯;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name;
      """
    Then the result should be, in any order:
      | name    |
      | '人'    |
      | '公司'   |
      | '城市'   |
      | '就读于'  |
      | '朋友'   |
      | '所属城市' |
      | '就职于'  |
      | '同事'   |
    Then drop all graph

  Scenario: [1-3] 删除点边标签-多标签-无业务数据
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
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name;
      """
    Then the result should be, in any order:
      | name    |
      | '人'    |
      | '公司'   |
      | '学校'   |
      | '城市'   |
      | '就读于'  |
      | '朋友'   |
      | '所属城市' |
      | '籍贯'   |
      | '就职于'  |
      | '同事'   |
    When executing queries without error:
      """
      DROP NODE 人, 学校;
      DROP EDGE 同事, 籍贯;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name;
      """
    Then the result should be, in any order:
      | name    |
      | '公司'   |
      | '城市'   |
      | '就读于'  |
      | '朋友'   |
      | '所属城市' |
      | '就职于'  |
    Then drop all graph

  Scenario: [1-4] 删除点边标签-单标签-有业务数据
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
    Then the result should be, in any order:
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
    # 删除点标签会删除点数据和关联的边数据，不会删除边标签，边标签仍然存在但数量为0
    When executing queries without error:
      """
      DROP NODE 公司;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result should be, in any order:
      | name   | total |
      | '人'    | 5     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '籍贯'   | 5     |
      | '就职于'  | 0     |
      | '同事'   | 1     |
    # 删除边标签不会影响点数据
    When executing queries without error:
      """
      DROP EDGE 籍贯;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result should be, in any order:
      | name   | total |
      | '人'    | 5     |
      | '学校'   | 4     |
      | '城市'   | 4     |
      | '就读于'  | 5     |
      | '朋友'   | 4     |
      | '所属城市' | 4     |
      | '就职于'  | 0     |
      | '同事'   | 1     |
    Then drop all graph

  Scenario: [1-5] 删除点边标签-多标签-有业务数据
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
    Then the result should be, in any order:
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
    # 删除点标签会删除点数据和关联的边数据，不会删除边标签，边标签仍然存在但数量为0
    When executing queries without error:
      """
      DROP NODE 公司, 学校;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result should be, in any order:
      | name   | total |
      | '人'    | 5     |
      | '城市'   | 4     |
      | '就读于'  | 0     |
      | '朋友'   | 4     |
      | '所属城市' | 0     |
      | '籍贯'   | 5     |
      | '就职于'  | 0     |
      | '同事'   | 1     |
    # 删除边标签不会影响点数据
    When executing queries without error:
      """
      DROP EDGE 籍贯, 朋友;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result should be, in any order:
      | name   | total |
      | '人'    | 5     |
      | '城市'   | 4     |
      | '就读于'  | 0     |
      | '所属城市' | 0     |
      | '就职于'  | 0     |
      | '同事'   | 1     |
    Then drop all graph

  Scenario: [1-6] 删除点边标签-删除后重新创建同名标签
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:person {name STRING})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      DROP NODE person;
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD NODE { (:person {age INT64}) };
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name     | properties             |
      | 'person' | ['_PRIMARY_KEY', 'age'] |
    Then drop all graph

  # ============================================================
  # 2. 关联影响
  # ============================================================

  Scenario Outline: [2-1] 删除点边标签-依赖关系-有索引时删除点标签-<indexType>
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
      CREATE INDEX index01 FOR (n:人) ON (n.姓名) OPTIONS {indexConfig: {unique: <indexType>}};
      CREATE INDEX index02 FOR (n:公司) ON (n.名称) OPTIONS {indexConfig: {unique: <indexType>}};
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes, properties WHERE name CONTAINS 'index';
      """
    Then the result should be, in any order:
      | name      | labelsOrTypes | properties |
      | 'index01' | '人'          | ['姓名']    |
      | 'index02' | '公司'        | ['名称']    |
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
      """
      DROP NODE 公司;
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes, properties WHERE name CONTAINS 'index';
      """
    Then the result should be, in any order:
      | name      | labelsOrTypes | properties |
      | 'index01' | '人'          | ['姓名']    |
    Then drop all graph
    Examples:
      | indexType |
      | true      |
      | false     |

  Scenario: [2-2] 删除点边标签-依赖关系-自引用关系的点标签删除
    Given drop all graph
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
    Then the result should be, in any order:
      | name | total |
      | '人'  | 5     |
      | '朋友' | 4     |
    # 删除点标签会删除点数据和关联的边数据，不会删除边标签，边标签仍然存在但数量为0
    When executing queries without error:
      """
      DROP NODE 人;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result should be, in any order:
      | name | total |
      | '朋友' | 0     |
    Then drop all graph

  Scenario: [2-3] 删除点边标签-依赖关系-被多个边引用的点标签删除
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
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    # 删除点标签会删除点数据和关联的边数据，不会删除边标签，边标签仍然存在但数量为0
    When executing queries without error:
      """
      DROP NODE 人;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result should be, in any order:
      | name   | total |
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

  Scenario: [2-4] 删除点边标签-依赖关系-被多层依赖删除根标签
    Given drop all graph
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
    Then the result should be, in any order:
      | name   | total |
      | '人'    | 1     |
      | '学校'   | 1     |
      | '城市'   | 1     |
      | '就读于'  | 1     |
      | '所属城市' | 1     |
    # 删除根标签只会删除关联的边数据，不会删除下级关联边数据，边标签仍然存在但数量为0
    When executing queries without error:
      """
      DROP NODE 人;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result should be, in any order:
      | name   | total |
      | '学校'   | 1     |
      | '城市'   | 1     |
      | '就读于'  | 0     |
      | '所属城市' | 1     |
    Then drop all graph

    # ============================================================
    # 3. 删除后验证
    # ============================================================

  Scenario: [3-1] 删除点标签后验证关联边数据不可查询
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person {name STRING}),
        (:Company {name STRING}),
        (:Person)-[:WorkAt]->(:Company)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person {name:"张三"}), (b:Company {name:"阿里"}), (a)-[:WorkAt]->(b);
      """
    When executing query:
      """
      MATCH (p:Person)-[r:WorkAt]->(c:Company) RETURN p.name, c.name;
      """
    Then the result should contain:
      | p.name | c.name |
      | '张三'  | '阿里'  |
    When executing queries without error:
      """
      DROP NODE Person;
      """
    When executing query:
      """
      MATCH (p:Person)-[r:WorkAt]->(c:Company) RETURN p.name, c.name;
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [3-2] 删除边标签后验证关联点数据仍可查询
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person {name STRING}),
        (:Company {name STRING}),
        (:Person)-[:WorkAt]->(:Company)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Person {name:"张三"}), (b:Company {name:"阿里"}), (a)-[:WorkAt]->(b);
      """
    When executing query:
      """
      MATCH (p:Person) RETURN p.name;
      """
    Then the result should contain:
      | p.name |
      | '张三'  |
    When executing queries without error:
      """
      DROP EDGE WorkAt;
      """
    When executing query:
      """
      MATCH (p:Person) RETURN p.name;
      """
    Then the result should contain:
      | p.name |
      | '张三'  |
    Then drop all graph

  Scenario: [3-3] 删除点标签后无法创建引用该点的边
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person {name STRING}),
        (:Company {name STRING})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      DROP NODE Person;
      """
    When executing query:
      """
      ALTER GRAPH ADD EDGE { (:Person)-[:WorkAt]->(:Company) };
      """
    Then the error should be contain:
      """
      [1613]Label does not exist
      """
    Then drop all graph

  Scenario: [3-4] 删除点标签后索引自动清理
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person {name STRING, age INT64})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE INDEX name_index FOR (n:Person) ON (n.name);
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes;
      """
    Then the result should contain:
      | name         | labelsOrTypes |
      | 'name_index' | 'Person'      |
    When executing queries without error:
      """
      DROP NODE Person;
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes;
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [3-5] 删除边标签后索引自动清理
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person {name STRING}),
        (:Person)-[:Knows {since DATE}]->(:Person)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE INDEX knows_index FOR ()-[r:Knows]-() ON (r.since);
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes WHERE name = "knows_index";
      """
    Then the result should contain:
      | name          | labelsOrTypes |
      | 'knows_index' | 'Knows'       |
    When executing queries without error:
      """
      DROP EDGE Knows;
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes WHERE name = "knows_index";
      """
    Then the result should be empty
    Then drop all graph
