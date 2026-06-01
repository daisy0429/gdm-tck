# encoding: utf-8
#
# GDM Admin Import: Bulk Import - bulk import scenarios
#
# 测试范围:
#   - 基础批量导入
#   - 批量导入 + 验证
#   - 批量导入 + 跳过预计数
#   - 批量导入 + 允许溢写
#   - 批量导入 + 完整性能选项
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import  @skip_bug
Feature: GDM Admin Import - Bulk Import

  Background:
    Given having executed:
      """
      DROP GRAPH bulk_import
      """

  # ---------------------------------------------------------------------------
  # 1. 基础批量导入
  #    验证 --bulk 参数使用批量写入路径
  # ---------------------------------------------------------------------------

  Scenario: [Import-Bulk-01] basic bulk import
    When executing gdm-admin import with manifest "bulk/manifest.toml" and args "--bulk"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 2. 批量导入 + 验证
  #    验证 --bulk --validate 在导入后运行验证检查
  # ---------------------------------------------------------------------------

  Scenario: [Import-Bulk-02] bulk import with validation
    When executing gdm-admin import with manifest "bulk/manifest.toml" and args "--bulk --validate"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"

  # ---------------------------------------------------------------------------
  # 3. 批量导入 + 跳过预计数
  #    验证 --bulk --no-precount 跳过预导入 CSV 计数
  # ---------------------------------------------------------------------------

  Scenario: [Import-Bulk-03] bulk import with no-precount
    When executing gdm-admin import with manifest "bulk/manifest.toml" and args "--bulk --no-precount"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"

  # ---------------------------------------------------------------------------
  # 4. 批量导入 + 允许溢写
  #    验证 --bulk --bulk-allow-spill 允许生成多个 SST 文件
  # ---------------------------------------------------------------------------

  Scenario: [Import-Bulk-04] bulk import with allow-spill
    When executing gdm-admin import with manifest "bulk/manifest.toml" and args "--bulk --bulk-allow-spill"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"

  # ---------------------------------------------------------------------------
  # 5. 批量导入 + 完整性能选项
  #    验证 --bulk --validate --no-precount --bulk-allow-spill 组合使用
  # ---------------------------------------------------------------------------

  Scenario: [Import-Bulk-05] bulk import with full performance options
    When executing gdm-admin import with manifest "bulk/manifest.toml" and args "--bulk --validate --no-precount --bulk-allow-spill"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
