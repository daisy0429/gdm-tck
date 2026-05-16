Feature: 覆盖GDM-CYPHER核心运算符/谓词的自动化测试

# ===================== 1. 正则匹配运算符测试 =====================
# 1.1 基础正则匹配（覆盖LET/RETURN场景）
  Scenario Outline: regex-operator-basic-LET-RETURN匹配
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                                   | result |
      | LET email = "johndoe@gmail.com" RETURN email =~ "[a-zA-Z0-9_.-]+@[a-zA-Z0-9]+\\.(com\ | cn)" AS result; |
      | LET email = "johndoe@gmail.org" RETURN email =~ "[a-zA-Z0-9_.-]+@[a-zA-Z0-9]+\\.(com\ | cn)" AS result; |
      | LET s = "" RETURN s =~ "^$" AS result;                                                                | true   |
      | LET phone = "13800138000" RETURN phone =~ "^1[3-9]\\d{9}$" AS result;                                 | true   |
      | LET phone = "12800138000" RETURN phone =~ "^1[3-9]\\d{9}$" AS result;                                 | false  |

# 1.2 MATCH WHERE正则过滤（覆盖节点过滤场景）
  Scenario Outline: regex-operator-match-where-节点过滤
    Given test data cleared: MATCH (n:User) DETACH DELETE n;
    Given test data exists: CREATE (n:User {email: "<email>"});
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | count(n) |
      | <result> |
    Examples:
      | email    | GQL                                                                                                       | result |
      | test@cn | MATCH (n:User) WHERE n.email =~ "[a-zA-Z0-9_.-]+@[a-zA-Z0-9]+\\.(com\ | cn)" RETURN count(n) AS `count(n)`; |
      | test@org | MATCH (n:User) WHERE n.email =~ "[a-zA-Z0-9_.-]+@[a-zA-Z0-9]+\\.(com\ | cn)" RETURN count(n) AS `count(n)`; |

# ===================== 2. 规范化运算符测试 =====================
  Scenario Outline: normalize-operator-all-types-四种规范化校验
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | normRes  |
      | <result> |
    Examples:
      | GQL | result |
      | RETURN "Å" IS NORMALIZED AS normRes; | true |
      | RETURN "Å" IS NFD NORMALIZED AS normRes; | false |
      | RETURN "Å" IS NFKC NORMALIZED AS normRes; | true |
      | RETURN "Å" IS NFKD NORMALIZED AS normRes; | false |
      | RETURN "ﬁ" IS NFKC NORMALIZED AS normRes; | false |
      | RETURN "①" IS NFKC NORMALIZED AS normRes; | false |
# ===================== 3. 列表运算符测试 =====================
# 3.1 列表索引取值（正向/反向/越界）
  Scenario Outline: list-operator-index-索引取值
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                       | result |
      | LET items = ["a", 1, "b", 34] RETURN items[0] AS result;  | 'a'    |
            # 修复：字符串结果用双引号，匹配框架返回格式 |
      | LET items = ["a", 1, "b", 34] RETURN items[1] AS result;  | 1      |
      | LET items = ["a", 1, "b", 34] RETURN items[-1] AS result; | 34     |
      | LET items = ["a", 1, "b", 34] RETURN items[-2] AS result; | 'b'    |
            # 修复：字符串结果用双引号 |
      | LET items = ["a", 1] RETURN items[10] AS result;          | null   |

# 3.2 列表切片取值（全切片场景）
  Scenario Outline: list-operator-slice-切片取值
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                        | result       |
      | LET items = ["a", 1, "b", 34] RETURN items[1:] AS result;  | [1, 'b', 34] |
      | LET items = ["a", 1, "b", 34] RETURN items[:2] AS result;  | ['a', 1]     |
      | LET items = ["a", 1, "b", 34] RETURN items[1:3] AS result; | [1, 'b']     |
      | LET items = ["a", 1, "b", 34] RETURN items[0:0] AS result; | []           |
      | LET items = ["a", 1, "b", 34] RETURN items[-2:] AS result; | ['b', 34]    |
      | LET items = ["a", 1, "b", 34] RETURN items[:-2] AS result; | ['a', 1]     |

# ===================== 4. 路径运算符测试 =====================
# 4.1 PATH构造路径（简化断言：只校验节点数）
  Scenario Outline: path-operator-build-点边构造路径
    Given test data cleared: MATCH (n) DETACH DELETE n;
    Given test data exists: CREATE (n1 {id: "U01"}), (n2 {id: "U02"}), ()-[e {id:39}]->();
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | path_node_count |
      | <result>        |
    Examples:
      | GQL                                                                                                                  | result |
      | MATCH (n1 {id: "U01"}), (n2 {id: "U02"}), ()-[e {id:39}]->() RETURN SIZE(NODES(PATH[n2, e, n1])) AS path_node_count; | 2      |

# 4.2 子路径连接（||运算符）
  Scenario Outline: path-operator-concat-子路径连接
    Given test data cleared: MATCH (n) DETACH DELETE n;
    Given test data exists: CREATE (a {id: "U01"})-[]->(b {id: "U02"})-[]->(c {id: "U03"});
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | path_node_count |
      | <result>        |
    Examples:
      | GQL                                                                                             | result |
      | MATCH p1=({id:"U01"})-[]->(n), p2=(n)-[]->() RETURN SIZE(NODES(p1 \ | \ |
      | MATCH p1=({id:"U01"})-[]->() RETURN SIZE(NODES(p1 \ | \ |

# ===================== 5. EXISTS谓词测试 =====================
# 5.1 基础EXISTS谓词（单pattern）
  Scenario Outline: exists-predicate-basic-基础存在性
    Given test data cleared: MATCH (n) DETACH DELETE n;
    Given test data exists: CREATE (n {_id: "A"})-[]->(m);
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                       | result |
      | RETURN EXISTS { (n)-[]->() WHERE n._id = "A" } AS result; | true   |
      | RETURN EXISTS { (n)-[]->() WHERE n._id = "B" } AS result; | false  |

# 5.2 复杂EXISTS谓词（多pattern+过滤）
  Scenario Outline: exists-predicate-complex-复杂子查询
    Given test data cleared: MATCH (n) DETACH DELETE n;
    Given test data exists: CREATE (:movie {rating:8.0})<-[:direct]-(:Director {name:"Ang Lee"});
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                                   | result |
      | MATCH (n:movie) WHERE n.rating>7.5 RETURN EXISTS { (n)<-[:direct]-({name:"Ang Lee"}) } AS result;     | true   |
      | MATCH (n:movie) WHERE n.rating>7.5 RETURN EXISTS { (n)<-[:direct]-({name:"Zhang Yimou"}) } AS result; | false  |
      | RETURN EXISTS { (a)-[]->(b), (b)-[]->(c) WHERE a.id="NonExist" } AS result;                           | false  |

# ===================== 6. 值类型谓词测试（适配GDM-CYPHER原生语法） =====================
  Scenario Outline: type-predicate-all-types-全类型判断
    Given test data cleared: MATCH (n:TestNode) DETACH DELETE n;
    Given test data exists:
      """
    CREATE (n:TestNode {
      // 基础数据类型
      boolVal: true,
      strVal: "test",
      int64Val: 10000000000,
      float64Val: 2.0,
      // 时间类型（GDM-CYPHER原生语法）
      datetimeVal: datetime('2024-01-01T12:00:00+0800'),
      localdatetimeVal: localdatetime('2024-01-01T12:00:00'),
      dateVal: date('2024-01-01'),
      timeVal: time('12:00:00'),
      localtimeVal: localtime('12:00:00'),
      durationVal: duration({years:1}),
      // 空间类型（GDM-CYPHER原生语法）
      point2dVal: Point({x:1.0, y:2.0}),
      point3dVal: Point({x:1.0, y:2.0, z:3.0}),
      // 列表类型
      listVal: [1.0, 2.0, "test"]
    });
    """
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL | result |
      | MATCH (n:TestNode) RETURN n.boolVal IS TYPED BOOL AS result; | true |
      | MATCH (n:TestNode) RETURN n.strVal IS TYPED STRING AS result; | true |
      | MATCH (n:TestNode) RETURN n.int64Val IS TYPED INT64 AS result; | true |
      | MATCH (n:TestNode) RETURN n.float64Val IS TYPED FLOAT64 AS result; | true |
      | MATCH (n:TestNode) RETURN n.datetimeVal IS TYPED DATETIME AS result; | true |
      | MATCH (n:TestNode) RETURN n.localdatetimeVal IS TYPED LOCALDATETIME AS result; | true |
      | MATCH (n:TestNode) RETURN n.dateVal IS TYPED DATE AS result; | true |
      | MATCH (n:TestNode) RETURN n.timeVal IS TYPED TIME AS result; | true |
      | MATCH (n:TestNode) RETURN n.localtimeVal IS TYPED LOCALTIME AS result; | true |
      | MATCH (n:TestNode) RETURN n.durationVal IS TYPED DURATION AS result; | true |
      | MATCH (n:TestNode) RETURN n.point2dVal IS TYPED POINT2D AS result; | true |
      | MATCH (n:TestNode) RETURN n.point3dVal IS TYPED POINT3D AS result; | true |
      | MATCH (n:TestNode) RETURN n.listVal IS TYPED LIST AS result; | true |
      | MATCH (n:TestNode) RETURN n.int64Val IS TYPED STRING AS result; | false |
      | MATCH (n:TestNode) RETURN n.listVal IS TYPED INT64 AS result; | false |