# encoding: utf-8
#
# GDM Admin Import: Error Handling - ImportEdge Phase
#
# 测试范围:
#   - ImportEdge（导入边）阶段的错误处理
#   - 边引用不存在的顶点
#   - 数据类型不匹配（字符串转数值、字符串转布尔、字符串转时间）
#   - 列不匹配（缺少列、分隔符与值重复）
#   - 主键异常（为空、同一批次重复、跨批次重复）
#   - 数值溢出
#
# 导入流程阶段:
#   Phase 1: Preflight - 预检阶段
#   Phase 2: ImportNode - 导入顶点
#   Phase 3: ImportEdge - 导入边
#   Phase 4: Finalize - 收尾阶段
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - Error Handling - ImportEdge Phase

  Background:
    Given having executed:
      """
      DROP GRAPH error_importedge_ref_missing_vertex;
      DROP GRAPH error_importedge_type_mismatch;
      DROP GRAPH error_importedge_type_mismatch_bool;
      DROP GRAPH error_importedge_type_mismatch_time;
      DROP GRAPH error_importedge_missing_column;
      DROP GRAPH error_importedge_delimiter_in_value;
      DROP GRAPH error_importedge_empty_pk;
      DROP GRAPH error_importedge_duplicate_pk_same_batch;
      DROP GRAPH error_importedge_duplicate_pk_cross_batch;
      DROP GRAPH error_importedge_numeric_overflow
      """

  # ===========================================================================
  # 1. 边引用不存在的顶点
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 1.1 边引用不存在的终点
  #    验证边引用不存在的顶点时导入失败
  #    顶点: 2行有效数据
  #    边: 第1行有效(1->2)，第2行引用不存在的顶点(2->999)
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-01] edge references non-existent vertex, edge import fails
    When executing gdm-admin import with manifest "error_importedge/edge_ref_missing_vertex/manifest.toml" and args "--errors-out /tmp/edge_ref_missing_vertex_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 2. 数据类型不匹配 - 转数值类型失败
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 2.1 字符串转 float 失败
  #    验证边属性中字符串无法转换为 float 时导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-02] string value cannot be converted to float, edge import fails
    When executing gdm-admin import with manifest "error_importedge/type_mismatch_string_to_int/manifest.toml" and args "--errors-out /tmp/edge_string_to_float_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 edges imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 3. 数据类型不匹配 - 转布尔类型失败
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 3.1 字符串转 boolean 失败
  #    验证边属性中字符串无法转换为 boolean 时导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-03] string value cannot be converted to boolean, edge import fails
    When executing gdm-admin import with manifest "error_importedge/type_mismatch_string_to_bool/manifest.toml" and args "--errors-out /tmp/edge_string_to_bool_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 edges imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 4. 数据类型不匹配 - 转时间类型失败
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 4.1 字符串转 date 失败
  #    验证边属性中字符串无法转换为 date 时导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-04] string value cannot be converted to date, edge import fails
    When executing gdm-admin import with manifest "error_importedge/type_mismatch_string_to_time/manifest.toml" and args "--errors-out /tmp/edge_string_to_date_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 edges imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 5. 列不匹配
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 5.1 缺少列
  #    验证边数据缺少列时导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-05] edge missing column causes import failure
    When executing gdm-admin import with manifest "error_importedge/missing_column/manifest.toml" and args "--errors-out /tmp/edge_missing_column_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 edges imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 5.2 分隔符与值重复
  #    验证边数据中分隔符与值重复时导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-06] edge delimiter in value causes import failure
    When executing gdm-admin import with manifest "error_importedge/delimiter_in_value/manifest.toml" and args "--errors-out /tmp/edge_delimiter_in_value_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 edges imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 6. 主键异常
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 6.1 主键为空
  #    验证边主键（src）为空时导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-07] edge empty primary key causes import failure
    When executing gdm-admin import with manifest "error_importedge/empty_primary_key/manifest.toml" and args "--errors-out /tmp/edge_empty_pk_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 edges imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 6.2 同一批次主键重复
  #    验证同一批次内边主键重复时导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-08] edge duplicate primary key in same batch causes import failure
    When executing gdm-admin import with manifest "error_importedge/duplicate_pk_same_batch/manifest.toml" and args "--errors-out /tmp/edge_dup_pk_same_batch_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 6.3 跨批次主键重复
  #    验证跨批次边主键重复时导入失败
  #    数据: 2048行边(batch_size=2048)，第1行和第2049行src=1,dst=2
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-09] edge duplicate primary key across batches causes import failure
    When executing gdm-admin import with manifest "error_importedge/duplicate_pk_cross_batch/manifest.toml" and args "--errors-out /tmp/edge_dup_pk_cross_batch_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2050 vertices imported
    And the import summary should show 2048 edges imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 7. 数值溢出
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 7.1 int 类型数值溢出
  #    验证边属性中超出 int 范围的值导致导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Edge-10] edge numeric overflow causes import failure
    When executing gdm-admin import with manifest "error_importedge/numeric_overflow/manifest.toml" and args "--errors-out /tmp/edge_numeric_overflow_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 edges imported
    And the import summary should show 1 rows errored
