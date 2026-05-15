#encoding: utf-8

Feature: 创建图模型-模型名的校验、点标签定义、边标签定义、属性定义、图模型结构

  Background:
    Given drop all graph
    Given drop all graphType

  # ============================================================
  # 1. 图模型名校验
  # ============================================================

  Scenario Outline: [1-1] 创建图模型-图模型名校验正确-混合模型名-<my_graph_type>
    When executing queries without error:
      """
      CREATE GRAPH TYPE <my_graph_type> {
        (:Person{name string, age int64})
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name              | gql |
      | '<my_graph_type>' | 'CREATE GRAPH TYPE <my_graph_type> { (:Person {name string,age int64}) };' |
    Then drop all graphType
    Examples:
      | my_graph_type |
      | graph01       |
      | graph_123     |
      | _graph        |
      | aa            |
      | AA            |

  Scenario Outline: [1-2] 创建图模型-图模型名校验-关键字-<my_graph_type>
    When executing queries without error:
      """
      CREATE GRAPH TYPE <my_graph_type> {
        (:Person{name string, age int64})
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name              | gql |
      | '<my_graph_type>' | 'CREATE GRAPH TYPE <my_graph_type> { (:Person {name string,age int64}) };' |
    Then drop all graphType
    Examples:
      | my_graph_type |
      | func          |
      | select        |
      | case          |
      | chan          |
      | interface     |
      | const         |
      | continue      |
      | defer         |
      | go            |
      | map           |
      | struct        |
      | switch        |
      | if            |
      | else          |
      | goto          |
      | package       |
      | fallthrough   |
      | var           |
      | return        |
      | sys           |
      | create        |
      | alter         |
      | drop          |
      | show          |
      | match         |
      | where         |

  Scenario Outline: [1-3] 创建图模型-图模型名校验-特殊字符-<graphType>
    And executing query:
      """
      CREATE GRAPH TYPE <graphType>test {
        (:Person{name string, age int64})
      };
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Examples:
      | graphType   |
      | ！          |
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
      | /           |
      | ?           |
      | \ |
      | ￥           |
      | ……          |
      | `           |
      | ~           |
      | 【           |
      | 】           |
      | '           |

  Scenario: [1-4] 创建图模型-图模型名校验-唯一性校验
    When executing queries without error:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string, age int64})
      };
      """
    When executing query:
      """
      CREATE GRAPH TYPE my_graph_type {
        (:Person{name string, age int64})
      };
      """
    Then the error should be contain:
      """
      graph type 'my_graph_type' is already exists
      """
    Then drop all graphType

  Scenario: [1-5] 创建图模型-图模型名校验-长度限制-等于128
    And executing queries without error:
      """
      CREATE GRAPH TYPE bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb {
        (:Person{name string, age int64})
      };
      """
    When executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should contain:
      | name                                                                                                                               | gql |
      | 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' | 'CREATE GRAPH TYPE bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb { (:Person {name string,age int64}) };' |
    Then drop all graphType

  Scenario: [1-6] 创建图模型-图模型名校验-长度限制-大于128
    When executing query:
      """
      CREATE GRAPH TYPE aabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb {
        (:Person{name string, age int64})
      };
      """
    Then the error should be contain:
      """
      [2610]Identifier name
      """
    Then drop all graphType

  # ============================================================
  # 2. 点标签定义
  # ============================================================

  Scenario: [2-1] 创建图模型-点标签定义-无属性
    When executing queries without error:
      """
      CREATE GRAPH TYPE NoPropertyGraph {
        (:SimpleVertex),
        (:SimpleVertex)-[:SimpleEdge]->(:SimpleVertex)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name               | gql |
      | 'NoPropertyGraph'  | 'CREATE GRAPH TYPE NoPropertyGraph { (:SimpleVertex {}),(:SimpleVertex)-[:SimpleEdge {}]->(:SimpleVertex) };' |
    Then drop all graphType

  Scenario: [2-2] 创建图模型-点标签定义-包含所有数据类型
    When executing queries without error:
      """
      CREATE GRAPH TYPE DataTypesGraph {
        (:TestVertex{
          id STRING NOT NULL,
          age INT64,
          score FLOAT32,
          rating FLOAT64,
          isActive BOOL,
          birthDate DATE,
          createdDate DATETIME,
          lastActive LOCALDATETIME,
          loginTime TIME,
          workTime LOCALTIME,
          homeLocation POINT2D,
          currentLocation POINT3D
        }),
        (:TestVertex)-[:TestEdge]->(:TestVertex)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'DataTypesGraph';
      """
    And the result should be, in any order:
      | name             |
      | 'DataTypesGraph' |
    Then drop all graphType

  Scenario: [2-3] 创建图模型-点标签定义-多个点标签
    When executing queries without error:
      """
      CREATE GRAPH TYPE MultipleVertexGraph {
        (:User{id string, name string}),
        (:Product{sku string, price float64}),
        (:Order{order_id string, amount float64}),
        (:User)-[:PLACE]->(:Order),
        (:Order)-[:CONTAINS]->(:Product)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'MultipleVertexGraph';
      """
    And the result should be, in any order:
      | name                 |
      | 'MultipleVertexGraph' |
    Then drop all graphType

  Scenario Outline: [2-4] 创建图模型-点标签定义-无效标签名-<vertexType>
    When executing query:
      """
      CREATE GRAPH TYPE InvalidVertexGraph {
        (:<vertexType>abc{name string, age int64})
      };
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Examples:
      | vertexType  |
      | ！          |
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
      | \ |
      | ￥           |
      | ……          |
      | `           |
      | ~           |
      | 【           |
      | 】           |
      | '           |

  Scenario: [2-5] 创建图模型-点标签定义-重复定义
    When executing query:
      """
      CREATE GRAPH TYPE DuplicateVertexGraph {
        (:SimpleVertex),
        (:SimpleVertex)
      };
      """
    Then the error should be contain:
      """
      [2702]Variable '_SimpleVertex_' already declared
      """
    Then drop all graphType

  # ============================================================
  # 3. 边标签定义
  # ============================================================

  Scenario: [3-1] 创建图模型-边标签定义-无属性
    When executing queries without error:
      """
      CREATE GRAPH TYPE NoPropertyEdgeGraph {
        (:A{id string}),
        (:B{id string}),
        (:A)-[:RelatedTo]->(:B),
        (:B)-[:ConnectedTo]->(:A)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name                  | gql |
      | 'NoPropertyEdgeGraph' | 'CREATE GRAPH TYPE NoPropertyEdgeGraph { (:B {id string}),(:A {id string}),(:B)-[:ConnectedTo {}]->(:A),(:A)-[:RelatedTo {}]->(:B) };' |
    Then drop all graphType

  Scenario: [3-2] 创建图模型-边标签定义-包含所有数据类型
    When executing queries without error:
      """
      CREATE GRAPH TYPE EdgePropertiesGraph {
        (:User{userId string}),
        (:Product{productId string}),
        (:User)-[:Purchased{
          _PRIMARY_KEY string,
          quantity INT64,
          amount FLOAT32,
          rating FLOAT64,
          isActive BOOL,
          purchaseDate DATE,
          purchaseTime TIME,
          purchasedAt LOCALDATETIME NOT NULL,
          purchaseDatetime DATETIME,
          location POINT2D,
          destination POINT3D
        }]->(:Product)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'EdgePropertiesGraph';
      """
    And the result should be, in any order:
      | name                  |
      | 'EdgePropertiesGraph' |
    Then drop all graphType

  Scenario: [3-3] 创建图模型-边标签定义-自旋边
    When executing queries without error:
      """
      CREATE GRAPH TYPE SelfReferenceGraph {
        (:Person{id string}),
        (:Person)-[:Knows{since LOCALDATETIME}]->(:Person)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name                 | gql |
      | 'SelfReferenceGraph' | 'CREATE GRAPH TYPE SelfReferenceGraph { (:Person {id string}),(:Person)-[:Knows {since localdatetime}]->(:Person) };' |
    Then drop all graphType

  Scenario: [3-4] 创建图模型-边标签定义-多个边类型
    When executing queries without error:
      """
      CREATE GRAPH TYPE MultipleEdgeGraph {
        (:User{id string}),
        (:Product{sku string}),
        (:Order{order_id string}),
        (:User)-[:BUY]->(:Product),
        (:User)-[:PLACE]->(:Order),
        (:Order)-[:CONTAINS]->(:Product),
        (:User)-[:REVIEW]->(:Product)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'MultipleEdgeGraph';
      """
    And the result should be, in any order:
      | name                |
      | 'MultipleEdgeGraph' |
    Then drop all graphType

  Scenario: [3-5] 创建图模型-边标签定义-有向边两个方向
    When executing queries without error:
      """
      CREATE GRAPH TYPE DirectedEdgeGraph {
        (:A{id string}),
        (:B{id string}),
        (:A)-[:FORWARD]->(:B),
        (:B)-[:BACKWARD]->(:A)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'DirectedEdgeGraph';
      """
    And the result should be, in any order:
      | name                |
      | 'DirectedEdgeGraph' |
    Then drop all graphType

  Scenario Outline: [3-6] 创建图模型-边标签定义-无效边标签名-<edgeType>
    When executing query:
      """
      CREATE GRAPH TYPE InvalidEdgeGraph {
        (:ValidVertex{id string}),
        (:ValidVertex)-[:<edgeType>abc]->(:ValidVertex)
      };
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Examples:
      | edgeType    |
      | ！          |
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
      | \ |
      | ￥           |
      | ……          |
      | `           |
      | ~           |
      | 【           |
      | 】           |
      | '           |

  Scenario: [3-7] 创建图模型-边标签定义-重复定义
    When executing query:
      """
      CREATE GRAPH TYPE DuplicateEdgeGraph {
        (:A{id string}),
        (:B{id string}),
        (:A)-[:SameEdge{prop1 string}]->(:B),
        (:A)-[:SameEdge{prop2 uint32}]->(:B)
      };
      """
    Then the error should be contain:
      """
      [2702]Variable 'A_SameEdge_B' already declared
      """
    Then drop all graphType

  # ============================================================
  # 4. 属性定义
  # ============================================================

  Scenario: [4-1] 创建图模型-属性定义-属性约束-NOT NULL
    When executing queries without error:
      """
      CREATE GRAPH TYPE ConstraintGraph01 {
        (:User{userId STRING NOT NULL}),
        (:User)-[:Follows{since LOCALDATETIME NOT NULL}]->(:User)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name              | gql |
      | 'ConstraintGraph01' | 'CREATE GRAPH TYPE ConstraintGraph01 { (:User {userId string NOT NULL}),(:User)-[:Follows {since localdatetime NOT NULL}]->(:User) };' |
    Then drop all graphType

  Scenario: [4-2] 创建图模型-属性定义-属性约束-PRIMARY_KEY
    When executing queries without error:
      """
      CREATE GRAPH TYPE ConstraintGraph03 {
        (:User{_PRIMARY_KEY string, userId string}),
        (:User)-[:Follows{_PRIMARY_KEY string, since LOCALDATETIME}]->(:User)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name              | gql |
      | 'ConstraintGraph03' | 'CREATE GRAPH TYPE ConstraintGraph03 { (:User {_PRIMARY_KEY STRING NOT NULL,userId string}),(:User)-[:Follows {_PRIMARY_KEY STRING NOT NULL,since localdatetime}]->(:User) };' |
    Then drop all graphType

  Scenario Outline: [4-3] 创建图模型-属性定义-无效属性名-<propertyType>
    When executing query:
      """
      CREATE GRAPH TYPE InvalidPropertyGraph {
        (:Test{ <propertyType>abc string }),
        (:Test)-[:Test{ <propertyType>abc string }]->(:Test)
      };
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Examples:
      | propertyType |
      | ！           |
      | @            |
      | #            |
      | %            |
      | $            |
      | &            |
      | ^            |
      | *            |
      | (            |
      | )            |
      | +            |
      | -            |
      | =            |
      | {            |
      | }            |
      | [            |
      | ]            |
      | :            |
      | "            |
      | ;            |
      | ,            |
      | .            |
      | /            |
      | ?            |
      | \ |
      | ￥            |
      | ……           |
      | `            |
      | ~            |
      | 【            |
      | 】            |
      | '            |

  Scenario: [4-4] 创建图模型-属性定义-重复定义属性
    When executing query:
      """
      CREATE GRAPH TYPE DuplicatePropertyGraph {
        (:Test{
          id STRING,
          id INT64
        }),
        (:Test)-[:Test]->(:Test)
      };
      """
    Then the error should be contain:
      """
      duplicate property name: id
      """
    Then drop all graphType

  Scenario: [4-5] 创建图模型-属性定义-多种约束组合
    When executing queries without error:
      """
      CREATE GRAPH TYPE CombinedConstraintGraph {
        (:Person{
          _PRIMARY_KEY string,
          name STRING NOT NULL,
          age INT64,
          email STRING
        }),
        (:Person)-[:KNOWS{since DATE NOT NULL}]->(:Person)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'CombinedConstraintGraph';
      """
    And the result should be, in any order:
      | name                     |
      | 'CombinedConstraintGraph' |
    Then drop all graphType

  # ============================================================
  # 5. 图模型结构定义
  # ============================================================

  Scenario: [5-1] 创建图模型-模型结构定义-最小图模型（只有一个点）
    When executing queries without error:
      """
      CREATE GRAPH TYPE MinimalGraph {
        (:SingleVertex{id string})
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name            | gql |
      | 'MinimalGraph'  | 'CREATE GRAPH TYPE MinimalGraph { (:SingleVertex {id string}) };' |
    Then drop all graphType

  Scenario: [5-2] 创建图模型-模型结构定义-只有点没有边
    When executing queries without error:
      """
      CREATE GRAPH TYPE VertexOnlyGraph {
        (:User{id string}),
        (:Product{id string})
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE;
      """
    And the result should be, in any order:
      | name              | gql |
      | 'VertexOnlyGraph' | 'CREATE GRAPH TYPE VertexOnlyGraph { (:Product {id string}),(:User {id string}) };' |
    Then drop all graphType

  Scenario: [5-3] 创建图模型-模型结构定义-只有边点标签为空
    When executing query:
      """
      CREATE GRAPH TYPE EdgeOnlyGraph {
        ()-[:Edge]->()
      };
      """
    Then the error should be contain:
      """
      [2851]Mapping relation is invalid, startNodeTableName or endNodeTableName is empty
      """
    Then drop all graphType

  Scenario: [5-4] 创建图模型-模型结构定义-只有边点标签不存在（失败）
    When executing query:
      """
      CREATE GRAPH TYPE EdgeOnlyGraph {
        (:Person)-[:Creates]->(:Person)
      };
      """
    Then the error should be contain:
      """
      [1613]Label does not exist
      """
    Then drop all graphType

  Scenario: [5-5] 创建图模型-模型结构定义-复杂的社交网络模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE SocialNetwork {
        (:Person{name STRING NOT NULL, age UINT64, email STRING}),
        (:Post{content STRING, createdOn LOCALDATETIME}),
        (:Person)-[:Follows{since LOCALDATETIME}]->(:Person),
        (:Person)-[:Likes{likedAt LOCALDATETIME}]->(:Post),
        (:Person)-[:Creates]->(:Post)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name;
      """
    And the result should be, in any order:
      | name             |
      | 'SocialNetwork'  |
    Then drop all graphType

  Scenario: [5-6] 创建图模型-模型结构定义-电商模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE EcommerceGraph {
        (:Customer{id string, name string, email string}),
        (:Product{sku string, name string, price float64}),
        (:Order{order_id string, amount float64, status string}),
        (:Customer)-[:PLACE{order_date datetime}]->(:Order),
        (:Order)-[:INCLUDES{quantity int32}]->(:Product),
        (:Customer)-[:REVIEW{rating int32, review_date date}]->(:Product)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'EcommerceGraph';
      """
    And the result should be, in any order:
      | name             |
      | 'EcommerceGraph' |
    Then drop all graphType

  Scenario: [5-7] 创建图模型-模型结构定义-企业组织模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE OrganizationGraph {
        (:Employee{id string, name string, title string}),
        (:Department{dept_id string, name string}),
        (:Project{proj_id string, name string}),
        (:Employee)-[:WORKS_IN]->(:Department),
        (:Employee)-[:MANAGES]->(:Department),
        (:Employee)-[:PARTICIPATES]->(:Project),
        (:Department)-[:OWNS]->(:Project)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'OrganizationGraph';
      """
    And the result should be, in any order:
      | name                |
      | 'OrganizationGraph' |
    Then drop all graphType

  Scenario: [5-8] 创建图模型-模型结构定义-多层关系模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE MultiLayerGraph {
        (:Country{name string, code string}),
        (:City{name string, population int64}),
        (:District{name string}),
        (:Street{name string}),
        (:Country)-[:HAS_CITY]->(:City),
        (:City)-[:HAS_DISTRICT]->(:District),
        (:District)-[:HAS_STREET]->(:Street)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'MultiLayerGraph';
      """
    And the result should be, in any order:
      | name              |
      | 'MultiLayerGraph' |
    Then drop all graphType

  Scenario: [5-9] 创建图模型-模型结构定义-医疗健康模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE HealthcareGraph {
        (:Patient{id string, name string, age int64}),
        (:Doctor{id string, name string, specialty string}),
        (:Hospital{id string, name string, address string}),
        (:Patient)-[:VISITS{visit_date date}]->(:Hospital),
        (:Doctor)-[:WORKS_AT]->(:Hospital),
        (:Doctor)-[:TREATS{diagnosis string}]->(:Patient)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'HealthcareGraph';
      """
    And the result should be, in any order:
      | name               |
      | 'HealthcareGraph'  |
    Then drop all graphType

  Scenario: [5-10] 创建图模型-模型结构定义-物流运输模型
    When executing queries without error:
      """
      CREATE GRAPH TYPE LogisticsGraph {
        (:Warehouse{id string, location string}),
        (:Vehicle{id string, type string, capacity int64}),
        (:Driver{id string, name string}),
        (:Route{id string, distance int64}),
        (:Warehouse)-[:STORES]->(:Vehicle),
        (:Driver)-[:DRIVES]->(:Vehicle),
        (:Vehicle)-[:TAKES]->(:Route)
      };
      """
    Then executing query:
      """
      SHOW GRAPH TYPE YIELD name WHERE name = 'LogisticsGraph';
      """
    And the result should be, in any order:
      | name              |
      | 'LogisticsGraph'  |
    Then drop all graphType

  Scenario: [5-11] 创建图模型-模型结构定义-空模型（无效）
    When executing query:
      """
      CREATE GRAPH TYPE EmptyGraph {
      };
      """
    Then a SyntaxError should be raised at compile time: InvalidUnicodeLiteral
    Then drop all graphType