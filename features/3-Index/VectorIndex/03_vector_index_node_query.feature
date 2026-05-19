# encoding: utf-8

@index @ddl
Feature: VectorIndex-Node-Query

  Background:
    Given an empty graph
    And having executed:
      """
      create label VecNode (embedding LIST null, category string null);
      """

  Scenario: [1] VecNode-vectorQuery-topK-cosine
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_q FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 3, `vector.similarity_function`: 'cosine'}};
      """
    And having executed:
      """
      CREATE (n:VecNode {embedding: [1.0, 0.0, 0.0], category: 'a'});
      CREATE (n:VecNode {embedding: [0.0, 1.0, 0.0], category: 'b'});
      CREATE (n:VecNode {embedding: [0.9, 0.1, 0.0], category: 'c'});
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_vec_q', 2, [1.0, 0.0, 0.0]) YIELD node, score RETURN node.category AS cat, score ORDER BY score DESC;
      """
    Then the result count should be [2]
    And the result should contain:
      | cat  |
      | 'a'  |
      | 'c'  |

  Scenario: [2] VecNode-vectorQuery-topK-euclidean
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_euc FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 2, `vector.similarity_function`: 'euclidean'}};
      """
    And having executed:
      """
      CREATE (n:VecNode {embedding: [0.0, 0.0], category: 'origin'});
      CREATE (n:VecNode {embedding: [3.0, 4.0], category: 'far'});
      CREATE (n:VecNode {embedding: [1.0, 1.0], category: 'near'});
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_vec_euc', 2, [0.0, 0.0]) YIELD node, score RETURN node.category AS cat ORDER BY cat;
      """
    Then the result should be, in order:
      | cat      |
      | 'near'   |
      | 'origin' |

  Scenario: [3] VecNode-vectorQuery-topK1-singleResult
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_k1 FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 2, `vector.similarity_function`: 'cosine'}};
      """
    And having executed:
      """
      CREATE (n:VecNode {embedding: [1.0, 0.0], category: 'x'});
      CREATE (n:VecNode {embedding: [0.0, 1.0], category: 'y'});
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_vec_k1', 1, [0.99, 0.01]) YIELD node, score RETURN node.category AS cat;
      """
    Then the result count should be [1]
    And the result should contain:
      | cat |
      | 'x' |

  Scenario Outline: [4] VecNode-vectorQuery-scoreNotZero-<simFunc>
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_score_<simFunc> FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 3, `vector.similarity_function`: '<simFunc>'}};
      """
    And having executed:
      """
      CREATE (n:VecNode {embedding: [1.0, 2.0, 3.0], category: 'target'});
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_vec_score_<simFunc>', 1, [1.0, 2.0, 3.0]) YIELD node, score RETURN node.category AS cat, score;
      """
    Then the result should not be empty

    Examples:
      | simFunc   |
      | cosine    |
      | euclidean |

  Scenario: [5] VecNode-vectorQuery-noIndexFallsBack
    When executing query:
      """
      MATCH (n:VecNode) WHERE n.embedding = [1.0, 0.0] RETURN n.category AS cat;
      """
    Then the result should be empty
    And no side effects

  Scenario: [6] VecNode-vectorQuery-insertAfterIndexCreation
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_late FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 2, `vector.similarity_function`: 'cosine'}};
      """
    And having executed:
      """
      CREATE (n:VecNode {embedding: [1.0, 0.0], category: 'first'});
      """
    And having executed:
      """
      CREATE (n:VecNode {embedding: [0.5, 0.5], category: 'second'});
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_vec_late', 10, [1.0, 0.0]) YIELD node, score RETURN node.category AS cat ORDER BY cat;
      """
    Then the result should be, in order:
      | cat      |
      | 'first'  |
      | 'second' |
