# encoding: utf-8
#
# GDM Admin Import: Import Root - import root directory scenarios
#
# 测试范围:
#   - 默认 import-root 为 manifest 所在目录
#   - 自定义 import-root 解析相对路径
#   - 嵌套目录结构
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - Import Root

  Background:
    Given having executed:
      """
      DROP GRAPH import_root
      """

  # ---------------------------------------------------------------------------
  # 1. 默认 import-root 为 manifest 所在目录
  #    验证不指定 --import-root 时，相对路径相对于 manifest 目录解析
  # ---------------------------------------------------------------------------

  Scenario: [Import-Root-01] default import-root is manifest directory
    When executing gdm-admin import with manifest "import_root/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 2. 自定义 import-root 解析相对路径
  #    验证 --import-root 参数覆盖相对路径的解析根目录
  # ---------------------------------------------------------------------------

  Scenario: [Import-Root-02] custom import-root resolves relative paths
    When executing gdm-admin import with manifest "import_root/manifest.toml" and args "--import-root /tmp"
    Then the CLI exit code should not be 0

  # ---------------------------------------------------------------------------
  # 3. 嵌套目录结构
  #    验证 manifest 中的 path 使用嵌套子目录 (data/persons.csv)
  # ---------------------------------------------------------------------------

  Scenario: [Import-Root-03] import-root with nested directory structure
    When executing gdm-admin import with manifest "import_root/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
