# encoding: utf-8

@index @ddl
Feature: VectorIndex-Error-Matrix

  Scenario Outline: [1] VecIndex-error-<errName>
    Given an empty graph
    And having executed:
      """
      create label ErrVecNode (embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_err FOR (n:ErrVecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
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
      | errName            | ErrCql                                                                                                    | ErrType                    | ErrMsg           |
      | duplicate_index    | CREATE VECTOR INDEX idx_vec_err FOR (n:ErrVecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}} | ConstraintValidationFailed | already exists   |
      | drop_not_exist     | DROP INDEX idx_vec_phantom                                                                                | EntityNotFound             | does not exist   |
      | label_not_exist    | CREATE VECTOR INDEX idx_vec_nolbl FOR (n:NoSuchLabel) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}} | SemanticError              | does not exist   |
      | column_not_exist   | CREATE VECTOR INDEX idx_vec_nocol FOR (n:ErrVecNode) ON (n.no_such_col) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}} | SemanticError              | does not exist   |

  Scenario Outline: [2] VecIndex-error-missingOptions-<errName>
    Given an empty graph
    And having executed:
      """
      create label OptNode (embedding LIST null);
      """
    When executing query:
      """
      <ErrCql>
      """
    Then a <ErrType> should be raised at any time

    Examples:
      | errName              | ErrCql                                                                                                         | ErrType       |
      | missing_dimensions   | CREATE VECTOR INDEX idx_opt_miss FOR (n:OptNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.similarity_function`: 'cosine'}} | ArgumentError |
      | missing_simfunc      | CREATE VECTOR INDEX idx_opt_miss2 FOR (n:OptNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4}}                | ArgumentError |

  Scenario Outline: [3] VecIndex-error-invalidSimFunc-<simFunc>
    Given an empty graph
    And having executed:
      """
      create label InvSimNode (embedding LIST null);
      """
    When executing query:
      """
      CREATE VECTOR INDEX idx_inv_sim FOR (n:InvSimNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: '<simFunc>'}};
      """
    Then a <ErrType> should be raised at any time

    Examples:
      | simFunc   | ErrType       |
      | invalid   | ArgumentError |
      | cosine2   | ArgumentError |
      | dot       | ArgumentError |

  Scenario: [4] VecIndex-error-ifNotExists-safe
    Given an empty graph
    And having executed:
      """
      create label SafeVecNode (embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_vec_safe FOR (n:SafeVecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    When executing query without error:
      """
      CREATE VECTOR INDEX idx_vec_safe IF NOT EXISTS FOR (n:SafeVecNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
      """
    Then the result should be empty
    And no side effects

  Scenario Outline: [5] VecIndex-error-relIndex-<errName>
    Given an empty graph
    And having executed:
      """
      create label ErrRelNode (name string null);
      """
    And having executed:
      """
      create relationshipType ERR_VEC_REL (embedding LIST null);
      """
    And having executed:
      """
      CREATE VECTOR INDEX idx_rel_vec_err FOR ()-[r:ERR_VEC_REL]->() ON (r.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}};
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
      | errName             | ErrCql                                                                                                                     | ErrType                    | ErrMsg         |
      | rel_duplicate_index | CREATE VECTOR INDEX idx_rel_vec_err FOR ()-[r:ERR_VEC_REL]->() ON (r.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}} | ConstraintValidationFailed | already exists |
      | rel_type_not_exist  | CREATE VECTOR INDEX idx_rel_no FOR ()-[r:NO_SUCH_REL]->() ON (r.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}}     | SemanticError              | does not exist |
      | rel_col_not_exist   | CREATE VECTOR INDEX idx_rel_nc FOR ()-[r:ERR_VEC_REL]->() ON (r.no_col) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}}        | SemanticError              | does not exist |

  Scenario Outline: [6] VecIndex-error-invalidIndexName-<errName>
    Given an empty graph
    And having executed:
      """
      create label InvNameNode (embedding LIST null);
      """
    When executing query:
      """
      <ErrCql>
      """
    Then a <ErrType> should be raised at compile time
    And the error should contain:
      """
      <ErrMsg>
      """
    And no side effects

    Examples:
      | errName          | ErrCql                                                                                                                 | ErrType     | ErrMsg          |
      | empty_name       | CREATE VECTOR INDEX `` FOR (n:InvNameNode) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}}   | SyntaxError | Invalid input   |
      | syntax_no_on     | CREATE VECTOR INDEX idx_bad FOR (n:InvNameNode) (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 4, `vector.similarity_function`: 'cosine'}} | SyntaxError | Invalid input   |

  Scenario Outline: [7] VecIndex-error-queryInvalidIndexName-<errName>
    Given an empty graph
    And having executed:
      """
      create label QErrNode (embedding LIST null);
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

    Examples:
      | errName              | ErrCql                                                                            | ErrType       | ErrMsg         |
      | query_unknown_index  | CALL db.index.vector.queryNodes('no_such_idx', 1, [0.0]) YIELD node RETURN node  | EntityNotFound | does not exist |
