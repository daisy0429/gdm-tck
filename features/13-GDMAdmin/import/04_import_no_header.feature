# encoding: utf-8
#
# GDM Admin Import: No Header CSV - no header CSV handling scenarios
#
# 测试范围:
#   - header = false + columns 声明
#   - 下标映射 id = [{ index = 0, name = "id" }]
#   - 下标属性映射 { index = 2, name = "type" }
#   - vertex 和 edge 同时覆盖
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - No Header CSV

  Background:
    Given having executed:
      """
      DROP GRAPH no_header
      """

  # ---------------------------------------------------------------------------
  # 1. 无表头 vertex CSV 导入
  #    验证 header = false + columns 声明正确导入顶点数据
  # ---------------------------------------------------------------------------

  Scenario: [Import-NoHeader-01] import vertex CSV without header using columns declaration
    When executing gdm-admin import with manifest "no_header/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 7 vertices imported

  # ---------------------------------------------------------------------------
  # 2. vertex ID 下标映射
  #    验证 id = [{ index = 0, name = "id" }] 按下标读取主键
  # ---------------------------------------------------------------------------

  Scenario: [Import-NoHeader-02] vertex id mapping by index
    When executing gdm-admin import with manifest "no_header/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 7 vertices imported

  # ---------------------------------------------------------------------------
  # 3. vertex 属性下标映射
  #    验证 { index = 2, name = "type" } 按下标读取属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-NoHeader-03] vertex property mapping by index
    When executing gdm-admin import with manifest "no_header/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 7 vertices imported

  # ---------------------------------------------------------------------------
  # 4. 无表头 edge CSV 导入
  #    验证 header = false + columns 声明正确导入边数据
  # ---------------------------------------------------------------------------

  Scenario: [Import-NoHeader-04] import edge CSV without header using columns declaration
    When executing gdm-admin import with manifest "no_header/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 edges imported

  # ---------------------------------------------------------------------------
  # 5. edge 端点下标映射
  #    验证边的 src/dst 使用下标映射读取端点 ID
  # ---------------------------------------------------------------------------

  Scenario: [Import-NoHeader-05] edge with no-header CSV and index-based endpoint mapping
    When executing gdm-admin import with manifest "no_header/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
