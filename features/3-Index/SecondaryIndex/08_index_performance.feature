# encoding: utf-8
# 非严格模式：通过 CREATE 节点隐式创建 Label 和属性。

@index @performance
Feature: SecondaryIndex-Performance

  Scenario: [1] Index-performance-exactMatch-vs-fullScan
    Given an empty graph
    And having executed:
      """
      UNWIND range(1, 1000) AS i
      CREATE (:PerfNode {idx: i, name: 'name_' + i})
      """
    And having executed:
      """
      CREATE INDEX idx_perf_name FOR (n:PerfNode) ON (n.name);
      """
    When executing query:
      """
      MATCH (n:PerfNode {name: 'name_500'}) RETURN n.idx AS idx
      """
    Then the result should be, in any order:
      | idx |
      | 500 |
    And the plan of query should contain "NodeIndexSeek":
      """
      MATCH (n:PerfNode {name: 'name_500'}) RETURN n.idx AS idx
      """

  Scenario: [2] Index-performance-rangeQuery-withIndex
    Given an empty graph
    And having executed:
      """
      UNWIND range(1, 1000) AS i
      CREATE (:PerfRange {idx: i})
      """
    And having executed:
      """
      CREATE INDEX idx_perf_idx FOR (n:PerfRange) ON (n.idx);
      """
    When executing query:
      """
      MATCH (n:PerfRange) WHERE n.idx > 990 RETURN n.idx AS idx ORDER BY n.idx
      """
    Then the result should be, in order:
      | idx |
      | 991 |
      | 992 |
      | 993 |
      | 994 |
      | 995 |
      | 996 |
      | 997 |
      | 998 |
      | 999 |
      | 1000 |
    And the plan of query should contain "NodeIndexSeekByRange":
      """
      MATCH (n:PerfRange) WHERE n.idx > 990 RETURN n.idx AS idx ORDER BY n.idx
      """

  Scenario: [3] Index-performance-compositeIndex-advantage
    Given an empty graph
    And having executed:
      """
      UNWIND range(1, 500) AS i
      CREATE (:PerfComp {first: 'group_' + (i % 10), second: i})
      """
    And having executed:
      """
      CREATE INDEX idx_perf_comp FOR (n:PerfComp) ON (n.first, n.second);
      """
    When executing query:
      """
      MATCH (n:PerfComp) WHERE n.first = 'group_5' AND n.second > 45 RETURN n.second AS second ORDER BY n.second
      """
    Then the result should not be empty
    And the plan of query should contain "NodeIndexSeekByRange":
      """
      MATCH (n:PerfComp) WHERE n.first = 'group_5' AND n.second > 45 RETURN n.second AS second ORDER BY n.second
      """

  Scenario: [4] Index-performance-relIndex-traversal
    Given an empty graph
    And having executed:
      """
      UNWIND range(1, 100) AS i
      CREATE (:PerfA {id: i})-[:PERF_REL {weight: i * 0.1}]->(:PerfB {id: i})
      """
    And having executed:
      """
      CREATE INDEX idx_perf_rel FOR ()-[r:PERF_REL]->() ON (r.weight);
      """
    When executing query:
      """
      MATCH ()-[r:PERF_REL]->() WHERE r.weight > 9.0 RETURN r.weight AS w ORDER BY w
      """
    Then the result should not be empty
    And the plan of query should contain "RelationshipIndexSeekByRange":
      """
      MATCH ()-[r:PERF_REL]->() WHERE r.weight > 9.0 RETURN r.weight AS w ORDER BY w
      """

  @ignore
  @todo-ldbc
  Scenario: [5] Index-performance-ldbc-exactMatch-vs-fullScan
    Given an empty graph
    And having executed:
      """
      CREATE INDEX idx_person_firstName FOR (n:Person) ON (n.firstName);
      """
    When executing query:
      """
      MATCH (n:Person {firstName: 'Alice'}) RETURN n.firstName, n.lastName
      """
    Then the result should not be empty

  @ignore
  @todo-ldbc
  Scenario: [6] Index-performance-ldbc-indexHitRate-verify
    Given an empty graph
    And having executed:
      """
      CREATE INDEX idx_person_lastName FOR (n:Person) ON (n.lastName);
      """
    When executing query:
      """
      PROFILE MATCH (n:Person) WHERE n.lastName = 'Smith' RETURN count(n) AS cnt
      """
    Then the result should not be empty
