#encoding: utf-8

Feature: 创建图-图名校验、图参数配置、图模型：预定义模型、基于已有模型、复制已有图

  Background:
    Given drop all graph

  # ============================================================
  # 1. 图名校验
  # ============================================================

  Scenario Outline: [1-1] 创图-图名校验-混合图名-<graph>
    When executing query:
      """
      CREATE GRAPH <graph>
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

  Scenario Outline: [1-2] 创图-图名校验-与系统图<graph>重名
    When executing query:
      """
      CREATE GRAPH <graph>
      """
    Then the error should be contain:
      """
      [1606]Database already exists
      """
    Examples:
      | graph   |
      | sys     |
      | default |

  Scenario Outline: [1-3] 创图-图名校验-特殊字符-<aa>
    And executing query:
      """
      CREATE GRAPH test<aa>1
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Examples:
      | aa          |
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
      | "           |
      | ;           |
      | ,           |
      | .           |
      | /           |
      | ?           |
      | \|undefined |
      | ￥           |
      | ……          |
      | `           |
      | ~           |
      | 【           |
      | 】           |
      | '           |

  Scenario Outline: [1-4] 创图-图名校验-关键字-<graph>
    When executing query:
      """
      CREATE GRAPH <graph>
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
      | graph       |
      | func        |
      | select      |
      | case        |
      | chan        |
      | interface   |
      | const       |
      | continue    |
      | defer       |
      | go          |
      | map         |
      | struct      |
      | switch      |
      | if          |
      | else        |
      | goto        |
      | package     |
      | fallthrough |
      | var         |
      | return      |
      | sys         |

  Scenario: [1-5] 创图-图名校验-唯一性
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS my_graph
      """
    When executing query:
      """
      CREATE GRAPH my_graph
      """
    Then the error should be contain:
      """
      [1606]Database already exists
      """
    Then drop all graph

  Scenario: [1-6] 创图-图名校验-长度限制-等于128
    And executing query:
      """
      CREATE GRAPH bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    When executing query:
      """
      show graph yield name;
      """
    And the result should contain:
      | name                                                                                                                               |
      | 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' |
    Then drop all graph

  Scenario: [1-7] 创图-图名校验-长度限制-大于128
    And executing query:
      """
      CREATE GRAPH bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb;
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """

  Scenario: [1-8] 创图-图名校验-图不存在时创图
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    And executing query:
      """
      CREATE GRAPH my_graph;
      """
    Then the error should be contain:
      """
      [1606]Database already exists
      """
    When executing query:
      """
      CREATE GRAPH IF NOT EXISTS my_graph;
      """
    Then the result should be empty
    When executing query:
      """
      show graph yield name;
      """
    Then the result should contain:
      | name       |
      | 'my_graph' |
    Then drop all graph

  Scenario: [1-9] 创图-图描述信息-COMMENT
    When executing queries without error:
      """
      CREATE GRAPH my_graph  {
      (:Person{name STRING NOT NULL, age UINT32}),
      (:Club),
      (:Club)-[:Follows{createdOn LOCAL DATETIME NOT NULL}]->(:Club),
      (:Person)-[:Joins]->(:Club)
      } COMMENT 'This is my graph';
      """
    When executing query:
      """
      show graph yield name;
      """
    Then the result should contain:
      | name       |
      | 'my_graph' |
    Then drop all graph

  # ============================================================
  # 2. 图参数配置
  # ============================================================

  Scenario Outline: [2-1] 创图-图参数配置-段数量-<segmentCount>
    And executing query:
      """
      CREATE GRAPH graph<segmentCount> SEGMENT <segmentCount>
      """
    When executing query:
      """
      show graph yield name,segmentCount where name = 'graph<segmentCount>'
      """
    And the result should be, in any order:
      | name                  | segmentCount   |
      | 'graph<segmentCount>' | <segmentCount> |
    And drop all graph
    Examples:
      | segmentCount |
      | 1            |
      | 2            |
      | 3            |
      | 4            |
      | 5            |
      | 7            |
      | 8            |
      | 9            |
      | 10           |
      | 16           |

  Scenario: [2-2] 创图-图参数配置-段数量-默认值
    When executing queries without error:
      """
      CREATE GRAPH default_segment_graph;
      """
    When executing query:
      """
      show graph yield name,segmentCount where name = 'default_segment_graph'
      """
    And the result should be, in any order:
      | name                    | segmentCount |
      | 'default_segment_graph' | 1            |
    Then drop all graph

  Scenario Outline: [2-3] 创图-图参数配置-容量-<capacity>，单位M，0M表示不限制
    When executing query:
      """
      CREATE GRAPH graph<capacity1> LIMIT <capacity1>
      """
    Then executing query without error:
      """
      show graph yield name,capacity where name = 'graph<capacity1>';
      """
    And the result should be, in any order:
      | name               | capacity     |
      | 'graph<capacity1>' | '<capacity>' |
    Then drop all graph
    Examples:
      | capacity | capacity1     |
      | 0.0MB    | 0             |
      | 1.0MB    | 1             |
      | 1.0GB    | 1024          |
      | 2.0GB    | 2048          |
      | 1.0EB    | 1111111111111 |

  Scenario: [2-4] 创图-图参数配置-容量-负数
    When executing query:
      """
      CREATE GRAPH negative_limit_graph LIMIT -1
      """
    Then the error should be contain:
      """
      [2700]Invalid input
      """
    Then drop all graph

  Scenario: [2-5] 创图-图参数配置-加密类型：不加密
    When executing queries without error:
      """
      CREATE GRAPH my_graph01;
      CREATE GRAPH my_graph02 ENCRYPTION USING ' ';
      CREATE GRAPH my_graph03 ENCRYPTION USING 'plain';
      """
    Then executing query without error:
      """
      show graph yield name,cipherMode;
      """
    And the result should contain:
      | name         | cipherMode |
      | 'my_graph01' | 'plain'    |
      | 'my_graph02' | 'plain'    |
      | 'my_graph03' | 'plain'    |
    Then drop all graph

  Scenario Outline: [2-6] 创图-图参数配置-加密类型-<cipherMode>，存储需开启IS_ENCRYPT=1
    And executing query:
      """
      CREATE GRAPH graph_cipherMode ENCRYPTION USING '<cipherMode>'
      """
    When executing query:
      """
      show graph yield name,cipherMode where name = 'graph_cipherMode'
      """
    And the result should be, in any order:
      | name               | cipherMode     |
      | 'graph_cipherMode' | '<cipherMode>' |
    And drop all graph
    Examples:
      | cipherMode |
      | aes128-cbc |
      | aes256-cbc |
      | aes128-cfb |
      | aes256-cfb |
      | aes128-ctr |
      | aes256-ctr |
      | aes128-ecb |
      | aes256-ecb |
      | aes128-ofb |
      | aes256-ofb |
      | aes128-ccm |
      | aes256-ccm |
      | aes128-gcm |
      | aes256-gcm |
      | aes128-ocb |
      | aes256-ocb |
      | sm4-ecb    |
      | sm4-cbc    |
      | sm4-cfb    |
      | sm4-ofb    |
      | sm4-ctr    |

  Scenario: [2-7] 创图-图参数配置-加密类型：错误的加密类型
    When executing query:
      """
      CREATE GRAPH my_graph ENCRYPTION USING 'plain001';
      """
    Then the error should be contain:
      """
      [2815]Unsupported algorithm mode ('plain001')
      """
    Then drop all graph

  Scenario Outline: [2-8] 创图-图参数配置-字符集：UTF-8/GB18030(暂不支持)
    And executing query:
      """
      CREATE GRAPH graph_character CHARACTER SET '<character>'
      """
    When executing query:
      """
      show graph yield name,`character set` where name = 'graph_character'
      """
    And the result should be, in any order:
      | name              | character set |
      | 'graph_character' | '<character>' |
    And drop all graph
    Examples:
      | character |
      | UTF-8     |

  Scenario: [2-9] 创图-图参数配置-字符集-不支持的字符集
    When executing query:
      """
      CREATE GRAPH graph_unsupported CHARACTER SET 'GB2312'
      """
    Then the error should be contain:
      """
      [2804]The character set is UTF-8/GB18030
      """
    Then drop all graph

  Scenario Outline: [2-10] 创图-图参数配置-副本数-<replicaCount>，多个副本需要集群环境
    And executing query:
      """
      CREATE GRAPH graph<replicaCount> REPLICA <replicaCount>
      """
    When executing query:
      """
      show graph yield name,replicaCount where name = 'graph<replicaCount>'
      """
    And the result should be, in any order:
      | name                  | replicaCount   |
      | 'graph<replicaCount>' | <replicaCount> |
    And drop all graph
    Examples:
      | replicaCount |
      | 1            |
      | 3            |

  Scenario: [2-11] 创图-图参数配置-副本数，超过节点数
    When executing query:
      """
      CREATE GRAPH my_graph REPLICA 10
      """
    Then the error should be contain:
      """
      [1641]Input store_num is less than repl_num
      """
    Then drop all graph

  Scenario: [2-12] 创图-图参数配置-副本数-非法值-默认给1
    When executing query:
      """
      CREATE GRAPH my_graph REPLICA 0
      """
    When executing query:
      """
      show graph yield name,replicaCount where name = 'my_graph'
      """
    And the result should be, in any order:
      | name       | replicaCount |
      | 'my_graph' | 1            |
    Then drop all graph

  Scenario: [2-13] 创图-图参数配置-描述信息
    When executing queries without error:
      """
      CREATE GRAPH my_graph01 COMMENT ""
      CREATE GRAPH my_graph02 COMMENT " this is my social graph "
      CREATE GRAPH my_graph03 COMMENT 'single quote comment'
      CREATE GRAPH my_graph04 COMMENT "comment with special chars !@#$%^&*()"
      """
    Then drop all graph

  Scenario: [2-14] 创图-图参数配置-组合参数
    When executing queries without error:
      """
      CREATE GRAPH combined_graph SEGMENT 3 REPLICA 3 LIMIT 1024 COMMENT "combined config"
      """
    When executing query:
      """
      show graph yield name,segmentCount,replicaCount,capacity where name = 'combined_graph'
      """
    And the result should be, in any order:
      | name             | segmentCount | replicaCount | capacity |
      | 'combined_graph' | 3            | 3            | '1.0GB'  |
    Then drop all graph

  # ============================================================
  # 3. 图模型
  # ============================================================

  Scenario: [3-1] 创图-图模型-预定义模型：所有属性类型
    Given drop all graph
    And executing queries without error:
      """
      DROP GRAPH IF EXISTS my_graph
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph {
      (:Person{name string,age integer,p1 datetime,p2 date,p3 localdatetime,
      p4 time,p5 localtime,p6 point2d,p7 point3d,p8 bool,p9 float32,p10 float64,p11 list<int64>})
      }
      """
    Given an already exist graph:
      """
      my_graph
      """
    And executing queries without error:
      """
      SHOW NODE Person PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes     | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']         | false    |
      | 'Person' | 'name'         | ['string']        | true     |
      | 'Person' | 'age'          | ['int64']         | true     |
      | 'Person' | 'p1'           | ['datetime']      | true     |
      | 'Person' | 'p2'           | ['date']          | true     |
      | 'Person' | 'p3'           | ['localdatetime'] | true     |
      | 'Person' | 'p4'           | ['time']          | true     |
      | 'Person' | 'p5'           | ['localtime']     | true     |
      | 'Person' | 'p6'           | ['point2d']       | true     |
      | 'Person' | 'p7'           | ['point3d']       | true     |
      | 'Person' | 'p8'           | ['bool']          | true     |
      | 'Person' | 'p9'           | ['float32']       | true     |
      | 'Person' | 'p10'          | ['float64']       | true     |
      | 'Person' | 'p11'          | ['list<int64>']   | true     |
    Then drop all graph

  Scenario: [3-2] 创图-图模型-预定义模型：两点一边
    Then executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string,age int64 }),
        (animal:Animal{name String,age int64}),
        (person)-[:Likes{year DateTime}]->(animal)
      };
      """
    Given an already exist graph:
      """
      my_graph
      """
    And executing queries without error:
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
    And executing queries without error:
      """
      SHOW EDGE * Property;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'Likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Likes' | 'year'         | ['datetime']  | true     |
    Then drop all graph

  Scenario: [3-3] 创图-图模型-预定义模型：多点多边复杂模型
    Then executing queries without error:
      """
      CREATE GRAPH complex_graph {
        (user:User{id string, name string, email string}),
        (product:Product{sku string, price float64, category string}),
        (order:Order{order_id string, amount float64, status string}),
        (user)-[:PLACED{order_date datetime}]->(order),
        (order)-[:INCLUDES{quantity int32}]->(product),
        (user)-[:REVIEWS{rating int32, review_date date}]->(product)
      };
      """
    Given an already exist graph:
      """
      complex_graph
      """
    And executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema    | propertyName   | propertyTypes | nullable |
      | 'User'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'User'    | 'id'           | ['string']    | true     |
      | 'User'    | 'name'         | ['string']    | true     |
      | 'User'    | 'email'        | ['string']    | true     |
      | 'Product' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Product' | 'sku'          | ['string']    | true     |
      | 'Product' | 'price'        | ['float64']   | true     |
      | 'Product' | 'category'     | ['string']    | true     |
      | 'Order'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Order'   | 'order_id'     | ['string']    | true     |
      | 'Order'   | 'amount'       | ['float64']   | true     |
      | 'Order'   | 'status'       | ['string']    | true     |
    Then drop all graph

  Scenario Outline: [3-4] 创图-图模型-基于已有图模型创建图
    Given drop all graph
    Given drop all graphType
    And executing queries without error:
      """
      DROP GRAPH TYPE IF EXISTS my_graph_type;
      """
    Then executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (customer : Customer => {id   STRING , name   STRING  }),
        (account : Account => { no   STRING , type   STRING }),
        ( customer )<-[: HOLDS ]-( account ),
        ( account )-[: TRANSFER  { amount   INTEGER }]->( account )
      };
      """
    And executing queries without error:
      """
      <createGraph>
      """
    Given an already exist graph:
      """
      my_graph
      """
    And executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'Account'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Account'  | 'no'           | ['string']    | true     |
      | 'Account'  | 'type'         | ['string']    | true     |
      | 'Customer' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Customer' | 'id'           | ['string']    | true     |
      | 'Customer' | 'name'         | ['string']    | true     |
    And executing queries without error:
      """
      SHOW EDGE * Property;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'TRANSFER' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'TRANSFER' | 'amount'       | ['int64']     | true     |
      | 'HOLDS'    | '_PRIMARY_KEY' | ['int64']     | false    |
    # 当图的schema改变后，不影响图模型的结构
    When executing queries without error:
      """
      DROP NODE Customer;
      """
    And executing queries without error:
      """
      CREATE GRAPH my_graph01 my_graph_type;
      """
    Given an already exist graph:
      """
      my_graph01
      """
    And executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'Account'  | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Account'  | 'no'           | ['string']    | true     |
      | 'Account'  | 'type'         | ['string']    | true     |
      | 'Customer' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Customer' | 'id'           | ['string']    | true     |
      | 'Customer' | 'name'         | ['string']    | true     |
    And executing queries without error:
      """
      SHOW EDGE * Property;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'TRANSFER' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'TRANSFER' | 'amount'       | ['int64']     | true     |
      | 'HOLDS'    | '_PRIMARY_KEY' | ['int64']     | false    |
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name            | gql                                                                                                                                                                                                 |
      | 'my_graph_type' | 'CREATE GRAPH TYPE my_graph_type { (:Account {no string,type string}),(:Customer {id string,name string}),(:Account)-[:TRANSFER {amount int64}]->(:Account),(:Account)-[:HOLDS {}]->(:Customer) };' |
    Then drop all graph
    Then drop all graphType
    Examples:
      | createGraph                                |
      | CREATE GRAPH my_graph my_graph_type;       |
      | CREATE GRAPH my_graph :: my_graph_type;    |
      | CREATE GRAPH my_graph TYPED my_graph_type; |

  Scenario: [3-5] 创图-图模型-基于不存在的图模型创建图
    Given drop all graph
    Given drop all graphType
    Then executing query:
      """
      CREATE GRAPH my_graph my_graph_type;
      """
    Then the error should be contain:
      """
      [2790]Graph type 'my_graph_type' is not exists
      """
    Then drop all graph

  Scenario: [3-6] 创图-图模型-基于已存在的图-空图
    Given drop all graph
    Given drop all graphType
    When executing queries without error:
      """
      CREATE GRAPH my_graph;
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph01 LIKE my_graph;
      """
    Given an already exist graph:
      """
      my_graph01
      """
    When executing query:
      """
      SHOW ALL SCHEMA;
      """
    Then the result should be empty
    Then drop all graph
    Then drop all graphType

  Scenario: [3-7] 创图-图模型-基于已存在的图-有模型的图
    Then executing queries without error:
      """
      CREATE GRAPH my_graph {
        (person:Person{name string,age int64 }),
        (animal:Animal{name String,age int64}),
        (person)-[:Likes{year DateTime}]->(animal)
      };
      """
    Then executing queries without error:
      """
      CREATE GRAPH my_graph01 LIKE my_graph;
      """
    Given an already exist graph:
      """
      my_graph01
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
    And executing queries without error:
      """
      SHOW EDGE * Property;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'Likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Likes' | 'year'         | ['datetime']  | true     |
    # 当复制图的schema改变后，不影响来源图的模型结构
    When executing queries without error:
      """
      DROP NODE Person;
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
    And executing queries without error:
      """
      SHOW EDGE * Property;
      """
    Then the result should be, in any order:
      | schema  | propertyName   | propertyTypes | nullable |
      | 'Likes' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Likes' | 'year'         | ['datetime']  | true     |
    Then drop all graph

  Scenario: [3-8] 创图-图模型-基于已存在的图复制后，删除原图不影响已复制图
    # 1. 创建原图（包含节点和边）
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (person:Person{name string, age int64}),
        (city:City{name string, population int64}),
        (person)-[:LIVES_IN{since datetime}]->(city)
      };
      """
    # 2. 基于原图复制创建新图
    When executing queries without error:
      """
      CREATE GRAPH copied_graph LIKE source_graph;
      """
    # 3. 验证复制图包含原图的模型结构
    Given an already exist graph:
      """
      copied_graph
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
      | 'City'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'City'   | 'name'         | ['string']    | true     |
      | 'City'   | 'population'   | ['int64']     | true     |
    When executing queries without error:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'LIVES_IN' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'LIVES_IN' | 'since'        | ['datetime']  | true     |
    # 4. 删除原图
    When executing queries without error:
      """
      DROP GRAPH source_graph;
      """
    # 5. 验证复制图的模型结构仍然存在且完整（不受原图删除影响）
    Given an already exist graph:
      """
      copied_graph
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
      | 'City'   | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'City'   | 'name'         | ['string']    | true     |
      | 'City'   | 'population'   | ['int64']     | true     |
    When executing queries without error:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'LIVES_IN' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'LIVES_IN' | 'since'        | ['datetime']  | true     |
    Then drop all graph

  Scenario: [3-9] 创图-图模型-基于已存在的图复制-源图为空图
    # 1. 创建空图
    When executing queries without error:
      """
      CREATE GRAPH empty_graph;
      """
    # 2. 基于空图复制创建新图
    When executing queries without error:
      """
      CREATE GRAPH copied_empty_graph LIKE empty_graph;
      """
    # 3. 验证复制图存在且为空图
    Given an already exist graph:
      """
      copied_empty_graph
      """
    When executing query:
      """
      SHOW ALL SCHEMA;
      """
    Then the result should be empty
    # 4. 删除原空图
    When executing queries without error:
      """
      DROP GRAPH empty_graph;
      """
    # 5. 验证复制图仍然存在且为空
    Given an already exist graph:
      """
      copied_empty_graph
      """
    When executing query:
      """
      SHOW ALL SCHEMA;
      """
    Then the result should be empty
    Then drop all graph

  Scenario: [3-10] 创图-图模型-基于已存在的图复制-源图不存在
    When executing query:
      """
      CREATE GRAPH non_exist_graph_copy LIKE non_exist_graph;
      """
    Then the error should be contain:
      """
      [1605]Database does not exist. Database name: 'non_exist_graph'
      """
    Then drop all graph

  Scenario: [3-11] 创图-图模型-基于已存在的图复制-目标图已存在
    # 1. 创建原图
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (person:Person{name string}),
        (person)-[:KNOWS]->(person)
      };
      """
    # 2. 创建目标图
    When executing queries without error:
      """
      CREATE GRAPH target_graph;
      """
    # 3. 尝试复制到已存在的目标图
    When executing query:
      """
      CREATE GRAPH target_graph LIKE source_graph;
      """
    Then the error should be contain:
      """
      [1606]Database already exists
      """
    Then drop all graph

  Scenario: [3-12] 创图-图模型-基于已存在的图复制-源图包含多种属性类型
    # 1. 创建包含多种属性类型的原图
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (user:User{
          id string,
          age int64,
          score float64,
          is_active bool,
          birthday date,
          created_time datetime,
          location point2d
        }),
        (product:Product{
          name string,
          price float64
        }),
        (user)-[:PURCHASE{amount int64, purchase_time datetime}]->(product)
      };
      """
    # 2. 基于原图复制创建新图
    When executing queries without error:
      """
      CREATE GRAPH copied_graph LIKE source_graph;
      """
    # 3. 验证复制图的节点属性
    Given an already exist graph:
      """
      copied_graph
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema    | propertyName   | propertyTypes | nullable |
      | 'User'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'User'    | 'id'           | ['string']    | true     |
      | 'User'    | 'age'          | ['int64']     | true     |
      | 'User'    | 'score'        | ['float64']   | true     |
      | 'User'    | 'is_active'    | ['bool']      | true     |
      | 'User'    | 'birthday'     | ['date']      | true     |
      | 'User'    | 'created_time' | ['datetime']  | true     |
      | 'User'    | 'location'     | ['point2d']   | true     |
      | 'Product' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Product' | 'name'         | ['string']    | true     |
      | 'Product' | 'price'        | ['float64']   | true     |
    When executing queries without error:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName    | propertyTypes | nullable |
      | 'PURCHASE' | '_PRIMARY_KEY'  | ['int64']     | false    |
      | 'PURCHASE' | 'amount'        | ['int64']     | true     |
      | 'PURCHASE' | 'purchase_time' | ['datetime']  | true     |
    Then drop all graph

  Scenario: [3-13] 创图-图模型-基于已存在的图复制-源图包含NOT NULL约束
    # 1. 创建包含NOT NULL约束的原图
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (:Person{
          name STRING NOT NULL,
          age UINT32 NOT NULL,
          email STRING
        }),
        (:Person)-[:FRIEND_OF{since DATE NOT NULL}]->(:Person)
      };
      """
    # 2. 基于原图复制创建新图
    When executing queries without error:
      """
      CREATE GRAPH copied_graph LIKE source_graph;
      """
    # 3. 验证复制图保留NOT NULL约束
    Given an already exist graph:
      """
      copied_graph
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Person' | 'name'         | ['string']    | false    |
      | 'Person' | 'age'          | ['uint32']    | false    |
      | 'Person' | 'email'        | ['string']    | true     |
    When executing queries without error:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema      | propertyName   | propertyTypes | nullable |
      | 'FRIEND_OF' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'FRIEND_OF' | 'since'        | ['date']      | false    |
    Then drop all graph

  Scenario: [3-14] 创图-图模型-基于已存在的图复制-源图包含有向边
    # 1. 创建包含有向边的原图
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (a:NodeA),
        (b:NodeB),
        (c:NodeC),
        (a)-[:DIRECTED_EDGE]->(b),
        (c)-[:ANOTHER_EDGE]->(a)
      };
      """
    # 2. 基于原图复制创建新图
    When executing queries without error:
      """
      CREATE GRAPH copied_graph LIKE source_graph;
      """
    # 3. 验证复制图保留有向边
    Given an already exist graph:
      """
      copied_graph
      """
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema          | propertyName   | propertyTypes | nullable |
      | 'DIRECTED_EDGE' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'ANOTHER_EDGE'  | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph

  Scenario: [3-15] 创图-图模型-基于已存在的图复制-多次复制同一源图
    # 1. 创建原图
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (:Person{name string}),
        (:Person)-[:KNOWS]->(:Person)
      };
      """
    # 2. 多次基于同一原图复制创建多个新图
    When executing queries without error:
      """
      CREATE GRAPH copied_graph01 LIKE source_graph;
      CREATE GRAPH copied_graph02 LIKE source_graph;
      CREATE GRAPH copied_graph03 LIKE source_graph;
      """
    # 3. 验证所有复制图都存在且结构正确
    Given an already exist graph:
      """
      copied_graph01
      """
    Given an already exist graph:
      """
      copied_graph02
      """
    Given an already exist graph:
      """
      copied_graph03
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Person' | 'name'         | ['string']    | true     |
    # 4. 删除原图
    When executing queries without error:
      """
      DROP GRAPH source_graph;
      """
    # 5. 验证所有复制图仍然存在且结构完整
    Given an already exist graph:
      """
      copied_graph01
      """
    Given an already exist graph:
      """
      copied_graph02
      """
    Given an already exist graph:
      """
      copied_graph03
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema   | propertyName   | propertyTypes | nullable |
      | 'Person' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Person' | 'name'         | ['string']    | true     |
    Then drop all graph

  Scenario: [3-16] 创图-图模型-基于已存在的图复制-链式复制
    # 1. 创建原始图
    When executing queries without error:
      """
      CREATE GRAPH graph_v1 {
        (:User{name string}),
        (:User)-[:FOLLOW]->(:User)
      };
      """
    # 2. 基于v1复制创建v2
    When executing queries without error:
      """
      CREATE GRAPH graph_v2 LIKE graph_v1;
      """
    # 3. 基于v2复制创建v3
    When executing queries without error:
      """
      CREATE GRAPH graph_v3 LIKE graph_v2;
      """
    # 4. 验证v3包含正确的模型结构
    Given an already exist graph:
      """
      graph_v3
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | 'User' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'User' | 'name'         | ['string']    | true     |
    # 5. 删除v1
    When executing queries without error:
      """
      DROP GRAPH graph_v1;
      """
    # 6. 验证v2和v3仍然存在且结构完整
    Given an already exist graph:
      """
      graph_v2
      """
    Given an already exist graph:
      """
      graph_v3
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | 'User' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'User' | 'name'         | ['string']    | true     |
    # 7. 删除v2
    When executing queries without error:
      """
      DROP GRAPH graph_v2;
      """
    # 8. 验证v3仍然存在且结构完整
    Given an already exist graph:
      """
      graph_v3
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema | propertyName   | propertyTypes | nullable |
      | 'User' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'User' | 'name'         | ['string']    | true     |
    Then drop all graph

  Scenario: [3-17] 创图-图模型-基于已存在的图复制-源图包含自环边
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (:Employee{name string, level int32}),
        (:Employee)-[:MANAGES]->(:Employee)
      };
      """
    When executing queries without error:
      """
      CREATE GRAPH copied_graph LIKE source_graph;
      """
    Given an already exist graph:
      """
      copied_graph
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'Employee' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Employee' | 'name'         | ['string']    | true     |
      | 'Employee' | 'level'        | ['int32']     | true     |
    When executing queries without error:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema    | propertyName   | propertyTypes | nullable |
      | 'MANAGES' | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph

  Scenario: [3-18] 创图-图模型-基于已存在的图复制-源图包含多个边类型
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (:User{id string}),
        (:Product{sku string}),
        (:Order{order_no string}),
        (:User)-[:BUY]->(:Product),
        (:User)-[:PLACE]->(:Order),
        (:Order)-[:CONTAINS]->(:Product),
        (:User)-[:REVIEW]->(:Product)
      };
      """
    When executing queries without error:
      """
      CREATE GRAPH copied_graph LIKE source_graph;
      """
    Given an already exist graph:
      """
      copied_graph
      """
    When executing query:
      """
      SHOW EDGE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'BUY'      | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'PLACE'    | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'CONTAINS' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'REVIEW'   | '_PRIMARY_KEY' | ['int64']     | false    |
    Then drop all graph

  Scenario: [3-19] 创图-图模型-基于已存在的图复制后修改复制图结构
    When executing queries without error:
      """
      CREATE GRAPH source_graph {
        (:Original{field1 string, field2 int64})
      };
      """
    When executing queries without error:
      """
      CREATE GRAPH copied_graph LIKE source_graph;
      """
    # 修改复制图的结构：为已有节点添加属性
    Given an already exist graph:
      """
      copied_graph
      """
    When executing queries without error:
      """
      ALTER NODE Original ADD PROPERTY {field3 STRING NOT NULL};
      """
    # 验证原图结构未受影响
    Given an already exist graph:
      """
      source_graph
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'Original' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Original' | 'field1'       | ['string']    | true     |
      | 'Original' | 'field2'       | ['int64']     | true     |
    # 验证复制图包含了新增的属性
    Given an already exist graph:
      """
      copied_graph
      """
    When executing queries without error:
      """
      SHOW NODE * PROPERTY;
      """
    Then the result should be, in any order:
      | schema     | propertyName   | propertyTypes | nullable |
      | 'Original' | '_PRIMARY_KEY' | ['int64']     | false    |
      | 'Original' | 'field1'       | ['string']    | true     |
      | 'Original' | 'field2'       | ['int64']     | true     |
      | 'Original' | 'field3'       | ['string']    | false    |
    Then drop all graph