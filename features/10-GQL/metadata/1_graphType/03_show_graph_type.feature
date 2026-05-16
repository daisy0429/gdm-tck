Feature: SHOW GRAPH TYPE - 图模型查询功能测试

  Background:
    Given drop all graph
    And drop all graphType

    # ============================================================
    # 1. 基础功能测试
    # ============================================================

  Scenario Outline: [1-1] 基础功能测试-基础语法-<comment>
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            <gql>
            """
    Then the result should be, in any order:
      | name            | gql                                                                      |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' |
    Then drop all graph
    And drop all graphType
    Examples:
      | gql               | comment |
      | SHOW GRAPH TYPE;  | 全大写     |
      | SHOW GRAPH TYPE   | 无分号     |
      | show graph type;  | 全小写     |
      | Show Graph Type;  | 大小写混合   |
      | SHOW GRAPH TYPE ; | 多余空格    |

  Scenario: [1-2] 基础功能测试-无图模型查询
    Given drop all graph
    Then drop all graphType
    When executing query:
            """
            SHOW GRAPH TYPE;
            """
    Then the result should be empty
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE;
            """
    Then the result should be, in any order:
      | name            | gql                                                                      |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' |
    When executing queries without error:
            """
            DROP GRAPH TYPE my_graph_type;
            """
    When executing query:
            """
            SHOW GRAPH TYPE;
            """
    Then the result should be empty
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 2. YIELD 子句测试
    # ============================================================

  Scenario: [2-1] YIELD子句测试-YIELD所有列和指定列
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
        # YIELD所有列
    When executing query:
            """
            SHOW GRAPH TYPE YIELD *;
            """
    Then the result should be, in any order:
      | name            | gql                                                                      |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' |
        # YIELD单列name
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name;
            """
    Then the result should be, in any order:
      | name            |
      | 'my_graph_type' |
        # YIELD单列gql
    When executing query:
            """
            SHOW GRAPH TYPE YIELD gql RETURN gql;
            """
    Then the result should be, in any order:
      | gql                                                                      |
      | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' |
        # YIELD多列name, gql
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, gql RETURN name, gql;
            """
    Then the result should be, in any order:
      | name            | gql                                                                      |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' |
        # YIELD列顺序颠倒
    When executing query:
            """
            SHOW GRAPH TYPE YIELD gql, name RETURN gql, name;
            """
    Then the result should be, in any order:
      | gql                                                                      | name            |
      | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' | 'my_graph_type' |
    Then drop all graph
    And drop all graphType

  Scenario: [2-2] YIELD子句测试-重复列
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, name RETURN name, name;
            """
    Then the error should be contain:
            """
            Multiple result columns with the same name are not supported
            """
    Then drop all graph
    And drop all graphType

  Scenario: [2-3] YIELD子句测试-不存在的列
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD nonexist RETURN nonexist;
            """
    Then the error should be contain:
      """
      [2701]Variable `nonexist` not defined
      """
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 3. WHERE 子句测试
    # ============================================================

  Scenario: [3-1] WHERE子句测试-等值匹配
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type01 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE my_graph_type02 {
                (:Animal {name string, age int64})
            };
            """
        # 等值匹配存在
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name = 'my_graph_type01' RETURN *;
            """
    Then the result should be, in any order:
      | name              | gql                                                                        |
      | 'my_graph_type01' | 'CREATE GRAPH TYPE my_graph_type01 { (:Person {name string,age int64}) };' |
        # 等值匹配不存在
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name = 'nonexist' RETURN *;
            """
    Then the result should be empty
    Then drop all graph
    And drop all graphType

  Scenario: [3-2] WHERE子句测试-大小比较
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE A_graph_type {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE B_graph_type {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE C_graph_type {
                (:Person {name string, age int64})
            };
            """
        # 大于条件
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name > 'B_graph_type' RETURN *;
            """
    Then the result should be, in any order:
      | name           | gql                                                                     |
      | 'C_graph_type' | 'CREATE GRAPH TYPE C_graph_type { (:Person {name string,age int64}) };' |
        # 小于条件
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name < 'B_graph_type' RETURN *;
            """
    Then the result should be, in any order:
      | name           | gql                                                                     |
      | 'A_graph_type' | 'CREATE GRAPH TYPE A_graph_type { (:Person {name string,age int64}) };' |
    Then drop all graph
    And drop all graphType

  Scenario: [3-3] WHERE子句测试-逻辑组合
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type01 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE my_graph_type02 {
                (:Animal {name string, age int64})
            };
            CREATE GRAPH TYPE other_type {
                (:Other {name string, age int64})
            };
            """
        # AND条件
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name = 'my_graph_type01' AND gql CONTAINS 'Person' RETURN *;
            """
    Then the result should be, in any order:
      | name              | gql                                                                        |
      | 'my_graph_type01' | 'CREATE GRAPH TYPE my_graph_type01 { (:Person {name string,age int64}) };' |
        # OR条件
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name = 'my_graph_type01' OR name = 'my_graph_type02' RETURN *;
            """
    Then the result should be, in any order:
      | name              | gql                                                                        |
      | 'my_graph_type01' | 'CREATE GRAPH TYPE my_graph_type01 { (:Person {name string,age int64}) };' |
      | 'my_graph_type02' | 'CREATE GRAPH TYPE my_graph_type02 { (:Animal {name string,age int64}) };' |
        # NOT条件
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE NOT name = 'my_graph_type01' RETURN *;
            """
    Then the result should be, in any order:
      | name              | gql                                                                        |
      | 'my_graph_type02' | 'CREATE GRAPH TYPE my_graph_type02 { (:Animal {name string,age int64}) };' |
      | 'other_type'      | 'CREATE GRAPH TYPE other_type { (:Other {name string,age int64}) };'       |
    Then drop all graph
    And drop all graphType

  Scenario: [3-4] WHERE子句测试-列表测试
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type01 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE my_graph_type02 {
                (:Animal {name string, age int64})
            };
            """
        # IN列表
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name IN ['my_graph_type01', 'test'] RETURN *;
            """
    Then the result should be, in any order:
      | name              | gql                                                                        |
      | 'my_graph_type01' | 'CREATE GRAPH TYPE my_graph_type01 { (:Person {name string,age int64}) };' |
        # NOT IN列表
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE NOT name IN ['my_graph_type01', 'test'] RETURN *;
            """
    Then the result should be, in any order:
      | name              | gql                                                                        |
      | 'my_graph_type02' | 'CREATE GRAPH TYPE my_graph_type02 { (:Animal {name string,age int64}) };' |
        # IN空列表
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name IN [] RETURN *;
            """
    Then the result should be empty
    Then drop all graph
    And drop all graphType

  Scenario: [3-5] WHERE子句测试-字符串匹配
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE animal_type {
                (:Animal {name string, age int64})
            };
            CREATE GRAPH TYPE my_person_type {
                (:Person {name string, age int64})
            };
            """
        # STARTS WITH
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name STARTS WITH 'person' RETURN *;
            """
    Then the result should be, in any order:
      | name          | gql                                                                    |
      | 'person_type' | 'CREATE GRAPH TYPE person_type { (:Person {name string,age int64}) };' |
        # ENDS WITH
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name ENDS WITH '_type' RETURN *;
            """
    Then the result should be, in any order:
      | name             | gql                                                                       |
      | 'person_type'    | 'CREATE GRAPH TYPE person_type { (:Person {name string,age int64}) };'    |
      | 'animal_type'    | 'CREATE GRAPH TYPE animal_type { (:Animal {name string,age int64}) };'    |
      | 'my_person_type' | 'CREATE GRAPH TYPE my_person_type { (:Person {name string,age int64}) };' |
        # CONTAINS
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE name CONTAINS 'person' RETURN *;
            """
    Then the result should be, in any order:
      | name             | gql                                                                       |
      | 'person_type'    | 'CREATE GRAPH TYPE person_type { (:Person {name string,age int64}) };'    |
      | 'my_person_type' | 'CREATE GRAPH TYPE my_person_type { (:Person {name string,age int64}) };' |
    Then drop all graph
    And drop all graphType

  Scenario: [3-6] WHERE子句测试-IS NOT NULL
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * WHERE gql IS NOT NULL RETURN *;
            """
    Then the result should be, in any order:
      | name            | gql                                                                      |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' |
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 4. RETURN 子句测试
    # ============================================================

  Scenario: [4-1] RETURN子句测试-投影和表达式
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
        # RETURN所有列
    When executing query:
            """
            SHOW GRAPH TYPE YIELD * RETURN *;
            """
    Then the result should be, in any order:
      | name            | gql                                                                      |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' |
        # 返回子集
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, gql RETURN name;
            """
    Then the result should be, in any order:
      | name            |
      | 'my_graph_type' |
        # 改变列顺序
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, gql RETURN gql, name;
            """
    Then the result should be, in any order:
      | gql                                                                      | name            |
      | 'CREATE GRAPH TYPE my_graph_type { (:Person {name string,age int64}) };' | 'my_graph_type' |
        # 字符串表达式
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN 'GraphType: ' + name AS fullName;
            """
    Then the result should be, in any order:
      | fullName                   |
      | 'GraphType: my_graph_type' |
        # 返回常量
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name, 'constant' AS const_col, 100 AS num;
            """
    Then the result should be, in any order:
      | name            | const_col  | num |
      | 'my_graph_type' | 'constant' | 100 |
    Then drop all graph
    And drop all graphType

  Scenario: [4-2] RETURN子句测试-重复列
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, gql RETURN name, name, gql;
            """
    Then the error should be contain:
            """
            Multiple result columns with the same name are not supported
            """
    Then drop all graph
    And drop all graphType

  Scenario: [4-3] RETURN子句测试-不存在列
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE my_graph_type {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, gql RETURN invalid;
            """
    Then the error should be contain:
      """
      [2701]Variable `invalid` not defined
      """
    Then drop all graph
    And drop all graphType

  Scenario: [4-4] RETURN子句测试-CASE表达式
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE animal_type {
                (:Animal {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name, CASE name WHEN 'person_type' THEN 'PE' WHEN 'animal_type' THEN 'AN' ELSE 'OTHER' END AS code;
            """
    Then the result should be, in any order:
      | name          | code |
      | 'person_type' | 'PE' |
      | 'animal_type' | 'AN' |
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 5. DISTINCT 去重测试
    # ============================================================

  Scenario: [5-1] DISTINCT去重测试
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE animal_type {
                (:Animal {name string, age int64})
            };
            """
        # RETURN DISTINCT
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN DISTINCT name;
            """
    Then the result should be, in any order:
      | name          |
      | 'person_type' |
      | 'animal_type' |
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 6. ORDER BY 排序测试
    # ============================================================

  Scenario: [6-1] ORDER BY排序测试
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE animal_type {
                (:Animal {name string, age int64})
            };
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            """
        # ASC排序
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name ORDER BY name ASC;
            """
    Then the result should be, in order:
      | name          |
      | 'animal_type' |
      | 'person_type' |
        # DESC排序
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name ORDER BY name DESC;
            """
    Then the result should be, in order:
      | name          |
      | 'person_type' |
      | 'animal_type' |
    Then drop all graph
    And drop all graphType

  Scenario: [6-2] ORDER BY排序测试-排序列不在YIELD中
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name ORDER BY gql;
            """
    Then the error should be contain:
      """
      [2701]Variable `gql` not defined
      """
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 7. SKIP / LIMIT 分页测试
    # ============================================================

  Scenario: [7-1] SKIP-LIMIT分页测试
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE type01 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE type02 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE type03 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE type04 {
                (:Person {name string, age int64})
            };
            """
        # LIMIT 2
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name ORDER BY name LIMIT 2;
            """
    Then the result should be, in order:
      | name     |
      | 'type01' |
      | 'type02' |
        # SKIP 1
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name ORDER BY name SKIP 1;
            """
    Then the result should be, in order:
      | name     |
      | 'type02' |
      | 'type03' |
      | 'type04' |
        # SKIP 1 LIMIT 2
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN name ORDER BY name SKIP 1 LIMIT 2;
            """
    Then the result should be, in order:
      | name     |
      | 'type02' |
      | 'type03' |
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 8. AS 别名测试
    # ============================================================

  Scenario: [8-1] AS别名测试
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            """
        # YIELD中AS别名
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name AS graph_type_name RETURN graph_type_name;
            """
    Then the result should be, in any order:
      | graph_type_name |
      | 'person_type'   |
        # YIELD多列别名
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name AS n, gql AS g RETURN n, g;
            """
    Then the result should be, in any order:
      | n             | g                                                                      |
      | 'person_type' | 'CREATE GRAPH TYPE person_type { (:Person {name string,age int64}) };' |
        # RETURN中AS别名
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, gql RETURN name AS n, gql AS g;
            """
    Then the result should be, in any order:
      | n             | g                                                                      |
      | 'person_type' | 'CREATE GRAPH TYPE person_type { (:Person {name string,age int64}) };' |
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 9. 表达式与函数测试
    # ============================================================

  Scenario: [9-1] 表达式与函数测试
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            """
        # toUpper函数
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN toUpper(name) AS result;
            """
    Then the result should be, in any order:
      | result        |
      | 'PERSON_TYPE' |
        # toLower函数
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN toLower(name) AS result;
            """
    Then the result should be, in any order:
      | result        |
      | 'person_type' |
        # substring函数
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN substring(name, 0, 6) AS result;
            """
    Then the result should be, in any order:
      | result   |
      | 'person' |
        # size函数
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN size(name) AS result;
            """
    Then the result should be, in any order:
      | result |
      | 11     |
        # 字符串拼接
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name RETURN 'Type: ' + name AS result;
            """
    Then the result should be, in any order:
      | result              |
      | 'Type: person_type' |
    Then drop all graph
    And drop all graphType

    # ============================================================
    # 10. 管线式组合完整场景
    # ============================================================

  Scenario: [10-1] 管线式组合-基础组合
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE animal_type {
                (:Animal {name string, age int64})
            };
            CREATE GRAPH TYPE person_extended {
                (:Person {name string, age int64, email string})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, gql WHERE name STARTS WITH 'person' RETURN name ORDER BY name LIMIT 5;
            """
    Then the result should be, in order:
      | name              |
      | 'person_extended' |
      | 'person_type'     |
    Then drop all graph
    And drop all graphType

  Scenario: [10-2] 管线式组合-多条件过滤
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE person_type {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE animal_type {
                (:Animal {name string, age int64})
            };
            CREATE GRAPH TYPE person_extended {
                (:Person {name string, age int64, email string})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name, gql WHERE name IN ['person_type', 'person_extended', 'animal_type'] AND gql CONTAINS 'Person' RETURN name ORDER BY name;
            """
    Then the result should be, in order:
      | name              |
      | 'person_extended' |
      | 'person_type'     |
    Then drop all graph
    And drop all graphType

  Scenario: [10-3] 管线式组合-分页查询
    Given drop all graph
    Then drop all graphType
    When executing queries without error:
            """
            CREATE GRAPH TYPE type01 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE type02 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE type03 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE type04 {
                (:Person {name string, age int64})
            };
            CREATE GRAPH TYPE type05 {
                (:Person {name string, age int64})
            };
            """
    When executing query:
            """
            SHOW GRAPH TYPE YIELD name WHERE name STARTS WITH 'type' RETURN name ORDER BY name SKIP 1 LIMIT 3;
            """
    Then the result should be, in order:
      | name     |
      | 'type02' |
      | 'type03' |
      | 'type04' |
    Then drop all graph
    And drop all graphType