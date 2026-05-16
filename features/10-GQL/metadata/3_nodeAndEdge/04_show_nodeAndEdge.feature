#encoding: utf-8

Feature: SHOW SCHEMA - 标签模型查询功能测试

  Background:
    Given an empty graph

  # ============================================================
  # 1. 基础功能测试
  # ============================================================

  Scenario Outline: [1-1] 基础功能测试-基础语法-<comment>
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:Person {username STRING NOT NULL}),
        (:Company {name STRING NOT NULL}),
        (:University {name STRING NOT NULL}),
        (:Project {title STRING}),
        (:Event {name STRING}),
        (:Location {name STRING}),
        (:SkillSet {name STRING}),
        (:Person)-[:WorkAt]->(:Company),
        (:Person)-[:StudyAt]->(:University),
        (:Person)-[:ParticipateIn]->(:Project),
        (:Event)-[:HeldAt]->(:Location),
        (:Person)-[:Possesses]->(:SkillSet)
      }
      """
    When executing query:
      """
      <gql>
      """
    Then the result count should be [<count>]
    Examples:
      | gql                | count | comment      |
      | SHOW NODE SCHEMA;  | 7     | '全大写-节点标签'   |
      | SHOW NODE SCHEMA   | 7     | '无分号-节点标签'   |
      | show node schema;  | 7     | '全小写-节点标签'   |
      | Show Node Schema;  | 7     | '首字母大写-节点标签' |
      | sHoW nOdE sChEmA;  | 7     | '大小写混合-节点标签' |
      | SHOW NODE SCHEMA ; | 7     | '多余空格-节点标签'  |
      | SHOW EDGE SCHEMA;  | 5     | '全大写-边标签'    |
      | SHOW EDGE SCHEMA   | 5     | '无分号-边标签'    |
      | show edge schema;  | 5     | '全小写-边标签'    |
      | Show Edge Schema;  | 5     | '首字母大写-边标签'  |
      | sHoW eDgE sChEmA;  | 5     | '大小写混合-边标签'  |
      | SHOW EDGE SCHEMA ; | 5     | '多余空格-边标签'   |
      | SHOW ALL SCHEMA;   | 12    | '全大写-全部标签'   |
      | SHOW ALL SCHEMA    | 12    | '无分号-全部标签'   |
      | show all schema;   | 12    | '全小写-全部标签'   |
      | Show All Schema;   | 12    | '首字母大写-全部标签' |
      | sHoW aLl sChEmA;   | 12    | '大小写混合-全部标签' |
      | SHOW ALL SCHEMA ;  | 12    | '多余空格-全部标签'  |

  Scenario: [1-2] 基础功能测试-空图查询
    Given an empty graph
    When executing query:
      """
      SHOW NODE SCHEMA;
      """
    Then the result should be empty
    When executing query:
      """
      SHOW EDGE SCHEMA;
      """
    Then the result should be empty
    When executing query:
      """
      SHOW ALL SCHEMA;
      """
    Then the result should be empty

  Scenario: [1-3] 基础功能测试-创建标签后查询（无数据）
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:Person {username STRING NOT NULL}),
        (:Company {name STRING NOT NULL}),
        (:Person)-[:WorkAt]->(:Company)
      }
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total, properties;
      """
    Then the result count should be [2]
    And the result should contain:
      | name      | total | properties                   |
      | 'Person'  | 0     | ['_PRIMARY_KEY', 'username'] |
      | 'Company' | 0     | ['_PRIMARY_KEY', 'name']     |
    When executing query:
      """
      SHOW EDGE SCHEMA  YIELD name, total, properties, mapping;
      """
    Then the result count should be [1]
    And the result should contain:
      | name     | total | properties       | mapping             |
      | 'WorkAt' | 0     | ['_PRIMARY_KEY'] | ['Person->Company'] |
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result count should be [3]
    And the result should contain:
      | name      | total |
      | 'Person'  | 0     |
      | 'Company' | 0     |
      | 'WorkAt'  | 0     |

  Scenario: [1-4] 基础功能测试-添加数据后查询
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL, 年龄 INT64, 性别 BOOL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL, 创办时间 STRING}),
        (:公司 {名称 STRING NOT NULL, 成立时间 STRING}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
        (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
        (:人)-[:同事]->(:人),
        (:学校)-[:所属城市]->(:城市)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明", 年龄:25, 性别:true}),
             (b:人{姓名:"张文", 年龄:35, 性别:true}),
             (c:人{姓名:"王武", 年龄:18, 性别:true}),
             (d:人{姓名:"陈阳", 年龄:21, 性别:true}),
             (e:人{姓名:"周萌", 年龄:22, 性别:false}),
             (f:城市{名称:"成都"}),
             (g:城市{名称:"武汉"}),
             (h:城市{名称:"深圳"}),
             (i:城市{名称:"北京"}),
             (j:学校{名称:"四川大学", 创办时间:"1896年"}),
             (k:学校{名称:"武汉大学",创办时间:"1893年"}),
             (m:学校{名称:"华中科技大学",创办时间:"1952年"}),
             (n:学校{名称:"深圳大学",创办时间:"1983年"}),
             (o:公司{名称:"百度", 成立时间:"2000年1月"}),
             (p:公司{名称:"腾讯科技（深圳）有限公司",成立时间:"1998年11月"}),
             (a)-[:朋友]->(d),
             (a)-[:朋友]->(b),
             (c)-[:朋友]->(e),
             (e)-[:朋友]->(d),
             (e)-[:籍贯]->(f),
             (d)-[:籍贯]->(f),
             (b)-[:籍贯]->(f),
             (c)-[:籍贯]->(g),
             (a)-[:籍贯]->(h),
             (a)-[:就读于{入学时间:date('2018-09-01'),毕业时间:date('2022-06-30')}]->(m),
             (b)-[:就读于{入学时间:date('2015-09-01'),毕业时间:date('2019-06-23')}]->(j),
             (c)-[:就读于{入学时间:date('2022-09-01'),毕业时间:date('2026-06-19')}]->(n),
             (d)-[:就读于{入学时间:date('2006-09-01'),毕业时间:date('2010-06-30')}]->(k),
             (e)-[:就读于{入学时间:date('2019-09-01'),毕业时间:date('2023-06-21')}]->(m),
             (e)-[:就职于{入职时间:date('2022-07-01'),离职时间:date('2023-05-01')}]->(o),
             (a)-[:就职于{入职时间:date('2019-08-02'),离职时间:date('2022-12-31')}]->(o),
             (b)-[:就职于{入职时间:date('2012-02-01'),离职时间:date('2020-06-30')}]->(p),
             (e)-[:同事]->(a),
             (n)-[:所属城市]->(h),
             (k)-[:所属城市]->(g),
             (m)-[:所属城市]->(g),
             (j)-[:所属城市]->(f)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total, properties;
      """
    And the result should contain:
      | name | total | properties                         |
      | '人'  | 5     | ['_PRIMARY_KEY', '姓名', '年龄', '性别'] |
      | '城市' | 4     | ['_PRIMARY_KEY', '名称']             |
      | '学校' | 4     | ['_PRIMARY_KEY', '名称', '创办时间']     |
      | '公司' | 2     | ['_PRIMARY_KEY', '名称', '成立时间']     |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, total, properties,mapping;
      """
    And the result should contain:
      | name   | total | properties                       | mapping    |
      | '朋友'   | 4     | ['_PRIMARY_KEY']                 | ['人->人']   |
      | '籍贯'   | 5     | ['_PRIMARY_KEY']                 | ['人->城市']  |
      | '就读于'  | 5     | ['_PRIMARY_KEY', '入学时间', '毕业时间'] | ['人->学校']  |
      | '就职于'  | 3     | ['_PRIMARY_KEY', '入职时间', '离职时间'] | ['人->公司']  |
      | '同事'   | 1     | ['_PRIMARY_KEY']                 | ['人->人']   |
      | '所属城市' | 4     | ['_PRIMARY_KEY']                 | ['学校->城市'] |
    When executing query:
      """
      SHOW ALL SCHEMA;
      """
    Then the result count should be [10]

  # ============================================================
  # 2. YIELD 子句测试
  # ============================================================

  Scenario: [2-1] YIELD子句测试-YIELD *
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明",年龄:25}),
             (b:人{姓名:"张文",年龄:35}),
             (c:人{姓名:"王武",年龄:18}),
             (f:城市{名称:"成都"}),
             (g:城市{名称:"武汉"}),
             (a)-[:朋友]->(b),
             (a)-[:朋友]->(c),
             (a)-[:籍贯]->(f),
             (b)-[:籍贯]->(g)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name,total,properties;
      """
    And the result should contain:
      | name | total | properties                   |
      | '人'  | 3     | ['_PRIMARY_KEY', '姓名', '年龄'] |
      | '城市' | 2     | ['_PRIMARY_KEY', '名称']       |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name,total,properties,mapping;
      """
    And the result should contain:
      | name | total | properties       | mapping   |
      | '朋友' | 2     | ['_PRIMARY_KEY'] | ['人->人']  |
      | '籍贯' | 2     | ['_PRIMARY_KEY'] | ['人->城市'] |
    When executing query:
      """
      SHOW ALL SCHEMA YIELD *;
      """
    And the result count should be [5]

  Scenario: [2-2] YIELD子句测试-指定列
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (c:人{姓名:"王武"}),
             (f:城市{名称:"成都"}),
             (a)-[:朋友]->(b),
             (a)-[:朋友]->(c)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name;
      """
    Then the result should contain:
      | name |
      | '人'  |
      | '城市' |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total;
      """
    Then the result should contain:
      | name | total |
      | '人'  | 3     |
      | '城市' | 1     |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name;
      """
    Then the result should contain:
      | name |
      | '朋友' |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, total;
      """
    Then the result should contain:
      | name | total |
      | '朋友' | 2     |
    When executing query:
      """
      SHOW ALL SCHEMA YIELD name, total;
      """
    Then the result should contain:
      | name | total |
      | '人'  | 3     |
      | '城市' | 1     |
      | '朋友' | 2     |

  Scenario: [2-3] YIELD子句测试-列顺序
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (a)-[:朋友]->(b)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total;
      """
    Then the result should contain:
      | name | total |
      | '人'  | 2     |
      | '城市' | 1     |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD total, name;
      """
    Then the result should contain:
      | total | name |
      | 2     | '人'  |
      | 1     | '城市' |

  Scenario: [2-4] YIELD子句测试-重复列-不支持
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL})
      }
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, name;
      """
    Then the error should be contain:
      """
      Multiple result columns with the same name are not supported
      """

  Scenario: [2-5] YIELD子句测试-列不存在
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL})
      }
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD nonexist;
      """
    Then the error should be contain:
      """
      [2701]Variable `nonexist` not defined
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, nonexist;
      """
    Then the error should be contain:
      """
      [2701]Variable `nonexist` not defined
      """

  Scenario: [2-6] YIELD子句测试-列名大小写敏感
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL})
      }
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD Name;
      """
    Then the error should be contain:
      """
      [2701]Variable `Name` not defined
      """

  # ============================================================
  # 3. WHERE 子句测试
  # ============================================================

  Scenario: [3-1] WHERE子句测试-等值条件
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就读于]->(:学校)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (c:人{姓名:"王武"}),
             (f:城市{名称:"成都"}),
             (g:城市{名称:"武汉"}),
             (j:学校{名称:"四川大学"}),
             (a)-[:朋友]->(b),
             (a)-[:朋友]->(c),
             (a)-[:籍贯]->(f),
             (b)-[:就读于]->(j)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total WHERE name = '人';
      """
    Then the result should contain:
      | name | total |
      | '人'  | 3     |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total WHERE name = 'Nonexist';
      """
    Then the result should be empty
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, total WHERE name = '朋友';
      """
    Then the result should contain:
      | name | total |
      | '朋友' | 2     |

  Scenario: [3-2] WHERE子句测试-数值条件
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:公司 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就读于]->(:学校),
        (:人)-[:就职于]->(:公司)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (c:人{姓名:"王武"}),
             (d:人{姓名:"陈阳"}),
             (f:城市{名称:"成都"}),
             (j:学校{名称:"四川大学"}),
             (o:公司{名称:"百度"}),
             (a)-[:朋友]->(b),
             (a)-[:朋友]->(c),
             (a)-[:朋友]->(d),
             (a)-[:籍贯]->(f),
             (a)-[:就读于]->(j),
             (a)-[:就职于]->(o)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total WHERE total > 1;
      """
    Then the result should contain:
      | name | total |
      | '人'  | 4     |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, total WHERE total = 1;
      """
    Then the result should contain:
      | name  | total |
      | '籍贯'  | 1     |
      | '就读于' | 1     |
      | '就职于' | 1     |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total WHERE total = 1;
      """
    Then the result should contain:
      | name | total |
      | '城市' | 1     |
      | '学校' | 1     |
      | '公司' | 1     |

  Scenario: [3-3] WHERE子句测试-多条件组合（AND）
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:同事]->(:人)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (a)-[:朋友]->(b),
             (a)-[:籍贯]->(f),
             (a)-[:同事]->(b)
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, total, mapping WHERE name = '朋友' AND total = 1;
      """
    Then the result should contain:
      | name | total | mapping  |
      | '朋友' | 1     | ['人->人'] |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total WHERE total = 1 AND name CONTAINS '市';
      """
    Then the result should contain:
      | name | total |
      | '城市' | 1     |

  Scenario: [3-4] WHERE子句测试-多条件组合（OR）
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就读于]->(:学校)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (j:学校{名称:"四川大学"}),
             (a)-[:朋友]->(b),
             (a)-[:籍贯]->(f),
             (a)-[:就读于]->(j)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total WHERE name = '人' OR total = 1;
      """
    Then the result should contain:
      | name | total |
      | '人'  | 2     |
      | '城市' | 1     |
      | '学校' | 1     |

  Scenario: [3-5] WHERE子句测试-NOT条件
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (g:城市{名称:"武汉"}),
             (a)-[:朋友]->(b),
             (a)-[:籍贯]->(f),
             (b)-[:籍贯]->(g)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total WHERE NOT name = '人';
      """
    Then the result should contain:
      | name | total |
      | '城市' | 2     |
      | '学校' | 0     |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total WHERE NOT name IN ['人', '城市'];
      """
    Then the result should contain:
      | name | total |
      | '学校' | 0     |

  Scenario: [3-6] WHERE子句测试-字符串匹配
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:就读于]->(:学校)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (j:学校{名称:"四川大学"}),
             (a)-[:朋友]->(b),
             (a)-[:就读于]->(j)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name WHERE name STARTS WITH '人';
      """
    Then the result should contain:
      | name |
      | '人'  |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name WHERE name ENDS WITH '市';
      """
    Then the result should contain:
      | name |
      | '城市' |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name WHERE name CONTAINS '友';
      """
    Then the result should contain:
      | name |
      | '朋友' |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name WHERE name =~ '.*学.*';
      """
    Then the result should contain:
      | name |
      | '学校' |

  Scenario: [3-7] WHERE子句测试-列表操作（IN）
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL})
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (j:学校{名称:"四川大学"})
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name WHERE name IN ['人', '城市'];
      """
    Then the result should contain:
      | name |
      | '人'  |
      | '城市' |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name WHERE NOT name IN ['人', '城市'];
      """
    Then the result should contain:
      | name |
      | '学校' |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name WHERE name IN [];
      """
    Then the result should be empty

  Scenario: [3-8] WHERE子句测试-mapping条件（仅EDGE）
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就读于]->(:学校)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (j:学校{名称:"四川大学"}),
             (a)-[:朋友]->(b),
             (a)-[:籍贯]->(f),
             (a)-[:就读于]->(j)
      """
    When executing queries without error:
      """
      SHOW EDGE SCHEMA YIELD name, mapping WHERE mapping = ['人->人'];
      """
    Then the result should contain:
      | name | mapping  |
      | 朋友   | ['人->人'] |
    When executing queries without error:
      """
      SHOW EDGE SCHEMA YIELD name, mapping WHERE mapping = ['人->城市'];
      """
    Then the result should contain:
      | name | mapping   |
      | '籍贯' | ['人->城市'] |

  # ============================================================
  # 4. RETURN 子句测试
  # ============================================================

  Scenario: [4-1] RETURN子句测试-RETURN *
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (a)-[:朋友]->(b)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD * RETURN *;
      """
    Then the column count should match the following list:
      | id | name | description | properties | total | mapping |
    And the result count should be [2]
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD * RETURN *;
      """
    Then the column count should match the following list:
      | id | name | description | properties | total | mapping |
    And the result count should be [1]

  Scenario: [4-2] RETURN子句测试-指定列
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
        (:城市 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明",年龄:25}),
             (b:人{姓名:"张文",年龄:35}),
             (f:城市{名称:"成都"}),
             (a)-[:朋友]->(b)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total RETURN name;
      """
    Then the result should contain:
      | name |
      | '人'  |
      | '城市' |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total, properties RETURN name, properties;
      """
    Then the result should contain:
      | name | properties                   |
      | '人'  | ['_PRIMARY_KEY', '姓名', '年龄'] |
      | '城市' | ['_PRIMARY_KEY', '名称']       |

  Scenario: [4-3] RETURN子句测试-表达式与别名
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (c:人{姓名:"王武"}),
             (f:城市{名称:"成都"}),
             (j:学校{名称:"四川大学"}),
             (a)-[:朋友]->(b),
             (a)-[:朋友]->(c)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total RETURN name, total + 1 AS totalPlusOne;
      """
    Then the result should contain:
      | name | totalPlusOne |
      | '人'  | 4            |
      | '城市' | 2            |
      | '学校' | 2            |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name RETURN 'Node:' + name AS nodeName;
      """
    Then the result should contain:
      | nodeName  |
      | 'Node:人'  |
      | 'Node:城市' |
      | 'Node:学校' |

  Scenario: [4-4] RETURN子句测试-CASE表达式
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"}),
             (a)-[:朋友]->(b),
             (a)-[:籍贯]->(f)
      """
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, total RETURN name, CASE total WHEN 1 THEN '有数据' WHEN 0 THEN '无数据' ELSE '未知' END AS dataStatus;
      """
    Then the result should contain:
      | name | dataStatus |
      | '朋友' | '有数据'      |
      | '籍贯' | '有数据'      |

  # ============================================================
  # 5. 扩展功能测试
  # ============================================================

  Scenario: [5-1] 扩展功能测试-ORDER BY排序
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:公司 {名称 STRING NOT NULL}),
        (:人)-[:朋友]->(:人),
        (:人)-[:籍贯]->(:城市),
        (:人)-[:就读于]->(:学校),
        (:人)-[:就职于]->(:公司)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (c:人{姓名:"王武"}),
             (d:人{姓名:"陈阳"}),
             (f:城市{名称:"成都"}),
             (g:城市{名称:"武汉"}),
             (j:学校{名称:"四川大学"}),
             (k:学校{名称:"武汉大学"}),
             (o:公司{名称:"百度"}),
             (p:公司{名称:"腾讯"}),
             (a)-[:朋友]->(b),
             (a)-[:朋友]->(c),
             (a)-[:朋友]->(d),
             (a)-[:籍贯]->(f),
             (b)-[:籍贯]->(g),
             (a)-[:就读于]->(j),
             (b)-[:就职于]->(o)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total RETURN name, total ORDER BY total DESC;
      """
    Then the result should be, in any order:
      | name | total |
      | '人'  | 4     |
      | '城市' | 2     |
      | '学校' | 2     |
      | '公司' | 2     |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total RETURN name, total ORDER BY name ASC;
      """
    Then the result should be, in any order:
      | name | total |
      | '公司' | 2     |
      | '城市' | 2     |
      | '人'  | 4     |
      | '学校' | 2     |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, total RETURN name, total ORDER BY total ASC, name DESC;
      """
    Then the result should be, in any order:
      | name  | total |
      | '就职于' | 1     |
      | '就读于' | 1     |
      | '籍贯'  | 2     |
      | '朋友'  | 3     |

  Scenario: [5-2] 扩展功能测试-SKIP/LIMIT分页
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL}),
        (:学校 {名称 STRING NOT NULL}),
        (:公司 {名称 STRING NOT NULL})
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (c:人{姓名:"王武"}),
             (d:人{姓名:"陈阳"}),
             (f:城市{名称:"成都"}),
             (g:城市{名称:"武汉"}),
             (j:学校{名称:"四川大学"}),
             (k:学校{名称:"武汉大学"})
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name LIMIT 2;
      """
    Then the result count should be [2]
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name SKIP 2;
      """
    Then the result count should be [2]
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name SKIP 1 LIMIT 2;
      """
    Then the result count should be [2]

  Scenario: [5-3] 扩展功能测试-AS别名
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL}),
        (:城市 {名称 STRING NOT NULL})
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明"}),
             (b:人{姓名:"张文"}),
             (f:城市{名称:"成都"})
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name AS nodeName RETURN nodeName;
      """
    Then the result should contain:
      | nodeName |
      | '人'      |
      | '城市'     |
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name AS n, total AS t RETURN n, t;
      """
    Then the result should contain:
      | n    | t |
      | '人'  | 2 |
      | '城市' | 1 |

  Scenario: [5-4] 扩展功能测试-多标签组合场景
    Given an empty graph
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
        (:人 {姓名 STRING NOT NULL, 年龄 INT64, 性别 BOOL}),
        (:员工 {员工编号 INT64 NOT NULL}),
        (:经理 {级别 INT64}),
        (:部门 {部门名称 STRING NOT NULL}),
        (:人)-[:工作于]->(:部门),
        (:员工)-[:管理]->(:部门),
        (:经理)-[:监督]->(:员工)
      }
      """
    When executing queries without error:
      """
      CREATE (a:人{姓名:"李明",年龄:25,性别:true}),
             (b:人{姓名:"张文",年龄:35,性别:true}),
             (c:人{姓名:"王武",年龄:18,性别:true}),
             (d:员工{员工编号:1001}),
             (e:员工{员工编号:1002}),
             (f:经理{级别:3}),
             (g:部门{部门名称:"技术部"}),
             (h:部门{部门名称:"市场部"}),
             (a)-[:工作于]->(g),
             (b)-[:工作于]->(g),
             (c)-[:工作于]->(h),
             (d)-[:管理]->(g),
             (f)-[:监督]->(d)
      """
    When executing query:
      """
      SHOW NODE SCHEMA YIELD name, total, properties WHERE total > 1;
      """
    Then the result should contain:
      | name | total | properties                         |
      | '人'  | 3     | ['_PRIMARY_KEY', '姓名', '年龄', '性别'] |
      | '部门' | 2     | ['_PRIMARY_KEY', '部门名称']           |
    When executing query:
      """
      SHOW EDGE SCHEMA YIELD name, mapping WHERE mapping = ['人->部门'] OR mapping = ['员工->部门'];
      """
    Then the result should contain:
      | name  | mapping    |
      | '工作于' | ['人->部门']  |
      | '管理'  | ['员工->部门'] |