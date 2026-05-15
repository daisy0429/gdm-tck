#encoding: utf-8
Feature: BOOL/空间/时间/LIST所有数据类型的运算符和谓词校验

  Background: 初始化基础类型测试数据
    Given test data cleared: MATCH (n) DETACH DELETE n;
    Given test data exists:
    """
    create graph type as {
      (person:Person{
        name STRING NOT NULL,
        age INT64,
        height FLOAT64,
        sex BOOL,
        home POINT2D,
        school POINT3D,
        t1 DATETIME,
        t2 LOCALDATETIME,
        t3 DATE,
        t4 TIME,
        t5 LOCALTIME,
        t6 DURATION,
        email LIST
      }),
      (pet:Pet{name STRING NULL})
    };
    # 2. 添加测试数据
    CREATE
      (p1:Person{
        name:"张三",
        age:25,
        height:1.78,
        sex:true,
        home:Point({x:116.40, y:39.90}),
        school:Point({x:114.30, y:30.50, z:20}),
        t1:datetime('2024-01-01T12:00:00+0800'),
        t2:localdatetime('2024-01-01T12:00:00'),
        t3:date('2024-01-01'),
        t4:time('12:30:45'),
        t5:localtime('12:30:45'),
        t6:duration({years:1, months:2, days:3}),
        email:["zhangsan@test.com", "zs@test.com", 123]
      }),
      (p2:Person{
        name:"李四",
        age:30,
        height:1.85,
        sex:false,
        home:Point({x:120.10, y:30.20}),
        school:Point({x:118.80, y:32.00, z:15}),
        t1:datetime('2023-12-31T18:00:00+0800'),
        t2:localdatetime('2023-12-31T18:00:00'),
        t3:date('2023-12-31'),
        t4:time('18:45:30'),
        t5:localtime('18:45:30'),
        t6:duration({years:2, nanoseconds:100}),
        email:[456, true, "lisi@test.com"]
      }),
      (pet1:Pet{name:NULL});
    """

# ===================== 1. STRING类型测试 =====================
  Scenario Outline: string-type-operator-类型校验与运算
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                  | result  |
      | MATCH (p:Person{name:"张三"}) RETURN p.name IS TYPED STRING AS result; | true    |
      | MATCH (p:Person{name:"张三"}) RETURN p.name =~ "^张.*" AS result;       | true    |
      | MATCH (p:Person{name:"张三"}) RETURN (p.name + "_test") AS result;     | 张三_test |
      | MATCH (pet:Pet{name:NULL}) RETURN pet.name IS NULL AS result;        | true    |
      | MATCH (p:Person{name:"张三"}) RETURN p.name IS NOT NULL AS result;     | true    |

# ===================== 2. INT64/FLOAT64类型测试 =====================
  Scenario Outline: numeric-type-operator-数值运算与校验
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                          | result |
      | MATCH (p:Person{name:"张三"}) RETURN p.age IS TYPED INT64 AS result;                           | true   |
      | MATCH (p:Person{name:"张三"}) RETURN p.height IS TYPED FLOAT64 AS result;                      | true   |
      | MATCH (p1:Person{name:"张三"}), (p2:Person{name:"李四"}) RETURN p1.age + p2.age AS result;       | 55     |
      | MATCH (p1:Person{name:"张三"}), (p2:Person{name:"李四"}) RETURN p1.height - p2.height AS result; | -0.07  |
      | MATCH (p:Person{name:"张三"}) RETURN p.age > 20 AS result;                                     | true   |
      | MATCH (p:Person{name:"张三"}) RETURN p.height < 1.80 AS result;                                | true   |

# ===================== 3. BOOL类型测试 =====================
  Scenario Outline: bool-type-operator-布尔运算与校验
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                        | result |
      | MATCH (p:Person{name:"张三"}) RETURN p.sex IS TYPED BOOL AS result;                          | true   |
      | MATCH (p1:Person{name:"张三"}), (p2:Person{name:"李四"}) RETURN (p1.sex AND p2.sex) AS result; | false  |
      | MATCH (p1:Person{name:"张三"}), (p2:Person{name:"李四"}) RETURN (p1.sex OR p2.sex) AS result;  | true   |
      | MATCH (p:Person{name:"张三"}) RETURN NOT p.sex AS result;                                    | false  |
      | MATCH (p:Person{name:"张三"}) RETURN (p.sex = true) AS result;                               | true   |

# ===================== 4. 空间类型（POINT2D/3D）测试 =====================
  Scenario Outline: spatial-type-operator-空间类型校验与操作
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                     | result |
      | MATCH (p:Person{name:"张三"}) RETURN p.home IS TYPED POINT2D AS result;   | true   |
      | MATCH (p:Person{name:"张三"}) RETURN p.school IS TYPED POINT3D AS result; | true   |
      | RETURN Point({x:116.40, y:39.90}) IS TYPED POINT2D AS result;           | true   |
      | RETURN Point({x:114.30, y:30.50, z:20}) IS TYPED POINT3D AS result;     | true   |

# ===================== 5. 时间类型测试 =====================
  Scenario Outline: temporal-type-operator-时间运算与校验
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                    | result     |
      | MATCH (p:Person{name:"张三"}) RETURN p.t3 IS TYPED DATE AS result;                       | true       |
      | MATCH (p:Person{name:"张三"}) RETURN p.t1 IS TYPED DATETIME AS result;                   | true       |
      | MATCH (p:Person{name:"张三"}) RETURN (p.t3 + duration({days:1})) AS result;              | 2024-01-02 |
      | MATCH (p1:Person{name:"张三"}), (p2:Person{name:"李四"}) RETURN (p1.t3 > p2.t3) AS result; | true       |
      | MATCH (p:Person{name:"张三"}) RETURN p.t6 IS TYPED DURATION AS result;                   | true       |

# ===================== 6. LIST类型测试 =====================
  Scenario Outline: list-type-operator-列表操作与校验
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                            | result              |
      | MATCH (p:Person{name:"张三"}) RETURN p.email IS TYPED LIST AS result;            | true                |
      | MATCH (p:Person{name:"张三"}) RETURN p.email[0] AS result;                       | zhangsan@test.com   |
      | MATCH (p:Person{name:"张三"}) RETURN p.email[1:] AS result;                      | ["zs@test.com",123] |
      | MATCH (p:Person{name:"张三"}) RETURN SIZE(p.email) AS result;                    | 3                   |
      | MATCH (p:Person{name:"张三"}) RETURN ("zhangsan@test.com" IN p.email) AS result; | true                |

# ===================== 7. 边界场景测试 =====================
  Scenario Outline: boundary-type-operator-数据类型边界校验
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                            | result |
#       # INT64最大值校验                                                                                   |
      | CREATE (p:Person{name:"边界测试", age:9223372036854775807}) RETURN p.age IS TYPED INT64 AS result; | true   |
       # 空LIST校验                                                                                      |
      | CREATE (p:Person{name:"空列表", email:[]}) RETURN p.email IS TYPED LIST AS result;                | true   |
       # 时间格式合法性                                                                                      |
      | RETURN date('2024-02-30') IS NULL AS result;                                                   | true   |
       # POINT2D空坐标校验                                                                                 |
      | RETURN Point({x:NULL, y:39.90}) IS NULL AS result;                                             | true   |
