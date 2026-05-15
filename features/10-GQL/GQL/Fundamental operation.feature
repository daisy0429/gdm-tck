Feature: GDM-CYPHER运算符/谓词全量测试覆盖正则/规范化/列表/路径/EXISTS/类型判断/数值/逻辑/集合/空值等所有核心运算符/谓词

# ===================== 基础配置：统一前置数据清理 =====================
  Background:
    Given test data cleared: MATCH (n) DETACH DELETE n;

# ===================== 1. 正则匹配运算符测试 =====================
## 1.1 基础正则匹配（LET/RETURN场景）
  Scenario Outline: regex-operator-basic-LET-RETURN匹配
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                                   | result |             |
      | LET email = "johndoe@gmail.com" RETURN email =~ "[a-zA-Z0-9_.-]+@[a-zA-Z0-9]+\\.(com\|cn)" AS result; | true   |             |
      | LET email = "johndoe@gmail.org" RETURN email =~ "[a-zA-Z0-9_.-]+@[a-zA-Z0-9]+\\.(com\|cn)" AS result; | false  |             |
      | LET s = "" RETURN s =~ "^$" AS result;                                                                | true   |             |
      | LET phone = "13800138000" RETURN phone =~ "^1[3-9]\\d{9}$" AS result;                                 | true   |             |
      | LET phone = "12800138000" RETURN phone =~ "^1[3-9]\\d{9}$" AS result;                                 | false  |             |
      | LET name = "张三" RETURN name =~ "^[\\u4e00-\\u9fa5]{2,4}$" AS result;                                  | true   | # 新增：中文字符正则 |
      | LET mix = "Test123_中文" RETURN mix =~ "^[a-zA-Z0-9_\\u4e00-\\u9fa5]+$" AS result;                      | true   | # 新增：混合字符正则 |

## 1.2 MATCH WHERE正则过滤（节点过滤场景）
  Scenario Outline: regex-operator-match-where-节点过滤
    Given test data exists: CREATE (n:User {email: "<email>"});
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | count(n) |
      | <result> |
    Examples:
      | email         | GQL                                                                                                       | result | 备注           |
      | test@cn       | MATCH (n:User) WHERE n.email =~ "[a-zA-Z0-9_.-]+@[a-zA-Z0-9]+\\.(com\|cn)" RETURN count(n) AS `count(n)`; | 1      |              |
      | test@org      | MATCH (n:User) WHERE n.email =~ "[a-zA-Z0-9_.-]+@[a-zA-Z0-9]+\\.(com\|cn)" RETURN count(n) AS `count(n)`; | 0      |              |
      | 123@test.com  | MATCH (n:User) WHERE n.email =~ "^\\d+@test\\.com$" RETURN count(n) AS `count(n)`;                        | 1      | # 新增：纯数字前缀正则 |
      | zhang@test.cn | MATCH (n:User) WHERE n.email =~ "^[a-z]+@test\\.cn$" RETURN count(n) AS `count(n)`;                       | 1      | # 新增：纯小写前缀正则 |
## 1.3 正则边界场景（特殊字符/空值）
  Scenario Outline: regex-operator-boundary-特殊场景
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                       | result | 备注       |
      | LET s = "test@123.com" RETURN s =~ ".*\\d+.*" AS result;  | true   | # 包含数字   |
      | LET s = null RETURN s =~ "^test$" AS result;              | null   | # 空值正则匹配 |
      | LET s = "a.b.c" RETURN s =~ "a\\.b\\.c" AS result;        | true   | # 转义特殊字符 |
      | LET s = "test\nline" RETURN s =~ "test\\nline" AS result; | true   | # 换行符正则  |
      | LET s = "test\ttab" RETURN s =~ "test\\ttab" AS result;   | true   | # 制表符正则  |

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
      | GQL                                       | result | 备注              |
      | RETURN "Å" IS NORMALIZED AS normRes;      | true   | # NFC（默认），全版本兼容 |
      | RETURN "Å" IS NFD NORMALIZED AS normRes;  | false  | # NFD拆分，结果稳定    |
      | RETURN "Å" IS NFKC NORMALIZED AS normRes; | true   | # v0.34.0+ 结果更新 |
      | RETURN "Å" IS NFKD NORMALIZED AS normRes; | false  | # NFKD拆分，结果稳定   |
      | RETURN "é" IS NFD NORMALIZED AS normRes;  | false  | # 重音字符校验        |
      | RETURN "ﬁ" IS NFKC NORMALIZED AS normRes; | false  | # 连字字符校验        |
      | RETURN "ñ" IS NFC NORMALIZED AS normRes;  | true   | # 西班牙语字符        |
      | RETURN "Ä" IS NFKD NORMALIZED AS normRes; | false  | # 德语字符          |
      | RETURN "①" IS NFKC NORMALIZED AS normRes; | false  | # 带圈数字字符        |
      | RETURN "test" IS NORMALIZED AS normRes;   | true   | # 新增：普通字符校验     |
      | RETURN null IS NORMALIZED AS normRes;     | null   | # 新增：空值规范化校验    |

# ===================== 3. 列表运算符测试 =====================
## 3.1 列表索引取值（正向/反向/越界/空列表）
  Scenario Outline: list-operator-index-索引取值
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                       | result | 备注                |
      | LET items = ["a", 1, "b", 34] RETURN items[0] AS result;  | "a"    | # 修复：双引号匹配GDM返回格式 |
      | LET items = ["a", 1, "b", 34] RETURN items[1] AS result;  | 1      |                   |
      | LET items = ["a", 1, "b", 34] RETURN items[-1] AS result; | 34     |                   |
      | LET items = ["a", 1, "b", 34] RETURN items[-2] AS result; | "b"    | # 修复：双引号          |
      | LET items = ["a", 1] RETURN items[10] AS result;          | null   | # 越界              |
      | LET items = [] RETURN items[0] AS result;                 | null   | # 新增：空列表索引        |
      | LET items = [true, null, 3.14] RETURN items[1] AS result; | null   | # 新增：空值元素         |
      | LET items = [[1,2], [3,4]] RETURN items[1][0] AS result;  | 3      | # 新增：嵌套列表索引       |

## 3.2 列表切片取值（全场景+边界）
  Scenario Outline: list-operator-slice-切片取值
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                         | result       | 备注         |
      | LET items = ["a", 1, "b", 34] RETURN items[1:] AS result;   | [1, "b", 34] | # 修复：空格对齐  |
      | LET items = ["a", 1, "b", 34] RETURN items[:2] AS result;   | ["a", 1]     |            |
      | LET items = ["a", 1, "b", 34] RETURN items[1:3] AS result;  | [1, "b"]     |            |
      | LET items = ["a", 1, "b", 34] RETURN items[0:0] AS result;  | []           |            |
      | LET items = ["a", 1, "b", 34] RETURN items[-2:] AS result;  | ["b", 34]    | # 新增：反向切片  |
      | LET items = ["a", 1, "b", 34] RETURN items[:-2] AS result;  | ["a", 1]     | # 新增：反向切片  |
      | LET items = ["a", 1, "b", 34] RETURN items[2:-1] AS result; | ["b"]        | # 新增：混合切片  |
      | LET items = [] RETURN items[1:] AS result;                  | []           | # 新增：空列表切片 |

## 3.3 列表函数（SIZE/CONTAINS/INDEXOF）
  Scenario Outline: list-operator-functions-列表函数
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                 | result | 备注      |
      | LET items = ["a", 1, "b", 34] RETURN SIZE(items) AS result;         | 4      | # 列表长度  |
      | LET items = ["a", 1, "b", 34] RETURN CONTAINS(items, 1) AS result;  | true   | # 包含元素  |
      | LET items = ["a", 1, "b", 34] RETURN INDEXOF(items, "b") AS result; | 2      | # 元素索引  |
      | LET items = ["a", 1, "b", 34] RETURN INDEXOF(items, 10) AS result;  | -1     | # 元素不存在 |
      | LET items = [] RETURN SIZE(items) AS result;                        | 0      | # 空列表长度 |

# ===================== 4. 路径运算符测试 =====================
## 4.1 PATH构造路径（点边构成路径）
  Scenario Outline: path-operator-build-点边构造路径
    Given test data exists: CREATE (n1 {id: "U01"}), (n2 {id: "U02"}), ()-[e {id:39}]->();
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | path_node_count | edge_id |
      | <node_count>    | <e_id>  |
    Examples:
      | GQL                                                                                                                                   | node_count | e_id |
      | MATCH (n1 {id: "U01"}), (n2 {id: "U02"}), ()-[e {id:39}]->() RETURN SIZE(NODES(PATH[n2, e, n1])) AS path_node_count, e.id AS edge_id; | 2          | 39   |

## 4.2 子路径连接（||运算符）
  Scenario Outline: path-operator-concat-子路径连接
    Given test data exists: CREATE (a {id: "U01"})-[]->(b {id: "U02"})-[]->(c {id: "U03"});
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | path_node_count |
      | <length>        |
    Examples:
      | GQL                                                                                             | length |
      | MATCH p1=({id:"U01"})-[]->(n), p2=(n)-[]->() RETURN SIZE(NODES(p1 \|\| p2)) AS path_node_count; | 3      |
      | MATCH p1=({id:"U01"})-[]->() RETURN SIZE(NODES(p1 \|\| null)) AS path_node_count;               | 0      |
      | MATCH p1=null, p2=null RETURN SIZE(NODES(p1 \|\| p2)) AS path_node_count;                       | 0      |
      # 新增：空路径连接

## 4.3 路径函数（NODES/RELATIONSHIPS/LENGTH）
  Scenario Outline: path-operator-functions-路径函数
    Given test data exists: CREATE (a {id: "U01"})-[:LINK]->(b {id: "U02"})-[:LINK]->(c {id: "U03"});
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                             | result | 备注      |
      | MATCH p=({id:"U01"})-[*]->({id:"U03"}) RETURN LENGTH(p) AS result;              | 2      | # 路径长度  |
      | MATCH p=({id:"U01"})-[*]->({id:"U03"}) RETURN SIZE(NODES(p)) AS result;         | 3      | # 节点数   |
      | MATCH p=({id:"U01"})-[*]->({id:"U03"}) RETURN SIZE(RELATIONSHIPS(p)) AS result; | 2      | # 关系数   |
      | MATCH p=null RETURN LENGTH(p) AS result;                                        | null   | # 空路径长度 |

# ===================== 5. EXISTS谓词测试 =====================
## 5.1 基础EXISTS谓词（单pattern）
  Scenario Outline: exists-predicate-basic-基础存在性
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
      | RETURN EXISTS { (n)-[:NON_EXIST]->() } AS result;         | false  |
      # 新增：不存在的关系类型

## 5.2 复杂EXISTS谓词（多pattern+过滤）
  Scenario Outline: exists-predicate-complex-复杂子查询
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
      | RETURN EXISTS { (n:movie) WHERE n.rating > 9.0 } AS result;                                           | false  |
       # 新增：数值过滤

# ===================== 6. 类型判断谓词测试 =====================
## 6.1 基础类型判断（IS TYPED）
  Scenario Outline: type-predicate-basic-基础类型判断
    Given test data exists:
"""
    CREATE (n {
      time: localdatetime("2024-01-01T12:00:00"),
      point2d: point(1.0,2.0),
      list: [1.0,2.0],
      intVal: 100,
      strVal: "test",
      boolVal: true,
      nullVal: null
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
      | GQL                                                       | result | 备注                 |
      | MATCH (n) RETURN n IS TYPED NODE AS result;               | true   |                    |
      | MATCH (n) RETURN n.time IS TYPED LOCALDATETIME AS result; | true   |                    |
      | MATCH (n) RETURN n.point2d IS TYPED POINT2D AS result;    | true   |                    |
      | MATCH (n) RETURN n.list IS TYPED LIST<FLOAT64> AS result; | true   |                    |
      | MATCH (n) RETURN n.intVal IS TYPED INT64 AS result;       | true   | # 修复：原用例错误写成STRING |
      | MATCH (n) RETURN n.strVal IS TYPED STRING AS result;      | true   | # 修复：原用例错误写成INT64  |
      | MATCH (n) RETURN n.boolVal IS TYPED BOOL AS result;       | true   | # 新增：布尔类型          |
      | MATCH (n) RETURN n.nullVal IS TYPED NULL AS result;       | true   | # 新增：空值类型          |

## 6.2 类型函数（TYPE/TOSTRING/TOINTEGER）
  Scenario Outline: type-predicate-functions-类型转换函数
    Given test data exists: CREATE (n {intVal: 100, strVal: "123", floatVal: 3.14});
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                               | result  | 备注         |
      | MATCH (n) RETURN TYPE(n.intVal) AS result;        | "INT64" |            |
      | MATCH (n) RETURN TOSTRING(n.intVal) AS result;    | "100"   | # 转字符串     |
      | MATCH (n) RETURN TOINTEGER(n.strVal) AS result;   | 123     | # 转整数      |
      | MATCH (n) RETURN TOFLOAT(n.intVal) AS result;     | 100.0   | # 新增：转浮点   |
      | MATCH (n) RETURN TOINTEGER(n.floatVal) AS result; | 3       | # 新增：浮点转整数 |
      | MATCH (n) RETURN TOINTEGER("abc") AS result;      | null    | # 新增：转换失败  |

# ===================== 7. 数值运算符测试 =====================
  Scenario Outline: numeric-operator-basic-数值运算
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                            | result | 备注     |
      | RETURN 10 + 5 AS result;       | 15     | # 加法   |
      | RETURN 10 - 5 AS result;       | 5      | # 减法   |
      | RETURN 10 * 5 AS result;       | 50     | # 乘法   |
      | RETURN 10 / 5 AS result;       | 2      | # 除法   |
      | RETURN 10 % 3 AS result;       | 1      | # 取模   |
      | RETURN POWER(10, 2) AS result; | 100    | # 幂运算  |
      | RETURN ABS(-10) AS result;     | 10     | # 绝对值  |
      | RETURN ROUND(3.14) AS result;  | 3      | # 四舍五入 |
      | RETURN CEIL(3.14) AS result;   | 4      | # 向上取整 |
      | RETURN FLOOR(3.99) AS result;  | 3      | # 向下取整 |

# ===================== 8. 逻辑运算符测试 =====================
  Scenario Outline: logical-operator-basic-逻辑运算
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                              | result | 备注        |
      | RETURN true AND false AS result; | false  | # 与运算     |
      | RETURN true OR false AS result;  | true   | # 或运算     |
      | RETURN NOT true AS result;       | false  | # 非运算     |
      | RETURN true XOR false AS result; | true   | # 异或运算    |
      | RETURN null AND true AS result;  | null   | # 新增：空值逻辑 |
      | RETURN null OR true AS result;   | true   | # 新增：空值逻辑 |

# ===================== 9. 集合谓词测试（ANY/ALL/SINGLE/NONE） =====================
  Scenario Outline: collection-predicate-any-任意元素满足
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                    | result |
      | RETURN ANY(x IN [1,2,3] WHERE x > 2) AS result;        | true   |
      | RETURN ANY(x IN [1,2,3] WHERE x > 3) AS result;        | false  |
      | RETURN ANY(x IN [] WHERE x > 0) AS result;             | false  |
            # 空列表
      | RETURN ANY(x IN [1,null,3] WHERE x IS NULL) AS result; | true   |
      # 空值元素

  Scenario Outline: collection-predicate-all-所有元素满足
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                             | result |
      | RETURN ALL(x IN [1,2,3] WHERE x > 0) AS result; | true   |
      | RETURN ALL(x IN [1,2,3] WHERE x > 1) AS result; | false  |
      | RETURN ALL(x IN [] WHERE x > 0) AS result;      | true   |
      # 空列表（空真）

  Scenario Outline: collection-predicate-single-仅一个元素满足
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                | result |
      | RETURN SINGLE(x IN [1,2,3] WHERE x > 2) AS result; | true   |
      | RETURN SINGLE(x IN [1,2,3] WHERE x > 1) AS result; | false  |
      | RETURN SINGLE(x IN [] WHERE x > 0) AS result;      | false  |
      # 空列表

  Scenario Outline: collection-predicate-none-无元素满足
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                              | result |
      | RETURN NONE(x IN [1,2,3] WHERE x > 3) AS result; | true   |
      | RETURN NONE(x IN [1,2,3] WHERE x > 2) AS result; | false  |
      | RETURN NONE(x IN [] WHERE x > 0) AS result;      | true   |
      # 空列表（空真）

# ===================== 10. 空值运算符测试（IS NULL/IS NOT NULL） =====================
  Scenario Outline: null-operator-basic-空值判断
    Given test data exists: CREATE (n {name: "test", nullVal: null});
    When executing queries without error:
"""
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                            | result |
      | MATCH (n) RETURN n.nullVal IS NULL AS result;  | true   |
      | MATCH (n) RETURN n.name IS NULL AS result;     | false  |
      | MATCH (n) RETURN n.nonExist IS NULL AS result; | true   |
      | MATCH (n) RETURN n.name IS NOT NULL AS result; | true   |
      | RETURN null IS NULL AS result;                 | true   |
