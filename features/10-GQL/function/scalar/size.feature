#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/functions/scalar/#functions-size
#参数：expected STRING | LIST<ANY>
#https://neo4j.com/docs/cypher-manual/current/functions/scalar/#functions-length
#参数：expected PATH

Feature: size

  Scenario Outline: size(string|list) - positive-cases - bug5507
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                      | result | 备注                   |
      | LET x = SIZE('12345') RETURN x;          | 5      | 计算字符串的字符数            |
      | LET x = SIZE('') RETURN x;               | 0      | 空字符串返回 0             |
      | LET x = SIZE(null) RETURN x;             | null   | 空字符串返回 0             |
      | LET x = SIZE([1, 2, 3, 4, 5]) RETURN x;  | 5      | 计算列表元素数量             |
      | LET x = SIZE([]) RETURN x;               | 0      | 空列表返回 0              |
      | LET x = SIZE([null, null]) RETURN x;     | 2      | 列表中的 `null` 元素也被计入长度 |
      | LET x = SIZE([1, 'abc', true]) RETURN x; | 3      | 列表中混合类型元素的数量         |


  Scenario: size(path)
    Given an empty graph
    And having executed:
      """
      CREATE (a:Person {name: "Alice"})-[:KNOWS]->(b:Person {name: "Bob"})-[:KNOWS]->(c:Person {name: "Charlie"});
      """
    And having executed:
      """
      MATCH (a) WHERE a.name = 'Alice' RETURN size([p=(a)-->()-->() | p]) AS fof
      """
    Then the result should be, in any order:
      | fof |
      | 1   |

  Scenario: size(list)
    Given an empty graph
    And having executed:
      """
      CREATE (a:Person {name: "Alice"})-[:KNOWS]->(b:Person {name: "Bob"})-[:KNOWS]->(c:Person {name: "Charlie"});
      """
    And having executed:
      """
      RETURN SIZE([item IN [{key: 'value'}] | item.key]) AS x;
      """
    Then the result should be, in any order:
      | x |
      | 1 |


  Scenario Outline: size-negative-cases
    When executing queries:
    """
    CREATE (a:Person {name: "Alice"})-[:KNOWS]->(b:Person {name: "Bob"})-[:KNOWS]->(c:Person {name: "Charlie"});
    """
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                                                                 | error                                                       | 备注                    |
      | LET x = SIZE(123) RETURN x;                                         | Type mismatch: expected List<Any> or String but was Integer | 不支持的类型（整数）            |
      | LET x = SIZE(true) RETURN x;                                        | Type mismatch: expected List<Any> or String but was Boolean | 不支持的类型（布尔值）           |
      | LET x = SIZE({key: 'value'}) RETURN x;                              | Type mismatch: expected List<Any> or String but was Map             | 不支持的类型（Map 对象）        |
      | MATCH p = (a:Person)-[*]->(c:Person) RETURN size(p) AS path_length; | Type mismatch: expected List<Any> or String but was Path    | 此处应该用length(p)而不是size |
