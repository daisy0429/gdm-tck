#encoding: utf-8
#http://10.13.4.249:8090/display/GSQL/FILTER：FILTER (whereClause | searchCondition)
#https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/analogous-cypher/
#Selects a subset of the records of the current working table. Cypher uses WITH instead.
#todo test:数据类型？
#  todo test: filter where+子句
#  todo test:filter <search condition各种条件、操作符>

Feature: filter

  Background:
    Given an empty graph
    And executing queries without error:
     """
    CREATE (:Person{name: 'Alice', age: 18});
    CREATE (:Person{name: 'Bob', age: 19});
    CREATE (:Person{name: 'Tom', age: 20});
    match (m:Person{name: 'Alice'}),(n:Person{name: 'Bob'}) create (m)-[:FRIEND{since:2020,strength:6}]->(m);
    match (m:Person{name: 'Alice'}),(n:Person{name: 'Tom'}) create (m)-[:FRIEND{since:2021}]->(m);
    """
    And sleep (1)

  Scenario Outline: []filter冒烟测试
    When executing query without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                                                                                       | result                             | desc                       |
      | MATCH (n) FILTER n.age = 18 RETURN n.name as x;                                                                           | 'Alice'                            | 点属性等值查询filter              |
      | MATCH (n) FILTER where n.age = 18 RETURN n.name  as x ;                                                                   | 'Alice'                            | 点属性等值查询filter where        |
      | MATCH (p1)-[r:FRIEND]->(p2) FILTER r.since = 2020 RETURN r.since as x;                                                    | 2020                               | 边属性等值查询filter              |
      | MATCH (p1)-[r:FRIEND]->(p2) FILTER where r.since = 2020 RETURN r.since as x;                                              | 2020                               | 边属性等值查询 filter where       |
      | MATCH (p1)-[r:FRIEND]->(p2) FILTER r.since > 2020 RETURN r.since as x;                                                    | 2021                               | 边属性>查询                     |
      | MATCH (n:Person) FILTER n.age % 2 = 0 RETURN collect(n.name) as x;                                                        | ['Tom', 'Alice']                   | filter运算符支持%               |
      | MATCH (n) FILTER n.age = 18 FILTER n.name = 'Alice' RETURN n as x;                                                        | (:Person {age: 18, name: 'Alice'}) | 多filter子句                  |
      | FOR i IN [1, 2, 3] FILTER i = 1 RETURN i as x;                                                                            | 1                                  | for+filter                 |
      | FOR i IN [1, 2, 3] FILTER (i = 1) OR (i = 2) RETURN collect(i) as x;                                                      | [1, 2]                             | filter逻辑操作符or              |
      | MATCH (n) FILTER n.age = 18 WITH n MATCH (m) FILTER m.name = 'Tom' RETURN n.name as x;                                    | 'Alice'                            | filter + with +match       |
#      | MATCH (n:Person) FILTER n.age = 18 WITH n MATCH (m:Person) FILTER m.name = 'Alice' RETURN collect([n.name, m.name]) as x; | ['Alice']                          | filter + with +match       |
      | MATCH (n:Person) FILTER false RETURN collect(n.name) as x;                                                                | []                                 | filterFalse空条件验证           |
      | MATCH (n) FILTER n.nonexistentField = 18 RETURN collect(n) as x;                                                          | []                                 | filter查询结果为空               |
      | MATCH (p1)-[r:FRIEND]->(p2) FILTER (r.since = 2020) AND (r.strength > 5) RETURN r.since as x;                             | 2020                               | 边的多个属性上使用FILTER（AND 逻辑运算符） |
      | MATCH (p1)-[r:FRIEND]->(p2) FILTER (r.since = 2020) AND (r.strength > 5) RETURN r.since as x;                             | 2020                               | 边的多个属性上使用FILTER（AND 逻辑运算符） |
      | MATCH (p1)-[r:FRIEND]->(p2) FILTER r.since = 2020 OR r.strength > 7 RETURN p1.name as x;                                  | 'Alice'                            | 在边的属性上使用FILTER（OR 逻辑运算符）   |
      | MATCH (p1)-[r:FRIEND]->(p2) FILTER r.since = 2020 FILTER r.strength > 2 RETURN r.since as x;                              | 2020                               | 边上多个flter                  |
      | MATCH (p1)-[r:FRIEND]->(p2) FILTER r.since = 2020 WITH p1, p2, r MATCH (p3) WHERE p3.age > 19 RETURN r.strength as x;     | 6                                  | 在边的属性上使用FILTER和WITH结合      |

  Scenario Outline: []FILTER多条件逻辑操作验证（And/OR）-bug5353,bug5524
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | MATCH (n) FILTER (n.age = 18 OR n.age = 19) RETURN collect(n.name) as x; | ['Bob', 'Alice'] |
      | MATCH (n) FILTER (n.age = 18 OR n.nonexistentField = 1) RETURN n.name as x; | 'Alice' |
      | MATCH (p:Person)-[r:FRIEND]->(p) filter r.since = 2020 OR r.since = 2021 RETURN collect(p.name) as x; | ['Alice', 'Alice'] |
      | MATCH (n) FILTER (n.age = 18 AND n.name = 'Alice') RETURN n.name as x; | 'Alice' |
      | MATCH (p:Person)-[r:FRIEND]->(p) filter r.since = 2020 AND p.age = 18 RETURN p.name as x; | 'Alice' |
      | MATCH (p:Person)-[r:FRIEND]->(p) WHERE (r.since = 2020 AND p.age = 18) OR (r.since = 2021 AND p.age > 18) RETURN p.name as x; | 'Alice' |
#      | MATCH (n:Person) filter WHERE n.age > 18 AND (n.name =~ 'A.*' OR n.name =~ 'T.*') RETURN n.name as x;                         | 'Tom               |
#      | MATCH (n:Person) FIlTER WHERE n.age > 17 AND n.name =~ 'A.*' return n.name as x;                                              | 'Alice'            |  bug5524,neo4j也未支持       |
      | MATCH (n) FILTER ((n.age = 18 OR n.age = 19) AND n.name = 'Alice') RETURN n.name as x;                                        | 'Alice' |

  Scenario: []多个MATCH和多个FILTER的验证
    When executing query without error:
      """
      MATCH (n) FILTER (n.age = 18) FILTER (n.name = 'Alice') MATCH (m) FILTER (m.age = 20) FILTER (m.name = 'Tom') RETURN n,m;
      """
    Then the result should be, in any order:
      | n                                  | m                                |
      | (:Person {age: 18, name: 'Alice'}) | (:Person {age: 20, name: 'Tom'}) |

  Scenario: []filter true空条件
    When executing query without error:
      """
      MATCH (n:Person) FILTER TRUE RETURN n.name
      """
    Then the result should be, in any order:
      | n.name  |
      | 'Alice' |
      | 'Bob'   |
      | 'Tom'   |

  Scenario Outline: filter-negative-cases
    When executing queries:
      """
  <GQL>
  """
    Then the error should be contain:
      """
  <error>
  """
    Examples:
      | GQL | error |
      | MATCH (n) FILTER n.age > RETURN n; | [2700]Invalid input |
      | MATCH (n) FILTER () RETURN n; | [2700]Invalid input |

