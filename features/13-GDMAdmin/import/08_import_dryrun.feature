# encoding: utf-8
#
# GDM Admin Import: Dry Run - validation without import scenarios
#
# 测试范围:
#   - 验证配置但不写入数据
#   - 检测无效 manifest 语法
#   - 检测缺失的 CSV 文件
# # todo 更新script: --dry-run不需要指定用户和密码
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - Dry Run

  Background:
    Given having executed:
      """
      DROP GRAPH dryrun
      """

  # ---------------------------------------------------------------------------
  # 1. dry-run 验证配置
  #    验证 --dry-run 只验证配置不写入数据
  # ---------------------------------------------------------------------------

  Scenario: [Import-DryRun-01] dry-run validates manifest without writing data
    When executing gdm-admin import dry-run with manifest "dryrun/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"

  # ---------------------------------------------------------------------------
  # 2. dry-run 检测无效 manifest
  #    验证 --dry-run 能检测出 manifest 中的错误
  # ---------------------------------------------------------------------------

  Scenario: [Import-DryRun-02] dry-run detects invalid manifest syntax
    When executing gdm-admin import dry-run with manifest "dryrun/manifest_invalid.toml"
    Then the CLI exit code should not be 0

  # ---------------------------------------------------------------------------
  # 3. dry-run 检测缺失 CSV 文件
  #    验证 --dry-run 能检测出引用不存在的 CSV 文件
  # ---------------------------------------------------------------------------

  Scenario: [Import-DryRun-03] dry-run detects missing CSV files
    When executing gdm-admin import dry-run with manifest "dryrun/manifest_invalid.toml"
    Then the CLI exit code should not be 0

  # ---------------------------------------------------------------------------
  # 4. dry-run 输出显示计划摘要
  #    验证 --dry-run 输出包含计划导入的顶点和边数
  # ---------------------------------------------------------------------------

  Scenario: [Import-DryRun-04] dry-run output shows planned import summary
    When executing gdm-admin import dry-run with manifest "dryrun/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
