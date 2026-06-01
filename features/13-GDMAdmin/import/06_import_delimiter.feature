# encoding: utf-8
#
# GDM Admin Import: CSV Delimiter - delimiter handling scenarios
#
# 测试范围:
#   - 制表符分隔 (\t)
#   - 分号分隔 (;)
#   - 管道符分隔 (|)
#   - 每个场景同时包含 vertex 和 edge
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - CSV Delimiter

  Background:
    Given having executed:
      """
      DROP GRAPH delimiter_comma;
      DROP GRAPH delimiter_tab;
      DROP GRAPH delimiter_semicolon;
      DROP GRAPH delimiter_pipe;
      DROP GRAPH delimiter_override
      """

  # ---------------------------------------------------------------------------
  # 1. 逗号分隔（默认）
  #    验证默认逗号分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-01] import with comma delimiter (default)
    When executing gdm-admin import with manifest "delimiter/manifest_comma.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 2. 制表符分隔
  #    验证 \t 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-02] import with tab delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_tab.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 3. 分号分隔
  #    验证 ; 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-03] import with semicolon delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_semicolon.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 4. 管道符分隔
  #    验证 | 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-04] import with pipe delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_pipe.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 5. 文件级分隔符覆盖
  #    验证单个文件的 delimiter 覆盖全局设置
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-05] per-file delimiter override
    When executing gdm-admin import with manifest "delimiter/manifest_override.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
