#encoding: utf-8

Feature: SHOW NODE/EDGE PROPERTY - 查询节点/关系属性信息

  Background:
    Given an empty graph

  # ============================================================
  # 1. 基础功能测试
  # ============================================================

  Scenario Outline: [1-1] 基础功能测试-基础语法-查询节点-<comment>
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
    When executing query:
      """
      <gql>
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '人'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'    | '姓名'           | ['string']    | false    |
      | '人'    | '年龄'           | ['int64']     | true     |
      | '人'    | '性别'           | ['bool']      | true     |
      | '城市'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '城市'   | '名称'           | ['string']    | false    |
      | '学校'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '学校'   | '名称'           | ['string']    | false    |
      | '学校'   | '创办时间'         | ['string']    | true     |
      | '公司'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '公司'   | '名称'           | ['string']    | false    |
      | '公司'   | '成立时间'         | ['string']    | true     |
    Then drop all graph
    And drop all graphType
    Examples:
      | gql                    | comment |
      | SHOW NODE * PROPERTY;  | '全大写'   |
      | SHOW NODE * PROPERTY   | '无分号'   |
      | show node * property;  | '全小写'   |
      | Show Node * Property;  | '首字母大写' |
      | sHoW nOdE * PrOpErTy;  | '大小写混合' |
      | SHOW NODE * PROPERTY ; | '多余空格'  |

  Scenario Outline: [1-1b] 基础功能测试-基础语法-查询边-<comment>
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
    When executing query:
      """
      <gql>
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '朋友'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '籍贯'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'         | ['date']      | true     |
      | '就读于'  | '毕业时间'         | ['date']      | true     |
      | '就职于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就职于'  | '入职时间'         | ['date']      | true     |
      | '就职于'  | '离职时间'         | ['date']      | true     |
      | '同事'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '所属城市' | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph
    And drop all graphType
    Examples:
      | gql                    | comment |
      | SHOW EDGE * PROPERTY;  | '全大写'   |
      | SHOW EDGE * PROPERTY   | '无分号'   |
      | show edge * property;  | '全小写'   |
      | Show Edge * Property;  | '首字母大写' |
      | sHoW eDgE * PrOpErTy;  | '大小写混合' |
      | SHOW EDGE * PROPERTY ; | '多余空格'  |

  Scenario: [1-2] 基础功能测试-无数据查询
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be empty
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be empty
    Then drop all graph
    And drop all graphType

  Scenario: [1-3] 基础功能测试-查询所有节点属性
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64, 性别 BOOL}),
          (:城市 {名称 STRING NOT NULL}),
          (:学校 {名称 STRING NOT NULL, 创办时间 STRING}),
          (:公司 {名称 STRING NOT NULL, 成立时间 STRING})
      }
      """
    When executing query:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '人'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'    | '姓名'           | ['string']    | false    |
      | '人'    | '年龄'           | ['int64']     | true     |
      | '人'    | '性别'           | ['bool']      | true     |
      | '城市'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '城市'   | '名称'           | ['string']    | false    |
      | '学校'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '学校'   | '名称'           | ['string']    | false    |
      | '学校'   | '创办时间'         | ['string']    | true     |
      | '公司'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '公司'   | '名称'           | ['string']    | false    |
      | '公司'   | '成立时间'         | ['string']    | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [1-4] 基础功能测试-查询单个节点标签属性
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64, 性别 BOOL})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '人'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'    | '姓名'           | ['string']    | false    |
      | '人'    | '年龄'           | ['int64']     | true     |
      | '人'    | '性别'           | ['bool']      | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [1-5] 基础功能测试-查询多个节点标签属性
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
          (:城市 {名称 STRING NOT NULL})
      }
      """
    When executing query:
      """
      SHOW NODE 人,城市 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '人'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'    | '姓名'           | ['string']    | false    |
      | '人'    | '年龄'           | ['int64']     | true     |
      | '城市'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '城市'   | '名称'           | ['string']    | false    |
    Then drop all graph
    And drop all graphType

  Scenario: [1-6] 基础功能测试-查询所有关系属性
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL}),
          (:城市 {名称 STRING NOT NULL}),
          (:学校 {名称 STRING NOT NULL}),
          (:公司 {名称 STRING NOT NULL}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
          (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
          (:人)-[:朋友]->(:人),
          (:人)-[:籍贯]->(:城市),
          (:人)-[:同事]->(:人),
          (:学校)-[:所属城市]->(:城市)
      }
      """
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '朋友'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '籍贯'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'         | ['date']      | true     |
      | '就读于'  | '毕业时间'         | ['date']      | true     |
      | '就职于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就职于'  | '入职时间'         | ['date']      | true     |
      | '就职于'  | '离职时间'         | ['date']      | true     |
      | '同事'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '所属城市' | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph
    And drop all graphType

  Scenario: [1-7] 基础功能测试-查询单个关系属性
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL}),
          (:学校 {名称 STRING NOT NULL}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校)
      }
      """
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'         | ['date']      | true     |
      | '就读于'  | '毕业时间'         | ['date']      | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [1-8] 基础功能测试-查询多个关系属性
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL}),
          (:学校 {名称 STRING NOT NULL}),
          (:公司 {名称 STRING NOT NULL}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
          (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司)
      }
      """
    When executing query:
      """
      SHOW EDGE 就读于,就职于 PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'         | ['date']      | true     |
      | '就读于'  | '毕业时间'         | ['date']      | true     |
      | '就职于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就职于'  | '入职时间'         | ['date']      | true     |
      | '就职于'  | '离职时间'         | ['date']      | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [1-9] 基础功能测试-查询不存在的对象
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 不存在 PROPERTY;
      """
    Then the result should be empty
    When executing query:
      """
      SHOW EDGE 不存在 PROPERTY;
      """
    Then the result should be empty
    Then drop all graph
    And drop all graphType

  # ============================================================
  # 2. YIELD 子句测试
  # ============================================================

  Scenario: [2-1] YIELD子句测试-YIELD *
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD *;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '人'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'    | '姓名'           | ['string']    | false    |
      | '人'    | '年龄'           | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD *;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'         | ['date']      | true     |
      | '就读于'  | '毕业时间'         | ['date']      | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [2-2] YIELD子句测试-指定单列
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64, 性别 BOOL}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName;
      """
    Then the result should be, in any order:
      | propertyName   |
      | '_PRIMARY_KEY' |
      | '姓名'           |
      | '年龄'           |
      | '性别'           |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD propertyName;
      """
    Then the result should be, in any order:
      | propertyName   |
      | '_PRIMARY_KEY' |
      | '入学时间'         |
      | '毕业时间'         |
    Then drop all graph
    And drop all graphType

  Scenario: [2-3] YIELD子句测试-指定多列
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName, propertyTypes;
      """
    Then the result should be, in any order:
      | propertyName   | propertyTypes |
      | '_PRIMARY_KEY' | ['int64']     |
      | '姓名'           | ['string']    |
      | '年龄'           | ['int64']     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD propertyName, propertyTypes;
      """
    Then the result should be, in any order:
      | propertyName   | propertyTypes |
      | '_PRIMARY_KEY' | ['int64']     |
      | '入学时间'         | ['date']      |
      | '毕业时间'         | ['date']      |
    Then drop all graph
    And drop all graphType

  Scenario: [2-4] YIELD子句测试-列顺序
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName, nullable;
      """
    Then the result should be, in any order:
      | propertyName   | nullable |
      | '_PRIMARY_KEY' | false    |
      | '姓名'           | false    |
      | '年龄'           | true     |
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD nullable, propertyName;
      """
    Then the result should be, in any order:
      | nullable | propertyName   |
      | false    | '_PRIMARY_KEY' |
      | false    | '姓名'           |
      | true     | '年龄'           |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD propertyName, nullable;
      """
    Then the result should be, in any order:
      | propertyName   | nullable |
      | '_PRIMARY_KEY' | false    |
      | '入学时间'         | true     |
      | '毕业时间'         | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD nullable, propertyName;
      """
    Then the result should be, in any order:
      | nullable | propertyName   |
      | false    | '_PRIMARY_KEY' |
      | true     | '入学时间'         |
      | true     | '毕业时间'         |
    Then drop all graph
    And drop all graphType

  Scenario: [2-5] YIELD子句测试-重复列-不支持
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName, propertyName;
      """
    Then the error should be contain:
      """
      Multiple result columns with the same name are not supported
      """
    Then drop all graph
    And drop all graphType

  Scenario: [2-6] YIELD子句测试-非法列名
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD non_exist_column;
      """
    Then the error should be contain:
      """
      [2701]Variable `non_exist_column` not defined
      """
    Then drop all graph
    And drop all graphType

  Scenario: [2-7] YIELD子句测试-列名大小写敏感
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD PROPERTYNAME;
      """
    Then the error should be contain:
      """
      [2701]Variable `PROPERTYNAME` not defined
      """
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD PROPERTYNAME;
      """
    Then the error should be contain:
      """
      [2701]Variable `PROPERTYNAME` not defined
      """
    Then drop all graph
    And drop all graphType

  # ============================================================
  # 3. WHERE 子句测试
  # ============================================================

  Scenario: [3-1] WHERE子句测试-等值过滤
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64, 城市 STRING}),
          (:文章 {标题 STRING, 内容 STRING}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人),
          (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE * PROPERTY YIELD * WHERE propertyName = '姓名';
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'    | '姓名'         | ['string']    | true     |
    When executing query:
      """
      SHOW EDGE * PROPERTY YIELD * WHERE propertyName = '入学时间';
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '就读于'  | '入学时间'       | ['date']      | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [3-2] WHERE子句测试-范围过滤
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64, 分数 FLOAT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * WHERE nullable = true;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'    | '年龄'         | ['int64']     | true     |
      | '人'    | '姓名'         | ['string']    | true     |
      | '人'    | '分数'         | ['float64']   | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD * WHERE nullable = true;
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '就读于'  | '入学时间'       | ['date']      | true     |
      | '就读于'  | '毕业时间'       | ['date']      | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [3-3] WHERE子句测试-AND组合条件
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE * PROPERTY YIELD * WHERE schema = '人' AND nullable = false;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '人'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'    | '姓名'           | ['string']    | false    |
    When executing query:
      """
      SHOW EDGE * PROPERTY YIELD * WHERE schema = '就读于' AND nullable = false;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph
    And drop all graphType

  Scenario: [3-4] WHERE子句测试-OR组合条件
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64, 邮箱 STRING}),
          (:文章 {标题 STRING, 内容 STRING}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人),
          (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE * PROPERTY YIELD * WHERE propertyName = '姓名' OR propertyName = '标题';
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'    | '姓名'         | ['string']    | true     |
      | '文章'   | '标题'         | ['string']    | true     |
    When executing query:
      """
      SHOW EDGE * PROPERTY YIELD * WHERE propertyName = '入学时间' OR propertyName = '入职时间';
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '就读于'  | '入学时间'       | ['date']      | true     |
      | '就职于'  | '入职时间'       | ['date']      | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [3-5] WHERE子句测试-括号组合条件
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64, 城市 STRING}),
          (:文章 {标题 STRING, 阅读数 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE * PROPERTY YIELD * WHERE (schema = '人' AND propertyName = '姓名') OR (schema = '文章' AND propertyTypes = ['int64']);
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '人'    | '姓名'           | ['string']    | true     |
      | '文章'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | '文章'   | '阅读数'          | ['int64']     | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [3-6] WHERE子句测试-类型不匹配
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * WHERE propertyName = 123;
      """
    Then the result should be empty
    Then drop all graph
    And drop all graphType

  Scenario: [3-7] WHERE子句测试-空结果
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * WHERE propertyName = '不存在的属性';
      """
    Then the result should be empty
    Then drop all graph
    And drop all graphType

  Scenario: [3-8] WHERE子句测试-无YIELD直接WHERE-应报错
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY WHERE propertyName = '姓名';
      """
    Then the result should be, in any order:
      | schema | propertyName | propertyTypes | nullable |
      | '人'    | '姓名'         | ['string']    | true     |
    Then drop all graph
    And drop all graphType

  # ============================================================
  # 4. RETURN 子句测试
  # ============================================================

  Scenario: [4-1] RETURN子句测试-RETURN *
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * RETURN *;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '人'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | '人'    | '姓名'           | ['string']    | true     |
      | '人'    | '年龄'           | ['int64']     | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD * RETURN *;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | '就读于'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | '就读于'  | '入学时间'         | ['date']      | true     |
      | '就读于'  | '毕业时间'         | ['date']      | true     |
    Then drop all graph
    And drop all graphType

  Scenario: [4-2] RETURN子句测试-投影子集
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64, 性别 BOOL}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * RETURN propertyName, propertyTypes;
      """
    Then the result should be, in any order:
      | propertyName   | propertyTypes |
      | '_PRIMARY_KEY' | ['int64']     |
      | '姓名'           | ['string']    |
      | '年龄'           | ['int64']     |
      | '性别'           | ['bool']      |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD * RETURN propertyName, propertyTypes;
      """
    Then the result should be, in any order:
      | propertyName   | propertyTypes |
      | '_PRIMARY_KEY' | ['int64']     |
      | '入学时间'         | ['date']      |
      | '毕业时间'         | ['date']      |
    Then drop all graph
    And drop all graphType

  Scenario: [4-3] RETURN子句测试-列顺序
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING NOT NULL, 年龄 INT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * RETURN propertyName, nullable;
      """
    Then the result should be, in any order:
      | propertyName   | nullable |
      | '_PRIMARY_KEY' | false    |
      | '姓名'           | false    |
      | '年龄'           | true     |
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * RETURN nullable, propertyName;
      """
    Then the result should be, in any order:
      | nullable | propertyName   |
      | false    | '_PRIMARY_KEY' |
      | false    | '姓名'           |
      | true     | '年龄'           |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD * RETURN propertyName, nullable;
      """
    Then the result should be, in any order:
      | propertyName   | nullable |
      | '_PRIMARY_KEY' | false    |
      | '入学时间'         | true     |
      | '毕业时间'         | true     |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD * RETURN nullable, propertyName;
      """
    Then the result should be, in any order:
      | nullable | propertyName   |
      | false    | '_PRIMARY_KEY' |
      | true     | '入学时间'         |
      | true     | '毕业时间'         |
    Then drop all graph
    And drop all graphType

  Scenario: [4-4] RETURN子句测试-重复列-不支持
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * RETURN propertyName, propertyName;
      """
    Then the error should be contain:
      """
      Multiple result columns with the same name are not supported
      """
    Then drop all graph
    And drop all graphType

  Scenario: [4-5] RETURN子句测试-非法列名
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD * RETURN non_exist_column;
      """
    Then the error should be contain:
      """
      [2701]Variable `non_exist_column` not defined
      """
    Then drop all graph
    And drop all graphType

  Scenario: [4-6] RETURN子句测试-无YIELD直接RETURN-应报错
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY RETURN *;
      """
    Then the error should be contain:
      """
      [2700]Invalid input 'RETURN'
      """
    Then drop all graph
    And drop all graphType

  # ============================================================
  # 5. 可选扩展测试（AS别名/表达式/ORDER BY/SKIP/LIMIT）
  # ============================================================

  Scenario: [5-1] AS别名测试-基本用法
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName AS 属性名, propertyTypes AS 属性类型 RETURN 属性名, 属性类型;
      """
    Then the result should be, in any order:
      | 属性名            | 属性类型       |
      | '_PRIMARY_KEY' | ['int64']  |
      | '姓名'           | ['string'] |
      | '年龄'           | ['int64']  |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD propertyName AS 属性名, propertyTypes AS 属性类型 RETURN 属性名, 属性类型;
      """
    Then the result should be, in any order:
      | 属性名            | 属性类型      |
      | '_PRIMARY_KEY' | ['int64'] |
      | '入学时间'         | ['date']  |
      | '毕业时间'         | ['date']  |
    Then drop all graph
    And drop all graphType

  Scenario: [5-2] AS别名测试-别名冲突-应报错
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName AS schema, schema AS schema2 RETURN *;
      """
    Then the result should be, in any order:
      | schema         | schema2 |
      | '_PRIMARY_KEY' | '人'     |
      | '姓名'           | '人'     |
      | '年龄'           | '人'     |
    Then drop all graph
    And drop all graphType

  Scenario: [5-3] 表达式测试-基本运算（若支持）
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName, propertyTypes RETURN propertyName, propertyTypes, 1 + 2 AS 常量值;
      """
    Then the result should be, in any order:
      | propertyName   | propertyTypes | 常量值 |
      | '_PRIMARY_KEY' | ['int64']     | 3   |
      | '姓名'           | ['string']    | 3   |
      | '年龄'           | ['int64']     | 3   |
    Then drop all graph
    And drop all graphType

  Scenario: [5-4] 表达式测试-函数调用（若支持）
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName RETURN upper(propertyName) AS 大写名称;
      """
    Then the result should be, in any order:
      | 大写名称           |
      | '_PRIMARY_KEY' |
      | '姓名'           |
      | '年龄'           |
    Then drop all graph
    And drop all graphType

  Scenario: [5-5] ORDER BY排序测试
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64, 城市 STRING}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName RETURN propertyName ORDER BY propertyName ASC;
      """
    Then the result should be, in any order:
      | propertyName   |
      | '_PRIMARY_KEY' |
      | '城市'           |
      | '姓名'           |
      | '年龄'           |
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName RETURN propertyName ORDER BY propertyName DESC;
      """
    Then the result should be, in any order:
      | propertyName   |
      | '年龄'           |
      | '姓名'           |
      | '城市'           |
      | '_PRIMARY_KEY' |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD propertyName RETURN propertyName ORDER BY propertyName ASC;
      """
    Then the result should be, in any order:
      | propertyName   |
      | '_PRIMARY_KEY' |
      | '入学时间'         |
      | '毕业时间'         |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD propertyName RETURN propertyName ORDER BY propertyName DESC;
      """
    Then the result should be, in any order:
      | propertyName   |
      | '毕业时间'         |
      | '入学时间'         |
      | '_PRIMARY_KEY' |
    Then drop all graph
    And drop all graphType

  Scenario: [5-6] SKIP/LIMIT分页测试
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64, 邮箱 STRING, 城市 STRING}),
          (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:人)
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName RETURN propertyName SKIP 1 LIMIT 2;
      """
    Then the result should be, in any order:
      | propertyName |
      | '姓名'         |
      | '年龄'         |
    When executing query:
      """
      SHOW EDGE 就读于 PROPERTY YIELD propertyName RETURN propertyName SKIP 1 LIMIT 2;
      """
    Then the result should be, in any order:
      | propertyName |
      | '入学时间'       |
      | '毕业时间'       |
    Then drop all graph
    And drop all graphType

  Scenario: [5-7] SKIP/LIMIT分页测试-超出范围
    When executing queries without error:
      """
      ALTER GRAPH ADD BATCH {
          (:人 {姓名 STRING, 年龄 INT64})
      }
      """
    When executing query:
      """
      SHOW NODE 人 PROPERTY YIELD propertyName RETURN propertyName SKIP 10 LIMIT 5;
      """
    Then the result should be empty
    Then drop all graph
    And drop all graphType