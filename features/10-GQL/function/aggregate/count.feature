#encoding: utf-8

Feature: COUNT

  Scenario Outline: count-positive-cases
    Given an empty graph
    When  executing queries without error:
      """
    CREATE (:Person {name: 'Alice', age: 25,list: [1, 2, 3]});
    CREATE (:Person {name: 'Bob', age: 30,list: [3]});
    CREATE (:Animal {species: 'Cat', name: 'Kitty'});
    CREATE (:Animal {species: 'Dog'});
      """
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | MATCH (n) RETURN COUNT(n) as x; | 4 |
      | MATCH (n) RETURN COUNT(n.age) as x; | 2 |
      | MATCH (n) RETURN COUNT(n.list) AS x; | 2 |
      | MATCH (n) RETURN COUNT(n.notExist) AS x; | 0 |
      | UNWIND [DURATION('P1DT2H'), DURATION('P2DT4H'), DURATION('P3DT6H')] AS m LET x = COUNT(ALL m) RETURN x; | 3 |
      | UNWIND [DURATION('P1DT2H'), null, DURATION('P3DT6H')] AS m LET x = COUNT(ALL m) RETURN x; | 2 |
      | UNWIND [] AS m LET x = COUNT(ALL m) RETURN x; | 0 |
  Scenario Outline: count-negative-cases
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
      | MATCH (n:Unknown) RETURN COUNT(n) as x; | [1613]Label does not exist. Label name: 'Unknown' |