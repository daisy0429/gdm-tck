#encoding: utf-8

Feature: insert

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

  Scenario Outline: []insert冒烟测试
    When executing query without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                                                                                                | result   | desc            |
      | insert (a:Person{name:'Alice5', age:20}) return a.name as x;                                                                       | 'Alice5' | 插入顶点            |
      | insert (a:Person{name:'Alice5', age:20,weight:2.3}) return a.weight as x;                                                          | 2.3      | 插入顶点时添加不存在的属性字段 |
      | insert (a:Person2{name:'Alice', age:20}) return a.name as x;                                                                       | 'Alice'  | 插入顶点时使用不存在的标签模型 |
      | INSERT (a:Person2{name: "Alice6"})-[r:FRIEND{strength:6}]->(b:Person2 {name: "Alice7"}) return r.strength as x;                    | 6        | 插入路径            |
      | MATCH (a:Person {name: "Alice"}) ,(b:Person {name: "Bob"}) INSERT (a)-[r:FRIEND{strength:7}]->(b) return r.strength as x;          | 7        | 与match联用仅插入边    |
      | MATCH (a:Person {name: "Alice"}) ,(b:Person {name: "Bob"}) INSERT (a)-[r:FRIEND2{strength:7}]->(b) return r.strength as x;         | 7        | 插入边时使用不存在的标签模型  |
      | MATCH (a:Person {name: "Alice"}) ,(b:Person {name: "Bob"}) INSERT (a)-[r:FRIEND2{since:2021,strength:7}]->(b) return r.since as x; | 2021     | 插入边时使用不存在的属性字段  |


  Scenario Outline: []insert异常测试
    When executing query:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <result>
    """
    Examples:
      | GQL                                                  | result                                                       | desc  |
      | insert (a:Person{name:, age:20}) return a.name as x; | SyntaxError ([2700]Invalid input ',': at line 1, column 23.) | 缺少属性值 |

