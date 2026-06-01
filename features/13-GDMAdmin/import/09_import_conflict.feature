# encoding: utf-8
#
# GDM Admin Import: Conflict Handling - conflict strategy scenarios
#
# 测试范围:
#   - skip 策略（默认）跳过重复顶点
#   - error 策略终止于重复顶点
#   - skip 策略跳过重复边
#   - error 策略终止于重复边
#   - 复合主键冲突场景
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import  @ignore
Feature: GDM Admin Import - Conflict Handling

  Background:
    Given having executed:
      """
      DROP GRAPH conflict;
      DROP GRAPH conflict_dup;
      DROP GRAPH conflict_composite;
      DROP GRAPH conflict_composite_dup
      """

  # ---------------------------------------------------------------------------
  # 1. skip 策略跳过重复顶点
  #    验证 --on-conflict skip 跳过重复顶点，返回成功
  # ---------------------------------------------------------------------------

  Scenario: [Import-Conflict-01] skip strategy ignores duplicate vertices
    When executing gdm-admin import with manifest "conflict/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported
    When executing gdm-admin import with manifest "conflict/manifest_duplicate.toml" and args "--append --on-conflict skip"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"

  # ---------------------------------------------------------------------------
  # 2. error 策略终止于重复顶点
  #    验证 --on-conflict error 遇到重复顶点时终止导入
  # ---------------------------------------------------------------------------

  Scenario: [Import-Conflict-02] error strategy aborts on duplicate vertices
    When executing gdm-admin import with manifest "conflict/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported
    When executing gdm-admin import with manifest "conflict/manifest.toml" and args "--append --on-conflict error"
    Then the CLI exit code should not be 0

  # ---------------------------------------------------------------------------
  # 3. skip 策略跳过重复边
  #    验证 --on-conflict skip 跳过重复边，返回成功
  # ---------------------------------------------------------------------------

  Scenario: [Import-Conflict-03] skip strategy with duplicate edges
    When executing gdm-admin import with manifest "conflict/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 2 edges imported
    When executing gdm-admin import with manifest "conflict/manifest_duplicate.toml" and args "--append --on-conflict skip"
    Then the CLI exit code should be 0

  # ---------------------------------------------------------------------------
  # 4. error 策略终止于重复边
  #    验证 --on-conflict error 遇到重复边时终止导入
  # ---------------------------------------------------------------------------

  Scenario: [Import-Conflict-04] error strategy with duplicate edges
    When executing gdm-admin import with manifest "conflict/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 2 edges imported
    When executing gdm-admin import with manifest "conflict/manifest.toml" and args "--append --on-conflict error"
    Then the CLI exit code should not be 0

  # ---------------------------------------------------------------------------
  # 5. 默认冲突策略为 skip
  #    验证不指定 --on-conflict 时默认使用 skip
  # ---------------------------------------------------------------------------

  Scenario: [Import-Conflict-05] default conflict strategy is skip
    When executing gdm-admin import with manifest "conflict/manifest.toml"
    Then the CLI exit code should be 0
    When executing gdm-admin import with manifest "conflict/manifest_duplicate.toml" and args "--append"
    Then the CLI exit code should be 0

  # ---------------------------------------------------------------------------
  # 6. 复合主键冲突 - skip 策略
  #    验证复合主键重复时 skip 策略正确处理
  # ---------------------------------------------------------------------------

  Scenario: [Import-Conflict-06] skip strategy with composite id vertex conflict
    When executing gdm-admin import with manifest "conflict/manifest_composite.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported
    When executing gdm-admin import with manifest "conflict/manifest_composite.toml" and args "--append --on-conflict skip"
    Then the CLI exit code should be 0

  # ---------------------------------------------------------------------------
  # 7. 复合主键冲突 - error 策略
  #    验证复合主键重复时 error 策略终止导入
  # ---------------------------------------------------------------------------

  Scenario: [Import-Conflict-07] error strategy with composite id vertex conflict
    When executing gdm-admin import with manifest "conflict/manifest_composite.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported
    When executing gdm-admin import with manifest "conflict/manifest_composite.toml" and args "--append --on-conflict error"
    Then the CLI exit code should not be 0


  # ---------------------------------------------------------------------------
  # 增量导入主键冲突（标签表主键、和库中存量数据主键冲突）
  #    验证 --append 向已有数据的图追加导入时，若增量数据与库中已有数据主键冲突，
  #    状态为 COMPLETED_WITH_ERRORS，冲突的顶点被 skip，无冲突的边正常导入
  # ---------------------------------------------------------------------------

  Scenario: [Import-Conflict-08] append with primary key conflict returns COMPLETED_WITH_ERRORS
    When executing gdm-admin import with manifest "basic/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    When executing gdm-admin import with manifest "basic/manifest.toml" and args "--append"
    Then the CLI exit code should not be 0
    And the import summary should show status "COMPLETED_WITH_ERRORS"
    And the import summary should show 0 vertices imported
    And the import summary should show 2 edges imported
    And the import summary should show 3 rows skipped
