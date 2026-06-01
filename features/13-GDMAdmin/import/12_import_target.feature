# encoding: utf-8
#
# GDM Admin Import: Target Override - target override scenarios
#
# 测试范围:
#   - --target space.graph 覆盖目标
#   - --space 覆盖空间
#   - --graph 覆盖图名
#   - --target 与 --space 互斥
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - Target Override

  Background:
    Given having executed:
      """
      DROP GRAPH target_default;
      DROP GRAPH target_override;
      DROP GRAPH target_graph_override
      """

  # ---------------------------------------------------------------------------
  # 1. --target 覆盖目标
  #    验证 --target space.graph 格式覆盖 manifest 中的目标
  # ---------------------------------------------------------------------------

  Scenario: [Import-Target-01] override target with --target space.graph
    When executing gdm-admin import with manifest "target/manifest.toml" and args "--target default.target_override"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported

  # ---------------------------------------------------------------------------
  # 2. --space 覆盖空间
  #    验证 --space 参数覆盖 manifest 中的 space
  # ---------------------------------------------------------------------------

  Scenario: [Import-Target-02] override space with --space
    When executing gdm-admin import with manifest "target/manifest.toml" and args "--space default"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"

  # ---------------------------------------------------------------------------
  # 3. --graph 覆盖图名
  #    验证 --graph 参数覆盖 manifest 中的 graph
  # ---------------------------------------------------------------------------

  Scenario: [Import-Target-03] override graph with --graph
    When executing gdm-admin import with manifest "target/manifest.toml" and args "--graph target_graph_override"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"

  # ---------------------------------------------------------------------------
  # 4. --target 与 --space 互斥
  #    验证同时使用 --target 和 --space 时应报错
  # ---------------------------------------------------------------------------

  Scenario: [Import-Target-04] --target and --space are mutually exclusive
    When executing gdm-admin import with manifest "target/manifest.toml" and args "--target default.target_graph --space other"
    Then the CLI exit code should not be 0
