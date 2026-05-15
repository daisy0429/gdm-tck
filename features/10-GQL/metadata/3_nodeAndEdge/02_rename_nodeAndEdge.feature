#encoding: utf-8

Feature: 点边标签重命名-基础重命名、关联影响（无业务数据、有业务数据、有索引、各种结构的关联关系）

  Background:
    Given drop all graph

  # ============================================================
  # 1. 基础重命名
  # ============================================================

  Scenario Outline: [1-1] 标签重命名-正确重命名-<label>
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
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name     | properties                     |
      | 'person' | ['_PRIMARY_KEY', 'username']   |
      | 'likes'  | ['_PRIMARY_KEY', 'since']      |
    When executing queries without error:
      """
      ALTER NODE person RENAME TO <label>;
      ALTER EDGE likes RENAME TO <label>;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties WHERE name = '<label>';
      """
    Then the result should be, in any order:
      | name      | properties                   |
      | '<label>' | ['_PRIMARY_KEY', 'username'] |
      | '<label>' | ['_PRIMARY_KEY', 'since']    |
    Then drop all graph
    Examples:
      | label         |
      | test01        |
      | test标签       |
      | 测试标签test01  |
      | 测试标签01      |
      | aa            |
      | AA            |
      | test_abc      |

  Scenario: [1-2] 标签重命名-重命名不存在的标签
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
      ALTER NODE person RENAME TO person1;
      """
    Then the error should be contain:
      """
      [1613]Label does not exist. Label name: 'person'
      """
    When executing query:
      """
      ALTER EDGE likes RENAME TO likes1;
      """
    Then the error should be contain:
      """
      [1615]Relation does not exist. Relation name: 'likes'
      """
    Then drop all graph

  Scenario: [1-3] 标签重命名-重命名为已存在的标签名
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING}),
        (:公司 {名称 STRING}),
        (:人)-[:朋友]->(:人),
        (:人)-[:同事]->(:人)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing query:
      """
      ALTER NODE 人 RENAME TO 公司;
      """
    Then the error should be contain:
      """
      [1608]Table already exists. Table name: '公司'
      """
    When executing query:
      """
      ALTER EDGE 朋友 RENAME TO 同事;
      """
    Then the error should be contain:
      """
      [1608]Table already exists. Table name: '同事'
      """
    Then drop all graph

  Scenario: [1-4] 标签重命名-重命名为自身
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING}),
        (:人)-[:朋友]->(:人)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing query:
      """
      ALTER NODE 人 RENAME TO 人;
      """
    Then the error should be contain:
      """
      [1608]Table already exists. Table name: '人'
      """
    When executing query:
      """
      ALTER EDGE 朋友 RENAME TO 朋友;
      """
    Then the error should be contain:
      """
      [1608]Table already exists. Table name: '朋友'
      """
    Then drop all graph

  Scenario: [1-5] 标签重命名-重命名为空
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING}),
        (:人)-[:朋友]->(:人)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing query:
      """
      ALTER NODE 人 RENAME TO ` `;
      """
    Then the error should be contain:
      """
      [1503]Illegal name
      """
    When executing query:
      """
      ALTER EDGE 朋友 RENAME TO ` `;
      """
    Then the error should be contain:
      """
      [1503]Illegal name
      """
    Then drop all graph

  Scenario Outline: [1-6] 标签重命名-重命名为特殊字符-<label>
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
      ALTER NODE person RENAME TO <label>vertex;
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    When executing query:
      """
      ALTER EDGE likes RENAME TO <label>edge;
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Then drop all graph
    Examples:
      | label       |
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
      | '           |
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
      | 【          |
      | 】          |
      | '           |

  Scenario: [1-7] 标签重命名-长度限制-128
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
      ALTER NODE person RENAME TO bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      ALTER EDGE likes RENAME TO bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    When executing query:
      """
      ALTER NODE person RENAME TO bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    Then drop all graph

  Scenario: [1-8] 标签重命名-连续重命名
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
      ALTER NODE person RENAME TO person01;
      ALTER EDGE likes RENAME TO likes01;
      ALTER NODE person01 RENAME TO person02;
      ALTER EDGE likes01 RENAME TO likes02;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name       | properties                     |
      | 'person02' | ['_PRIMARY_KEY', 'username']   |
      | 'likes02'  | ['_PRIMARY_KEY', 'since']      |
    When executing queries without error:
      """
      ALTER NODE person02 RENAME TO person;
      ALTER EDGE likes02 RENAME TO likes;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name     | properties                     |
      | 'person' | ['_PRIMARY_KEY', 'username']   |
      | 'likes'  | ['_PRIMARY_KEY', 'since']      |
    Then drop all graph

  Scenario: [1-9] 标签重命名-同时重命名点和边
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
      ALTER NODE person RENAME TO user;
      ALTER EDGE likes RENAME TO loves;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name    | properties                     |
      | 'user'  | ['_PRIMARY_KEY', 'username']   |
      | 'loves' | ['_PRIMARY_KEY', 'since']      |
    Then drop all graph

  Scenario: [1-10] 标签重命名-重命名后删除原标签名
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
      ALTER NODE person RENAME TO user;
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name WHERE name = 'person';
      """
    Then the result should be empty
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name WHERE name = 'user';
      """
    Then the result should contain:
      | name   |
      | 'user' |
    Then drop all graph

  Scenario: [1-11] 标签重命名-重命名后创建同名标签
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
        (:person {username STRING NOT NULL})
      };
      """
    When executing queries without error:
      """
      ALTER NODE person RENAME TO user;
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD NODE { (:person {age INT64}) };
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, properties;
      """
    Then the result should contain:
      | name     | properties                   |
      | 'user'   | ['_PRIMARY_KEY', 'username'] |
      | 'person' | ['_PRIMARY_KEY', 'age']      |
    Then drop all graph

  Scenario: [1-12] 标签重命名-批量重命名多个标签
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
        (:animal {name STRING NOT NULL}),
        (:person)-[:likes{since LOCALDATETIME}]->(:animal),
        (:person)-[:knows]->(:person)
      };
      """
    When executing queries without error:
      """
      ALTER NODE person RENAME TO user;
      ALTER NODE animal RENAME TO pet;
      ALTER EDGE likes RENAME TO loves;
      ALTER EDGE knows RENAME TO acquaintance;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, properties;
      """
    Then the result should be, in any order:
      | name           | properties                     |
      | 'user'         | ['_PRIMARY_KEY', 'username']   |
      | 'pet'          | ['_PRIMARY_KEY', 'name']       |
      | 'loves'        | ['_PRIMARY_KEY', 'since']      |
      | 'acquaintance' | ['_PRIMARY_KEY']               |
    Then drop all graph
  # ============================================================
  # 2. 关联影响
  # ============================================================

  Scenario: [2-1] 标签重命名-关联影响-无业务数据
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
      ALTER NODE 人 RENAME TO person;
      ALTER EDGE 朋友 RENAME TO friends;
      """
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name;
      """
    Then the result should be, in any order:
      | name       |
      | 'person'   |
      | '公司'      |
      | '学校'      |
      | '城市'      |
      | '就读于'    |
      | 'friends'  |
      | '所属城市'   |
      | '籍贯'      |
      | '就职于'    |
      | '同事'      |
    Then drop all graph

  Scenario: [2-2] 标签重命名-关联影响-有业务数据
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
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER NODE 人 RENAME TO person;
      ALTER EDGE 就读于 RENAME TO study;
      """
    When executing query:
      """
      MATCH path=(m)-[r]->(n) RETURN DISTINCT type(r) AS relationshipType, labels(m) AS startLabel, labels(n) AS endLabel;
      """
    Then the result should be, in any order:
      | relationshipType | startLabel  | endLabel      |
      | '同事'            | ['person']  | ['person']    |
      | '就职于'          | ['person']  | ['公司']       |
      | 'study'          | ['person']  | ['学校']       |
      | '籍贯'            | ['person']  | ['城市']       |
      | '朋友'            | ['person']  | ['person']    |
      | '所属城市'         | ['学校']     | ['城市']       |
    Then drop all graph

  Scenario: [2-3] 标签重命名-关联影响-有索引
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE INDEX index01 FOR (n:人) ON (n.姓名) OPTIONS {indexConfig: {unique: <indexType>}};
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes, properties WHERE name = 'index01';
      """
    Then the result should be, in any order:
      | name      | labelsOrTypes | properties |
      | 'index01' | '人'          | ['姓名']    |
    When executing queries without error:
      """
      ALTER NODE 人 RENAME TO person;
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes, properties WHERE name = 'index01';
      """
    Then the result should be, in any order:
      | name      | labelsOrTypes | properties |
      | 'index01' | 'person'      | ['姓名']    |
    Then drop all graph
    Examples:
      | indexType |
      | true      |
      | false     |

  Scenario: [2-4] 标签重命名-关联影响-自旋边
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
        (:人)-[:朋友]->(:人)
      };
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      ALTER NODE 人 RENAME TO person;
      ALTER EDGE 朋友 RENAME TO friends;
      """
    When executing query:
      """
      MATCH path=(m)-[r]->(n) WHERE type(r) = 'friends' RETURN DISTINCT type(r) AS relationshipType, labels(m) AS startLabel, labels(n) AS endLabel;
      """
    Then the result should be, in any order:
      | relationshipType | startLabel  | endLabel    |
      | 'friends'        | ['person']  | ['person']  |
    Then drop all graph

  Scenario: [2-5] 标签重命名-关联影响-循环引用
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:A),
        (:B),
        (:C),
        (:A)-[:R1]->(:B),
        (:B)-[:R2]->(:C),
        (:C)-[:R3]->(:A)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:A), (b:B), (c:C),
        (a)-[:R1]->(b),
        (b)-[:R2]->(c),
        (c)-[:R3]->(a);
      """
    When executing query:
      """
      MATCH path=(m)-[r]->(n) RETURN type(r) AS relationshipType, labels(m) AS startLabel, labels(n) AS endLabel;
      """
    Then the result should be, in any order:
      | relationshipType | startLabel | endLabel |
      | 'R1'             | ['A']      | ['B']    |
      | 'R2'             | ['B']      | ['C']    |
      | 'R3'             | ['C']      | ['A']    |
    When executing queries without error:
      """
      ALTER NODE A RENAME TO a;
      ALTER EDGE R3 RENAME TO r3;
      """
    When executing query:
      """
      MATCH path=(m)-[r]->(n) RETURN type(r) AS relationshipType, labels(m) AS startLabel, labels(n) AS endLabel;
      """
    Then the result should be, in any order:
      | relationshipType | startLabel | endLabel |
      | 'R1'             | ['a']      | ['B']    |
      | 'R2'             | ['B']      | ['C']    |
      | 'r3'             | ['C']      | ['a']    |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, mapping;
      """
    Then the result should be, in any order:
      | name | mapping    |
      | 'R1' | ['a->B']   |
      | 'R2' | ['B->C']   |
      | 'r3' | ['C->a']   |
    Then drop all graph

  Scenario: [2-6] 标签重命名-关联影响-点标签重命名对多条边的影响
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:A),
        (:B),
        (:C),
        (:A)-[:R1]->(:B),
        (:A)-[:R2]->(:C),
        (:C)-[:R3]->(:A)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:A), (b:B), (c:C),
        (a)-[:R1]->(b),
        (a)-[:R2]->(c),
        (c)-[:R3]->(a);
      """
    When executing query:
      """
      MATCH path=(m)-[r]->(n) RETURN type(r) AS relationshipType, labels(m) AS startLabel, labels(n) AS endLabel;
      """
    Then the result should be, in any order:
      | relationshipType | startLabel | endLabel |
      | 'R1'             | ['A']      | ['B']    |
      | 'R2'             | ['A']      | ['C']    |
      | 'R3'             | ['C']      | ['A']    |
    When executing queries without error:
      """
      ALTER NODE A RENAME TO a;
      ALTER EDGE R3 RENAME TO r3;
      """
    When executing query:
      """
      MATCH path=(m)-[r]->(n) RETURN type(r) AS relationshipType, labels(m) AS startLabel, labels(n) AS endLabel;
      """
    Then the result should be, in any order:
      | relationshipType | startLabel | endLabel |
      | 'R1'             | ['a']      | ['B']    |
      | 'R2'             | ['a']      | ['C']    |
      | 'r3'             | ['C']      | ['a']    |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, mapping;
      """
    Then the result should be, in any order:
      | name | mapping    |
      | 'R1' | ['a->B']   |
      | 'R2' | ['a->C']   |
      | 'r3' | ['C->a']   |
    Then drop all graph

  Scenario: [2-7] 标签重命名-关联影响-多层路径
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Level1),
        (:Level2),
        (:Level3),
        (:Level4),
        (:Level1)-[:EDGE1]->(:Level2),
        (:Level2)-[:EDGE2]->(:Level3),
        (:Level3)-[:EDGE3]->(:Level4)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (l1:Level1), (l2:Level2), (l3:Level3), (l4:Level4),
        (l1)-[:EDGE1]->(l2),
        (l2)-[:EDGE2]->(l3),
        (l3)-[:EDGE3]->(l4);
      """
    When executing query:
      """
      MATCH path=(m)-[r]->(n) RETURN type(r) AS relationshipType, labels(m) AS startLabel, labels(n) AS endLabel;
      """
    Then the result should be, in any order:
      | relationshipType | startLabel   | endLabel     |
      | 'EDGE1'          | ['Level1']   | ['Level2']   |
      | 'EDGE2'          | ['Level2']   | ['Level3']   |
      | 'EDGE3'          | ['Level3']   | ['Level4']   |
    When executing queries without error:
      """
      ALTER NODE Level2 RENAME TO L2;
      ALTER EDGE EDGE2 RENAME TO E2;
      """
    When executing query:
      """
      MATCH path=(m)-[r]->(n) RETURN type(r) AS relationshipType, labels(m) AS startLabel, labels(n) AS endLabel;
      """
    Then the result should be, in any order:
      | relationshipType | startLabel   | endLabel     |
      | 'EDGE1'          | ['Level1']   | ['L2']       |
      | 'E2'             | ['L2']       | ['Level3']   |
      | 'EDGE3'          | ['Level3']   | ['Level4']   |
    Then drop all graph

  Scenario: [2-8] 标签重命名-重命名点标签后边标签映射更新验证
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:User {name STRING}),
        (:Product {sku STRING}),
        (:User)-[:BUY]->(:Product)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (u:User {name:"张三"}), (p:Product {sku:"P001"}), (u)-[:BUY]->(p);
      """
    When executing query:
      """
      MATCH (u)-[:BUY]->(p) RETURN u.name, p.sku;
      """
    Then the result should contain:
      | u.name | p.sku  |
      | '张三'  | 'P001' |
    When executing queries without error:
      """
      ALTER NODE User RENAME TO Customer;
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, mapping;
      """
    Then the result should contain:
      | name  | mapping          |
      | 'BUY' | ['Customer->Product'] |
    When executing query:
      """
      MATCH (c)-[:BUY]->(p) RETURN c.name, p.sku;
      """
    Then the result should contain:
      | c.name | p.sku  |
      | '张三'  | 'P001' |
    Then drop all graph

  Scenario: [2-9] 标签重命名-重命名边标签后查询数据验证
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:User {name STRING}),
        (:User)-[:FOLLOW]->(:User)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (u1:User {name:"张三"}), (u2:User {name:"李四"}), (u1)-[:FOLLOW]->(u2);
      """
    When executing query:
      """
      MATCH (u1)-[:FOLLOW]->(u2) RETURN u1.name, u2.name;
      """
    Then the result should contain:
      | u1.name | u2.name |
      | '张三'   | '李四'   |
    When executing queries without error:
      """
      ALTER EDGE FOLLOW RENAME TO SUBSCRIBE;
      """
    When executing query:
      """
      MATCH (u1)-[:SUBSCRIBE]->(u2) RETURN u1.name, u2.name;
      """
    Then the result should contain:
      | u1.name | u2.name |
      | '张三'   | '李四'   |
    Then drop all graph

  Scenario: [2-10] 标签重命名后索引查询验证
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
      CREATE (p1:Person {name:"张三", age:25}), (p2:Person {name:"李四", age:30});
      """
    When executing query:
      """
      MATCH (n:Person) WHERE n.name = '张三' RETURN n.age;
      """
    Then the result should contain:
      | n.age |
      | 25    |
    When executing queries without error:
      """
      ALTER NODE Person RENAME TO User;
      """
    When executing query:
      """
      SHOW INDEXES YIELD name, labelsOrTypes;
      """
    Then the result should contain:
      | name        | labelsOrTypes |
      | 'name_index' | 'User'        |
    When executing query:
      """
      MATCH (n:User) WHERE n.name = '张三' RETURN n.age;
      """
    Then the result should contain:
      | n.age |
      | 25    |
    Then drop all graph

  Scenario: [2-11] 标签重命名-重命名点标签后创建新的边
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Author {name STRING}),
        (:Book {title STRING})
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing queries without error:
      """
      CREATE (a:Author {name:"鲁迅"}), (b:Book {title:"朝花夕拾"});
      """
    When executing queries without error:
      """
      ALTER NODE Author RENAME TO Writer;
      """
    When executing queries without error:
      """
      ALTER GRAPH ADD EDGE { (:Writer)-[:WRITE]->(:Book) };
      """
    When executing queries without error:
      """
      MATCH (w:Writer), (b:Book) CREATE (w)-[:WRITE]->(b);
      """
    When executing query:
      """
      MATCH (w)-[:WRITE]->(b) RETURN w.name, b.title;
      """
    Then the result should contain:
      | w.name | b.title     |
      | '鲁迅'  | '朝花夕拾'   |
    Then drop all graph