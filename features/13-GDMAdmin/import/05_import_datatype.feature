# encoding: utf-8
#
# GDM Admin Import: Data Type Coverage - data type handling scenarios
#
# 测试范围:
#   - 基础类型: string, int, float, boolean
#   - 时间类型: date, datetime, localdatetime, localtime, time, duration
#   - 空间类型: WGS84-2D, WGS84-3D, Cartesian-2D, Cartesian-3D (预留)
#   - 特殊类型: null
#   - 类型自动推断
#   - 每个用例同时覆盖 vertex 和 edge
#   - 每个用例包含导入后库中数据校验
#
# fixme code: 暂未支持导入的数据类型：point、list、map
#
@admin @import
Feature: GDM Admin Import - Data Type Coverage

  Background:
    Given having executed:
      """
      DROP GRAPH datatype_basic
      """
    And having executed:
      """
      DROP GRAPH datatype
      """
    And having executed:
      """
      DROP GRAPH datatype_null
      """
    And having executed:
      """
      DROP GRAPH datatype_infer
      """
    And having executed:
      """
      DROP GRAPH datatype_infer_time
      """

  # ---------------------------------------------------------------------------
  # 1. 基础类型
  #    验证 string, int, float, boolean 类型的顶点和边属性导入
  #    manifest: datatype/manifest_basic.toml
  #    数据: basic_vertices.csv (2行), basic_edges.csv (2行)
  # ---------------------------------------------------------------------------

  Scenario: [Import-Datatype-01] import vertex and edge with basic types (string, int, float, boolean)
    When executing gdm-admin import with manifest "datatype/manifest_basic.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 datatype_basic 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["datatype_basic"]
    # 顶点总量校验
    When executing query without error:
      """
      MATCH (n:BasicVertex) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # 边总量校验
    When executing query without error:
      """
      MATCH ()-[r:BASIC_EDGE]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # 顶点抽样校验: Alice
    When executing query without error:
      """
      MATCH (n:BasicVertex {name: 'Alice'}) RETURN n.id, n.name, n.age, n.score, n.active
      """
    Then the result should be, in any order:
      | n.id | n.name  | n.age | n.score | n.active |
      | 1    | 'Alice' | 30    | 3.14    | true     |
    # 顶点抽样校验: Bob
    When executing query without error:
      """
      MATCH (n:BasicVertex {name: 'Bob'}) RETURN n.id, n.name, n.age, n.score, n.active
      """
    Then the result should be, in any order:
      | n.id | n.name | n.age | n.score | n.active |
      | 2    | 'Bob'  | 25    | 2.71    | false    |
    # 边抽样校验: Alice->Bob
    When executing query without error:
      """
      MATCH (a:BasicVertex {name: 'Alice'})-[r:BASIC_EDGE]->(b:BasicVertex {name: 'Bob'})
      RETURN r.since, r.weight, r.active
      """
    Then the result should be, in any order:
      | r.since | r.weight | r.active |
      | 2020    | 0.8      | true     |

  # ---------------------------------------------------------------------------
  # 2. 时间类型综合
  #    验证 6 种时间类型 (date, datetime, localdatetime, localtime, time, duration)
  #    同时导入的顶点和边属性
  #    manifest: datatype/manifest.toml
  #    数据: typed_vertices.csv (3行), typed_edges.csv (2行)
  # ---------------------------------------------------------------------------

  Scenario: [Import-Datatype-02] import vertex and edge with all time types (date, datetime, localdatetime, localtime, time, duration)
    When executing gdm-admin import with manifest "datatype/manifest.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 datatype 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["datatype"]
    # 顶点总量校验
    When executing query without error:
      """
      MATCH (n:TypeVertex) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # 边总量校验
    When executing query without error:
      """
      MATCH ()-[r:TYPE_EDGE]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # 顶点抽样校验: Alice 的 date 类型属性
    When executing query without error:
      """
      MATCH (n:TypeVertex {name: 'Alice'}) RETURN n.created_date
      """
    Then the result should be, in any order:
      | n.created_date |
      | '2024-01-15'   |
    # 顶点抽样校验: Alice 的 datetime 类型属性
    When executing query without error:
      """
      MATCH (n:TypeVertex {name: 'Alice'}) RETURN n.created_datetime
      """
    Then the result should be, in any order:
      | n.created_datetime |
      | '2024-01-15T12:30:00Z' |
    # 顶点抽样校验: Alice 的 localdatetime 类型属性
    When executing query without error:
      """
      MATCH (n:TypeVertex {name: 'Alice'}) RETURN n.localdatetime_val
      """
    Then the result should be, in any order:
      | n.localdatetime_val |
      | '2024-01-15T12:30:00' |
    # 顶点抽样校验: Alice 的 localtime 类型属性
    When executing query without error:
      """
      MATCH (n:TypeVertex {name: 'Alice'}) RETURN n.localtime_val
      """
    Then the result should be, in any order:
      | n.localtime_val |
      | '12:30:00'      |
    # 顶点抽样校验: Alice 的 time 类型属性
    When executing query without error:
      """
      MATCH (n:TypeVertex {name: 'Alice'}) RETURN n.time_val
      """
    Then the result should be, in any order:
      | n.time_val |
      | '12:30:00+08:00' |
    # 顶点抽样校验: Alice 的 duration 类型属性
    When executing query without error:
      """
      MATCH (n:TypeVertex {name: 'Alice'}) RETURN n.duration_val
      """
    Then the result should be, in any order:
      | n.duration_val |
      | 'P1DT2H'       |
    # 边抽样校验: Alice->Bob 的 date 类型属性
    When executing query without error:
      """
      MATCH (a:TypeVertex {name: 'Alice'})-[r:TYPE_EDGE]->(b:TypeVertex {name: 'Bob'})
      RETURN r.created_date
      """
    Then the result should be, in any order:
      | r.created_date |
      | '2024-01-15'   |
    # 边抽样校验: Alice->Bob 的 datetime 类型属性
    When executing query without error:
      """
      MATCH (a:TypeVertex {name: 'Alice'})-[r:TYPE_EDGE]->(b:TypeVertex {name: 'Bob'})
      RETURN r.created_datetime
      """
    Then the result should be, in any order:
      | r.created_datetime |
      | '2024-01-15T12:30:00Z' |
    # 边抽样校验: Alice->Bob 的 duration 类型属性
    When executing query without error:
      """
      MATCH (a:TypeVertex {name: 'Alice'})-[r:TYPE_EDGE]->(b:TypeVertex {name: 'Bob'})
      RETURN r.duration_val
      """
    Then the result should be, in any order:
      | r.duration_val |
      | 'P1DT2H'       |

  # ---------------------------------------------------------------------------
  # 3. 空间类型 (预留)
  #    验证空间数据类型 (WGS84-2D, WGS84-3D, Cartesian-2D, Cartesian-3D)
  #    待 gdm-admin 支持 point 类型导入后补充
  # ---------------------------------------------------------------------------

  # fixme: 暂未支持导入的数据类型：point
  # Scenario: [Import-Datatype-03] import vertex and edge with spatial types (WGS84-2D, WGS84-3D, Cartesian-2D, Cartesian-3D)

  # ---------------------------------------------------------------------------
  # 4. NULL 值
  #    验证包含 null 值的顶点和边属性导入
  #    覆盖所有数据类型的 null: string, int, float, boolean, date, datetime,
  #    localdatetime, localtime, time, duration
  #    manifest: datatype/manifest_null.toml
  #    数据: null_vertices.csv (6行, 每列至少1个空值)
  #          null_edges.csv (5行, 每列至少1个空值)
  # ---------------------------------------------------------------------------

  Scenario: [Import-Datatype-04] import vertex and edge with null values across all data types - fixme code gdm75
    When executing gdm-admin import with manifest "datatype/manifest_null.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 6 vertices imported
    And the import summary should show 5 edges imported
    # 切换到 datatype_null 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["datatype_null"]
    # 顶点总量校验
    When executing query without error:
      """
      MATCH (n:NullVertex) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 6   |
    # 边总量校验
    When executing query without error:
      """
      MATCH ()-[r:NULL_EDGE]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 5   |
    # ---- 顶点: Alice (全量非空基线) ----
    When executing query without error:
      """
      MATCH (n:NullVertex {id: 1})
      RETURN n.name, n.age, n.score, n.active, n.created_date, n.duration_val
      """
    Then the result should be, in any order:
      | n.name  | n.age | n.score | n.active | n.created_date | n.duration_val |
      | 'Alice' | 30    | 3.14    | true     | '2024-01-15'   | 'P1DT2H'       |
    # ---- 顶点: Bob (int=null, float=null, boolean=null, 时间全null) ----
    When executing query without error:
      """
      MATCH (n:NullVertex {id: 2})
      RETURN n.name, n.age, n.score, n.active, n.created_date, n.duration_val
      """
    Then the result should be, in any order:
      | n.name | n.age | n.score | n.active | n.created_date | n.duration_val |
      | 'Bob'  | null  | null    | null     | null           | null           |
    # ---- 顶点: EmptyName (string=null) ----
    When executing query without error:
      """
      MATCH (n:NullVertex {id: 3}) RETURN n.name, n.age
      """
    Then the result should be, in any order:
      | n.name | n.age |
      | null   | 25    |
    # ---- 顶点: OnlyFalse (boolean=null) ----
    When executing query without error:
      """
      MATCH (n:NullVertex {id: 4}) RETURN n.active
      """
    Then the result should be, in any order:
      | n.active |
      | false    |
    # ---- 顶点: id=5 (基本类型全null, 时间类型非空) ----
    When executing query without error:
      """
      MATCH (n:NullVertex {id: 5})
      RETURN n.name, n.age, n.score, n.active, n.created_datetime, n.duration_val
      """
    Then the result should be, in any order:
      | n.name | n.age | n.score | n.active | n.created_datetime | n.duration_val |
      | null   | null  | null    | null     | '2024-02-20T08:00+00:00' | 'PT30M'  |
    # ---- 顶点: NullAll (除id外全null) ----
    When executing query without error:
      """
      MATCH (n:NullVertex {id: 6})
      RETURN n.name, n.age, n.score, n.active, n.created_date, n.duration_val
      """
    Then the result should be, in any order:
      | n.name    | n.age | n.score | n.active | n.created_date | n.duration_val |
      | 'NullAll' | null  | null    | null     | null           | null           |
    # ---- 边: Alice->Bob (全量非空基线) ----
    When executing query without error:
      """
      MATCH (a:NullVertex {id: 1})-[r:NULL_EDGE]->(b:NullVertex {id: 2})
      RETURN r.since, r.weight, r.active, r.created_date, r.duration_val
      """
    Then the result should be, in any order:
      | r.since | r.weight | r.active | r.created_date | r.duration_val |
      | 2020    | 0.8      | true     | '2024-01-15'   | 'P1DT2H'       |
    # ---- 边: Bob->EmptyName (基本类型全null, 时间全null) ----
    When executing query without error:
      """
      MATCH (a:NullVertex {id: 2})-[r:NULL_EDGE]->(b:NullVertex {id: 3})
      RETURN r.since, r.weight, r.active, r.created_date, r.duration_val
      """
    Then the result should be, in any order:
      | r.since | r.weight | r.active | r.created_date | r.duration_val |
      | null    | null     | null     | null           | null           |
    # ---- 边: OnlyFalse->id5 (float非空, 其余null) ----
    When executing query without error:
      """
      MATCH (a:NullVertex {id: 4})-[r:NULL_EDGE]->(b:NullVertex {id: 5})
      RETURN r.since, r.weight, r.active
      """
    Then the result should be, in any order:
      | r.since | r.weight | r.active |
      | null    | 0.6      | null     |
    # ---- 边: Alice->EmptyName (仅boolean非空) ----
    When executing query without error:
      """
      MATCH (a:NullVertex {id: 1})-[r:NULL_EDGE]->(b:NullVertex {id: 3})
      RETURN r.since, r.weight, r.active
      """
    Then the result should be, in any order:
      | r.since | r.weight | r.active |
      | null    | null     | false    |
    # ---- 边: id5->NullAll (仅duration非空) ----
    When executing query without error:
      """
      MATCH (a:NullVertex {id: 5})-[r:NULL_EDGE]->(b:NullVertex {id: 6})
      RETURN r.since, r.weight, r.active, r.duration_val
      """
    Then the result should be, in any order:
      | r.since | r.weight | r.active | r.duration_val |
      | null    | null     | null     | 'P3DT4H'       |

  # ---------------------------------------------------------------------------
  # 5. 类型自动推断
  #    验证省略 type 时的自动推断行为
  #    manifest: datatype/manifest_infer.toml (无 type 声明)
  #    数据: 基础类型 CSV, 覆盖 string/int/float/boolean
  # ---------------------------------------------------------------------------

  Scenario: [Import-Datatype-05] import vertex and edge with type auto-inference-basicType
    When executing gdm-admin import with manifest "datatype/manifest_infer.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 datatype_infer 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["datatype_infer"]
    # 顶点总量校验
    When executing query without error:
      """
      MATCH (n:InferVertex) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3  |
    # 边总量校验
    When executing query without error:
      """
      MATCH ()-[r:INFER_EDGE]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # 顶点抽样校验: Alice (自动推断类型)
    When executing query without error:
      """
      MATCH (n:InferVertex {name: 'Alice'}) RETURN n.id, n.name, n.age, n.score, n.active
      """
    Then the result should be, in any order:
      | n.id | n.name  | n.age | n.score | n.active |
      | 1    | 'Alice' | 30    | 3.14    | true     |
    # 顶点抽样校验: Bob (自动推断类型)
    When executing query without error:
      """
      MATCH (n:InferVertex {name: 'Bob'}) RETURN n.id, n.name, n.age, n.score, n.active
      """
    Then the result should be, in any order:
      | n.id | n.name | n.age | n.score | n.active |
      | 2    | 'Bob'  | 25    | 2.71    | false    |
    # 边抽样校验: Alice->Bob (自动推断类型)
    When executing query without error:
      """
      MATCH (a:InferVertex {name: 'Alice'})-[r:INFER_EDGE]->(b:InferVertex {name: 'Bob'})
      RETURN r.since, r.weight, r.active
      """
    Then the result should be, in any order:
      | r.since | r.weight | r.active |
      | 2020    | 0.8      | true     |

  # ---------------------------------------------------------------------------
  # 6. 时间类型自动推断
  #    验证省略 type 声明时，时间类型值的自动推断行为
  #    预期: 时间格式字符串被存储为 string 类型（非原生时间类型）
  #    manifest: datatype/manifest_infer_time.toml (无 type 声明)
  #    数据: typed_vertices.csv (3行), typed_edges.csv (2行)
  # ---------------------------------------------------------------------------

  Scenario: [Import-Datatype-06] import vertex and edge with type auto-inference for time types
    When executing gdm-admin import with manifest "datatype/manifest_infer_time.toml"
    Then the CLI exit code should be 0
    And the import summary should show status "OK"
    And the import summary should show 3 vertices imported
    And the import summary should show 2 edges imported
    # 切换到 datatype_infer_time 图进行数据校验
    When login in user for USER["admin"]-PWD["admin123"]-DB["datatype_infer_time"]
    # 顶点总量校验
    When executing query without error:
      """
      MATCH (n:InferTimeVertex) RETURN count(n) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 3   |
    # 边总量校验
    When executing query without error:
      """
      MATCH ()-[r:INFER_TIME_EDGE]->() RETURN count(r) AS cnt
      """
    Then the result should be, in any order:
      | cnt |
      | 2   |
    # 顶点抽样校验: Alice 的 date 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (n:InferTimeVertex {name: 'Alice'}) RETURN n.created_date
      """
    Then the result should be, in any order:
      | n.created_date |
      | '2024-01-15'   |
    # 顶点抽样校验: Alice 的 datetime 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (n:InferTimeVertex {name: 'Alice'}) RETURN n.created_datetime
      """
    Then the result should be, in any order:
      | n.created_datetime |
      | '2024-01-15T12:30:00Z' |
    # 顶点抽样校验: Alice 的 localdatetime 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (n:InferTimeVertex {name: 'Alice'}) RETURN n.localdatetime_val
      """
    Then the result should be, in any order:
      | n.localdatetime_val |
      | '2024-01-15T12:30:00' |
    # 顶点抽样校验: Alice 的 localtime 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (n:InferTimeVertex {name: 'Alice'}) RETURN n.localtime_val
      """
    Then the result should be, in any order:
      | n.localtime_val |
      | '12:30:00'      |
    # 顶点抽样校验: Alice 的 time 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (n:InferTimeVertex {name: 'Alice'}) RETURN n.time_val
      """
    Then the result should be, in any order:
      | n.time_val |
      | '12:30:00+08:00' |
    # 顶点抽样校验: Alice 的 duration 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (n:InferTimeVertex {name: 'Alice'}) RETURN n.duration_val
      """
    Then the result should be, in any order:
      | n.duration_val |
      | 'P1DT2H'       |
    # 边抽样校验: Alice->Bob 的 date 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (a:InferTimeVertex {name: 'Alice'})-[r:INFER_TIME_EDGE]->(b:InferTimeVertex {name: 'Bob'})
      RETURN r.created_date
      """
    Then the result should be, in any order:
      | r.created_date |
      | '2024-01-15'   |
    # 边抽样校验: Alice->Bob 的 datetime 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (a:InferTimeVertex {name: 'Alice'})-[r:INFER_TIME_EDGE]->(b:InferTimeVertex {name: 'Bob'})
      RETURN r.created_datetime
      """
    Then the result should be, in any order:
      | r.created_datetime |
      | '2024-01-15T12:30:00Z' |
    # 边抽样校验: Alice->Bob 的 duration 自动推断（应为字符串）
    When executing query without error:
      """
      MATCH (a:InferTimeVertex {name: 'Alice'})-[r:INFER_TIME_EDGE]->(b:InferTimeVertex {name: 'Bob'})
      RETURN r.duration_val
      """
    Then the result should be, in any order:
      | r.duration_val |
      | 'P1DT2H'       |
