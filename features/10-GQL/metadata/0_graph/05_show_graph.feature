#encoding: utf-8

Feature: SHOW GRAPH - 图查询功能测试

  Background:
    Given drop all graph

  # ============================================================
  # 1. 基础功能测试
  # ============================================================

  Scenario Outline: [1-1] 基础功能测试-基础语法-<comment>
    Given drop all graph
    When executing query:
      """
      <gql>
      """
    And the result count should be [2]
    Then drop all graph
    Examples:
      | gql            | comment |
      | SHOW GRAPH;    | '全大写'   |
      | SHOW GRAPH     | '无分号'   |
      | show graph;    | '全小写'   |
      | Show Graph;    | '首字母大写' |
      | sHoW gRaPh;    | '大小写混合' |
      | SHOW GRAPH ;   | '多余空格'  |
      | SHOW<br>GRAPH; | '换行分割'  |

  Scenario: [1-2] 基础功能测试-未创图查询
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH;
      """
    And the result count should be [2]
    Then drop all graph

  Scenario: [1-3] 基础功能测试-创图后查询
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH test;
      """
    When executing query:
      """
      SHOW GRAPH;
      """
    And the result count should be [3]
    Then drop all graph

  # ============================================================
  # 2. YIELD 子句测试
  # ============================================================

  Scenario: [2-1] YIELD子句测试-YIELD *
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD *;
      """
    Then the column count should match the following list:
      | name | segmentCount | replicaCount | status | capacity | size | creationDate | character set | cipherMode |
    Then drop all graph

  Scenario: [2-2] YIELD子句测试-指定列
    Given drop all graph
    #单列
    When executing query:
      """
      SHOW GRAPH YIELD name;
      """
    And the result should contain:
      | name      |
      | 'sys'     |
      | 'default' |
    #两列
    When executing query:
      """
      SHOW GRAPH YIELD name, status;
      """
    And the result should contain:
      | name      | status   |
      | 'sys'     | 'online' |
      | 'default' | 'online' |
    #三列
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount;
      """
    And the result should contain:
      | name      | segmentCount | replicaCount |
      | 'sys'     | 1            | 1            |
      | 'default' | 1            | 1            |
    #所有列
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount, status, capacity, size, creationDate, `character set`, cipherMode;
      """
    Then the column count should match the following list:
      | name | segmentCount | replicaCount | status | capacity | size | creationDate | character set | cipherMode |
    Then drop all graph

  Scenario: [2-3] YIELD子句测试-列顺序
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount;
      """
    And the result should contain:
      | name      | segmentCount | replicaCount |
      | 'sys'     | 1            | 1            |
      | 'default' | 1            | 1            |
    When executing query:
      """
      SHOW GRAPH YIELD replicaCount, name, segmentCount;
      """
    And the result should contain:
      | replicaCount | name      | segmentCount |
      | 1            | 'sys'     | 1            |
      | 1            | 'default' | 1            |
    Then drop all graph

  Scenario: [2-4] YIELD子句测试-重复列-不支持
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD name, name;
      """
    Then the error should be contain:
      """
      Multiple result columns with the same name are not supported
      """
    Then drop all graph

  Scenario: [2-5] YIELD子句测试-列不存在
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD nonexist;
      """
    Then the error should be contain:
      """
      [2701]Variable `nonexist` not defined
      """
    When executing query:
      """
      SHOW GRAPH YIELD name, nonexist, status;
      """
    Then the error should be contain:
      """
      [2701]Variable `nonexist` not defined
      """
    Then drop all graph

  Scenario: [2-6] YIELD子句测试-列名大小写-大小写敏感
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD name, status;
      """
    And the result should contain:
      | name      | status   |
      | 'sys'     | 'online' |
      | 'default' | 'online' |
    When executing query:
      """
      SHOW GRAPH YIELD NAME, STATUS;
      """
    Then the error should be contain:
      """
      [2701]Variable `NAME` not defined
      """
    When executing query:
      """
      SHOW GRAPH YIELD Name, Status;
      """
    Then the error should be contain:
      """
      [2701]Variable `Name` not defined
      """
    Then drop all graph

  # ============================================================
  # 3. WHERE 子句测试
  # ============================================================

  Scenario: [3-1] WHERE子句测试-等值条件
    Given drop all graph
    #等值匹配
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount WHERE name = 'default';
      """
    And the result should contain:
      | name      | segmentCount | replicaCount |
      | 'default' | 1            | 1            |
    #等值不匹配
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount WHERE name = 'nonexist';
      """
    Then the result should be empty
    #数值等值
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount WHERE segmentCount = 1;
      """
    And the result should contain:
      | name      | segmentCount | replicaCount |
      | 'sys'     | 1            | 1            |
      | 'default' | 1            | 1            |
    Then drop all graph

  Scenario: [3-2] WHERE子句测试-范围条件
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #等于
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount WHERE segmentCount = 3;
      """
    And the result should contain:
      | name   | segmentCount |
      | 'seg3' | 3            |
    #大于
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount WHERE segmentCount > 3;
      """
    And the result should contain:
      | name   | segmentCount |
      | 'seg5' | 5            |
    #大于等于
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount WHERE segmentCount >= 1;
      """
    And the result should contain:
      | name      | segmentCount |
      | 'sys'     | 1            |
      | 'default' | 1            |
      | 'seg5'    | 5            |
      | 'seg3'    | 3            |
    #小于
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount WHERE segmentCount < 5;
      """
    And the result should contain:
      | name      | segmentCount |
      | 'sys'     | 1            |
      | 'default' | 1            |
      | 'seg3'    | 3            |
    #小于等于
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount WHERE segmentCount <= 2;
      """
    And the result should contain:
      | name      | segmentCount |
      | 'sys'     | 1            |
      | 'default' | 1            |
    Then drop all graph

  Scenario: [3-3] WHERE子句测试-多条件组合（AND）
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #AND两条件
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE name = 'default' AND status = 'online';
      """
    And the result should contain:
      | name      | status   | segmentCount | replicaCount |
      | 'default' | 'online' | 1            | 1            |
    #AND三条件
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE segmentCount > 1 AND name CONTAINS 'seg' AND status = 'online';
      """
    And the result should contain:
      | name   | status   | segmentCount | replicaCount |
      | 'seg3' | 'online' | 3            | 1            |
      | 'seg5' | 'online' | 5            | 1            |
    Then drop all graph

  Scenario: [3-4] WHERE子句测试-多条件组合（OR）
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #OR两条件
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE name = 'default' OR name = 'seg3';
      """
    And the result should contain:
      | name      | status   | segmentCount | replicaCount |
      | 'default' | 'online' | 1            | 1            |
      | 'seg3'    | 'online' | 3            | 1            |
    #OR三条件
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, cipherMode WHERE segmentCount > 3 OR name = 'sys' OR cipherMode = 'plain';
      """
    And the result should contain:
      | name   | status   | segmentCount | cipherMode |
      | 'seg3' | 'online' | 3            | 'plain'    |
      | 'seg5' | 'online' | 5            | 'plain'    |
      | 'sys'  | 'online' | 1            | 'plain'    |
    Then drop all graph

  Scenario: [3-5] WHERE子句测试-混合AND/OR及括号
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #AND优先于OR
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE name = 'default' AND status = 'online' OR segmentCount = 3;
      """
    And the result should contain:
      | name      | status   | segmentCount | replicaCount |
      | 'default' | 'online' | 1            | 1            |
      | 'seg3'    | 'online' | 3            | 1            |
    #括号改变优先级
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE name = 'default' AND (status = 'online' OR segmentCount = 3);
      """
    And the result should contain:
      | name      | status   | segmentCount | replicaCount |
      | 'default' | 'online' | 1            | 1            |
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE (name = 'default' OR name = 'sys') AND (status = 'online' AND replicaCount > 0);
      """
    And the result should contain:
      | name      | status   | segmentCount | replicaCount |
      | 'default' | 'online' | 1            | 1            |
      | 'sys'     | 'online' | 1            | 1            |
    Then drop all graph

  Scenario: [3-6] WHERE子句测试-NOT条件
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #NOT等值
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE NOT name = 'default';
      """
    And the result should contain:
      | name   | status   | segmentCount | replicaCount |
      | 'seg3' | 'online' | 3            | 1            |
      | 'sys'  | 'online' | 1            | 1            |
      | 'seg5' | 'online' | 5            | 1            |
    #NOT IN
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE NOT name IN ['default', 'seg3'];
      """
    And the result should contain:
      | name   | status   | segmentCount | replicaCount |
      | 'sys'  | 'online' | 1            | 1            |
      | 'seg5' | 'online' | 5            | 1            |
    #NOT + 范围
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE NOT segmentCount > 2;
      """
    And the result should contain:
      | name      | status   | segmentCount | replicaCount |
      | 'default' | 'online' | 1            | 1            |
      | 'sys'     | 'online' | 1            | 1            |
    Then drop all graph

  Scenario: [3-7] WHERE子句测试-NULL/空值处理
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #IS NULL
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE size IS NULL;
      """
    Then the result should be empty
    #IS NOT NULL
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount WHERE name IS NOT NULL;
      """
    And the result should contain:
      | name      | status   | segmentCount | replicaCount |
      | 'seg3'    | 'online' | 3            | 1            |
      | 'sys'     | 'online' | 1            | 1            |
      | 'seg5'    | 'online' | 5            | 1            |
      | 'default' | 'online' | 1            | 1            |
    Then drop all graph

  Scenario: [3-8] WHERE子句测试-字符串匹配
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #STARTS WITH
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE name STARTS WITH 'seg' RETURN name,status;
      """
    Then the result should contain:
      | name   | status   |
      | 'seg3' | 'online' |
      | 'seg5' | 'online' |
    #ENDS WITH
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE name ENDS WITH 't' RETURN name,status;
      """
    Then the result should contain:
      | name      | status   |
      | 'default' | 'online' |
    #CONTAINS
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE name CONTAINS 'e' RETURN name,status;
      """
    And the result should contain:
      | name      | status   |
      | 'default' | 'online' |
      | 'seg3'    | 'online' |
      | 'seg5'    | 'online' |
    #正则匹配
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE name =~ 's.*' RETURN name,status;
      """
    And the result should contain:
      | name   | status   |
      | 'sys'  | 'online' |
      | 'seg3' | 'online' |
      | 'seg5' | 'online' |
    Then drop all graph

  Scenario: [3-9] WHERE子句测试-列表操作
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #IN
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE name IN ['default', 'seg3'] RETURN name,status;
      """
    Then the result should contain:
      | name      | status   |
      | 'default' | 'online' |
      | 'seg3'    | 'online' |
    #NOT IN
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE NOT name IN ['default', 'seg3'] RETURN name,status;
      """
    Then the result should contain:
      | name   | status   |
      | 'sys'  | 'online' |
      | 'seg5' | 'online' |
    #空列表
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE name IN [] RETURN name,status;
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [3-10] WHERE子句测试-类型不匹配
    Given drop all graph
    #时间类型与数字比较
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE creationDate > 123 RETURN name,status;
      """
    Then the result should be empty
    #数字与字符串比较
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE segmentCount = 'abc' RETURN name,status;
      """
    Then the result should be empty
    Then drop all graph

  # ============================================================
  # 4. RETURN 子句测试
  # ============================================================

  Scenario: [4-1] RETURN子句测试-RETURN *
    Given drop all graph
    #RETURN所有列
    When executing query:
      """
      SHOW GRAPH YIELD * RETURN *;
      """
    Then the column count should match the following list:
      | name | segmentCount | replicaCount | status | capacity | size | creationDate | character set | cipherMode |
    #YIELD后RETURN *
    When executing query:
      """
      SHOW GRAPH YIELD name, status RETURN *;
      """
    Then the result should contain:
      | name      | status   |
      | 'sys'     | 'online' |
      | 'default' | 'online' |
    #WHERE后RETURN *
    When executing query:
      """
      SHOW GRAPH YIELD name, status WHERE name = 'default' RETURN *;
      """
    Then the result should contain:
      | name      | status   |
      | 'default' | 'online' |
    Then drop all graph

  Scenario: [4-2] RETURN子句测试-指定列
    Given drop all graph
    #单列
    When executing query:
      """
      SHOW GRAPH YIELD * RETURN name;
      """
    Then the result should contain:
      | name      |
      | 'sys'     |
      | 'default' |
    #多列
    When executing query:
      """
      SHOW GRAPH YIELD * RETURN name,status;
      """
    Then the result should contain:
      | name      | status   |
      | 'sys'     | 'online' |
      | 'default' | 'online' |
    #返回子集
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount RETURN name,segmentCount;
      """
    Then the result should contain:
      | name      | segmentCount |
      | 'default' | 1            |
      | 'sys'     | 1            |
    #改变列顺序
    When executing query:
      """
      SHOW GRAPH YIELD name, status, segmentCount, replicaCount RETURN name,segmentCount, status, replicaCount;
      """
    Then the result should contain:
      | name      | segmentCount | status   | replicaCount |
      | 'default' | 1            | 'online' | 1            |
      | 'sys'     | 1            | 'online' | 1            |
    Then drop all graph

  Scenario: [4-3] RETURN子句测试-重复列
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD * RETURN name,name,status;
      """
    Then the error should be contain:
      """
      Multiple result columns with the same name are not supported
      """
    Then drop all graph

  Scenario: [4-4] RETURN子句测试-列不存在
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD * RETURN invalid;
      """
    Then the error should be contain:
      """
      [2701]Variable `invalid` not defined
      """
    When executing query:
      """
      SHOW GRAPH YIELD name, status RETURN name, invalid;
      """
    Then the error should be contain:
      """
      [2701]Variable `invalid` not defined
      """
    Then drop all graph

  Scenario: [4-5] RETURN子句测试-YIELD与RETURN组合
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #YIELD后过滤再返回
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE name = 'default' RETURN name, status;
      """
    Then the result should contain:
      | name      | status   |
      | 'default' | 'online' |
    #YIELD指定列+WHERE+RETURN子集
    When executing query:
      """
      SHOW GRAPH YIELD name, status, size, segmentCount WHERE segmentCount > 2 RETURN name, segmentCount;
      """
    Then the result should contain:
      | name   | segmentCount |
      | 'seg3' | 3            |
      | 'seg5' | 5            |
    #RETURN列不在YIELD中
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount RETURN name,status;
      """
    Then the error should be contain:
      """
      [2701]Variable `status` not defined
      """
    Then drop all graph

  Scenario: [4-6] RETURN子句测试-表达式与别名
    Given drop all graph
    #算术表达式
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount RETURN name, segmentCount + replicaCount AS totalParts;
      """
    Then the result should contain:
      | name      | totalParts |
      | 'default' | 2          |
      | 'sys'     | 2          |
    #字符串表达式
    When executing query:
      """
      SHOW GRAPH YIELD name, status RETURN name + ' [' + status + ']' AS fullInfo;
      """
    Then the result should contain:
      | fullInfo           |
      | 'sys [online]'     |
      | 'default [online]' |
    #返回常量
    When executing query:
      """
      SHOW GRAPH YIELD name RETURN name, 100 AS num;
      """
    Then the result should contain:
      | name      | num |
      | 'default' | 100 |
      | 'sys'     | 100 |
    Then drop all graph

  Scenario: [4-7] RETURN子句测试-CASE表达式
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD name, status RETURN name, CASE status WHEN 'online' THEN 'UP' WHEN 'offline' THEN 'DOWN' ELSE 'UNKNOWN' END AS state;
      """
    Then the result should contain:
      | name      | state |
      | 'default' | 'UP'  |
      | 'sys'     | 'UP'  |
    Then drop all graph

  Scenario: [4-8] RETURN子句测试-聚合函数
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD name, size RETURN count(*);
      """
    Then the result should contain:
      | count(*) |
      | 2        |
    Then drop all graph

  Scenario: [4-9] RETURN子句测试-DISTINCT去重
    Given drop all graph
    When executing query:
      """
      SHOW GRAPH YIELD status RETURN DISTINCT status;
      """
    Then the result should contain:
      | status   |
      | 'online' |
    Then drop all graph

  # ============================================================
  # 5. 扩展功能测试
  # ============================================================

  Scenario: [5-1] 扩展功能测试-ORDER BY排序
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #默认ASC升序
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount RETURN name, segmentCount ORDER BY segmentCount;
      """
    Then the result should be, in any order:
      | name      | segmentCount |
      | 'sys'     | 1            |
      | 'default' | 1            |
      | 'seg3'    | 3            |
      | 'seg5'    | 5            |
    #ASC显式
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount RETURN name, segmentCount ORDER BY segmentCount ASC;
      """
    Then the result should be, in any order:
      | name      | segmentCount |
      | 'sys'     | 1            |
      | 'default' | 1            |
      | 'seg3'    | 3            |
      | 'seg5'    | 5            |
    #DESC降序
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount RETURN name, segmentCount ORDER BY segmentCount DESC;
      """
    Then the result should be, in any order:
      | name      | segmentCount |
      | 'seg5'    | 5            |
      | 'seg3'    | 3            |
      | 'default' | 1            |
      | 'sys'     | 1            |
    #多列混合排序
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount RETURN name, segmentCount ORDER BY segmentCount ASC, name DESC;
      """
    Then the result should be, in any order:
      | name      | segmentCount |
      | 'sys'     | 1            |
      | 'default' | 1            |
      | 'seg3'    | 3            |
      | 'seg5'    | 5            |
    Then drop all graph

  Scenario: [5-2] 扩展功能测试-SKIP/LIMIT分页
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #LIMIT
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount LIMIT 1;
      """
    Then the result should be, in any order:
      | name   | segmentCount |
      | 'seg3' | 3            |
    #SKIP
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount SKIP 1;
      """
    Then the result should be, in any order:
      | name      | segmentCount |
      | 'seg5'    | 5            |
      | 'sys'     | 1            |
      | 'default' | 1            |
    #SKIP后LIMIT
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount SKIP 1 LIMIT 2;
      """
    Then the result should be, in any order:
      | name   | segmentCount |
      | 'seg5' | 5            |
      | 'sys'  | 1            |
    #SKIP + LIMIT 与 WHERE
    When executing query:
      """
      SHOW GRAPH YIELD * WHERE status = 'online' RETURN name, status SKIP 1 LIMIT 1;
      """
    Then the result should be, in any order:
      | name   | status   |
      | 'seg5' | 'online' |
    Then drop all graph

  Scenario: [5-3] 扩展功能测试-AS别名
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #YIELD中AS别名
    When executing query:
      """
      SHOW GRAPH YIELD name AS graph_name RETURN graph_name;
      """
    Then the result should contain:
      | graph_name |
      | 'seg5'     |
      | 'seg3'     |
      | 'default'  |
      | 'sys'      |
    #YIELD多列别名
    When executing query:
      """
      SHOW GRAPH YIELD name AS n, status AS s RETURN n, s;
      """
    Then the result should contain:
      | n         | s        |
      | 'seg5'    | 'online' |
      | 'seg3'    | 'online' |
      | 'default' | 'online' |
      | 'sys'     | 'online' |
    #别名与原列重名
    When executing query:
      """
      SHOW GRAPH YIELD name AS name, status AS s RETURN name, s;
      """
    Then the result should contain:
      | name      | s        |
      | 'seg5'    | 'online' |
      | 'seg3'    | 'online' |
      | 'default' | 'online' |
      | 'sys'     | 'online' |
    #RETURN中AS别名
    When executing query:
      """
      SHOW GRAPH YIELD * RETURN name AS n, status AS s;
      """
    Then the result should contain:
      | n         | s        |
      | 'seg5'    | 'online' |
      | 'seg3'    | 'online' |
      | 'default' | 'online' |
      | 'sys'     | 'online' |
    #RETURN别名与YIELD别名
    When executing query:
      """
      SHOW GRAPH YIELD name AS n, status AS s RETURN n AS graph_name, s AS state;
      """
    Then the result should contain:
      | graph_name | state    |
      | 'seg5'     | 'online' |
      | 'seg3'     | 'online' |
      | 'default'  | 'online' |
      | 'sys'      | 'online' |
    #表达式别名
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount AS seg RETURN name, seg * 2 AS doubleSeg;
      """
    Then the result should contain:
      | name      | doubleSeg |
      | 'sys'     | 2         |
      | 'default' | 2         |
      | 'seg3'    | 6         |
      | 'seg5'    | 10        |
    Then drop all graph

  Scenario: [5-4] 扩展功能测试-算术表达式
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH seg5 SEGMENT 5;
      CREATE GRAPH seg3 SEGMENT 3;
      """
    #加法
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount RETURN name, segmentCount + replicaCount AS total;
      """
    Then the result should contain:
      | name      | total |
      | 'seg5'    | 6     |
      | 'seg3'    | 4     |
      | 'default' | 2     |
      | 'sys'     | 2     |
    #减法
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount RETURN name, segmentCount - replicaCount AS diff;
      """
    Then the result should contain:
      | name      | diff |
      | 'seg5'    | 4    |
      | 'seg3'    | 2    |
      | 'default' | 0    |
      | 'sys'     | 0    |
    #乘法
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount RETURN name, segmentCount * 2 AS doubled;
      """
    Then the result should contain:
      | name      | doubled |
      | 'sys'     | 2       |
      | 'default' | 2       |
      | 'seg3'    | 6       |
      | 'seg5'    | 10      |
    #除法
    When executing query:
      """
      SHOW GRAPH YIELD * RETURN name, segmentCount / replicaCount AS num;
      """
    Then the result should contain:
      | name      | num |
      | 'sys'     | 1   |
      | 'default' | 1   |
      | 'seg3'    | 3   |
      | 'seg5'    | 5   |
    #嵌套表达式
    When executing query:
      """
      SHOW GRAPH YIELD name, segmentCount, replicaCount RETURN name, (segmentCount + replicaCount) * 2 AS doubledSum;
      """
    Then the result should contain:
      | name      | doubledSum |
      | 'sys'     | 4          |
      | 'default' | 4          |
      | 'seg3'    | 8          |
      | 'seg5'    | 12         |
    Then drop all graph

  Scenario: [5-5] 扩展功能测试-字符串函数
    Given drop all graph
    When executing queries without error:
      """
      CREATE GRAPH TEST;
      """
    #toUpper
    When executing query:
      """
      SHOW GRAPH YIELD name RETURN toUpper(name) AS upperName;
      """
    Then the result should contain:
      | upperName |
      | 'SYS'     |
      | 'DEFAULT' |
      | 'TEST'    |
    #toLower
    When executing query:
      """
      SHOW GRAPH YIELD name RETURN toLower(name) AS lowerName;
      """
    Then the result should contain:
      | lowerName |
      | 'sys'     |
      | 'default' |
      | 'test'    |
    #substring
    When executing query:
      """
      SHOW GRAPH YIELD name RETURN substring(name, 0, 3) AS prefix;
      """
    Then the result should contain:
      | prefix |
      | 'sys'  |
      | 'def'  |
      | 'TES'  |
    #size
    When executing query:
      """
      SHOW GRAPH YIELD name RETURN name, size(name) AS nameLength;
      """
    Then the result should contain:
      | name      | nameLength |
      | 'sys'     | 3          |
      | 'default' | 7          |
      | 'TEST'    | 4          |
    #replace
    When executing query:
      """
      SHOW GRAPH YIELD name RETURN replace(name, 'TEST', 'prod') AS replacedName;
      """
    Then the result should contain:
      | replacedName |
      | 'sys'        |
      | 'default'    |
      | 'prod'       |
    #trim
    When executing query:
      """
      SHOW GRAPH YIELD name RETURN trim(name) AS trimmedName;
      """
    Then the result should contain:
      | trimmedName |
      | 'sys'       |
      | 'default'   |
      | 'TEST'      |
    Then drop all graph