#encoding: utf-8

Feature: 修改图-修改图名、副本数、状态（online/offline）、（不支持：字符集、加密方式、容量、段数量）

  Background:
    Given drop all graph

  # ============================================================
  # 1. 修改图名
  # ============================================================

  Scenario Outline: [1-1] 修改图-重命名-正确混合图名-<graph>
    When executing queries without error:
      """
      CREATE GRAPH my_graph
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO <graph>;
      """
    When executing query:
      """
      show graph yield name;
      """
    And the result should contain:
      | name      |
      | '<graph>' |
    Then drop all graph
    Examples:
      | graph     |
      | graph01   |
      | graph测试图  |
      | 测试图test01 |
      | 测试图_01    |
      | aa        |
      | AA        |

  Scenario: [1-2] 修改图-重命名-不存在的图名
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO test;
      """
    Then the error should be contain:
      """
      [1605]Database does not exist. Database name: 'my_graph'
      """

  Scenario: [1-3] 修改图-重命名-为已存在的用户图名
    When executing queries without error:
      """
      CREATE GRAPH my_graph01;
      CREATE GRAPH my_graph02;
      """
    When executing query:
      """
      ALTER GRAPH my_graph01 RENAME TO my_graph02;
      """
    Then the error should be contain:
      """
      [1606]Database already exists. Database name: 'my_graph02'
      """
    Then drop all graph

  Scenario: [1-4] 修改图-重命名-为系统图名（sys和default是系统默认图，不允许重命名为系统图名）
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO sys;
      """
    Then the error should be contain:
      """
      [1606]Database already exists
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO default;
      """
    Then the error should be contain:
      """
      [1606]Database already exists
      """
    Then drop all graph

  Scenario: [1-5] 修改图-重命名-为自身
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO my_graph;
      """
    Then the error should be contain:
      """
      [1606]Database already exists. Database name: 'my_graph'
      """
    Then drop all graph

  Scenario: [1-6] 修改图-重命名-为空
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO ` `;
      """
    Then the error should be contain:
      """
      [1503]Illegal name
      """
    Then drop all graph

  Scenario Outline: [1-7] 修改图-重命名-特殊字符-<graph>
    When executing queries without error:
      """
      CREATE GRAPH my_graph
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO <graph>abc;
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Then drop all graph
    Examples:
      | graph       |
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
      | \|undefined |
      | ￥           |
      | ……          |
      | `           |
      | ·           |
      | ~           |
      | 【           |
      | 】           |
      | '           |

  Scenario: [1-8] 修改图-重命名-长度限制
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph RENAME TO bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO aabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    Then drop all graph

  Scenario: [1-9] 修改图-连续重命名
    When executing queries without error:
      """
      CREATE GRAPH my_graph
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph RENAME TO my_graph01;
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph01 RENAME TO my_graph02;
      """
    When executing query:
      """
      show graph yield name;
      """
    And the result should contain:
      | name         |
      | 'my_graph02' |
    When executing queries without error:
      """
      ALTER GRAPH my_graph02 RENAME TO my_graph;
      """
    When executing query:
      """
      show graph yield name;
      """
    And the result should contain:
      | name       |
      | 'my_graph' |
    Then drop all graph

  Scenario: [1-10] 修改图-重命名-offline状态下不允许重命名
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO my_graph_renamed;
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    Then drop all graph

  # ============================================================
  # 2. 修改副本数（只能从1修改为3，且只能修改一次）
  # ============================================================

  Scenario: [2-1] 修改图-副本数-从1修改为3（用户图）
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 1;
      """
    When alter graph "my_graph" replica to 3
    Then the result should be, in any order:
      | name       | replicaCount |
      | 'my_graph' | 3            |
    Then drop all graph

#系统图修改后无法再修改回来，暂时注释此测例
#  Scenario: [2-2] 修改图-副本数-从1修改为3（系统图sys）
#    When alter graph "sys" replica to 3
#    Then the result should be, in any order:
#      | name  | replicaCount |
#      | 'sys' | 3            |
#
#  Scenario: [2-3] 修改图-副本数-从1修改为3（系统图default）
#    When alter graph "default" replica to 3
#    Then the result should be, in any order:
#      | name      | replicaCount |
#      | 'default' | 3            |

  Scenario: [2-4] 修改图-副本数-从1修改为3后再次修改（包括修改为3或其他值）
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 1;
      """
    When alter graph "my_graph" replica to 3
    Then the result should be, in any order:
      | name       | replicaCount |
      | 'my_graph' | 3            |
    When executing query:
      """
      ALTER GRAPH my_graph REPLICA TO 3;
      """
    Then the error should be contain:
      """
      [1102]System not support
      """
    When executing query:
      """
      ALTER GRAPH my_graph REPLICA TO 2;
      """
    Then the error should be contain:
      """
      [1102]System not support
      """
    Then drop all graph

  Scenario: [2-5] 修改图-副本数-从不是1的副本数修改
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 2;
      """
    When executing query:
      """
      ALTER GRAPH my_graph REPLICA TO 3;
      """
    Then the error should be contain:
      """
      [1102]System not support
      """
    Then drop all graph

  Scenario: [2-6] 修改图-副本数-修改不存在的图
    When executing query:
      """
      ALTER GRAPH non_exist_graph REPLICA TO 3;
      """
    Then the error should be contain:
      """
      [1605]Database does not exist. Database name: 'non_exist_graph'
      """
    Then drop all graph

  Scenario: [2-7] 修改图-副本数-offline状态下不允许修改副本数
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 1;
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      ALTER GRAPH my_graph REPLICA TO 3;
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    Then drop all graph

  # ============================================================
  # 3. 修改图状态
  # ============================================================

  Scenario: [3-1] 修改图-状态-将online图改为offline
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing query:
      """
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      show graph yield name,status where name = 'my_graph';
      """
    And the result should be, in any order:
      | name       | status    |
      | 'my_graph' | 'offline' |
    Then drop all graph

  Scenario: [3-2] 修改图-状态-将offline图改为online
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      ALTER GRAPH my_graph ONLINE;
      """
    When executing query:
      """
      show graph yield name,status where name = 'my_graph';
      """
    And the result should be, in any order:
      | name       | status   |
      | 'my_graph' | 'online' |
    Then drop all graph

  Scenario: [3-3] 修改图-状态-将offline图再次改为offline
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      ALTER GRAPH my_graph OFFLINE;
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    When executing query:
      """
      show graph yield name,status where name = 'my_graph';
      """
    And the result should be, in any order:
      | name       | status    |
      | 'my_graph' | 'offline' |
    Then drop all graph

  Scenario: [3-4] 修改图-状态-将online图再次改为online
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing query:
      """
      ALTER GRAPH my_graph ONLINE;
      """
    Then the result should be empty
    When executing query:
      """
      show graph yield name,status where name = 'my_graph';
      """
    And the result should be, in any order:
      | name       | status   |
      | 'my_graph' | 'online' |
    Then drop all graph

  Scenario: [3-5] 修改图-状态-修改不存在的图
    When executing query:
      """
      ALTER GRAPH non_exist_graph OFFLINE;
      """
    Then the error should be contain:
      """
      [1605]Database does not exist. Database name: 'non_exist_graph'
      """
    Then drop all graph

  Scenario: [3-6] 修改图-状态-修改系统图（不支持修改状态）
    When executing query:
      """
      ALTER GRAPH sys OFFLINE;
      """
    Then the error should be contain:
      """
      [2788]Modification system graph is not allowed
      """
    When executing query:
      """
      ALTER GRAPH default OFFLINE;
      """
    Then the error should be contain:
      """
      [2788]Modification system graph is not allowed
      """

  Scenario: [3-7] 修改图-状态-offline状态下禁止写入操作
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string})
      };
      ALTER GRAPH my_graph OFFLINE;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing query:
      """
      CREATE (:Person {name: "test"});
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    Then drop all graph

  Scenario: [3-8] 修改图-状态-offline状态下禁止查询操作
    When executing queries without error:
      """
      CREATE GRAPH my_graph {
        (:Person{name string})
      };
      ALTER GRAPH my_graph OFFLINE;
      """
    Given an already exist graph:
      """
      my_graph
      """
    When executing query:
      """
      MATCH (n:Person) RETURN n.name;
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    Then drop all graph

  Scenario: [3-9] 修改图-状态-online状态下允许读写操作
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
      CREATE (:Person {name: "test"});
      """
    When executing query:
      """
      MATCH (n:Person) RETURN n.name;
      """
    Then the result should contain:
      | n.name |
      | 'test' |
    Then drop all graph

  Scenario: [3-10] 修改图-状态-连续切换状态
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph OFFLINE;
      ALTER GRAPH my_graph ONLINE;
      ALTER GRAPH my_graph OFFLINE;
      ALTER GRAPH my_graph ONLINE;
      """
    When executing query:
      """
      show graph yield name,status where name = 'my_graph';
      """
    And the result should be, in any order:
      | name       | status   |
      | 'my_graph' | 'online' |
    Then drop all graph

  # ============================================================
  # 4. 组合修改（包含有业务数据场景）
  # ============================================================

  Scenario: [4-1] 修改图-组合操作-重命名+修改副本数（无业务数据）
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 1;
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph RENAME TO my_graph_new;
      """
    When alter graph "my_graph_new" replica to 3
    Then the result should be, in any order:
      | name           | replicaCount |
      | 'my_graph_new' | 3            |
    Then drop all graph

  Scenario: [4-2] 修改图-组合操作-重命名+修改副本数（有业务数据）
    Given drop all graph
    Given drop all graphType
    Then executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
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
    When executing queries without error:
      """
      CREATE GRAPH my_graph my_graph_type REPLICA 1;
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
      """
      ALTER GRAPH my_graph RENAME TO my_graph_new;
      """
    When alter graph "my_graph_new" replica to 3
    Then the result should be, in any order:
      | name           | replicaCount |
      | 'my_graph_new' | 3            |
    Given an already exist graph:
      """
      my_graph_new
      """
    When executing query:
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
    Then drop all graph
    And drop all graphType

  Scenario: [4-3] 修改图-组合操作-重命名+修改状态
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph RENAME TO my_graph_new;
      ALTER GRAPH my_graph_new OFFLINE;
      """
    When executing query:
      """
      show graph yield name,status where name = 'my_graph_new';
      """
    And the result should be, in any order:
      | name           | status    |
      | 'my_graph_new' | 'offline' |
    Then drop all graph

  Scenario: [4-4] 修改图-组合操作-修改副本数+修改状态（无业务数据）
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 1;
      """
    When alter graph "my_graph" replica to 3
    Then the result should be, in any order:
      | name       | replicaCount |
      | 'my_graph' | 3            |
    When executing query:
      """
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      show graph yield name,replicaCount,status where name = 'my_graph';
      """
    And the result should be, in any order:
      | name       | replicaCount | status    |
      | 'my_graph' | 3            | 'offline' |
    Then drop all graph

  Scenario: [4-5] 修改图-组合操作-修改副本数+修改状态（有业务数据）
    Given drop all graph
    Given drop all graphType
    Then executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
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
    When executing queries without error:
      """
      CREATE GRAPH my_graph my_graph_type REPLICA 1;
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When alter graph "my_graph" replica to 3
    Then the result should be, in any order:
      | name       | replicaCount |
      | 'my_graph' | 3            |
    When executing query:
      """
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      show graph yield name,replicaCount,status where name = 'my_graph';
      """
    And the result should be, in any order:
      | name       | replicaCount | status    |
      | 'my_graph' | 3            | 'offline' |

    When executing query:
      """
      call db.meta.count();
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    When executing query:
      """
      ALTER GRAPH my_graph ONLINE;
      """
    Then executing query:
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
    Then drop all graph
    And drop all graphType

  Scenario: [4-6] 修改图-组合操作-全部修改（无业务数据）
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 1;
      """
    When executing queries without error:
      """
      ALTER GRAPH my_graph RENAME TO my_graph_new;
      """
    When alter graph "my_graph_new" replica to 3
    Then the result should be, in any order:
      | name           | replicaCount |
      | 'my_graph_new' | 3            |
    When executing queries without error:
      """
      ALTER GRAPH my_graph_new OFFLINE;
      ALTER GRAPH my_graph_new ONLINE;
      """
    When executing query:
      """
      show graph yield name,replicaCount,status where name = 'my_graph_new';
      """
    And the result should be, in any order:
      | name           | replicaCount | status   |
      | 'my_graph_new' | 3            | 'online' |
    Then drop all graph

  Scenario: [4-7] 修改图-组合操作-全部修改（有业务数据）
    Given drop all graph
    Given drop all graphType
    Then executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
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
    When executing queries without error:
      """
      CREATE GRAPH my_graph my_graph_type REPLICA 1;
      """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
      """
      ALTER GRAPH my_graph RENAME TO my_graph_new;
      """
    When alter graph "my_graph_new" replica to 3
    When executing queries without error:
      """
      ALTER GRAPH my_graph_new OFFLINE;
      ALTER GRAPH my_graph_new ONLINE;
      """
    When executing query:
      """
      show graph yield name,replicaCount,status where name = 'my_graph_new';
      """
    And the result should be, in any order:
      | name           | replicaCount | status   |
      | 'my_graph_new' | 3            | 'online' |
    Given an already exist graph:
      """
      my_graph_new
      """
    When executing query:
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
    Then drop all graph
    And drop all graphType

  Scenario: [4-8] 修改图-组合操作-修改副本数后重命名再修改状态
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 1;
      """
    When alter graph "my_graph" replica to 3
    Then the result should be, in any order:
      | name       | replicaCount |
      | 'my_graph' | 3            |
    When executing queries without error:
      """
      ALTER GRAPH my_graph RENAME TO my_graph_new;
      ALTER GRAPH my_graph_new OFFLINE;
      """
    When executing query:
      """
      show graph yield name,replicaCount,status where name = 'my_graph_new';
      """
    And the result should be, in any order:
      | name           | replicaCount | status    |
      | 'my_graph_new' | 3            | 'offline' |
    Then drop all graph

  Scenario: [4-9] 修改图-组合操作-offline状态下不允许任何修改操作
    When executing queries without error:
      """
      CREATE GRAPH my_graph REPLICA 1;
      ALTER GRAPH my_graph OFFLINE;
      """
    When executing query:
      """
      ALTER GRAPH my_graph RENAME TO my_graph_new;
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    When executing query:
      """
      ALTER GRAPH my_graph REPLICA TO 3;
      """
    Then the error should be contain:
      """
      [1592]Forbid operate on offline database
      """
    Then drop all graph