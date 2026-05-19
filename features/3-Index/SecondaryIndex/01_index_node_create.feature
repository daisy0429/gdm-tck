# encoding: utf-8
# 非严格模式：通过 CREATE 节点隐式创建 Label 和属性，不使用 create label DDL。

@index @ddl
Feature: create node index

  Scenario Outline: [1] Node-Create unique index-<datatype>
    Given an empty graph
    And having executed:
      """
      CREATE (:IdxUnique {p1: 's', p2: 0, p3: 0.0, p4: true, p5: date('2024-01-01'), p6: time('12:00:00'), p7: datetime('2024-01-01T00:00:00Z')})
      """
    When executing query:
      """
      CREATE INDEX <indexName> FOR (n:IdxUnique) ON (n.<prop>) OPTIONS {indexConfig: {unique: TRUE}};
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "<indexName>" should exist

    Examples:
      | datatype | prop | indexName       |
      | string   | p1   | idx_uniq_str   |
      | int      | p2   | idx_uniq_int   |
      | float    | p3   | idx_uniq_flt   |
      | bool     | p4   | idx_uniq_bool  |
      | date     | p5   | idx_uniq_date  |
      | time     | p6   | idx_uniq_time  |
      | datetime | p7   | idx_uniq_dt    |

  Scenario Outline: [2] Node-Create index on unsupported type-<datatype>
    Given an empty graph
    And having executed:
      """
      CREATE (:IdxTypeTest {<prop>: <sampleValue>})
      """
    When executing query:
      """
      CREATE INDEX <indexName> FOR (n:IdxTypeTest) ON (n.<prop>);
      """
    Then a <ErrType> should be raised at any time
    And the error should contain:
      """
      <ErrMsg>
    """
    And no side effects

    Examples:
      | datatype | prop      | indexName          | sampleValue        | ErrType | ErrMsg              |
      | list     | listProp  | idx_type_list      | [1, 2, 3]          | TypeError | index              |
      | duration | durProp   | idx_type_duration  | duration('P1D')    | TypeError | index              |
      | point    | pointProp | idx_type_point     | point({x: 1, y: 2}) | TypeError | index            |

  Scenario: [3] Node-Create non-unique index
    Given an empty graph
    And having executed:
      """
      CREATE (:B {name: 'init', age: 0})
      """
    When executing query:
      """
      CREATE INDEX idx_b_name FOR (n:B) ON (n.name);
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_b_name" should exist

  Scenario: [4] Node-Create index idempotent with IF NOT EXISTS
    Given an empty graph
    And having executed:
      """
      CREATE (:C {val: 'x'})
      """
    And having executed:
      """
      CREATE INDEX idx_c_val FOR (n:C) ON (n.val);
      """
    When executing query:
      """
      CREATE INDEX idx_c_val IF NOT EXISTS FOR (n:C) ON (n.val);
      """
    Then no side effects
    And the index "idx_c_val" should exist

  Scenario: [5] Node-Create unique index then insert data to verify usability
    Given an empty graph
    And having executed:
      """
      CREATE (:D {code: 'placeholder'})
      """
    And having executed:
      """
      CREATE INDEX idx_d_code FOR (n:D) ON (n.code) OPTIONS {indexConfig: {unique: TRUE}};
      """
    When executing query:
      """
      CREATE (n:D {code: 'alpha'}) RETURN n.code AS result;
      """
    Then the result should be, in any order:
      | result  |
      | 'alpha' |
    And the side effects should be:
      | +nodes      | 1 |
      | +properties | 1 |

  Scenario: [6] Node-Unique index rejects duplicate value
    Given an empty graph
    And having executed:
      """
      CREATE (:UniqTest {code: 'alpha'})
      """
    And having executed:
      """
      CREATE INDEX idx_uniq_code FOR (n:UniqTest) ON (n.code) OPTIONS {indexConfig: {unique: TRUE}};
      """
    When executing query:
      """
      CREATE (n:UniqTest {code: 'alpha'}) RETURN n.code;
      """
    Then a ConstraintValidationFailed should be raised at runtime
    And no side effects

  Scenario: [7] Node-Create index on label with no prior data
    Given an empty graph
    When executing query:
      """
      CREATE INDEX idx_no_data FOR (n:NewLabel) ON (n.name);
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_no_data" should exist

  Scenario: [8] Node-Create index then SHOW INDEXES verification
    Given an empty graph
    And having executed:
      """
      CREATE (:ShowIdx {val: 'test'})
      """
    And having executed:
      """
      CREATE INDEX idx_show FOR (n:ShowIdx) ON (n.val);
      """
    When executing query:
      """
      SHOW INDEXES YIELD name
      """
    Then the result should contain:
      | name      |
      | 'idx_show' |

  # TODO(严格模式): 待 GDM 支持 create label DDL 后，补充严格模式下索引创建用例
  # - 使用 create label 定义 schema 后创建索引
  # - 验证严格模式下属性类型与索引类型匹配
