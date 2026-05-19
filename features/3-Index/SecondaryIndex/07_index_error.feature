# encoding: utf-8
# 非严格模式：通过 CREATE 节点/关系隐式创建 Label、RelationshipType 和属性。

@index @ddl
Feature: SecondaryIndex-Error-Matrix

  Scenario Outline: [1] Index-error-<errName>
    Given an empty graph
    And having executed:
      """
      CREATE (:ErrNode {col1: 'x', col2: 0})
      """
    And having executed:
      """
      CREATE INDEX idx_err_exist FOR (n:ErrNode) ON (n.col1);
      """
    When executing query:
      """
      <ErrCql>
      """
    Then a <ErrType> should be raised at any time
    And the error should contain:
      """
      <ErrMsg>
      """
    And no side effects

    Examples:
      | errName            | ErrCql                                                              | ErrType                      | ErrMsg           |
      | duplicate_index    | CREATE INDEX idx_err_exist FOR (n:ErrNode) ON (n.col1)              | ConstraintValidationFailed   | already exists   |
      | drop_not_exist     | DROP INDEX idx_not_exist                                            | EntityNotFound               | does not exist   |
      | label_not_exist    | CREATE INDEX idx_no_label FOR (n:NoSuchLabel) ON (n.col1)           | SemanticError                | does not exist   |
      | column_not_exist   | CREATE INDEX idx_no_col FOR (n:ErrNode) ON (n.no_such_col)          | SemanticError                | does not exist   |
      | invalid_name_empty | CREATE INDEX `` FOR (n:ErrNode) ON (n.col1)                         | SyntaxError                  | Invalid input    |
      | syntax_no_on       | CREATE INDEX idx_bad FOR (n:ErrNode) (n.col1)                       | SyntaxError                  | Invalid input    |

  Scenario Outline: [2] Index-error-ifNotExists-<caseName>
    Given an empty graph
    And having executed:
      """
      CREATE (:SafeNode {p1: 'x'})
      """
    And having executed:
      """
      CREATE INDEX idx_safe FOR (n:SafeNode) ON (n.p1);
      """
    When executing query without error:
      """
      <SafeCql>
      """
    Then the result should be empty
    And no side effects

    Examples:
      | caseName                  | SafeCql                                                                  |
      | create_if_not_exists      | CREATE INDEX idx_safe IF NOT EXISTS FOR (n:SafeNode) ON (n.p1)           |
      | drop_if_exists_not_found  | DROP INDEX idx_phantom IF EXISTS                                         |

  Scenario: [3] Index-error-duplicateName-differentLabel
    Given an empty graph
    And having executed:
      """
      CREATE (:LabelA {x: 'a'})
      """
    And having executed:
      """
      CREATE (:LabelB {y: 'b'})
      """
    And having executed:
      """
      CREATE INDEX idx_dup_name FOR (n:LabelA) ON (n.x);
      """
    When executing query:
      """
      CREATE INDEX idx_dup_name FOR (n:LabelB) ON (n.y)
      """
    Then a ConstraintValidationFailed should be raised at any time
    And the error should contain:
      """
      already exists
      """
    And no side effects

  Scenario: [4] Index-error-uniqueIndex-rejectsDuplicateValue
    Given an empty graph
    And having executed:
      """
      CREATE (:UniqErr {code: 'alpha'})
      """
    And having executed:
      """
      CREATE INDEX idx_ue_code FOR (n:UniqErr) ON (n.code) OPTIONS {indexConfig: {unique: TRUE}};
      """
    When executing query:
      """
      CREATE (n:UniqErr {code: 'alpha'}) RETURN n.code;
      """
    Then a ConstraintValidationFailed should be raised at runtime
    And the error should contain:
      """
      already exists
      """
    And no side effects

  Scenario: [5] Index-error-dropUniqueIndex-thenAllowDuplicate
    Given an empty graph
    And having executed:
      """
      CREATE (:UniqDropErr {code: 'alpha'})
      """
    And having executed:
      """
      CREATE INDEX idx_ude FOR (n:UniqDropErr) ON (n.code) OPTIONS {indexConfig: {unique: TRUE}};
      """
    And having executed:
      """
      DROP INDEX idx_ude;
      """
    When executing query:
      """
      CREATE (n:UniqDropErr {code: 'alpha'}) RETURN n.code;
      """
    Then the result should be, in any order:
      | n.code  |
      | 'alpha' |
    And the side effects should be:
      | +nodes      | 1 |
      | +properties | 1 |

  Scenario Outline: [6] Index-error-relIndex-<errName>
    Given an empty graph
    And having executed:
      """
      CREATE (:ErrRel {name: 'p1'})-[:ERR_REL {rp1: 'x'}]->(:ErrRel {name: 'p2'})
      """
    And having executed:
      """
      CREATE INDEX idx_rel_err FOR ()-[r:ERR_REL]->() ON (r.rp1);
      """
    When executing query:
      """
      <ErrCql>
      """
    Then a <ErrType> should be raised at any time
    And the error should contain:
      """
      <ErrMsg>
      """
    And no side effects

    Examples:
      | errName              | ErrCql                                                                    | ErrType                    | ErrMsg         |
      | rel_duplicate_index  | CREATE INDEX idx_rel_err FOR ()-[r:ERR_REL]->() ON (r.rp1)               | ConstraintValidationFailed | already exists |
      | rel_type_not_exist   | CREATE INDEX idx_rel_no FOR ()-[r:NO_SUCH_REL]->() ON (r.rp1)            | SemanticError              | does not exist |
      | rel_col_not_exist    | CREATE INDEX idx_rel_nc FOR ()-[r:ERR_REL]->() ON (r.no_col)             | SemanticError              | does not exist |

  Scenario: [7] Index-error-relIndex-ifNotExists-idempotent
    Given an empty graph
    And having executed:
      """
      CREATE (:RelIdem {name: 'p1'})-[:REL_IDEM {val: 'x'}]->(:RelIdem {name: 'p2'})
      """
    And having executed:
      """
      CREATE INDEX idx_ri FOR ()-[r:REL_IDEM]->() ON (r.val);
      """
    When executing query without error:
      """
      CREATE INDEX idx_ri IF NOT EXISTS FOR ()-[r:REL_IDEM]->() ON (r.val);
      """
    Then the result should be empty
    And no side effects

  Scenario Outline: [8] Index-error-compositeIndex-<errName>
    Given an empty graph
    And having executed:
      """
      CREATE (:CompErr {p1: 'a', p2: 1})
      """
    When executing query:
      """
      <ErrCql>
      """
    Then a <ErrType> should be raised at any time
    And the error should contain:
      """
      <ErrMsg>
      """
    And no side effects

    Examples:
      | errName          | ErrCql                                                                   | ErrType                    | ErrMsg         |
      | comp_empty_cols  | CREATE INDEX idx_ce FOR (n:CompErr) ON ()                                | SyntaxError                | Invalid input  |
      | comp_dup_col     | CREATE INDEX idx_cd FOR (n:CompErr) ON (n.p1, n.p1)                      | SemanticError              | already exists |
