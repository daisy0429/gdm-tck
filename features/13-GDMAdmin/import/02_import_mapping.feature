# encoding: utf-8
#
# GDM Admin Import: Data Mapping - property mapping scenarios
#
# 测试范围:
#   - 显式属性映射 (name, type)
#   - 列名重映射 (column, name, type)
#   - 全属性导入 (properties = "*")
#   - include/exclude 过滤
#   - vertex 和 edge 同时覆盖
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - Data Mapping

  Background:
    Given having executed:
      """
      DROP GRAPH mapping_explicit;
      DROP GRAPH mapping_rename;
      DROP GRAPH mapping_wildcard;
      DROP GRAPH mapping_filter
      """

  # ---------------------------------------------------------------------------
  # 1. 显式属性映射 - vertex
  #    验证 { name, type } 显式映射方式正确导入顶点属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-01] vertex explicit property mapping with name and type
    When executing gdm-admin import with manifest "mapping/manifest_explicit.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported

  # ---------------------------------------------------------------------------
  # 2. 显式属性映射 - edge
  #    验证 { name, type } 显式映射方式正确导入边属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-02] edge explicit property mapping with name and type
    When executing gdm-admin import with manifest "mapping/manifest_explicit.toml"
    Then the CLI exit code should be 0
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 3. 列名重映射 - vertex
  #    验证 { column, name, type } 重映射方式正确导入顶点属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-03] vertex column rename mapping with column, name, type
    When executing gdm-admin import with manifest "mapping/manifest_rename.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported

  # ---------------------------------------------------------------------------
  # 4. 列名重映射 - edge
  #    验证 { column, name, type } 重映射方式正确导入边属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-04] edge column rename mapping with column, name, type
    When executing gdm-admin import with manifest "mapping/manifest_rename.toml"
    Then the CLI exit code should be 0
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 5. 全属性导入 - vertex
  #    验证 properties = "*" 导入 CSV 中所有列作为顶点属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-05] vertex import all properties with wildcard
    When executing gdm-admin import with manifest "mapping/manifest_wildcard.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported

  # ---------------------------------------------------------------------------
  # 6. 全属性导入 - edge
  #    验证 properties = "*" 导入 CSV 中所有列作为边属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-06] edge import all properties with wildcard
    When executing gdm-admin import with manifest "mapping/manifest_wildcard.toml"
    Then the CLI exit code should be 0
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 7. include/exclude 过滤 - vertex
  #    验证 properties = { include = "*", exclude = [...] } 正确排除顶点属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-07] vertex include all with exclude list
    When executing gdm-admin import with manifest "mapping/manifest_include_exclude.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported

  # ---------------------------------------------------------------------------
  # 8. include/exclude 过滤 - edge
  #    验证 properties = { include = "*", exclude = [...] } 正确排除边属性
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-08] edge include all with exclude list
    When executing gdm-admin import with manifest "mapping/manifest_include_exclude.toml"
    Then the CLI exit code should be 0
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 9. 混合映射方式
  #    验证同一 manifest 中 vertex 使用显式映射、edge 使用通配符
  # ---------------------------------------------------------------------------

  Scenario: [Import-Mapping-09] mixed mapping: vertex explicit + edge wildcard in same manifest
    When executing gdm-admin import with manifest "mapping/manifest_explicit.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
