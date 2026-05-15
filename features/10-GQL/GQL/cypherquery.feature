 #===================== 基础数据初始化 =====================
 Feature: GQL运算符全量测试-基于人物/城市/学校/公司数据，测试6类GQL运算符功能

   Background: 初始化测试数据
     Given test data cleared: MATCH (n) DETACH DELETE n;
     Then  executing query:
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
           (k:学校{名称:"武汉大学", 创办时间:"1893年"}),
           (m:学校{名称:"华中科技大学", 创办时间:"1952年"}),
           (n:学校{名称:"深圳大学", 创办时间:"1983年"}),
           (o:公司{名称:"百度", 成立时间:"2000年1月"}),
           (p:公司{名称:"腾讯科技（深圳）有限公司", 成立时间:"1998年11月"}),
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
           (j)-[:所属城市]->(f);
    """

   Scenario Outline: regex-operator-person-姓名/公司名正则匹配
     When executing queries without error:
    """
    <GQL>
    """
     Then the result should be, in any order:
       | result   |
       | <result> |
     Examples:
       | GQL                                                                | result |
       | LET name = "李明" RETURN name =~ "^李.*" AS result;                   | true   |
       | LET company = "腾讯科技（深圳）有限公司" RETURN company =~ ".*腾讯.*" AS result; | true   |
       | LET school = "武汉大学" RETURN school =~ "^华中.*" AS result;            | false  |

# ===================== 2. 规范化运算符测试 =====================
   Scenario Outline: normalize-operator-名称规范化校验
     When executing queries without error:
    """
    <GQL>
    """
     Then the result should be, in any order:
       | normRes  |
       | <result> |
     Examples:
       | GQL                                                           | result |
       | MATCH (n:学校{名称:"四川大学"}) RETURN n.名称 IS NORMALIZED AS normRes; | true   |
       | RETURN "Å" IS NFKC NORMALIZED AS normRes;                     | true   |
       | RETURN "ﬁ" IS NFKC NORMALIZED AS normRes;                     | false  |

# ===================== 3. 列表运算符测试 =====================
   Scenario Outline: list-operator-person-属性列表操作
     When executing queries without error:
    """
    <GQL>
    """
     Then the result should be, in any order:
       | result   |
       | <result> |
     Examples:
       | GQL                                                      | result        |
       | LET ages = [25,35,18,21,22] RETURN ages[0] AS result;    | 25            |
       | LET ages = [25,35,18,21,22] RETURN ages[-1] AS result;   | 22            |
       | LET ages = [25,35,18,21,22] RETURN ages[1:] AS result;   | [35,18,21,22] |
       | LET names = ["李明","张文","王武"] RETURN names[:2] AS result; | ["李明","张文"]   |

# ===================== 4. 路径运算符测试 =====================
   Scenario Outline: path-operator-build-人物关系路径
     When executing queries without error:
    """
    <GQL>
    """
     Then the result path node count should be <length>
     Examples:
       | GQL                                                                                   | length |
       | MATCH (a:人{姓名:"李明"}), (d:人{姓名:"陈阳"}), (a)-[e:朋友]->(d) RETURN PATH[a,e,d] AS result;   | 2      |
       | MATCH p1=({姓名:"周萌"})-[:朋友]->(), p2=()-[:朋友]->({姓名:"李明"}) RETURN p1 \|\| p2 AS result; | 3      |

# ===================== 5. EXISTS谓词测试 =====================
   Scenario Outline: exists-predicate-person-关系存在性校验
     When executing queries without error:
    """
    <GQL>
    """
     Then the result should be, in any order:
       | result   |
       | <result> |
     Examples:
       | GQL                                                                      | result |
       | RETURN EXISTS { (n:人{姓名:"李明"})-[:朋友]->(m:人) } AS result;                 | true   |
       | RETURN EXISTS { (n:人{姓名:"周萌"})-[:就职于]->(o:公司{名称:"腾讯"}) } AS result;      | false  |
       | MATCH (n:人{姓名:"张文"}) RETURN EXISTS { (n)-[:籍贯]->({名称:"成都"}) } AS result; | true   |

# ===================== 6. 值类型谓词测试 =====================
   Scenario Outline: type-predicate-all-types-数据类型校验
     When executing queries without error:
    """
    <GQL>
    """
     Then the result should be, in any order:
       | result   |
       | <result> |
     Examples:
       | GQL                                                                | result |
       | MATCH (n:人{姓名:"李明"}) RETURN n.年龄 IS TYPED INT32 AS result;         | true   |
       | MATCH (n:人{姓名:"周萌"}) RETURN n.性别 IS TYPED BOOL AS result;          | true   |
       | MATCH (n:人{姓名:"李明"})-[:就读于]->(m) RETURN m IS TYPED NODE AS result; | true   |
       | MATCH (n:人{姓名:"李明"}) RETURN n.姓名 IS TYPED STRING AS result;        | true   |
#
   Scenario Outline: regex-operator-match-where-籍贯城市过滤
     When executing queries without error:
       """
       <GQL>
       """
     Then the result should be, in any order:
       | count(n) |
       | <result> |
     Examples:
       | GQL                                                                          | result |
       | MATCH (n:人)-[:籍贯]->(c:城市) WHERE c.名称 =~ "成.*" RETURN count(n) AS `count(n)`; | 3      |
       | MATCH (n:人)-[:籍贯]->(c:城市) WHERE c.名称 =~ "北.*" RETURN count(n) AS `count(n)`; | 0      |

# ===================== 2. 规范化运算符测试 =====================
   Scenario Outline: normalize-operator-名称规范化校验
     When executing queries without error:
       """
       <GQL>
       """
     Then the result should be, in any order:
       | normRes  |
       | <result> |
     Examples:
       | GQL                                                           | result |
       | MATCH (n:学校{名称:"四川大学"}) RETURN n.名称 IS NORMALIZED AS normRes; | true   |
       | RETURN "Å" IS NFKC NORMALIZED AS normRes;                     | true   |
       | RETURN "ﬁ" IS NFKC NORMALIZED AS normRes;                     | false  |

# ===================== 3. 列表运算符测试 =====================
   Scenario Outline: list-operator-person-属性列表操作
     When executing queries without error:
       """
       <GQL>
       """
     Then the result should be, in any order:
       | result   |
       | <result> |
     Examples:
       | GQL                                                      | result        |
       | LET ages = [25,35,18,21,22] RETURN ages[0] AS result;    | 25            |
       | LET ages = [25,35,18,21,22] RETURN ages[-1] AS result;   | 22            |
       | LET ages = [25,35,18,21,22] RETURN ages[1:] AS result;   | [35,18,21,22] |
       | LET names = ["李明","张文","王武"] RETURN names[:2] AS result; | ["李明","张文"]   |

# ===================== 4. 路径运算符测试 =====================
   Scenario Outline: path-operator-build-人物关系路径
     When executing queries without error:
       """
       <GQL>
       """
     Then the result path node count should be <length>
     Examples:
       | GQL                                                                                   | length |
       | MATCH (a:人{姓名:"李明"}), (d:人{姓名:"陈阳"}), (a)-[e:朋友]->(d) RETURN PATH[a,e,d] AS result;   | 2      |
       | MATCH p1=({姓名:"周萌"})-[:朋友]->(), p2=()-[:朋友]->({姓名:"李明"}) RETURN p1 \|\| p2 AS result; | 3      |

# ===================== 5. EXISTS谓词测试 =====================
   Scenario Outline: exists-predicate-person-关系存在性校验
     When executing queries without error:
       """
       <GQL>
       """
     Then the result should be, in any order:
       | result   |
       | <result> |
     Examples:
       | GQL                                                                      | result |
       | RETURN EXISTS { (n:人{姓名:"李明"})-[:朋友]->(m:人) } AS result;                 | true   |
       | RETURN EXISTS { (n:人{姓名:"周萌"})-[:就职于]->(o:公司{名称:"腾讯"}) } AS result;      | false  |
       | MATCH (n:人{姓名:"张文"}) RETURN EXISTS { (n)-[:籍贯]->({名称:"成都"}) } AS result; | true   |

# ===================== 6. 值类型谓词测试 =====================
   Scenario Outline: type-predicate-all-types-数据类型校验
     When executing queries without error:
       """
       <GQL>
       """
     Then the result should be, in any order:
       | result   |
       | <result> |
     Examples:
       | GQL                                                                       | result |
       | MATCH (n:人{姓名:"李明"}) RETURN n.年龄 IS TYPED INT32 AS result;                | true   |
       | MATCH (n:人{姓名:"周萌"}) RETURN n.性别 IS TYPED BOOL AS result;                 | true   |
       | MATCH (n:人{姓名:"李明"})-[:就读于]->(m) RETURN m IS TYPED NODE AS result;        | true   |
       | MATCH (n:人{姓名:"李明"}) RETURN n.姓名 IS TYPED STRING AS result;               | true   |
       | MATCH (n:人{姓名:"李明"})-[:就读于]->(m) RETURN m.创办时间 IS TYPED STRING AS result; | true   |

# ===================== 7. 业务场景查询测试（扩展） =====================
   Scenario Outline: business-query-person-籍贯+就读+就职关联
     When executing queries without error:
       """
       <GQL>
       """
     Then the result should be, in any order:
       | 姓名     | 籍贯     | 就读学校     | 就职公司      |
       | <name> | <city> | <school> | <company> |
     Examples:
       | GQL                                                                                                                                 | name | city | school | company |
       | MATCH (n:人)-[:籍贯]->(c), (n)-[:就读于]->(s), (n)-[:就职于]->(o) WHERE n.姓名="李明" RETURN n.姓名 AS 姓名, c.名称 AS 籍贯, s.名称 AS 就读学校, o.名称 AS 就职公司; | 李明   | 深圳   | 华中科技大学 | 百度      |
       | MATCH (n:人)-[:籍贯]->(c), (n)-[:就读于]->(s) WHERE n.姓名="周萌" RETURN n.姓名 AS 姓名, c.名称 AS 籍贯, s.名称 AS 就读学校, "" AS 就职公司;                    | 周萌   | 成都   | 华中科技大学 | 百度      |
