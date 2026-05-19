# encoding: utf-8
# 非严格模式：通过 CREATE 关系隐式创建 RelationshipType 和属性。

@index @ddl
Feature: Relationship index create, drop and query

  Scenario: [1] Rel-Create unique index and verify exists
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {name: 'p1'})-[:KNOWS {since: 2000, weight: 0.0}]->(:Person {name: 'p2'})
      """
    When executing query:
      """
      CREATE INDEX idx_rel_unique FOR ()-[r:KNOWS]-() ON (r.since) OPTIONS {indexConfig: {unique: TRUE}};
      """
    Then the result should be empty
    And the side effects should be:
      | +indexes | 1 |
    And the index "idx_rel_unique" should exist

  Scenario: [2] Rel-Create non-unique index and verify exists
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {name: 'p1'})-[:KNOWS {since: 2000, weight: 0.0}]->(:Person {name: 'p2'})
      """
    When executing query:
      """
      CREATE INDEX idx_rel_non FOR ()-[r:KNOWS]-() ON (r.weight);
      """
    Then the result should be empty
    And the side effects should be:
      | +indexes | 1 |
    And the index "idx_rel_non" should exist

  Scenario: [3] Rel-Drop index and verify not exist
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {name: 'p1'})-[:KNOWS {since: 2000, weight: 0.0}]->(:Person {name: 'p2'})
      """
    And having executed:
      """
      CREATE INDEX idx_drop_test FOR ()-[r:KNOWS]-() ON (r.weight);
      """
    When executing query:
      """
      DROP INDEX idx_drop_test;
      """
    Then the result should be empty
    And the side effects should be:
      | -indexes | 1 |
    And the index "idx_drop_test" should not exist

  Scenario: [4] Rel-Query through indexed property
    Given an empty graph
    And having executed:
      """
      CREATE (a:Person {name: 'Alice'})-[:KNOWS {since: 2020, weight: 0.8}]->(b:Person {name: 'Bob'})
      """
    And having executed:
      """
      CREATE (c:Person {name: 'Carol'})-[:KNOWS {since: 2021, weight: 0.6}]->(d:Person {name: 'Dave'})
      """
    And having executed:
      """
      CREATE INDEX idx_since FOR ()-[r:KNOWS]-() ON (r.since);
      """
    When executing query:
      """
      MATCH (a)-[r:KNOWS {since: 2020}]->(b) RETURN a.name, b.name
      """
    Then the result should be, in any order:
      | a.name  | b.name |
      | 'Alice' | 'Bob'  |
    And no side effects

  Scenario: [5] Rel-Range query on indexed property
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {name: 'A'})-[:KNOWS {since: 2019, weight: 0.3}]->(:Person {name: 'B'})
      """
    And having executed:
      """
      CREATE (:Person {name: 'C'})-[:KNOWS {since: 2020, weight: 0.7}]->(:Person {name: 'D'})
      """
    And having executed:
      """
      CREATE (:Person {name: 'E'})-[:KNOWS {since: 2021, weight: 0.9}]->(:Person {name: 'F'})
      """
    And having executed:
      """
      CREATE INDEX idx_weight FOR ()-[r:KNOWS]-() ON (r.weight);
      """
    When executing query:
      """
      MATCH (a)-[r:KNOWS]->(b) WHERE r.weight >= 0.7 RETURN a.name ORDER BY a.name
      """
    Then the result should be, in order:
      | a.name |
      | 'C'    |
      | 'E'    |
    And no side effects

  Scenario: [6] Rel-Unique index rejects duplicate value
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {name: 'A'})-[:LIKES {since: 2020}]->(:Person {name: 'B'})
      """
    And having executed:
      """
      CREATE INDEX idx_uniq_since FOR ()-[r:LIKES]-() ON (r.since) OPTIONS {indexConfig: {unique: TRUE}};
      """
    When executing query:
      """
      CREATE (:Person {name: 'C'})-[:LIKES {since: 2020}]->(:Person {name: 'D'})
      """
    Then a ConstraintValidationFailed should be raised at runtime
    And no side effects

  Scenario: [7] Rel-Undirected pattern query hits index
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {name: 'A'})-[:FRIEND {level: 1}]->(:Person {name: 'B'})
      """
    And having executed:
      """
      CREATE (:Person {name: 'C'})-[:FRIEND {level: 2}]->(:Person {name: 'D'})
      """
    And having executed:
      """
      CREATE INDEX idx_friend_level FOR ()-[r:FRIEND]-() ON (r.level);
      """
    When executing query:
      """
      MATCH ()-[r:FRIEND]-() WHERE r.level = 1 RETURN r.level AS level
      """
    Then the result should be, in any order:
      | level |
      | 1     |
    And no side effects

  Scenario: [8] Rel-DROP non-existent index raises error
    Given an empty graph
    When executing query:
      """
      DROP INDEX idx_not_exist;
      """
    Then a EntityNotFound should be raised at runtime
    And the error should contain:
      """
      does not exist
      """
    And no side effects

  Scenario: [9] Rel-Index on NULL property
    Given an empty graph
    And having executed:
      """
      CREATE (:Person {name: 'A'})-[:WORKS_WITH {weight: 0.5}]->(:Person {name: 'B'})
      """
    And having executed:
      """
      CREATE (:Person {name: 'C'})-[:WORKS_WITH {weight: null}]->(:Person {name: 'D'})
      """
    And having executed:
      """
      CREATE INDEX idx_ww FOR ()-[r:WORKS_WITH]-() ON (r.weight);
      """
    When executing query:
      """
      MATCH ()-[r:WORKS_WITH]->() WHERE r.weight = 0.5 RETURN r.weight AS w
      """
    Then the result should be, in any order:
      | w   |
      | 0.5 |
    And no side effects
