#encoding: utf-8
#GQL’s ELEMENT_ID() function is equivalent to Cypher’s elementId() function.
#https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/analogous-cypher/
#https://neo4j.com/docs/cypher-manual/current/functions/scalar/#functions-elementid
#gdmbase中等价于id(n);

Feature: ELEMENT_ID

  Scenario Outline: element_id 正向用例-bug5506
    When executing queries without error:
      """
    CREATE (:Person {name: 'user1'});
    CREATE (:Movie {title: 'movie1'});
    MATCH (p:Person {name: 'user1'}), (m:Movie {title: 'movie1'}) CREATE (p)-[:ACTED_IN]->(m);
    """
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should not be empty
    Examples:
      | GQL |
      | match (n:Person {name: 'user1'}) RETURN element_id(n); |
      | match (n:Person)-[r:ACTED_IN]->(m:Movie) RETURN element_id(r) AS id; |
      | match (n) where ELEMENT_ID(n) is not null return n; |
      | return ELEMENT_ID(null); |
      | match (n:Person {name: 'user1'}) LET x = ELEMENT_ID(n) RETURN x; |
      | match (n:Person)-[r:ACTED_IN]->(m:Movie) LET x = ELEMENT_ID(r) RETURN x; |
      | match (n:Person)-[r:ACTED_IN]->(m:Movie) LET x = Element_id(r) RETURN x; |


  Scenario Outline: element_id(null)-bug5506
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x    |
      | null |
    Examples:
      | GQL |
      | return ELEMENT_ID(null) as x; |

  Scenario Outline: element_id-异常参数
    When executing queries without error:
      """
    CREATE (:Person {name: 'user1'});
    CREATE (:Movie {title: 'movie1'});
    MATCH (p:Person {name: 'user1'}), (m:Movie {title: 'movie1'}) CREATE (p)-[:ACTED_IN]->(m);
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
      | match (n:Person {name: 'user1'}) LET x = ELEMENT_ID(n.name) RETURN x; | Type mismatch: expected Node or Relationship but was |
      | match (n:Person)-[r:ACTED_IN]->(m:Movie) LET x = ELEMENT_ID(r.title) RETURN x; | Type mismatch: expected Node or Relationship but was |
      | RETURN element_Id("string_value") AS result; | Type mismatch: expected Node or Relationship but was String |
      | RETURN element_Id(42) AS result; | Type mismatch: expected Node or Relationship but was Integer |
      | RETURN element_Id([1, 2, 3]) AS result; | Type mismatch: expected Node or Relationship but was List<Integer> |


