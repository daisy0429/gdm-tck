# encoding: utf-8
#
# GDM Admin Import: Error Handling - ImportNode Phase
#
# 测试范围:
#   - ImportNode（导入顶点）阶段的错误处理
#   - 数据类型不匹配（字符串转数值、布尔转数值、时间转数值）
#   - 数据类型不匹配（字符串转布尔、数组转布尔、时间转布尔）
#   - 数据类型不匹配（字符串转时间、数组转时间、布尔转时间）
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
# todo 注意：非严格模式.
# fixme script: 待更新严格模式/非严格模式下测试点。区分不同模式下的校验点
#
@admin @import
Feature: GDM Admin Import - Error Handling - ImportNode Phase

  Background:
    Given having executed:
      """
      DROP GRAPH error_importnode_type_mismatch;
      DROP GRAPH error_importnode_type_mismatch_bool;
      DROP GRAPH error_importnode_type_mismatch_time;
      DROP GRAPH error_importnode_type_mismatch_string_to_bool;
      DROP GRAPH error_importnode_type_mismatch_array_to_bool;
      DROP GRAPH error_importnode_type_mismatch_time_to_bool;
      DROP GRAPH error_importnode_type_mismatch_string_to_time;
      DROP GRAPH error_importnode_type_mismatch_array_to_time;
      DROP GRAPH error_importnode_type_mismatch_bool_to_time;
      DROP GRAPH error_importnode_missing_column;
      DROP GRAPH error_importnode_delimiter_in_value;
      DROP GRAPH error_importnode_empty_pk;
      DROP GRAPH error_importnode_duplicate_pk_same_batch;
      DROP GRAPH error_importnode_duplicate_pk_cross_batch;
      DROP GRAPH error_importnode_numeric_overflow
      """

  # ===========================================================================
  # 1. 数据类型不匹配 - 转数值类型失败
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 1.1 字符串转 int 失败
  #    验证顶点属性中字符串无法转换为 int 时导入失败
  # ---------------------------------------------------------------------------
  #fixme code 待确认。非严格模式下 实测string转为0写入数据库成功。
  Scenario: [Import-Error-Node-01] string value cannot be converted to int, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_string_to_int/manifest.toml" and args "--errors-out /tmp/node_string_to_int_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 1.2 布尔值转 int 失败
  #    验证顶点属性中布尔值无法转换为 int 时导入失败
    #fixme code 待确认。非严格模式下 实测转为0写入数据库成功。
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-02] boolean value cannot be converted to int, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_bool_to_int/manifest.toml" and args "--errors-out /tmp/node_bool_to_int_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 1.3 时间值转 int 失败
  #    验证顶点属性中时间值无法转换为 int 时导入失败
  #fixme code 待确认。非严格模式下 实测转为0写入数据库成功。
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-03] datetime value cannot be converted to int, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_time_to_int/manifest.toml" and args "--errors-out /tmp/node_time_to_int_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 2. 数据类型不匹配 - 转布尔类型失败
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 2.1 字符串转 boolean 失败
  #    验证顶点属性中字符串无法转换为 boolean 时导入失败
  #   fixme code 待确认。非严格模式下 实测转为false写入数据库成功。
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-04] string value cannot be converted to boolean, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_string_to_bool/manifest.toml" and args "--errors-out /tmp/node_string_to_bool_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 2.2 数组转 boolean 失败
  #    验证顶点属性中数组无法转换为 boolean 时导入失败
  #   fixme code 待确认。非严格模式下 实测转为false写入数据库成功。
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-05] array value cannot be converted to boolean, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_array_to_bool/manifest.toml" and args "--errors-out /tmp/node_array_to_bool_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 2.3 时间值转 boolean 失败
  #    验证顶点属性中时间值无法转换为 boolean 时导入失败
  #   fixme code 待确认。非严格模式下 实测转为false写入数据库成功。
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-06] datetime value cannot be converted to boolean, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_time_to_bool/manifest.toml" and args "--errors-out /tmp/node_time_to_bool_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 3. 数据类型不匹配 - 转时间类型失败
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 3.1 字符串转 date 失败
  #    验证顶点属性中字符串无法转换为 date 时导入失败
  #   fixme code 待确认。非严格模式下 实测字符串写入数据库成功。
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-07] string value cannot be converted to date, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_string_to_time/manifest.toml" and args "--errors-out /tmp/node_string_to_time_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 3.2 数组转 date 失败
  #    验证顶点属性中数组无法转换为 date 时导入失败
  # fixme code 待确认。非严格模式下 实测字符串形式写入数据库成功："[2024-01-15,2024-01-16]"
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-08] array value cannot be converted to date, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_array_to_time/manifest.toml" and args "--errors-out /tmp/node_array_to_time_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 3.3 布尔值转 date 失败
  #    验证顶点属性中布尔值无法转换为 date 时导入失败
  #   fixme code 待确认。非严格模式下 实测写入字符串"true"成功。
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-09] boolean value cannot be converted to date, vertex import fails
    When executing gdm-admin import with manifest "error_importnode/type_mismatch_bool_to_time/manifest.toml" and args "--errors-out /tmp/node_bool_to_time_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 4. 列不匹配
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 4.1 缺少列
  #    验证顶点数据缺少列时导入失败
  # fixme code 待确认。非严格模式下 实测缺少列数据写入数据库成功。
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-10] vertex missing column causes import failure
    When executing gdm-admin import with manifest "error_importnode/missing_column/manifest.toml" and args "--errors-out /tmp/node_missing_column_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # fixme script: 这是一个正向用例。后续请移到正向用例中
  # 4.2 值中包含分隔符，值由双引号包括。 数据写入成功
  #    验证顶点数据中分隔符与值重复时导入失败
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-11] vertex delimiter in value causes import failure
    When executing gdm-admin import with manifest "error_importnode/delimiter_in_value/manifest.toml" and args "--errors-out /tmp/node_delimiter_in_value_errors.jsonl"
    Then the CLI exit code should be 0
    And the import summary should show 2 vertices imported
    # todo 补充库中数据验证： match (n) where n.name ='Bo,b' return count (n)； 返回1

      # ---------------------------------------------------------------------------
  # 4.3 分隔符与值重复 （实质：多了一列值）
  #    验证顶点数据中分隔符与值重复时导入失败
  # fixme script: 这是一个正向用例。后续请移到正向用例中
  # fixme code 待确认。非严格模式下实测数据写入成功。最后多的列不影响
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-11b] vertex delimiter in value causes import failure
    When executing gdm-admin import with manifest "error_importnode/delimiter_in_value2/manifest.toml" and args "--errors-out /tmp/node_delimiter_in_value2_errors.jsonl"
    Then the CLI exit code should be 0
    And the import summary should show 2 vertices imported

  # ===========================================================================
  # 5. 主键异常
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 5.1 主键为空
  #    验证顶点主键为空时导入失败
  # fixme code ：报错信息待优化。没有忽略错误将正确的数据导入。
  # 实测：[preflight] graph was created by this import; skipping non-empty graph sampling
  #Error: "testdata/import/error_importnode/empty_primary_key/vertices.csv:4 empty import id mapping value for id"
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-12] vertex empty primary key causes import failure
    When executing gdm-admin import with manifest "error_importnode/empty_primary_key/manifest.toml" and args "--errors-out /tmp/node_empty_pk_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 5.2 同一批次主键重复
  #    验证同一批次内顶点主键重复时导入失败
  # 实测：[preflight] graph was created by this import; skipping non-empty graph sampling
  #Error: "testdata/import/error_importnode/duplicate_pk_same_batch/vertices.csv:3 duplicate import id mapping key Person:id=1"
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-13] vertex duplicate primary key in same batch causes import failure
    When executing gdm-admin import with manifest "error_importnode/duplicate_pk_same_batch/manifest.toml" and args "--errors-out /tmp/node_dup_pk_same_batch_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2 vertices imported
    And the import summary should show 1 rows errored

  # ---------------------------------------------------------------------------
  # 5.3 跨批次主键重复
  #    验证跨批次顶点主键重复时导入失败
  #    数据: 2048行(batch_size=2048)，第1行和第2049行id均为1
  # 实测：[preflight] graph was created by this import; skipping non-empty graph sampling
  #Error: "testdata/import/error_importnode/duplicate_pk_cross_batch/vertices.csv:2050 duplicate import id mapping key Person:id=1"
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-14] vertex duplicate primary key across batches causes import failure
    When executing gdm-admin import with manifest "error_importnode/duplicate_pk_cross_batch/manifest.toml" and args "--errors-out /tmp/node_dup_pk_cross_batch_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 2048 vertices imported
    And the import summary should show 1 rows errored

  # ===========================================================================
  # 6. 数值溢出
  # ===========================================================================

  # ---------------------------------------------------------------------------
  # 6.1 int 类型数值溢出
  #    验证顶点属性中超出 int 范围的值导致导入失败
  # fixme code 实测：数据写入成功,999999999999999999999存为0
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Node-15] vertex numeric overflow causes import failure
    When executing gdm-admin import with manifest "error_importnode/numeric_overflow/manifest.toml" and args "--errors-out /tmp/node_numeric_overflow_errors.jsonl"
    Then the CLI exit code should not be 0
    And the import summary should show 1 vertices imported
    And the import summary should show 1 rows errored
