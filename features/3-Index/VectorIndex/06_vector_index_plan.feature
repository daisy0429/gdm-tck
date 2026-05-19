# encoding: utf-8

@index @ddl
Feature: VectorIndex-Execution-Plan

  Scenario: [1] VecIndexPlan-vectorQuery-showsIndexUsage
    Given an empty graph
    And having executed:
      """
      create label PlanVec (embedding LIST null, category string null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_plan_vec FOR (n:PlanVec) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 3, `vector.similarity_function`: 'cosine'}};
      """
    And having executed:
      """
      CREATE (n:PlanVec {embedding: [1.0, 0.0, 0.0], category: 'a'});
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_plan_vec', 1, [1.0, 0.0, 0.0]) YIELD node, score RETURN node.category AS cat, score;
      """
    Then the result should not be empty

  Scenario: [2] VecIndexPlan-noVectorIndex-fallbackScan
    Given an empty graph
    And having executed:
      """
      create label NoVecIdx (embedding LIST null);
      """
    And having executed:
      """
      CREATE (n:NoVecIdx {embedding: [1.0, 2.0, 3.0]});
      """
    When executing query:
      """
      MATCH (n:NoVecIdx) WHERE n.embedding = [1.0, 2.0, 3.0] RETURN n.embedding AS emb;
      """
    Then the result should be, in any order:
      | emb            |
      | [1.0, 2.0, 3.0] |
    And the plan of query should contain "NodeByLabelScan":
      """
      MATCH (n:NoVecIdx) WHERE n.embedding = [1.0, 2.0, 3.0] RETURN n.embedding AS emb
      """

  Scenario: [3] VecIndexPlan-nodeIndexSeek-withSecondaryAndVectorIndex
    Given an empty graph
    And having executed:
      """
      create label DualIdx (name string null, embedding LIST null);
      """
    And having executed:
      """
      CREATE INDEX idx_dual_name FOR (n:DualIdx) ON (n.name);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_dual_vec FOR (n:DualIdx) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 2, `vector.similarity_function`: 'cosine'}};
      """
    And having executed:
      """
      CREATE (n:DualIdx {name: 'alpha', embedding: [1.0, 0.0]});
      """
    When executing query:
      """
      MATCH (n:DualIdx {name: 'alpha'}) RETURN n.name AS name;
      """
    Then the result should be, in any order:
      | name    |
      | 'alpha' |
    And the plan of query should contain "NodeIndexSeek":
      """
      MATCH (n:DualIdx {name: 'alpha'}) RETURN n.name AS name
      """
