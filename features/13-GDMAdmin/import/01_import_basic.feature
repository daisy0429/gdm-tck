# encoding: utf-8
#
# GDM Admin Import: Basic Import - basic import scenarios
#
# 测试范围:
#   - 仅导入顶点 (--vertices-only)
#   - 仅导入边 (--edges-only)
#   - 增量导入到非空图 (--append)
#   - 非空图导入拒绝（无 --append）
#   - 最小配置 manifest 导入
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import 
Feature: GDM Admin Import - Basic Import

  Background:
    Given having executed:
      """
      DROP GRAPH basic_import;
      DROP GRAPH basic_append
      """

  # ---------------------------------------------------------------------------
  # 1. 仅导入顶点
  #    验证 --vertices-only 参数只导入顶点数据，不导入边
  # ---------------------------------------------------------------------------

  Scenario: [Import-Basic-01] import vertices only
    When executing gdm-admin import with manifest "basic/manifest.toml" and args "--vertices-only"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 0 edges imported

  # ---------------------------------------------------------------------------
  # 2. 仅导入边
  #    验证 --edges-only 参数只导入边数据，不导入顶点
  # ---------------------------------------------------------------------------

  Scenario: [Import-Basic-02] import edges only
    When executing gdm-admin import with manifest "basic/manifest.toml" and args "--edges-only"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 0 vertices imported
    And the import summary should show 2 edges imported


  # ---------------------------------------------------------------------------
  # 4. 增量导入无冲突（正向验证）
  #    验证 --append 向已有数据的图追加导入时，若增量数据无主键冲突，
  #    导入成功且库中数据总量正确
  # todo fix script: 一起跑fail。手工单个跑pass
  # ---------------------------------------------------------------------------

  Scenario: [Import-Basic-06] append non-conflicting data succeeds and data is queryable
    When executing gdm-admin import with manifest "basic_append/manifest_init.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    When executing gdm-admin import with manifest "basic_append/manifest_inc.toml" and args "--append"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 2 vertices imported
    And the import summary should show 1 edges imported
    # 切换到 basic_append 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["basic_append"]
    # 总量校验：初始 3 顶点 + 增量 2 顶点 = 5
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 5   |
    # 总量校验：初始 2 边 + 增量 1 边 = 3
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # 初始数据抽样校验
    When executing query without error:
      """
      MATCH (n:Person {name: 'Alice'}) RETURN n.name, n.age, n.city
      """
    Then the result should be, in any order:
      | n.name  | n.age | n.city    |
      | 'Alice' | 30    | 'Beijing' |
    # 增量数据抽样校验
    When executing query without error:
      """
      MATCH (n:Person {name: 'Diana'}) RETURN n.name, n.age, n.city
      """
    Then the result should be, in any order:
      | n.name  | n.age | n.city     |
      | 'Diana' | 28    | 'Shenzhen' |
    # 增量边抽样校验
    When executing query without error:
      """
      MATCH (a:Person {name: 'Charlie'})-[r:KNOWS]->(b:Person {name: 'Diana'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2022    |

  # ---------------------------------------------------------------------------
  # 5. 非空图导入拒绝（无 --append）
  #    验证向已有数据的图导入时，若无 --append 参数应报错
  # ---------------------------------------------------------------------------

  Scenario: [Import-Basic-04] import to non-empty graph without --append should fail
    When executing gdm-admin import with manifest "basic/manifest.toml"
    Then the CLI exit code should be 0
    When executing gdm-admin import with manifest "basic/manifest.toml"
    Then the CLI exit code should not be 0

  # ---------------------------------------------------------------------------
  # 6. 最小配置 manifest 导入
  #    验证使用同时包含 vertex 和 edge 的 manifest 进行导入
  # ---------------------------------------------------------------------------

  Scenario: [Import-Basic-05] import with minimal manifest configuration (vertex + edge)
    When executing gdm-admin import with manifest "basic/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
