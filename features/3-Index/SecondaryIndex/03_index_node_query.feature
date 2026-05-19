# encoding: utf-8
# 非严格模式：通过 CREATE 节点隐式创建 Label 和属性。

@index @ddl
Feature: Node index query verification

  Scenario: [1] Node-Exact match query hits index data
    Given an empty graph
    And having executed:
      """
      CREATE (:TestNode {name: 'Alice', age: 30, score: 95.5})
      """
    And having executed:
      """
      CREATE (:TestNode {name: 'Bob', age: 25, score: 80.0})
      """
    And having executed:
      """
      CREATE INDEX idx_name FOR (n:TestNode) ON (n.name);
      """
    When executing query:
      """
      MATCH (n:TestNode {name: 'Alice'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |
    And no side effects

  Scenario Outline: [2] Node-Multi-datatype index exact match-<type>
    Given an empty graph
    And having executed:
      """
      <insert_data>
      """
    And having executed:
      """
      <create_index>
      """
    When executing query:
      """
      <query>
      """
    Then the result should be, in any order:
      | <resultCol>     |
      | <expectedValue> |
    And no side effects

    Examples:
      | type     | create_index                                                | insert_data                                                                                                         | query                                                                               | resultCol | expectedValue             |
      | string   | CREATE INDEX idx_str FOR (n:TypeNode) ON (n.strVal)         | CREATE (:TypeNode {strVal: 'hello'}), (:TypeNode {strVal: 'world'})                                                 | MATCH (n:TypeNode {strVal: 'hello'}) RETURN n.strVal AS val                         | val       | 'hello'                   |
      | int      | CREATE INDEX idx_int FOR (n:TypeNode) ON (n.intVal)         | CREATE (:TypeNode {intVal: 100}), (:TypeNode {intVal: 200})                                                         | MATCH (n:TypeNode) WHERE n.intVal = 100 RETURN n.intVal AS val                      | val       | 100                       |
      | float    | CREATE INDEX idx_float FOR (n:TypeNode) ON (n.floatVal)     | CREATE (:TypeNode {floatVal: 3.14}), (:TypeNode {floatVal: 2.71})                                                   | MATCH (n:TypeNode) WHERE n.floatVal = 3.14 RETURN n.floatVal AS val                 | val       | 3.14                      |
      | date     | CREATE INDEX idx_date FOR (n:TypeNode) ON (n.dateVal)       | CREATE (:TypeNode {dateVal: date('2024-01-01')}), (:TypeNode {dateVal: date('2024-06-15')})                          | MATCH (n:TypeNode) WHERE n.dateVal = date('2024-01-01') RETURN n.dateVal AS val      | val       | date('2024-01-01')         |
      | datetime | CREATE INDEX idx_dt FOR (n:TypeNode) ON (n.dtVal)           | CREATE (:TypeNode {dtVal: datetime('2024-01-01T10:00:00Z')}), (:TypeNode {dtVal: datetime('2024-06-15T12:00:00Z')})  | MATCH (n:TypeNode) WHERE n.dtVal = datetime('2024-01-01T10:00:00Z') RETURN n.dtVal AS val | val | datetime('2024-01-01T10:00:00Z') |

  Scenario Outline: [3] Node-Range query-<operator>
    Given an empty graph
    And having executed:
      """
      CREATE (:RangeNode {name: 'A', age: 20}), (:RangeNode {name: 'B', age: 30}), (:RangeNode {name: 'C', age: 40})
      """
    And having executed:
      """
      CREATE INDEX idx_age FOR (n:RangeNode) ON (n.age);
      """
    When executing query:
      """
      <query>
      """
    Then the result should be, in order:
      | n.name      |
      | <expected1> |
      | <expected2> |
    And no side effects

    Examples:
      | operator | query                                                          | expected1 | expected2 |
      | gt       | MATCH (n:RangeNode) WHERE n.age > 25 RETURN n.name ORDER BY n.name  | 'B'       | 'C'       |
      | lt       | MATCH (n:RangeNode) WHERE n.age < 35 RETURN n.name ORDER BY n.name  | 'A'       | 'B'       |

  Scenario: [4] Node-Range query greater-or-equal and less-or-equal
    Given an empty graph
    And having executed:
      """
      CREATE (:RangeNode {name: 'A', age: 20}), (:RangeNode {name: 'B', age: 30}), (:RangeNode {name: 'C', age: 40})
      """
    And having executed:
      """
      CREATE INDEX idx_age FOR (n:RangeNode) ON (n.age);
      """
    When executing query:
      """
      MATCH (n:RangeNode) WHERE n.age >= 30 AND n.age <= 40 RETURN n.name ORDER BY n.name
      """
    Then the result should be, in order:
      | n.name |
      | 'B'    |
      | 'C'    |
    And no side effects

  Scenario: [5] Node-NULL value not hit by index exact match
    Given an empty graph
    And having executed:
      """
      CREATE (:NullNode {name: 'hasVal', val: 10}), (:NullNode {name: 'noVal', val: null})
      """
    And having executed:
      """
      CREATE INDEX idx_val FOR (n:NullNode) ON (n.val);
      """
    When executing query:
      """
      MATCH (n:NullNode {val: 10}) RETURN n.name
      """
    Then the result should be, in any order:
      | n.name   |
      | 'hasVal' |
    And no side effects
    When executing query:
      """
      MATCH (n:NullNode) WHERE n.val IS NULL RETURN n.name
      """
    Then the result should be, in any order:
      | n.name  |
      | 'noVal' |
    And no side effects
    When executing query:
      """
      MATCH (n:NullNode) WHERE n.val IS NOT NULL RETURN n.name
      """
    Then the result should be, in any order:
      | n.name   |
      | 'hasVal' |

  Scenario: [6] Node-IN list query hits index
    Given an empty graph
    And having executed:
      """
      CREATE (:InNode {name: 'A', age: 20}), (:InNode {name: 'B', age: 30}), (:InNode {name: 'C', age: 40})
      """
    And having executed:
      """
      CREATE INDEX idx_in_age FOR (n:InNode) ON (n.age);
      """
    When executing query:
      """
      MATCH (n:InNode) WHERE n.age IN [20, 40] RETURN n.name ORDER BY n.name
      """
    Then the result should be, in order:
      | n.name |
      | 'A'    |
      | 'C'    |
    And no side effects

  Scenario: [7] Node-STARTS WITH prefix query hits index
    Given an empty graph
    And having executed:
      """
      CREATE (:StrNode {name: 'Alice'}), (:StrNode {name: 'Alan'}), (:StrNode {name: 'Bob'})
      """
    And having executed:
      """
      CREATE INDEX idx_str_name FOR (n:StrNode) ON (n.name);
      """
    When executing query:
      """
      MATCH (n:StrNode) WHERE n.name STARTS WITH 'Al' RETURN n.name ORDER BY n.name
      """
    Then the result should be, in order:
      | n.name  |
      | 'Alan'  |
      | 'Alice' |
    And no side effects

  Scenario: [8] Node-ENDS WITH and CONTAINS do full scan
    Given an empty graph
    And having executed:
      """
      CREATE (:ScanNode {name: 'Alice'}), (:ScanNode {name: 'Bob'})
      """
    And having executed:
      """
      CREATE INDEX idx_scan_name FOR (n:ScanNode) ON (n.name);
      """
    When executing query:
      """
      MATCH (n:ScanNode) WHERE n.name ENDS WITH 'ice' RETURN n.name
      """
    Then the result should be, in any order:
      | n.name  |
      | 'Alice' |
    And the plan of query should not contain "NodeIndexSeek":
      """
      MATCH (n:ScanNode) WHERE n.name ENDS WITH 'ice' RETURN n.name
      """
    When executing query:
      """
      MATCH (n:ScanNode) WHERE n.name CONTAINS 'ob' RETURN n.name
      """
    Then the result should be, in any order:
      | n.name |
      | 'Bob'  |

  Scenario: [9] Node-Empty result set query hits index
    Given an empty graph
    And having executed:
      """
      CREATE (:EmptyNode {name: 'Alice'}), (:EmptyNode {name: 'Bob'})
      """
    And having executed:
      """
      CREATE INDEX idx_empty_name FOR (n:EmptyNode) ON (n.name);
      """
    When executing query:
      """
      MATCH (n:EmptyNode {name: 'NonExistent'}) RETURN n.name
      """
    Then the result should be empty
    And no side effects

  Scenario: [10] Node-Order by indexed property with pagination
    Given an empty graph
    And having executed:
      """
      CREATE (:PageNode {name: 'A', age: 40}), (:PageNode {name: 'B', age: 20}), (:PageNode {name: 'C', age: 30})
      """
    And having executed:
      """
      CREATE INDEX idx_page_age FOR (n:PageNode) ON (n.age);
      """
    When executing query:
      """
      MATCH (n:PageNode) RETURN n.name ORDER BY n.age SKIP 1 LIMIT 1
      """
    Then the result should be, in order:
      | n.name |
      | 'C'    |
    And no side effects
