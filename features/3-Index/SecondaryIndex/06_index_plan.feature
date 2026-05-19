# encoding: utf-8
# 非严格模式：通过 CREATE 节点隐式创建 Label 和属性。

@index @ddl
Feature: Index execution plan verification

  Scenario: [1] IndexPlan-ExactMatch-NodeIndexSeek
    Given an empty graph
    And having executed:
      """
      CREATE (:PlanTest {name: 'alice', age: 30})
      """
    And having executed:
      """
      CREATE INDEX idx_plan_name FOR (n:PlanTest) ON (n.name);
      """
    When executing query:
      """
      MATCH (n:PlanTest {name: 'alice'}) RETURN n.name AS name
      """
    Then the result should be, in any order:
      | name    |
      | 'alice' |
    And the plan of query should contain "NodeIndexSeek":
      """
      MATCH (n:PlanTest {name: 'alice'}) RETURN n.name AS name
      """

  Scenario: [2] IndexPlan-RangeMatch-NodeIndexSeekByRange
    Given an empty graph
    And having executed:
      """
      CREATE (:PlanRange {score: 10}),
             (:PlanRange {score: 50}),
             (:PlanRange {score: 90})
      """
    And having executed:
      """
      CREATE INDEX idx_plan_score FOR (n:PlanRange) ON (n.score);
      """
    When executing query:
      """
      MATCH (n:PlanRange) WHERE n.score > 20 RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    And the plan of query should contain "NodeIndexSeekByRange":
      """
      MATCH (n:PlanRange) WHERE n.score > 20 RETURN count(n) AS cnt
      """

  Scenario: [3] IndexPlan-RelIndex-DirectedRelationshipIndexSeek
    Given an empty graph
    And having executed:
      """
      CREATE (a:PlanNode {id: 1})-[:HAS_REL {weight: 0.5}]->(b:PlanNode {id: 2}),
             (c:PlanNode {id: 3})-[:HAS_REL {weight: 1.5}]->(d:PlanNode {id: 4})
      """
    And having executed:
      """
      CREATE INDEX idx_rel_weight FOR ()-[r:HAS_REL]->() ON (r.weight);
      """
    When executing query:
      """
      MATCH ()-[r:HAS_REL]->() WHERE r.weight = 0.5 RETURN r.weight AS w
      """
    Then the result should be, in any order:
      | w   |
      | 0.5 |
    And the plan of query should contain "DirectedRelationshipIndexSeek":
      """
      MATCH ()-[r:HAS_REL]->() WHERE r.weight = 0.5 RETURN r.weight AS w
      """

  Scenario: [4] IndexPlan-NoIndex-NodeByLabelScan
    Given an empty graph
    And having executed:
      """
      CREATE (:NoIdxLabel {val: 'test'})
      """
    When executing query:
      """
      MATCH (n:NoIdxLabel {val: 'test'}) RETURN n.val AS val
      """
    Then the result should be, in any order:
      | val    |
      | 'test' |
    And the plan of query should contain "NodeByLabelScan":
      """
      MATCH (n:NoIdxLabel {val: 'test'}) RETURN n.val AS val
      """
    And the plan of query should not contain "NodeIndexSeek":
      """
      MATCH (n:NoIdxLabel {val: 'test'}) RETURN n.val AS val
      """

  Scenario Outline: [5] IndexPlan-CompositeIndex-<matchType>
    Given an empty graph
    And having executed:
      """
      CREATE (:PlanComp {p1: 'a', p2: 1, p3: 1.1}),
             (:PlanComp {p1: 'b', p2: 2, p3: 2.2})
      """
    And having executed:
      """
      CREATE INDEX idx_plan_comp FOR (n:PlanComp) ON (n.p1, n.p2);
      """
    Then the plan of query should contain "<operator>":
      """
      <query>
      """

    Examples:
      | matchType   | operator        | query                                                                  |
      | FullMatch   | NodeIndexSeek   | MATCH (n:PlanComp) WHERE n.p1 = 'a' AND n.p2 = 1 RETURN n.p1 AS p1    |
      | LeftPrefix  | NodeIndexSeek   | MATCH (n:PlanComp) WHERE n.p1 = 'a' RETURN n.p1 AS p1                  |
      | SkipLeft    | NodeByLabelScan | MATCH (n:PlanComp) WHERE n.p2 = 1 RETURN n.p1 AS p1                    |

  Scenario: [6] IndexPlan-CompositeRange-NodeIndexSeekByRange
    Given an empty graph
    And having executed:
      """
      CREATE (:PlanCompR {p1: 'a', p2: 10, p3: 1.0}),
             (:PlanCompR {p1: 'a', p2: 20, p3: 2.0}),
             (:PlanCompR {p1: 'b', p2: 30, p3: 3.0})
      """
    And having executed:
      """
      CREATE INDEX idx_plan_cr FOR (n:PlanCompR) ON (n.p1, n.p2);
      """
    Then the plan of query should contain "NodeIndexSeekByRange":
      """
      MATCH (n:PlanCompR) WHERE n.p1 = 'a' AND n.p2 > 15 RETURN n.p1 AS p1, n.p2 AS p2
      """

  Scenario: [7] IndexPlan-RelRange-RelationshipIndexSeekByRange
    Given an empty graph
    And having executed:
      """
      CREATE (:PlanRN {id: 1})-[:REL_RT {score: 10}]->(:PlanRN {id: 2}),
             (:PlanRN {id: 3})-[:REL_RT {score: 50}]->(:PlanRN {id: 4}),
             (:PlanRN {id: 5})-[:REL_RT {score: 90}]->(:PlanRN {id: 6})
      """
    And having executed:
      """
      CREATE INDEX idx_rel_score FOR ()-[r:REL_RT]->() ON (r.score);
      """
    Then the plan of query should contain "RelationshipIndexSeekByRange":
      """
      MATCH ()-[r:REL_RT]->() WHERE r.score > 20 RETURN r.score AS s
      """

  Scenario: [8] IndexPlan-IndexHint-UsingIndex
    Given an empty graph
    And having executed:
      """
      CREATE (:HintNode {name: 'alice', age: 30})
      """
    And having executed:
      """
      CREATE INDEX idx_hint_name FOR (n:HintNode) ON (n.name);
      """
    Then the plan of query should contain "NodeIndexSeek":
      """
      MATCH (n:HintNode) USING INDEX n:HintNode(name) WHERE n.name = 'alice' RETURN n.name AS name
      """

  Scenario: [9] IndexPlan-DropIndex-RevertToScan
    Given an empty graph
    And having executed:
      """
      CREATE (:DropPlan {val: 'x'})
      """
    And having executed:
      """
      CREATE INDEX idx_dp FOR (n:DropPlan) ON (n.val);
      """
    And having executed:
      """
      DROP INDEX idx_dp;
      """
    Then the plan of query should contain "NodeByLabelScan":
      """
      MATCH (n:DropPlan {val: 'x'}) RETURN n.val AS val
      """
    And the plan of query should not contain "NodeIndexSeek":
      """
      MATCH (n:DropPlan {val: 'x'}) RETURN n.val AS val
      """
