#encoding: utf-8

Feature: 移除属性列--基础移除功能，关联影响（有业务数据、索引、属性约束）等

  Background:
    Given drop all graph

  # ============================================================
  # 1. 基础移除功能
  # ============================================================

  Scenario: [1-1] 移除属性列-不存在
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    Then executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {name STRING NOT NULL}),
        (:person)-[:likes{year FLOAT32}]->(:person)
      };
      """
    # 删除标签下不存在的属性列
    When executing query:
      """
      ALTER NODE person DROP PROPERTY age;
      """
    Then the error should be contain:
      """
      [1609]Column does not exist. Column name: '[age]'
      """
    When executing query:
      """
      ALTER EDGE likes DROP PROPERTY distance;
      """
    Then the error should be contain:
      """
      [1609]Column does not exist. Column name: '[distance]'
      """
    # 多个属性列删除，只有一个属性列不存在
    When executing query:
      """
      ALTER NODE person DROP PROPERTY age, name;
      """
    Then the error should be contain:
      """
      [1609]Column does not exist. Column name: '[age]'
      """
    When executing query:
      """
      ALTER EDGE likes DROP PROPERTY distance, year;
      """
    Then the error should be contain:
      """
      [1609]Column does not exist. Column name: '[distance]'
      """
    # 多个属性列删除，多个属性列都不存在
    When executing query:
      """
      ALTER NODE person DROP PROPERTY age, sex;
      """
    Then the error should be contain:
      """
      [1609]Column does not exist. Column name: '[age sex]'
      """
    When executing query:
      """
      ALTER EDGE likes DROP PROPERTY distance, since;
      """
    Then the error should be contain:
      """
      [1609]Column does not exist. Column name: '[distance since]'
      """
    Then drop all graph

  Scenario: [1-2] 移除属性列-单属性移除-无业务数据
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    Then executing queries without error:
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
    Then executing queries without error:
      """
      ALTER NODE person DROP PROPERTY name;
      ALTER EDGE likes DROP PROPERTY year;
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph

  Scenario: [1-3] 移除属性列-多属性移除-无业务数据
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Given an already exist graph:
      """
      my_graph
      """
    Then executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:person {name STRING NOT NULL, age INT64}),
        (:person)-[:likes{year FLOAT32, since DATETIME}]->(:person)
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
      | 'person' | 'age'          | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'likes' | 'year'         | ['float32']   | true     |
      | 'likes' | 'since'        | ['datetime']  | true     |
    Then executing queries without error:
      """
      ALTER NODE person DROP PROPERTY name, age;
      ALTER EDGE likes DROP PROPERTY year, since;
      """
    When executing query:
      """
      SHOW NODE person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
    When executing query:
      """
      SHOW EDGE likes PROPERTY;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'likes' | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph

  Scenario: [1-4] 移除属性列-删除后重新添加相同类型属性
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
    When executing queries without error:
      """
      ALTER NODE person DROP PROPERTY score;
      """
    When executing queries without error:
      """
      ALTER NODE person ADD PROPERTY {score FLOAT64};
      """
    When executing query:
      """
      MATCH (n:person) RETURN n.name, n.score;
      """
    Then the result should contain:
      | n.name | n.score |
      | '张三'  | null    |
    Then drop all graph

  Scenario: [1-5] 移除属性列-批量删除多个标签的多个属性
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
        (:person {name STRING, age INT64, city STRING}),
        (:animal {name STRING, age INT64, type STRING})
      };
      """
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'person' | 'name'         | ['string']    | true     |
      | 'person' | 'age'          | ['int64']     | true     |
      | 'person' | 'city'         | ['string']    | true     |
      | 'animal' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'animal' | 'name'         | ['string']    | true     |
      | 'animal' | 'age'          | ['int64']     | true     |
      | 'animal' | 'type'         | ['string']    | true     |
    When executing queries without error:
      """
      ALTER NODE person DROP PROPERTY age, city;
      ALTER NODE animal DROP PROPERTY age, type;
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
    Then drop all graph

  # ============================================================
  # 2. 关联影响
  # ============================================================

  Scenario: [2-1] 移除属性列-有业务数据-单属性移除
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
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '姓名'        | ['string']    | true     |
      | '人'   | '年龄'        | ['int64']     | true     |
      | '人'   | '性别'        | ['bool']      | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'     | ['date']      | true     |
      | '就读于'  | '毕业时间'     | ['date']      | true     |
    Then executing queries without error:
      """
      ALTER NODE 人 DROP PROPERTY 年龄;
      ALTER EDGE 就读于 DROP PROPERTY 毕业时间;
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '姓名'        | ['string']    | true     |
      | '人'   | '性别'        | ['bool']      | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'     | ['date']      | true     |
    Then drop all graph

  Scenario: [2-2] 移除属性列-有业务数据-多属性移除
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
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '姓名'        | ['string']    | true     |
      | '人'   | '年龄'        | ['int64']     | true     |
      | '人'   | '性别'        | ['bool']      | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'     | ['date']      | true     |
      | '就读于'  | '毕业时间'     | ['date']      | true     |
    Then executing queries without error:
      """
      ALTER NODE 人 DROP PROPERTY 年龄, 性别;
      ALTER EDGE 就读于 DROP PROPERTY 入学时间, 毕业时间;
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '姓名'        | ['string']    | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph

  Scenario: [2-3] 移除属性列-删除后验证数据不可查询
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
        (:person {name STRING, age INT64})
      };
      """
    Then executing query:
      """
      CREATE (a:person { name:"张三", age:25});
      """
    When executing query:
      """
      MATCH (n:person) WHERE n.age = 25 RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | '张三' |
    When executing queries without error:
      """
      ALTER NODE person DROP PROPERTY age;
      """
    When executing query:
      """
      MATCH (n:person) WHERE n.age = 25 RETURN n.name;
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [2-4] 移除属性列-移除多标签的同名属性列
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
      SHOW NODE 公司, 学校 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '公司' | '_PRIMARY_KEY' | ['int64']     | false    |
      | '公司' | '名称'        | ['string']    | true     |
      | '公司' | '成立时间'     | ['string']    | true     |
      | '学校' | '_PRIMARY_KEY' | ['int64']     | false    |
      | '学校' | '名称'        | ['string']    | true     |
      | '学校' | '创办时间'     | ['string']    | true     |
    Then executing queries without error:
      """
      ALTER NODE 公司 DROP PROPERTY 名称;
      ALTER NODE 学校 DROP PROPERTY 名称;
      """
    When executing query:
      """
      SHOW NODE 公司, 学校 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '公司' | '_PRIMARY_KEY' | ['int64']     | false    |
      | '公司' | '成立时间'     | ['string']    | true     |
      | '学校' | '_PRIMARY_KEY' | ['int64']     | false    |
      | '学校' | '创办时间'     | ['string']    | true     |
    Then drop all graph

  Scenario Outline: [2-5] 移除属性列系-删除有索引的属性（被索引关联的属性不支持删除）
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
    # 创建索引
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
    When executing query:
      """
      ALTER NODE 公司 DROP PROPERTY 名称;
      """
    Then the error should be contain:
      """
      [1639]Col is used by index
      """
    # 删除索引后再次删除属性列
    When executing queries without error:
      """
      DROP INDEX index02;
      """
    Then executing queries without error:
      """
      ALTER NODE 公司 DROP PROPERTY 名称;
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

  Scenario: [2-6] 移除属性列-删除后重建同名属性列
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
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '姓名'        | ['string']    | true     |
      | '人'   | '年龄'        | ['int64']     | true     |
      | '人'   | '性别'        | ['bool']      | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'     | ['date']      | true     |
      | '就读于'  | '毕业时间'     | ['date']      | true     |
    Then executing queries without error:
      """
      ALTER NODE 人 DROP PROPERTY 年龄;
      ALTER EDGE 就读于 DROP PROPERTY 毕业时间;
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '姓名'        | ['string']    | true     |
      | '人'   | '性别'        | ['bool']      | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'     | ['date']      | true     |
    # 再次创建同名属性列，查询数据
    When executing queries without error:
      """
      ALTER NODE 人 ADD PROPERTY {年龄 FLOAT32};
      ALTER EDGE 就读于 ADD PROPERTY {毕业时间 DATETIME};
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '姓名'        | ['string']    | true     |
      | '人'   | '年龄'        | ['float32']   | true     |
      | '人'   | '性别'        | ['bool']      | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'     | ['date']      | true     |
      | '就读于'  | '毕业时间'     | ['datetime']  | true     |
    # 插入新数据
    When executing queries without error:
      """
      CREATE (a:人{姓名:"张三", 年龄:25, 性别:true}),
        (b:学校{名称:"电子科技大学", 创办时间:"1896年"}),
        (a)-[:就读于{入学时间:date('2018-09-01'),毕业时间:datetime('2022-06-30')}]->(b);
      """
    Then drop all graph

  Scenario: [2-7] 移除属性列-删除NOT NULL的属性列
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING NOT NULL, 年龄 INT64, 性别 BOOLEAN}),
        (:公司 {名称 STRING, 成立时间 STRING}),
        (:学校 {名称 STRING, 创办时间 STRING}),
        (:城市 {名称 STRING}),
        (:人)-[:就读于 {入学时间 DATE NOT NULL, 毕业时间 DATE}]->(:学校),
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
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '姓名'        | ['string']    | false    |
      | '人'   | '年龄'        | ['int64']     | true     |
      | '人'   | '性别'        | ['bool']      | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'     | ['date']      | false    |
      | '就读于'  | '毕业时间'     | ['date']      | true     |
    When executing queries without error:
      """
      ALTER NODE 人 DROP PROPERTY 姓名;
      ALTER EDGE 就读于 DROP PROPERTY 入学时间;
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'   | '年龄'        | ['int64']     | true     |
      | '人'   | '性别'        | ['bool']      | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '毕业时间'     | ['date']      | true     |
    Then drop all graph

  Scenario: [2-8] 移除属性列-主键列不允许删除
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
      ALTER NODE person DROP PROPERTY _PRIMARY_KEY;
      """
    Then the error should be contain:
      """
      [1639]Col is used by index
      """
    Then drop all graph