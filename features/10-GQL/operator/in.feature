#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/syntax/operators/#query-operators-boolean
#列表操作符

Feature: in

  Scenario Outline: in-operator-positive-cases
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | RETURN 'Neo4j' IN ['Neo4j', 'Graph'] AS x; | true |
      | return 123 IN [123, 456] as x; | true |
      | return 789 IN [123, 456] as x; | false |
      | return 'Test' IN ['Neo4j', 'Graph'] as x; | false |
      | RETURN [2, 1] IN [1, [2, 1], 3] AS x; | true |
      | RETURN [0, 2] IN [[1, 2], [3, 4]] AS x; | false |
      | return NULL IN ['Neo4j', 'Graph']  as x; | null |
      | RETURN [1, 2] IN [1, 2] AS x | false |

  Scenario: When null is involved in a membership check, the result is will be null-bug7436
    When executing queries without error:
      """
    RETURN null IN [1, 2, null] AS nullInList, 123 IN null AS valueInNull
    """
    Then the result should be, in any order:
      | nullInList | valueInNull |
      | null       | null        |

  Scenario: When null is involved in a membership check, the result is will be null-bug7436
    When executing queries without error:
      """
    RETURN null IN [1, 2, null] AS nullInList, 123 IN null AS valueInNull
    """
    Then the result should be, in any order:
      | nullInList | valueInNull |
      | null       | null        |

  Scenario: Checking if null is a member of a LIST using any()
    Given an empty graph
    When executing queries without error:
      """
      RETURN any(x IN [1, 2, null] WHERE x IS NULL) AS containsNull
      """
    Then the result should be, in any order:
      | containsNull |
      | true         |

  Scenario: in-operator-negative-cases-bug7436
    When executing queries without error:
      """
  return 'Neo4j' IN NULL as x;
  """
    Then the result should be, in any order:
      | x  |
      | null |