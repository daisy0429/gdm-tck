# encoding: utf-8

@index @ddl
Feature: VectorIndex-Node-Drop

  Scenario: [1] VecNode-dropVectorIndex-existing
    Given an empty graph
    And having executed:
      """
      create label VecNode (embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_drop FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      DROP INDEX idx_vec_drop;
      """
    Then the side effects should be:
      | -indexes | 1 |
    And the index "idx_vec_drop" should not exist

  Scenario: [2] VecNode-dropVectorIndex-ifExists-nonExistent
    Given an empty graph
    And having executed:
      """
      create label VecNode (embedding LIST null);
      """
    When executing query:
      """
      DROP INDEX idx_vec_phantom IF EXISTS;
      """
    Then no side effects

  Scenario: [3] VecNode-dropVectorIndex-nonExistent-error
    Given an empty graph
    And having executed:
      """
      create label VecNode (embedding LIST null);
      """
    When executing query:
      """
      DROP INDEX idx_vec_notfound;
      """
    Then a EntityNotFound should be raised at runtime
    And the error should contain:
      """
      does not exist
      """
    And no side effects

  Scenario: [4] VecNode-dropVectorIndex-thenRecreate
    Given an empty graph
    And having executed:
      """
      create label VecNode (embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_reuse FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      DROP INDEX idx_vec_reuse IF EXISTS;
      """
    Then the side effects should be:
      | -indexes | 1 |
    And the index "idx_vec_reuse" should not exist
    When executing query:
      """
      CREATE VECTOR INDEX idx_vec_reuse FOR (n:VecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 8, `vector.similarity_function`: 'euclidean'}};
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_vec_reuse" should exist
