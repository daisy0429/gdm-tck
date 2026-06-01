# encoding: utf-8
#
# GDM Admin Import: Composite ID - composite id handling scenarios
#
# 测试范围:
#   - 复合点ID (id = ["col1", "col2"])
#   - 边引用复合ID顶点
#   - 边自身端点使用复合ID
#   - 复合ID冲突检测
#   - vertex 和 edge 同时覆盖
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - Composite ID

  Background:
    Given having executed:
      """
      DROP GRAPH composite_id;
      DROP GRAPH composite_id_edge
      """

  # ---------------------------------------------------------------------------
  # 1. 复合点ID
  #    验证顶点使用两列复合主键 (country_code + place_id)
  # ---------------------------------------------------------------------------

  Scenario: [Import-CompositeID-01] vertex with composite id (2 columns)
    When executing gdm-admin import with manifest "composite_id/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 6 vertices imported

  # ---------------------------------------------------------------------------
  # 2. 边使用单列端点
  #    验证边的 src/dst 使用单列 ID 引用顶点
  # ---------------------------------------------------------------------------

  Scenario: [Import-CompositeID-02] edge with single-column src and dst
    When executing gdm-admin import with manifest "composite_id/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show 3 edges imported

  # ---------------------------------------------------------------------------
  # 3. 边引用复合ID顶点
  #    验证边的 dst 端点引用使用复合主键的顶点
  # ---------------------------------------------------------------------------

  Scenario: [Import-CompositeID-03] edge referencing vertex with composite id
    When executing gdm-admin import with manifest "composite_id/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"

  # ---------------------------------------------------------------------------
  # 4. 边两端均为复合ID
  #    验证边的 src 和 dst 都引用使用复合主键的顶点
  # ---------------------------------------------------------------------------

  Scenario: [Import-CompositeID-04] edge where both src and dst reference composite id vertices
    When executing gdm-admin import with manifest "composite_id/manifest_edge_composite.toml"
    Then the CLI exit code should be 0
    And the import summary should show 2 edges imported

  # ---------------------------------------------------------------------------
  # 5. 复合ID标签表 - 冲突策略=skip
  #    验证向已有复合主键顶点的图追加导入相同数据时，--on-conflict skip 策略
  #    正确跳过冲突顶点，状态为 COMPLETED_WITH_ERRORS，边正常导入
  #    导入完成后校验库中数据总量
  # ---------------------------------------------------------------------------

  Scenario: [Import-CompositeID-05] composite id vertex conflict with skip strategy
    When executing gdm-admin import with manifest "composite_id/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 6 vertices imported
    And the import summary should show 3 edges imported
    # 再次导入相同数据，验证冲突处理（skip 策略）
    When executing gdm-admin import with manifest "composite_id/manifest.toml" and args "--append --on-conflict skip"
    Then the CLI exit code should not be 0
    And the import summary should show status "COMPLETED_WITH_ERRORS"
    And the import summary should show 0 vertices imported
    And the import summary should show 3 edges imported
    And the import summary should show 6 rows skipped
    # 库中数据量校验：初始 6 顶点 + 0 新增 = 6
    When login in user for USER["admin"]-PWD["admin123"]-DB["composite_id"]
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 6   |
    # 库中数据量校验：初始 3 边 + 0 新增 = 3
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |

  # ---------------------------------------------------------------------------
  # 6. 复合ID边冲突检测
  #    验证复合主键边的重复导入冲突处理
  # ---------------------------------------------------------------------------

  Scenario: [Import-CompositeID-06] composite id conflict detection for edge
    When executing gdm-admin import with manifest "composite_id/manifest_edge_composite.toml"
    Then the CLI exit code should be 0
    And the import summary should show 2 edges imported
    # 再次导入相同数据，验证冲突处理
    When executing gdm-admin import with manifest "composite_id/manifest_edge_composite.toml" and args "--append --on-conflict skip"
    Then the CLI exit code should be 0
