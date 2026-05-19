# encoding: utf-8

@index @performance
Feature: VectorIndex-Performance

  @ignore
  @todo-ldbc
  # 待 LDBC SF0.1 数据集导入基础设施就绪后启用
  Scenario: [1] VecIndex-performance-vectorSearch-vs-fullScan
    Given an empty graph
    # 前置：需要 LDBC SF0.1 数据集已导入
    And having executed:
      """
      CREATE VECTOR INDEX idx_perf_vec FOR (n:Person) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 128, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_perf_vec', 10, $queryVec) YIELD node, score RETURN node.id, score;
      """
    Then the result should not be empty

  @ignore
  @todo-ldbc
  # 待 LDBC SF0.1 数据集导入基础设施就绪后启用
  Scenario: [2] VecIndex-performance-largeDimension-512
    Given an empty graph
    # 前置：需要 LDBC SF0.1 数据集已导入
    And having executed:
      """
      CREATE VECTOR INDEX idx_perf_512 FOR (n:Person) ON (n.embedding512) OPTIONS {indexConfig: {`vector.dimensions`: 512, `vector.similarity_function`: 'cosine'}};
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_perf_512', 5, $queryVec) YIELD node, score RETURN node.id, score;
      """
    Then the result should not be empty

  @ignore
  @todo-ldbc
  # 待 LDBC SF0.1 数据集导入基础设施就绪后启用
  Scenario: [3] VecIndex-performance-euclidean-vs-cosine
    Given an empty graph
    # 前置：需要 LDBC SF0.1 数据集已导入
    And having executed:
      """
      CREATE VECTOR INDEX idx_perf_euc FOR (n:Person) ON (n.embedding) OPTIONS {indexConfig: {`vector.dimensions`: 128, `vector.similarity_function`: 'euclidean'}};
      """
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_perf_euc', 10, $queryVec) YIELD node, score RETURN node.id, score;
      """
    Then the result should not be empty

  @ignore
  @todo-ldbc
  # 待 LDBC SF0.1 数据集导入基础设施就绪后启用
  Scenario: [4] VecIndex-performance-bulkInsert-thenQuery
    Given an empty graph
    # 前置：需要批量向量数据生成基础设施就绪
    When executing query:
      """
      CALL db.index.vector.queryNodes('idx_perf_bulk', 10, $queryVec) YIELD node, score RETURN count(node) AS cnt;
      """
    Then the result should not be empty
