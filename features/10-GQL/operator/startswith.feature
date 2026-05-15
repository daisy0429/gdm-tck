#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/syntax/operators/#query-operators-boolean
#字符串操作符

Feature: starts with

  Scenario Outline: starts-with-operator-positive-cases
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | return 'Neo4j' STARTS WITH 'Neo' as x; | true |
      | return 'Neo4j' STARTS WITH 'Graph' as x; | false |
      | return '' STARTS WITH '' as x; | true |
      | return NULL STARTS WITH 'Neo' as x; | null |
      | return 'Neo4j' STARTS WITH NULL as x; | null |
      | return 'Neo4j' STARTS WITH 123 as x; | null |
      | return 11 STARTS WITH '123' as x; | null |


