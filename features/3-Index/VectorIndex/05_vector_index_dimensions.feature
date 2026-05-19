# encoding: utf-8

@index @ddl
Feature: VectorIndex-Dimensions-Validation

  Scenario Outline: [1] VecIndex-validDimension-<dim>
    Given an empty graph
    And having executed:
      """
      create label DimNode (embedding LIST null);
      """
    When executing query:
      """
      CREATE VECTOR INDEX idx_dim_<dim> FOR (n:DimNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: <dim>, `vector.similarity_function`: 'cosine'}};
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_dim_<dim>" should exist

    Examples:
      | dim  |
      | 1    |
      | 2    |
      | 3    |
      | 4    |
      | 8    |
      | 16   |
      | 32   |
      | 64   |
      | 128  |
      | 256  |
      | 512  |
      | 1536 |

  Scenario: [2] VecIndex-dimensionMismatch-insertWrongDimVector
    Given an empty graph
    And having executed:
      """
      create label DimNode (embedding LIST null, category string null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_dim_mismatch FOR (n:DimNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 3, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      CREATE (n:DimNode {embedding: [1.0, 2.0], category: 'wrong_dim'});
      """
    Then the result should be, in any order:
      | n.category   |
      | 'wrong_dim'  |

  Scenario: [3] VecIndex-queryWithWrongDimensionVector
    Given an empty graph
    And having executed:
      """
      create label DimNode (embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_dim_qcheck FOR (n:DimNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 3, `vector.similarity_function`: 'cosine'}};
      """
    And having executed:
      """
      CREATE (n:DimNode {embedding: [1.0, 0.0, 0.0]});
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_dim_qcheck', 1, [1.0, 0.0]) YIELD node, score RETURN score;
      """
    Then an error should be raised

  Scenario Outline: [4] VecIndex-similarityFunction-<simFunc>-query
    Given an empty graph
    And having executed:
      """
      create label SimNode (embedding LIST null, name string null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_sim_<simFunc> FOR (n:SimNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 2, `vector.similarity_function`: '<simFunc>'}};
      """
    And having executed:
      """
      CREATE (n:SimNode {embedding: [1.0, 0.0], name: 'target'});
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_sim_<simFunc>', 1, [1.0, 0.0]) YIELD node, score RETURN node.name AS name, score;
      """
    Then the result should not be empty

    Examples:
      | simFunc   |
      | cosine    |
      | euclidean |
