# encoding: utf-8
#
# GDM Admin Import: Error Handling - Preflight Phase
#
# 测试范围:
#   - Preflight（预检）阶段的错误处理
#   - 解析 TOML manifest 文件失败
#   - 验证配置失败（graph、space、路径、编码等）
#   - space不存在
#   - manifest文件不存在
#   - import-root目录不存在
#   - CLI option非法（名称或值）
#
# 导入流程阶段:
#   Phase 1: Preflight - 预检阶段
#   Phase 2: ImportNode - 导入顶点
#   Phase 3: ImportEdge - 导入边
#   Phase 4: Finalize - 收尾阶段
#
# Neo4j 参考:
#   N/A - This is GDM-specific import tool testing

# fixme code 体验问题。Rust gRPC 框架的内部错误栈，直接透传给了用户
# ./plugin/gdm-admin -u admin -p admin123 catalog space create --space-id nonexistent_space_12345 --shard-count 2 --replication-factor 1
#Error: tonic::transport::Error(Transport, ConnectError(ConnectError("tcp connect error", 127.0.0.1:9800, Os { code: 61, kind: ConnectionRefused, message: "Connection refused" })))

@admin @import  @preflight
Feature: GDM Admin Import - Error Handling - Preflight Phase

  Background:
    Given having executed:
      """
      DROP GRAPH error_preflight_invalid_toml
      """
    And having executed:
      """
      DROP GRAPH error_preflight_missing_graph
      """
    And having executed:
      """
      DROP GRAPH error_preflight_missing_space
      """
    And having executed:
      """
      DROP GRAPH error_preflight_csv_not_found
      """
    And having executed:
      """
      DROP GRAPH error_preflight_space_not_exist
      """
    And having executed:
      """
      DROP GRAPH error_preflight_empty_csv
      """
    And having executed:
      """
      DROP GRAPH error_preflight_invalid_encoding
      """

  # ---------------------------------------------------------------------------
  # 1. TOML manifest 文件语法错误
  #    验证 manifest 文件解析失败时导入命令返回非零退出码，stderr 包含 TOML parse error
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-01] invalid TOML syntax in manifest causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/manifest_invalid_toml/manifest.toml"
    Then the CLI exit code should not be 0
    And the CLI stderr should contain 'TOML parse error'

  # ---------------------------------------------------------------------------
  # 2. manifest 缺少 graph 字段
  #    验证 manifest 中缺少必需的 graph 字段时导入失败，stderr 包含 TOML parse error
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-02] missing graph field in manifest causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/manifest_missing_graph/manifest.toml"
    Then the CLI exit code should not be 0
    And the CLI stderr should contain 'TOML parse error'

  # ---------------------------------------------------------------------------
  # 3. manifest 缺少 space 字段
  #    验证 manifest 中缺少必需的 space 字段时导入失败，stderr 包含 TOML parse error
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-03] missing space field in manifest causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/manifest_missing_space/manifest.toml"
    Then the CLI exit code should not be 0
    And the CLI stderr should contain 'TOML parse error'

  # ---------------------------------------------------------------------------
  # 4. CSV 文件不存在
  #    验证 manifest 中指定的 CSV 文件不存在时导入失败，stderr 包含 file not found
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-04] referenced CSV file not found causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/csv_file_not_found/manifest.toml"
    Then the CLI exit code should not be 0
    And the CLI stderr should contain 'file not found'

  # ---------------------------------------------------------------------------
  # 5. Space 不存在
  #    验证导入到不存在的 space 时导入报告 status=ABORTED
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-05] importing to non-existent space causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/space_not_exist/manifest.toml"
    Then the CLI exit code should not be 0
    And the import summary should show status "ABORTED"

  # ---------------------------------------------------------------------------
  # 6. CSV 文件为空（只有 header 没有数据行）
  #    验证空的 CSV 文件导入成功，status=OK，导入数量为0
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-06] empty CSV file with only header imports successfully with zero rows
    When executing gdm-admin import with manifest "error_preflight/empty_csv_file/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 0 vertices imported
    And the import summary should show 0 edges imported

  # ---------------------------------------------------------------------------
  # 7. CSV 文件编码错误
  #    验证非 UTF-8 编码的 CSV 文件导致导入失败
  # 实测pass： Error: Error(Utf8 { pos: Some(Position { byte: 8, line: 2, record: 1 }), err: Utf8Error { field: 1, valid_up_to: 0 } })
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-07] CSV file with invalid encoding causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/invalid_encoding/manifest.toml"
    Then the CLI exit code should not be 0
    And the CLI stderr should contain 'Utf8Error'


  # ---------------------------------------------------------------------------
  # 8. manifest 文件不存在
  #    验证指定的 manifest 文件路径不存在时导入失败
  # 实测pass： Error: "read /Users/dpp/*project/newdb/cyphertck/gdm-tck/testdata/import/error_preflight/nonexistent_path/manifest.toml: No such file or directory (os error 2)"
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-08] manifest file not found causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/nonexistent_path/manifest.toml"
    Then the CLI exit code should not be 0
    And the CLI stderr should contain 'No such file or directory'

  # ---------------------------------------------------------------------------
  # 9. --import-root 目录不存在
  #    验证指定的 import-root 目录不存在时导入失败
  # 实测pass：Error: "vertex file not found: /Users/dpp/*project/newdb/cyphertck/gdm-tck/testdata/import/error_preflight/ddd/vertices.csv"
  # 重复指定相同option时：
  # 实测pass：Stderr: error: the argument '--import-root <IMPORT_ROOT>' cannot be used multiple times
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-09] non-existent import-root directory causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/cli_option_error/manifest.toml" and args "--import-root /tmp/nonexistent_import_root_dir_12345"
    Then the CLI exit code should not be 0
    And the CLI stderr should contain 'cannot be used multiple times'


  # ---------------------------------------------------------------------------
  # 10. 非法 option 名称
  #    验证传入不存在的 option（如 --dry-ran）时导入失败
  # 实测pass： error: unexpected argument '--dry-ran' found
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-10] invalid option name causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/cli_option_error/manifest.toml" and args "--dry-ran"
    Then the CLI exit code should not be 0

  # ---------------------------------------------------------------------------
  # 11. 非法 option 值
  #    验证传入非法的 option 值（如 --retries -1）时导入失败
  # 实测pass： error: unexpected argument '-1' found
  # ---------------------------------------------------------------------------

  Scenario: [Import-Error-Preflight-11] invalid option value causes preflight failure
    When executing gdm-admin import with manifest "error_preflight/cli_option_error/manifest.toml" and args "--retries -1"
    Then the CLI exit code should not be 0
