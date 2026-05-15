#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/clauses/union/
#Composite query: UNION

Feature: union

  Background:
    Given an empty graph
    And executing queries without error:
     """
    UNWIND ['Alice', 'Bob', 'Carol', 'David'] AS name CREATE (:Person {name: name});
    UNWIND [1, 2, 3, 4, 5] AS num CREATE (:Number {value: num});
    """
    And sleep (1)

  Scenario: union
    When executing queries without error:
      """
    UNWIND [1, 2] AS x RETURN x UNION UNWIND [2,3] AS x RETURN x;
    """
    Then the result should be, in any order:
      | x |
      | 1 |
      | 2 |
      | 3 |

  Scenario: union different types
    When executing queries without error:
      """
    UNWIND [1] AS x RETURN x AS num UNION UNWIND ['a'] AS x RETURN x AS num;
    """
    Then the result should be, in any order:
      | num |
      | 1   |
      | 'a' |

  Scenario: union all
    When executing queries without error:
      """
    UNWIND [1, 2] AS x RETURN x UNION ALL UNWIND [2,3] AS x RETURN x;
    """
    Then the result should be, in any order:
      | x |
      | 1 |
      | 2 |
      | 2 |
      | 3 |

  Scenario Outline: union-clause-negative-cases
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
      | MATCH (p:Person) RETURN p.name AS name UNION MATCH (n:Number) RETURN n; | All sub queries in an UNION must have the same column names |
      | UNWIND [1, 2, 3] AS x RETURN x UNION UNWIND ['a', 'b', 'c'] AS x RETURN x, "extra_column"; | All sub queries in an UNION must have the same column names |
      | UNWIND [1, 2, 3] AS x RETURN x AS num UNION UNWIND [3, 4, 5] AS x RETURN x AS value; | All sub queries in an UNION must have the same column names |
