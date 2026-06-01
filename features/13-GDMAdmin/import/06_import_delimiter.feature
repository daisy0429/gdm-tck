# encoding: utf-8
#
# GDM Admin Import: CSV Delimiter - delimiter handling scenarios
#
# 测试范围:
#   - 逗号分隔（默认）
#   - 制表符分隔 (\t)
#   - 分号分隔 (;)
#   - 管道符分隔 (|)
#   - 空格分隔
#   - 冒号分隔 (:)
#   - 感叹号分隔 (!)
#   - @ 符号分隔
#   - # 符号分隔
#   - ￥ 符号分隔（反向：多字节字符不支持）
#   - $ 符号分隔
#   - % 符号分隔
#   - ^ 符号分隔
#   - & 符号分隔
#   - * 符号分隔
#   - 文件级分隔符覆盖
#   - 多字符分隔符（反向）
#   - 不支持的特殊字符分隔符（反向）
#   - 每个正向场景同时包含 vertex 和 edge，并校验库中数据
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
      DROP GRAPH delimiter_override;
      DROP GRAPH delimiter_space;
      DROP GRAPH delimiter_colon;
      DROP GRAPH delimiter_exclamation;
      DROP GRAPH delimiter_at;
      DROP GRAPH delimiter_hash;
      DROP GRAPH delimiter_yen;
      DROP GRAPH delimiter_dollar;
      DROP GRAPH delimiter_percent;
      DROP GRAPH delimiter_caret;
      DROP GRAPH delimiter_ampersand;
      DROP GRAPH delimiter_asterisk;
      DROP GRAPH delimiter_multi_char_vertex;
      DROP GRAPH delimiter_multi_char_edge;
      DROP GRAPH delimiter_special_char_vertex;
      DROP GRAPH delimiter_special_char_edge
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
    # 切换到 delimiter_comma 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_comma"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:CommaVertex {name: 'Alice'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:CommaVertex {name: 'Alice'})-[r:COMMA_EDGE]->(b:CommaVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

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
    # 切换到 delimiter_tab 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_tab"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:TabVertex {name: 'Bob'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name | n.age |
      | 'Bob'  | 25    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:TabVertex {name: 'Bob'})-[r:TAB_EDGE]->(b:TabVertex {name: 'Charlie'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2021    |

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
    # 切换到 delimiter_semicolon 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_semicolon"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:SemicolonVertex {name: 'Charlie'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name    | n.age |
      | 'Charlie' | 35    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:SemicolonVertex {name: 'Alice'})-[r:SEMICOLON_EDGE]->(b:SemicolonVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

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
    # 切换到 delimiter_pipe 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_pipe"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:PipeVertex {name: 'Alice'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:PipeVertex {name: 'Alice'})-[r:PIPE_EDGE]->(b:PipeVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

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
    # 切换到 delimiter_override 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_override"]
    # 总量校验
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
    # 顶点抽样校验（vertex 使用全局逗号分隔符）
    When executing query without error:
      """
      MATCH (n:OverrideVertex {name: 'Alice'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |
    # 边抽样校验（edge 使用文件级制表符分隔符覆盖）
    When executing query without error:
      """
      MATCH (a:OverrideVertex {name: 'Alice'})-[r:OVERRIDE_EDGE]->(b:OverrideVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 6. 空格分隔
  #    验证空格分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-06] import with space delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_space.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_space 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_space"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:SpaceVertex {name: 'Alice'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:SpaceVertex {name: 'Alice'})-[r:SPACE_EDGE]->(b:SpaceVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 7. 冒号分隔
  #    验证 : 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-07] import with colon delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_colon.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_colon 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_colon"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:ColonVertex {name: 'Bob'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name | n.age |
      | 'Bob'  | 25    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:ColonVertex {name: 'Bob'})-[r:COLON_EDGE]->(b:ColonVertex {name: 'Charlie'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2021    |

  # ---------------------------------------------------------------------------
  # 8. 感叹号分隔
  #    验证 ! 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-08] import with exclamation delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_exclamation.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_exclamation 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_exclamation"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:ExclamationVertex {name: 'Charlie'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name    | n.age |
      | 'Charlie' | 35    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:ExclamationVertex {name: 'Alice'})-[r:EXCLAMATION_EDGE]->(b:ExclamationVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 9. @ 符号分隔
  #    验证 @ 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-09] import with at delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_at.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_at 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_at"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:AtVertex {name: 'Alice'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:AtVertex {name: 'Alice'})-[r:AT_EDGE]->(b:AtVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 10. # 符号分隔
  #    验证 # 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-10] import with hash delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_hash.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_hash 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_hash"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:HashVertex {name: 'Bob'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name | n.age |
      | 'Bob'  | 25    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:HashVertex {name: 'Bob'})-[r:HASH_EDGE]->(b:HashVertex {name: 'Charlie'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2021    |

  # ---------------------------------------------------------------------------
  # 12. $ 符号分隔
  #    验证 $ 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-12] import with dollar delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_dollar.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_dollar 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_dollar"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:DollarVertex {name: 'Alice'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:DollarVertex {name: 'Alice'})-[r:DOLLAR_EDGE]->(b:DollarVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 13. % 符号分隔
  #    验证 % 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-13] import with percent delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_percent.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_percent 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_percent"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:PercentVertex {name: 'Bob'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name | n.age |
      | 'Bob'  | 25    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:PercentVertex {name: 'Bob'})-[r:PERCENT_EDGE]->(b:PercentVertex {name: 'Charlie'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2021    |

  # ---------------------------------------------------------------------------
  # 14. ^ 符号分隔
  #    验证 ^ 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-14] import with caret delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_caret.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_caret 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_caret"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:CaretVertex {name: 'Charlie'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name    | n.age |
      | 'Charlie' | 35    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:CaretVertex {name: 'Alice'})-[r:CARET_EDGE]->(b:CaretVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 15. & 符号分隔
  #    验证 & 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-15] import with ampersand delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_ampersand.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_ampersand 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_ampersand"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:AmpersandVertex {name: 'Alice'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name  | n.age |
      | 'Alice' | 30    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:AmpersandVertex {name: 'Alice'})-[r:AMPERSAND_EDGE]->(b:AmpersandVertex {name: 'Bob'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2020    |

  # ---------------------------------------------------------------------------
  # 16. * 符号分隔
  #    验证 * 分隔符正确解析 vertex 和 edge
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-16] import with asterisk delimiter
    When executing gdm-admin import with manifest "delimiter/manifest_asterisk.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 delimiter_asterisk 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["delimiter_asterisk"]
    # 总量校验
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
    # 顶点抽样校验
    When executing query without error:
      """
      MATCH (n:AsteriskVertex {name: 'Bob'}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name | n.age |
      | 'Bob'  | 25    |
    # 边抽样校验
    When executing query without error:
      """
      MATCH (a:AsteriskVertex {name: 'Bob'})-[r:ASTERISK_EDGE]->(b:AsteriskVertex {name: 'Charlie'}) RETURN r.since
      """
    Then the result should be, in any order:
      | r.since |
      | 2021    |

  # ---------------------------------------------------------------------------
  # 17. 多字符分隔符 - 顶点（反向）
  #    验证多字符分隔符（如 ##）在顶点导入时应报错或拒绝
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-17] multi-character delimiter on vertex import should fail
    When executing gdm-admin import with manifest "delimiter/manifest_multi_char_vertex.toml"
    Then the CLI exit code should not be 0
    And the error message should contain 'delimiter must be a single character'

  # ---------------------------------------------------------------------------
  # 18. 多字符分隔符 - 边（反向）
  #    验证多字符分隔符（如 ##）在边导入时应报错或拒绝
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-18] multi-character delimiter on edge import should fail
    When executing gdm-admin import with manifest "delimiter/manifest_multi_char_edge.toml"
    Then the CLI exit code should not be 0
    And the error message should contain 'delimiter must be a single character'

  # ---------------------------------------------------------------------------
  # 19. 不支持的特殊字符分隔符 - 顶点（反向）
  #    验证不支持的特殊字符（如空字符 \u0000）在顶点导入时应报错或拒绝
  #    TODO: 手动验证后更新校验点 gdm87
  # 实测Error: "id field 'id' for label 'SpecialCharEdgeVertex' column \"id\" not found in testdata/import/delimiter/vertices_comma.csv"
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-19] unsupported special character delimiter on vertex import should fail
    When executing gdm-admin import with manifest "delimiter/manifest_special_char_vertex.toml"
    # TODO: 手动验证后补充 Then 校验点

  # ---------------------------------------------------------------------------
  # 20. 不支持的特殊字符分隔符 - 边（反向）
  #    验证不支持的特殊字符（如空字符 \u0000）在边导入时应报错或拒绝
  #    TODO: 手动验证后更新校验点
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-20] unsupported special character delimiter on edge import should fail
    When executing gdm-admin import with manifest "delimiter/manifest_special_char_edge.toml"
    # TODO: 手动验证后补充 Then 校验点

  # ---------------------------------------------------------------------------
  # 10. 多字符分隔符 - 边（反向）
  #    验证多字符分隔符（如 ##）在边导入时应报错或拒绝
  #    TODO: 手动验证后更新校验点
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-10] multi-character delimiter on edge import should fail
    When executing gdm-admin import with manifest "delimiter/manifest_multi_char_edge.toml"
    # TODO: 手动验证后补充 Then 校验点

  # ---------------------------------------------------------------------------
  # 11. ￥ 符号分隔（反向）
  #    验证多字节字符 ￥（U+FFE5，3字节UTF-8）作为分隔符时应报错或拒绝
  #    产品限制：分隔符仅支持单字节字符（u8）
  #    TODO: 手动验证后更新校验点
  # ---------------------------------------------------------------------------

  Scenario: [Import-Delimiter-11] multi-byte character yen delimiter should fail
    When executing gdm-admin import with manifest "delimiter/manifest_yen.toml"
    # TODO: 手动验证后补充 Then 校验点
