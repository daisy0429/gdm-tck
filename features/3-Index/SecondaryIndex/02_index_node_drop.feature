# encoding: utf-8
# 非严格模式：通过 CREATE 节点隐式创建 Label 和属性。

@index @ddl
Feature: drop node index

  Scenario: [1] Node-Drop existing index
    Given an empty graph
    And having executed:
      """
      CREATE (:A {name: 'init'})
      """
    And having executed:
      """
      CREATE INDEX idx_a_name FOR (n:A) ON (n.name);
      """
    When executing query:
      """
      DROP INDEX idx_a_name;
      """
    Then the side effects should be:
      | -indexes | 1 |
    And the index "idx_a_name" should not exist

  Scenario: [2] Node-Drop non-existing index with IF EXISTS
    Given an empty graph
    When executing query:
      """
      DROP INDEX non_exist_idx IF EXISTS;
      """
    Then no side effects

  Scenario: [3] Node-Drop non-existing index without IF EXISTS
    Given an empty graph
    When executing query:
      """
      DROP INDEX non_exist_idx;
      """
    Then a EntityNotFound should be raised at runtime
    And the error should contain:
      """
      does not exist
      """
    And no side effects

  Scenario: [4] Node-Drop index then verify not exist
    Given an empty graph
    And having executed:
      """
      CREATE (:D {score: 0})
      """
    And having executed:
      """
      CREATE INDEX idx_d_score FOR (n:D) ON (n.score);
      """
    When executing query:
      """
      DROP INDEX idx_d_score IF EXISTS;
      """
    Then the side effects should be:
      | -indexes | 1 |
    And the index "idx_d_score" should not exist

  Scenario: [5] Node-Drop already-dropped index with IF EXISTS
    Given an empty graph
    And having executed:
      """
      CREATE (:E {val: 'x'})
      """
    And having executed:
      """
      CREATE INDEX idx_e_val FOR (n:E) ON (n.val);
      """
    And having executed:
      """
      DROP INDEX idx_e_val;
      """
    When executing query:
      """
      DROP INDEX idx_e_val IF EXISTS;
      """
    Then no side effects

  Scenario: [6] Node-Drop index does not affect data
    Given an empty graph
    And having executed:
      """
      CREATE (:DataNode {name: 'Alice', age: 30})
      """
    And having executed:
      """
      CREATE INDEX idx_data_name FOR (n:DataNode) ON (n.name);
      """
    When executing query:
      """
      DROP INDEX idx_data_name;
      """
    Then the side effects should be:
      | -indexes | 1 |
    And the index "idx_data_name" should not exist
    When executing query:
      """
      MATCH (n:DataNode) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |

  Scenario: [7] Node-Drop unique index then allow duplicate values
    Given an empty graph
    And having executed:
      """
      CREATE (:UniqDrop {code: 'alpha'})
      """
    And having executed:
      """
      CREATE INDEX idx_ud_code FOR (n:UniqDrop) ON (n.code) OPTIONS {indexConfig: {unique: TRUE}};
      """
    When executing query:
      """
      DROP INDEX idx_ud_code;
      """
    Then the side effects should be:
      | -indexes | 1 |
    When executing query:
      """
      CREATE (n:UniqDrop {code: 'alpha'}) RETURN n.code;
      """
    Then the result should be, in any order:
      | n.code  |
      | 'alpha' |
    And the side effects should be:
      | +nodes      | 1 |
      | +properties | 1 |
