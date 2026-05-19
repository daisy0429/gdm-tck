# encoding: utf-8
# 非严格模式：通过 CREATE 节点隐式创建 Label 和属性。

@index @ddl
Feature: Composite index creation, leftmost matching and deletion

  Scenario: [1] CompositeIndex-Create-2Column
    Given an empty graph
    And having executed:
      """
      CREATE (:CompositeTest {p1: 'init', p2: 0, p3: 0.0})
      """
    When executing query:
      """
      CREATE INDEX idx_comp FOR (n:CompositeTest) ON (n.p1, n.p2);
      """
    Then the index "idx_comp" should exist
    And the side effects should be:
      | +indexes | 1 |

  Scenario: [2] CompositeIndex-Create-3Column
    Given an empty graph
    And having executed:
      """
      CREATE (:Comp3Test {p1: 'init', p2: 0, p3: 0.0})
      """
    When executing query:
      """
      CREATE INDEX idx_comp3 FOR (n:Comp3Test) ON (n.p1, n.p2, n.p3);
      """
    Then the index "idx_comp3" should exist
    And the side effects should be:
      | +indexes | 1 |

  Scenario: [3] CompositeIndex-LeftmostMatch-AllColumns
    Given an empty graph
    And having executed:
      """
      CREATE (n:CompAll {p1: 'hello', p2: 100, p3: 1.5})
      """
    And having executed:
      """
      CREATE INDEX idx_comp_all FOR (n:CompAll) ON (n.p1, n.p2);
      """
    When executing query:
      """
      MATCH (n:CompAll) WHERE n.p1 = 'hello' AND n.p2 = 100 RETURN n.p1 AS p1, n.p2 AS p2
      """
    Then the result should be, in any order:
      | p1      | p2  |
      | 'hello' | 100 |
    And no side effects

  Scenario: [4] CompositeIndex-LeftmostMatch-PrefixOnly
    Given an empty graph
    And having executed:
      """
      CREATE (:CompPrefix {p1: 'alpha', p2: 10, p3: 2.5}),
             (:CompPrefix {p1: 'beta', p2: 20, p3: 3.5})
      """
    And having executed:
      """
      CREATE INDEX idx_comp_pfx FOR (n:CompPrefix) ON (n.p1, n.p2);
      """
    When executing query:
      """
      MATCH (n:CompPrefix) WHERE n.p1 = 'alpha' RETURN n.p1 AS p1, n.p2 AS p2
      """
    Then the result should be, in any order:
      | p1      | p2 |
      | 'alpha' | 10 |
    And no side effects

  Scenario: [5] CompositeIndex-LeftmostMatch-NonLeftColumn
    Given an empty graph
    And having executed:
      """
      CREATE (:CompNonLeft {p1: 'foo', p2: 42, p3: 9.9}),
             (:CompNonLeft {p1: 'bar', p2: 42, p3: 8.8})
      """
    And having executed:
      """
      CREATE INDEX idx_comp_nl FOR (n:CompNonLeft) ON (n.p1, n.p2);
      """
    When executing query:
      """
      MATCH (n:CompNonLeft) WHERE n.p2 = 42 RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    And no side effects

  Scenario Outline: [6] CompositeIndex-LeftmostMatch-<matchType>
    Given an empty graph
    And having executed:
      """
      CREATE (a:CompLM {p1: 'x', p2: 1, p3: 1.1}),
             (b:CompLM {p1: 'y', p2: 2, p3: 2.2})
      """
    And having executed:
      """
      CREATE INDEX idx_lm FOR (n:CompLM) ON (n.p1, n.p2, n.p3);
      """
    When executing query:
      """
      <query>
      """
    Then the result should be, in any order:
      | cnt      |
      | <expect> |
    And no side effects

    Examples:
      | matchType    | query                                                                                  | expect |
      | AllThree     | MATCH (n:CompLM) WHERE n.p1 = 'x' AND n.p2 = 1 AND n.p3 = 1.1 RETURN count(n) AS cnt | 1      |
      | LeftTwo      | MATCH (n:CompLM) WHERE n.p1 = 'x' AND n.p2 = 1 RETURN count(n) AS cnt                 | 1      |
      | LeftOne      | MATCH (n:CompLM) WHERE n.p1 = 'x' RETURN count(n) AS cnt                              | 1      |
      | SkipFirst    | MATCH (n:CompLM) WHERE n.p2 = 1 AND n.p3 = 1.1 RETURN count(n) AS cnt                 | 1      |

  Scenario: [7] CompositeIndex-Drop-Verify
    Given an empty graph
    And having executed:
      """
      CREATE (:CompDrop {p1: 'a', p2: 1, p3: 0.0})
      """
    And having executed:
      """
      CREATE INDEX idx_drop_test FOR (n:CompDrop) ON (n.p1, n.p2);
      """
    When executing query:
      """
      DROP INDEX idx_drop_test;
      """
    Then the index "idx_drop_test" should not exist
    And the side effects should be:
      | -indexes | 1 |

  Scenario: [8] CompositeIndex-Range query with prefix equality
    Given an empty graph
    And having executed:
      """
      CREATE (:CompRange {p1: 'x', p2: 10, p3: 1.0}),
             (:CompRange {p1: 'x', p2: 20, p3: 2.0}),
             (:CompRange {p1: 'y', p2: 30, p3: 3.0})
      """
    And having executed:
      """
      CREATE INDEX idx_comp_rng FOR (n:CompRange) ON (n.p1, n.p2);
      """
    When executing query:
      """
      MATCH (n:CompRange) WHERE n.p1 = 'x' AND n.p2 > 15 RETURN n.p2 AS p2 ORDER BY n.p2
      """
    Then the result should be, in order:
      | p2 |
      | 20 |
    And no side effects

  Scenario: [9] CompositeIndex-Sort uses index order
    Given an empty graph
    And having executed:
      """
      CREATE (:CompSort {p1: 'b', p2: 2, p3: 0.0}),
             (:CompSort {p1: 'a', p2: 1, p3: 0.0}),
             (:CompSort {p1: 'a', p2: 3, p3: 0.0})
      """
    And having executed:
      """
      CREATE INDEX idx_comp_sort FOR (n:CompSort) ON (n.p1, n.p2);
      """
    When executing query:
      """
      MATCH (n:CompSort) RETURN n.p1 AS p1, n.p2 AS p2 ORDER BY n.p1, n.p2
      """
    Then the result should be, in order:
      | p1   | p2 |
      | 'a'  | 1  |
      | 'a'  | 3  |
      | 'b'  | 2  |
    And no side effects

  Scenario: [10] CompositeIndex-Partial NULL in indexed columns
    Given an empty graph
    And having executed:
      """
      CREATE (:CompNull {p1: 'x', p2: null, p3: 1.0}),
             (:CompNull {p1: 'y', p2: 10, p3: 2.0})
      """
    And having executed:
      """
      CREATE INDEX idx_comp_null FOR (n:CompNull) ON (n.p1, n.p2);
      """
    When executing query:
      """
      MATCH (n:CompNull) WHERE n.p1 = 'x' AND n.p2 = null RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 0   |
    When executing query:
      """
      MATCH (n:CompNull) WHERE n.p1 = 'y' AND n.p2 = 10 RETURN n.p1 AS p1, n.p2 AS p2
      """
    Then the result should be, in any order:
      | p1   | p2 |
      | 'y'  | 10 |
