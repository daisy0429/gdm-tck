# encoding: utf-8

@index @ddl
Feature: VectorIndex-Node-Create

  Background:
    Given an empty graph
    And having executed:
      """
      create label VecNode (embedding LIST null, category string null);
      """

  Scenario Outline: [1] VecNode-createVectorIndex-<simFunc>
    When executing query:
      """
      CREATE VECTOR INDEX idx_vec_<simFunc> FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: '<simFunc>'}};
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_vec_<simFunc>" should exist

    Examples:
      | simFunc    |
      | cosine     |
      | euclidean  |

  Scenario Outline: [2] VecNode-createVectorIndex-variousDimensions-<dim>
    When executing query:
      """
      CREATE VECTOR INDEX idx_vec_dim_<dim> FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: <dim>, `vector.similarity_function`: 'cosine'}};
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_vec_dim_<dim>" should exist

    Examples:
      | dim |
      | 2   |
      | 4   |
      | 8   |
      | 128 |
      | 256 |

  Scenario: [3] VecNode-createVectorIndex-ifNotExists-idempotent
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_idem FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      CREATE VECTOR INDEX idx_vec_idem IF NOT EXISTS FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    Then no side effects
    And the index "idx_vec_idem" should exist

  Scenario: [4] VecNode-createVectorIndex-thenInsertVectorData
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_insert FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 3, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      CREATE (n:VecNode {embedding: [0.1, 0.2, 0.3], category: 'test'}) RETURN n.category AS cat;
      """
    Then the result should be, in any order:
      | cat    |
      | 'test' |
    And the side effects should be:
      | +nodes      | 1 |
      | +properties | 2 |

  Scenario: [5] VecNode-createVectorIndex-onStringPropertyFails
    Given an empty graph
    And having executed:
      """
      create label StrNode (name string null);
      """
    When executing query:
      """
      CREATE VECTOR INDEX idx_vec_str FOR (n:StrNode) ON (n.name) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    Then a TypeError should be raised at any time
    And the error should contain:
      """
      vector
      """
