# encoding: utf-8
#
# GDM Admin Import: Basic Import - Smoke Test Scenarios
#
# Test Scope:
#   - Basic import functionality verification
#   - Import process exit code verification
#   - Import report status verification
#   - Import summary statistics verification
#   - Post-import data verification via Bolt queries
#   - Data cleanup after test
#
# Neo4j Reference:
#   N/A - This is GDM-specific import tool testing
#
@admin @import @smoke
Feature: GDM Admin Import - Basic Import Smoke Test

  Background:
    Given having executed:
      """
      DROP GRAPH quickstart2
      """

  Scenario: [Import-Smoke-01] Basic import with quickstart data
    When executing gdm-admin import with manifest "quickstart/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 5 vertices imported
    And the import summary should show 5 edges imported
    # 切换到 quickstart2 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["quickstart2"]
    # 总量校验
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 5   |
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 5   |
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:Person {name: 'Alice'}) RETURN n.name, n.age, n.city
      """
    Then the result should be, in any order:
      | n.name  | n.age | n.city    |
      | 'Alice' | 30    | 'Beijing' |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:Person {name: 'Alice'})-[r:KNOWS]->(b:Person {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |
