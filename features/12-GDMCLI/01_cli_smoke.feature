# encoding: utf-8
#
# GDM CLI: Basic Query Execution - Smoke Test Scenarios
#
# Test Scope:
#   - Basic -e flag query execution
#   - Output format verification
#   - Error handling verification
#
# Neo4j Reference:
#   N/A - This is GDM-specific CLI tool testing
#
@cli @smoke
Feature: GDM CLI - Basic Query Execution Smoke Test

  Background:
    Given an empty graph

  Scenario: [CLI-Smoke-01] Execute simple MATCH query
    Given test data is loaded into graph "default"
    When executing gdm-cli with "-e" flag on graph "default":
      """
      MATCH (n:Person) RETURN n.name ORDER BY n.name
      """
    Then the CLI exit code should be 0
    And the CLI output should contain "Alice"
    And the CLI output should contain "Bob"
