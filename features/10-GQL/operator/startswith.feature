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
      | GQL                                      | result | 备注                    |
      | return 'Neo4j' STARTS WITH 'Neo' as x;   | true   | 字符串以指定前缀开头，应返回 true   |
      | return 'Neo4j' STARTS WITH 'Graph' as x; | false  | 字符串不以指定前缀开头，应返回 false |
      | return '' STARTS WITH '' as x;           | true   | 空字符串以空字符串开头，应返回 true  |
      | return NULL STARTS WITH 'Neo' as x;      | null   | null                  |
      | return 'Neo4j' STARTS WITH NULL as x;    | null   | null                  |
      | return 'Neo4j' STARTS WITH 123 as x;     | null   | 非string               |
      | return 11 STARTS WITH '123' as x;        | null   | 非string               |


