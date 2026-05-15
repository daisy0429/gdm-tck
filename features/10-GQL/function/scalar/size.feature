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
      | GQL | result |
      | LET x = SIZE('12345') RETURN x; | 5 |
      | LET x = SIZE('') RETURN x; | 0 |
      | LET x = SIZE(null) RETURN x; | null |
      | LET x = SIZE([1, 2, 3, 4, 5]) RETURN x; | 5 |
      | LET x = SIZE([]) RETURN x; | 0 |
      | LET x = SIZE([null, null]) RETURN x; | 2 |
      | LET x = SIZE([1, 'abc', true]) RETURN x; | 3 |


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
      | GQL | error |
      | LET x = SIZE(123) RETURN x; | Type mismatch: expected List<Any> or String but was Integer |
      | LET x = SIZE(true) RETURN x; | Type mismatch: expected List<Any> or String but was Boolean |
      | LET x = SIZE({key: 'value'}) RETURN x; | Type mismatch: expected List<Any> or String but was Map |
      | MATCH p = (a:Person)-[*]->(c:Person) RETURN size(p) AS path_length; | Type mismatch: expected List<Any> or String but was Path |
