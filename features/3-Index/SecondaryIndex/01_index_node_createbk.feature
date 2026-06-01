# encoding: utf-8
# 非严格模式：通过 CREATE 节点隐式创建 Label 和属性，不使用 create label DDL。
# todo：因为目前暂未支持时间类型数据的写入，所以临时将时间类型数据的测试单独拆分为一个用例
@index @ddl
Feature: create node index

  @skip_script
  Scenario Outline: [1] Node-Create unique index-basic-<datatype>
    Given an empty graph
    And having executed:
      """
      CREATE (:IdxUniqueBasic {p1: 's', p2: 0, p3: 0.0, p4: true})
      """
    When executing query:
      """
      CREATE INDEX <indexName> FOR (n:IdxUniqueBasic) ON (n.<prop>) OPTIONS {indexConfig: {unique: TRUE}};
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

  @skip_bug
  Scenario Outline: [1-time] Node-Create unique index-time-<datatype>
    Given an empty graph
    And having executed:
      """
      CREATE (:IdxUniqueTime {p5: date('2024-01-01'), p6: time('12:00:00'), p7: datetime('2024-01-01T00:00:00Z')})
      """
    When executing query:
      """
      CREATE INDEX <indexName> FOR (n:IdxUniqueTime) ON (n.<prop>) OPTIONS {indexConfig: {unique: TRUE}};
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "<indexName>" should exist

    Examples:
      | datatype | prop | indexName       |
      | date     | p5   | idx_uniq_date  |
      | time     | p6   | idx_uniq_time  |
      | datetime | p7   | idx_uniq_dt    |

  Scenario Outline: [2] Node-Create index on unsupported type-<datatype>
    Given an empty graph
    And having executed:
      """
      CREATE (:<labelName> {<prop>: <sampleValue>})
      """
    When executing query:
      """
      CREATE INDEX <indexName> FOR (n:<labelName>) ON (n.<prop>);
      """
    Then a <ErrType> should be raised at any time
    And the error message should contain '<ErrMsg>'
    And no side effects

    Examples:
      | datatype | labelName         | prop      | indexName          | sampleValue          | ErrType  | ErrMsg |
      | list     | IdxTypeTestBasic  | listProp  | idx_type_list      | [1, 2, 3]            | TypeError | index |
      | duration | IdxTypeTestTime   | durProp   | idx_type_duration  | duration('P1D')      | TypeError | index |
      | point    | IdxTypeTestSpatial| pointProp | idx_type_point     | point({x: 1, y: 2})  | TypeError | index |

  Scenario: [3] Node-Create non-unique index
    Given an empty graph
    And having executed:
      """
      CREATE (:IdxNonUnique {name: 'init', age: 0})
      """
    When executing query:
      """
      CREATE INDEX idx_nonuniq_name FOR (n:IdxNonUnique) ON (n.name);
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_nonuniq_name" should exist

  Scenario: [4] Node-Create index idempotent with IF NOT EXISTS
    Given an empty graph
    And having executed:
      """
      CREATE (:IdxIdempotent {val: 'x'})
      """
    And having executed:
      """
      CREATE INDEX idx_idemp_val FOR (n:IdxIdempotent) ON (n.val);
      """
    When executing query:
      """
      CREATE INDEX idx_idemp_val IF NOT EXISTS FOR (n:IdxIdempotent) ON (n.val);
      """
    Then no side effects
    And the index "idx_idemp_val" should exist

  Scenario: [5] Node-Create unique index then insert data to verify usability
    Given an empty graph
    And having executed:
      """
      CREATE (:IdxUniqueVerify {code: 'placeholder'})
      """
    And having executed:
      """
      CREATE INDEX idx_uverify_code FOR (n:IdxUniqueVerify) ON (n.code) OPTIONS {indexConfig: {unique: TRUE}};
      """
    When executing query:
      """
      CREATE (n:IdxUniqueVerify {code: 'alpha'}) RETURN n.code AS result;
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
      CREATE (:IdxUniqueReject {code: 'alpha'})
      """
    And having executed:
      """
      CREATE INDEX idx_ureject_code FOR (n:IdxUniqueReject) ON (n.code) OPTIONS {indexConfig: {unique: TRUE}};
      """
    When executing query:
      """
      CREATE (n:IdxUniqueReject {code: 'alpha'}) RETURN n.code;
      """
    Then a ConstraintValidationFailed should be raised at runtime
    And no side effects

  Scenario: [7] Node-Create index on label with no prior data
    Given an empty graph
    When executing query:
      """
      CREATE INDEX idx_nodata FOR (n:IdxNoData) ON (n.name);
      """
    Then the side effects should be:
      | +indexes | 1 |
    And the index "idx_nodata" should exist

  Scenario: [8] Node-Create index then SHOW INDEXES verification
    Given an empty graph
    And having executed:
      """
      CREATE (:IdxShowVerify {val: 'test'})
      """
    And having executed:
      """
      CREATE INDEX idx_show FOR (n:IdxShowVerify) ON (n.val);
      """
    When executing query:
      """
      SHOW INDEXES YIELD name
      """
    Then the result should contain:
      | name       |
      | 'idx_show' |

  # TODO(严格模式): 待 GDM 支持 create label DDL 后，补充严格模式下索引创建用例
  # - 使用 create label 定义 schema 后创建索引
  # - 验证严格模式下属性类型与索引类型匹配
