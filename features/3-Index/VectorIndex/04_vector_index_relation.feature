# encoding: utf-8

@index @ddl
Feature: VectorIndex-Relationship-CRUD

  Scenario: [1] RelVecIndex-create-onRelationship
    Given an empty graph
    And having executed:
      """
      create label VecPerson (name string null);
      """
    And having executed:
      """
      create relationshipType SIMILAR (weight float null, embedding LIST null);
      """
    When executing query:
      """
      CREATE VECTOR INDEX idx_rel_vec FOR ()-[r:SIMILAR]->() ON (r.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 3, `vector.similarity_function`: 'cosine'}};
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_rel_vec" should exist

  Scenario: [2] RelVecIndex-drop-existing
    Given an empty graph
    And having executed:
      """
      create label VecPerson (name string null);
      """
    And having executed:
      """
      create relationshipType SIMILAR (weight float null, embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_rel_drop FOR ()-[r:SIMILAR]->() ON (r.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 3, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      DROP INDEX idx_rel_drop;
      """
    Then the side effects should be:
      | -indexes | 1 |
    And the index "idx_rel_drop" should not exist

  Scenario: [3] RelVecIndex-createThenQueryWithVectorData
    Given an empty graph
    And having executed:
      """
      create label VecPerson (name string null);
      """
    And having executed:
      """
      create relationshipType SIMILAR (embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_rel_query FOR ()-[r:SIMILAR]->() ON (r.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 2, `vector.similarity_function`: 'cosine'}};
      """
    And having executed:
      """
      CREATE (a:VecPerson {name: 'A'})-[:SIMILAR {embedding: [1.0, 0.0]}]->(b:VecPerson {name: 'B'});
      CREATE (c:VecPerson {name: 'C'})-[:SIMILAR {embedding: [0.0, 1.0]}]->(d:VecPerson {name: 'D'});
      CREATE (e:VecPerson {name: 'E'})-[:SIMILAR {embedding: [0.9, 0.1]}]->(f:VecPerson {name: 'F'});
      """
    When executing query:
      """
      MATCH (a)-[r:SIMILAR]->(b) WHERE r.embedding = [1.0, 0.0] RETURN a.name, b.name;
      """
    Then the result should be, in any order:
      | a.name | b.name |
      | 'A'    | 'B'    |

  Scenario: [4] RelVecIndex-ifNotExists-idempotent
    Given an empty graph
    And having executed:
      """
      create label VecPerson (name string null);
      """
    And having executed:
      """
      create relationshipType SIMILAR (embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_rel_idem FOR ()-[r:SIMILAR]->() ON (r.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      CREATE VECTOR INDEX idx_rel_idem IF NOT EXISTS FOR ()-[r:SIMILAR]->() ON (r.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    Then no side effects
    And the index "idx_rel_idem" should exist
