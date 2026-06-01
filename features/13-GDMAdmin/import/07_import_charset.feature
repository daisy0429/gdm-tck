# encoding: utf-8
#
# GDM Admin Import: Charset - charset encoding handling scenarios
#
# Test Scope:
#   - UTF-8 encoding (default)
#   - GB18030 encoding
#   - GBK encoding
#   - GB2312 encoding
#   - Big5 encoding
#   - Latin1 encoding
#   - Post-import data verification via Bolt queries
#   - Unsupported charset encoding (negative)
#   - Mismatched declared vs actual encoding (negative)
#
# Neo4j Reference:
#   N/A - This is GDM-specific import tool testing
#
@admin @import
Feature: GDM Admin Import - Charset

  Background:
    Given having executed:
      """
      DROP GRAPH charset_utf8;
      DROP GRAPH charset_gb18030;
      DROP GRAPH charset_gbk;
      DROP GRAPH charset_gb2312;
      DROP GRAPH charset_big5;
      DROP GRAPH charset_latin1;
      DROP GRAPH charset_unsupported;
      DROP GRAPH charset_mismatched
      """

  # ---------------------------------------------------------------------------
  # 1. UTF-8 encoding (default)
  #    Verify default UTF-8 encoding correctly parses vertex and edge data,
  #    and data is queryable after import.
  # ---------------------------------------------------------------------------

  Scenario: [Import-Charset-01] import with UTF-8 encoding (default)
    When executing gdm-admin import with manifest "charset/utf8/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # Switch to charset_utf8 graph for data verification
    When login in user for USER["admin"]-PWD["admin123"]-DB["charset_utf8"]
    # Total count verification
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # Vertex sampling verification
    When executing query without error:
      """
      MATCH (n:Person {name: 'Alice'}) RETURN n.name, n.city
      """
    Then the result should be, in any order:
      | n.name  | n.city    |
      | 'Alice' | 'Beijing' |
    # Edge sampling verification
    When executing query without error:
      """
      MATCH (a:Person {name: 'Alice'})-[r:KNOWS]->(b:Person {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 2. GB18030 encoding
  #    Verify GB18030 encoded CSV file is correctly parsed,
  #    and Chinese characters are queryable after import.
  # ---------------------------------------------------------------------------

  Scenario: [Import-Charset-02] import with GB18030 encoding
    When executing gdm-admin import with manifest "charset/gb18030/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # Switch to charset_gb18030 graph for data verification
    When login in user for USER["admin"]-PWD["admin123"]-DB["charset_gb18030"]
    # Total count verification
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # Vertex sampling verification - Chinese characters
    When executing query without error:
      """
      MATCH (n:Person {name: '张三'}) RETURN n.name, n.city
      """
    Then the result should be, in any order:
      | n.name | n.city |
      | '张三' | '北京' |
    # Edge sampling verification
    When executing query without error:
      """
      MATCH (a:Person {name: '张三'})-[r:KNOWS]->(b:Person {name: '李四'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 3. GBK encoding
  #    Verify GBK encoded CSV file is correctly parsed,
  #    and Chinese characters are queryable after import.
  # ---------------------------------------------------------------------------

  Scenario: [Import-Charset-03] import with GBK encoding
    When executing gdm-admin import with manifest "charset/gbk/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # Switch to charset_gbk graph for data verification
    When login in user for USER["admin"]-PWD["admin123"]-DB["charset_gbk"]
    # Total count verification
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # Vertex sampling verification - Chinese characters
    When executing query without error:
      """
      MATCH (n:Person {name: '张三'}) RETURN n.name, n.city
      """
    Then the result should be, in any order:
      | n.name | n.city |
      | '张三' | '北京' |
    # Edge sampling verification
    When executing query without error:
      """
      MATCH (a:Person {name: '张三'})-[r:KNOWS]->(b:Person {name: '李四'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 4. GB2312 encoding
  #    Verify GB2312 encoded CSV file is correctly parsed,
  #    and Chinese characters are queryable after import.
  # ---------------------------------------------------------------------------

  Scenario: [Import-Charset-04] import with GB2312 encoding
    When executing gdm-admin import with manifest "charset/gb2312/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # Switch to charset_gb2312 graph for data verification
    When login in user for USER["admin"]-PWD["admin123"]-DB["charset_gb2312"]
    # Total count verification
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # Vertex sampling verification - Chinese characters
    When executing query without error:
      """
      MATCH (n:Person {name: '张三'}) RETURN n.name, n.city
      """
    Then the result should be, in any order:
      | n.name | n.city |
      | '张三' | '北京' |
    # Edge sampling verification
    When executing query without error:
      """
      MATCH (a:Person {name: '张三'})-[r:KNOWS]->(b:Person {name: '李四'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 5. Big5 encoding
  #    Verify Big5 encoded CSV file is correctly parsed,
  #    and Traditional Chinese characters are queryable after import.
  # ---------------------------------------------------------------------------

  Scenario: [Import-Charset-05] import with Big5 encoding
    When executing gdm-admin import with manifest "charset/big5/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # Switch to charset_big5 graph for data verification
    When login in user for USER["admin"]-PWD["admin123"]-DB["charset_big5"]
    # Total count verification
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # Vertex sampling verification - Traditional Chinese characters
    When executing query without error:
      """
      MATCH (n:Person {name: '張三'}) RETURN n.name, n.city
      """
    Then the result should be, in any order:
      | n.name | n.city |
      | '張三' | '台北' |
    # Edge sampling verification
    When executing query without error:
      """
      MATCH (a:Person {name: '張三'})-[r:KNOWS]->(b:Person {name: '李四'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 6. Latin1 encoding
  #    Verify Latin1 encoded CSV file is correctly parsed,
  #    and Western European characters are queryable after import.
  # ---------------------------------------------------------------------------

  Scenario: [Import-Charset-06] import with Latin1 encoding
    When executing gdm-admin import with manifest "charset/latin1/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # Switch to charset_latin1 graph for data verification
    When login in user for USER["admin"]-PWD["admin123"]-DB["charset_latin1"]
    # Total count verification
    When executing query without error:
      """
      MATCH (n) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    When executing query without error:
      """
      MATCH ()-[r]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # Vertex sampling verification - Western European characters
    When executing query without error:
      """
      MATCH (n:Person {name: 'José'}) RETURN n.name, n.city
      """
    Then the result should be, in any order:
      | n.name | n.city   |
      | 'José' | 'Madrid' |
    # Edge sampling verification
    When executing query without error:
      """
      MATCH (a:Person {name: 'José'})-[r:KNOWS]->(b:Person {name: 'François'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 7. Unsupported charset encoding
  #    Verify import fails when an unsupported charset is specified.
  # ---------------------------------------------------------------------------

  Scenario: [Import-Charset-07] import with unsupported charset encoding should fail
    When executing gdm-admin import with manifest "charset/unsupported_encoding/manifest.toml"
    Then the CLI exit code should not be 0

  # ---------------------------------------------------------------------------
  # 8. Mismatched declared vs actual encoding
  #    Verify import fails when manifest declares one charset but the CSV
  #    file is actually encoded in another charset.
  # ---------------------------------------------------------------------------

  Scenario: [Import-Charset-08] import with mismatched declared and actual encoding should fail
    When executing gdm-admin import with manifest "charset/mismatched_encoding/manifest.toml"
    Then the CLI exit code should not be 0
