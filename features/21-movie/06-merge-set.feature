#encoding: utf-8

# =============================================================================
# Feature: Movie Scenario - Step 6: MERGE and SET Incremental Update
# =============================================================================
# 来源: GDMBASE 电影知识场景教学（初级）第6步
# 目标: 在不破坏已有数据的前提下，做"新增或更新"的日常维护
# 前置条件: 需要完整的电影数据集
# =============================================================================

Feature: MovieScenario06 - MERGE and SET incremental update

  Background:
    # 初始化完整的电影数据集
    Given an empty graph
    And having executed:
      """
      CREATE
      (:人物 {姓名:'郭帆', 职业:'导演', 出生年:1980}),
      (:人物 {姓名:'吴京', 职业:'演员', 出生年:1974}),
      (:人物 {姓名:'刘德华', 职业:'演员', 出生年:1961}),
      (:人物 {姓名:'文牧野', 职业:'导演', 出生年:1985}),
      (:人物 {姓名:'徐峥', 职业:'演员', 出生年:1972}),
      (:人物 {姓名:'姜文', 职业:'导演', 出生年:1963}),
      (:人物 {姓名:'饺子', 职业:'导演', 出生年:1980}),
      (:电影 {片名:'流浪地球', 上映年:2019, 豆瓣评分:7.9, 片长:125}),
      (:电影 {片名:'流浪地球2', 上映年:2023, 豆瓣评分:8.3, 片长:173}),
      (:电影 {片名:'我不是药神', 上映年:2018, 豆瓣评分:9.0, 片长:117}),
      (:电影 {片名:'让子弹飞', 上映年:2010, 豆瓣评分:8.9, 片长:132}),
      (:电影 {片名:'哪吒之魔童降世', 上映年:2019, 豆瓣评分:8.4, 片长:110}),
      (:类型 {名称:'科幻'}),
      (:类型 {名称:'剧情'}),
      (:类型 {名称:'喜剧'}),
      (:类型 {名称:'动画'}),
      (:国家 {名称:'中国大陆'}),
      (:国家 {名称:'中国香港'}),
      (:奖项 {名称:'金鸡奖最佳故事片', 年份:2023}),
      (:奖项 {名称:'百花奖最佳影片', 年份:2018})
      """
    And having executed:
      """
      MATCH (guo:人物 {姓名:'郭帆'}), (wj:人物 {姓名:'吴京'}), (ldh:人物 {姓名:'刘德华'}),
            (wmy:人物 {姓名:'文牧野'}), (xz:人物 {姓名:'徐峥'}), (jw:人物 {姓名:'姜文'}), (jz:人物 {姓名:'饺子'}),
            (m1:电影 {片名:'流浪地球'}), (m2:电影 {片名:'流浪地球2'}), (m3:电影 {片名:'我不是药神'}),
            (m4:电影 {片名:'让子弹飞'}), (m5:电影 {片名:'哪吒之魔童降世'}),
            (sf:类型 {名称:'科幻'}), (dr:类型 {名称:'剧情'}), (xj:类型 {名称:'喜剧'}), (dh:类型 {名称:'动画'}),
            (cn:国家 {名称:'中国大陆'}), (hk:国家 {名称:'中国香港'}),
            (a1:奖项 {名称:'金鸡奖最佳故事片'}), (a2:奖项 {名称:'百花奖最佳影片'})
      CREATE
      (guo)-[:导演]->(m1),
      (guo)-[:导演]->(m2),
      (wj)-[:参演 {角色:'刘培强'}]->(m1),
      (wj)-[:参演 {角色:'刘培强'}]->(m2),
      (ldh)-[:参演 {角色:'图恒宇'}]->(m2),
      (wmy)-[:导演]->(m3),
      (xz)-[:参演 {角色:'程勇'}]->(m3),
      (jw)-[:导演]->(m4),
      (jw)-[:参演 {角色:'张牧之'}]->(m4),
      (jz)-[:导演]->(m5),
      (m1)-[:属于类型]->(sf),
      (m2)-[:属于类型]->(sf),
      (m3)-[:属于类型]->(dr),
      (m4)-[:属于类型]->(dr),
      (m4)-[:属于类型]->(xj),
      (m5)-[:属于类型]->(dh),
      (m1)-[:出品国家]->(cn),
      (m2)-[:出品国家]->(cn),
      (m3)-[:出品国家]->(cn),
      (m4)-[:出品国家]->(cn),
      (m4)-[:出品国家]->(hk),
      (m5)-[:出品国家]->(cn),
      (m2)-[:获得奖项]->(a1),
      (m3)-[:获得奖项]->(a2)
      """

  # ---------------------------------------------------------------------------
  # Scenario: 新增一部电影并补全导演/类型/国家关系
  # MERGE + SET 标准组合：MERGE 负责"有没有这条结构"，SET 负责"属性值是什么"
  # 可以重复执行，不容易产生重复节点和重复关系
  # ---------------------------------------------------------------------------
  Scenario: [1] Add a new movie with director, genre and country
    When executing query:
      """
      MERGE (m:电影 {片名:'独行月球'})
      SET m.上映年 = 2022, m.豆瓣评分 = 6.8, m.片长 = 122
      MERGE (d:人物 {姓名:'张吃鱼'})
      SET d.职业 = '导演', d.出生年 = 1986
      MERGE (t:类型 {名称:'科幻'})
      MERGE (c:国家 {名称:'中国大陆'})
      MERGE (d)-[:导演]->(m)
      MERGE (m)-[:属于类型]->(t)
      MERGE (m)-[:出品国家]->(c)
      """
    Then the result should be empty
    And no side effects
    # 验证新增的电影
    When executing query:
      """
      MATCH (m:电影 {片名:'独行月球'})
      RETURN m.片名 AS 片名, m.上映年 AS 上映年, m.豆瓣评分 AS 豆瓣评分, m.片长 AS 片长
      """
    Then the result should be, in any order:
      | 片名     | 上映年 | 豆瓣评分 | 片长 |
      | 独行月球 | 2022   | 6.8      | 122  |
    # 验证导演关系
    When executing query:
      """
      MATCH (p:人物)-[:导演]->(m:电影 {片名:'独行月球'})
      RETURN p.姓名 AS 导演
      """
    Then the result should be, in any order:
      | 导演   |
      | 张吃鱼 |
    # 验证类型关系
    When executing query:
      """
      MATCH (m:电影 {片名:'独行月球'})-[:属于类型]->(g:类型)
      RETURN g.名称 AS 类型
      """
    Then the result should be, in any order:
      | 类型 |
      | 科幻 |
    # 验证国家关系
    When executing query:
      """
      MATCH (m:电影 {片名:'独行月球'})-[:出品国家]->(c:国家)
      RETURN c.名称 AS 国家
      """
    Then the result should be, in any order:
      | 国家     |
      | 中国大陆 |

  # ---------------------------------------------------------------------------
  # Scenario: 补充演员关系（重复执行也不会重复创建）
  # 先 MATCH 到目标电影，再 MERGE 演员节点和参演关系
  # ---------------------------------------------------------------------------
  Scenario: [2] Add actor relationship with role
    When executing query:
      """
      MATCH (m:电影 {片名:'独行月球'})
      MERGE (a:人物 {姓名:'沈腾'})
      SET a.职业 = '演员', a.出生年 = 1979
      MERGE (a)-[:参演 {角色:'独孤月'}]->(m)
      """
    Then the result should be empty
    And no side effects
    # 验证演员关系
    When executing query:
      """
      MATCH (p:人物)-[r:参演]->(m:电影 {片名:'独行月球'})
      RETURN p.姓名 AS 演员, r.角色 AS 角色
      """
    Then the result should be, in any order:
      | 演员 | 角色   |
      | 沈腾 | 独孤月 |

  # ---------------------------------------------------------------------------
  # Scenario: 为同片演员建立"合作过"关系
  # 通过同一电影的双向参演模式找出"共同参演"的演员对
  # WHERE a <> b 排除演员与自己建立关系
  # ---------------------------------------------------------------------------
  Scenario: [3] Create cooperation relationships between actors
    Given having executed:
      """
      MATCH (m:电影 {片名:'流浪地球2'})
      MERGE (a:人物 {姓名:'吴京'})
      MERGE (b:人物 {姓名:'刘德华'})
      MERGE (a)-[:参演 {角色:'刘培强'}]->(m)
      MERGE (b)-[:参演 {角色:'图恒宇'}]->(m)
      """
    When executing query:
      """
      MATCH (a:人物)-[:参演]->(m:电影)<-[:参演]-(b:人物)
      WHERE a <> b
      MERGE (a)-[:合作过]->(b)
      """
    Then the result should be empty
    And no side effects
    # 验证合作关系
    When executing query:
      """
      MATCH (a:人物)-[:合作过]->(b:人物)
      RETURN a.姓名 AS 演员A, b.姓名 AS 演员B
      ORDER BY 演员A, 演员B
      """
    Then the result should be, in order:
      | 演员A  | 演员B  |
      | 刘德华 | 吴京   |
      | 吴京   | 刘德华 |

  # ---------------------------------------------------------------------------
  # Scenario: 验证更新结果
  # 查询新增电影的导演和演员关系
  # ---------------------------------------------------------------------------
  Scenario: [4] Verify incremental update results
    Given having executed:
      """
      MERGE (m:电影 {片名:'独行月球'})
      SET m.上映年 = 2022, m.豆瓣评分 = 6.8, m.片长 = 122
      MERGE (d:人物 {姓名:'张吃鱼'})
      SET d.职业 = '导演', d.出生年 = 1986
      MERGE (a:人物 {姓名:'沈腾'})
      SET a.职业 = '演员', a.出生年 = 1979
      MERGE (d)-[:导演]->(m)
      MERGE (a)-[:参演 {角色:'独孤月'}]->(m)
      """
    When executing query:
      """
      MATCH (p:人物)-[r:导演|参演]->(m:电影 {片名:'独行月球'})
      RETURN p.姓名 AS 姓名, type(r) AS 关系, m.片名 AS 电影
      ORDER BY 关系, 姓名
      """
    Then the result should be, in order:
      | 姓名   | 关系 | 电影     |
      | 张吃鱼 | 导演 | 独行月球 |
      | 沈腾   | 参演 | 独行月球 |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 重复执行 MERGE 不会创建重复数据
  # 验证幂等性
  # ---------------------------------------------------------------------------
  Scenario: [5] MERGE idempotency test
    When executing query:
      """
      MERGE (m:电影 {片名:'测试电影'})
      SET m.上映年 = 2024
      """
    Then the result should be empty
    When executing query:
      """
      MERGE (m:电影 {片名:'测试电影'})
      SET m.上映年 = 2024
      """
    Then the result should be empty
    When executing query:
      """
      MATCH (m:电影 {片名:'测试电影'})
      RETURN count(m) AS 电影数量
      """
    Then the result should be, in any order:
      | 电影数量 |
      | 1        |

  # ---------------------------------------------------------------------------
  # Scenario: 使用 MERGE 更新已有属性
  # ---------------------------------------------------------------------------
  Scenario: [6] Update existing properties with MERGE and SET
    Given having executed:
      """
      CREATE (:电影 {片名:'测试更新', 上映年:2020, 豆瓣评分:7.0})
      """
    When executing query:
      """
      MERGE (m:电影 {片名:'测试更新'})
      SET m.豆瓣评分 = 8.0, m.片长 = 120
      RETURN m.片名 AS 片名, m.上映年 AS 上映年, m.豆瓣评分 AS 豆瓣评分, m.片长 AS 片长
      """
    Then the result should be, in any order:
      | 片名     | 上映年 | 豆瓣评分 | 片长 |
      | 测试更新 | 2020   | 8.0      | 120  |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 使用 MERGE 创建关系（不存在则创建，存在则复用）
  # ---------------------------------------------------------------------------
  Scenario: [7] Create relationship with MERGE
    Given having executed:
      """
      CREATE (:人物 {姓名:'测试人物A'}), (:人物 {姓名:'测试人物B'})
      """
    When executing query:
      """
      MATCH (a:人物 {姓名:'测试人物A'}), (b:人物 {姓名:'测试人物B'})
      MERGE (a)-[:合作过]->(b)
      """
    Then the result should be empty
    When executing query:
      """
      MATCH (a:人物 {姓名:'测试人物A'})-[r:合作过]->(b:人物 {姓名:'测试人物B'})
      RETURN count(r) AS 关系数量
      """
    Then the result should be, in any order:
      | 关系数量 |
      | 1        |
    # 再次执行 MERGE，不应创建重复关系
    When executing query:
      """
      MATCH (a:人物 {姓名:'测试人物A'}), (b:人物 {姓名:'测试人物B'})
      MERGE (a)-[:合作过]->(b)
      """
    Then the result should be empty
    When executing query:
      """
      MATCH (a:人物 {姓名:'测试人物A'})-[r:合作过]->(b:人物 {姓名:'测试人物B'})
      RETURN count(r) AS 关系数量
      """
    Then the result should be, in any order:
      | 关系数量 |
      | 1        |

  # ---------------------------------------------------------------------------
  # Scenario: 使用 SET 添加新属性到已有节点
  # ---------------------------------------------------------------------------
  Scenario: [8] Add new properties to existing nodes with SET
    Given having executed:
      """
      CREATE (:电影 {片名:'属性测试', 上映年:2023})
      """
    When executing query:
      """
      MATCH (m:电影 {片名:'属性测试'})
      SET m.豆瓣评分 = 8.5, m.片长 = 130
      RETURN m.片名 AS 片名, m.上映年 AS 上映年, m.豆瓣评分 AS 豆瓣评分, m.片长 AS 片长
      """
    Then the result should be, in any order:
      | 片名     | 上映年 | 豆瓣评分 | 片长 |
      | 属性测试 | 2023   | 8.5      | 130  |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 综合增量更新场景
  # 新增电影 + 导演 + 演员 + 类型 + 国家，并验证完整数据
  # ---------------------------------------------------------------------------
  Scenario: [9] Complete incremental update workflow
    When executing query:
      """
      MERGE (m:电影 {片名:'新片测试'})
      SET m.上映年 = 2024, m.豆瓣评分 = 7.5, m.片长 = 100
      MERGE (d:人物 {姓名:'新导演'})
      SET d.职业 = '导演', d.出生年 = 1990
      MERGE (a:人物 {姓名:'新演员'})
      SET a.职业 = '演员', a.出生年 = 1995
      MERGE (t:类型 {名称:'新类型'})
      MERGE (c:国家 {名称:'新国家'})
      MERGE (d)-[:导演]->(m)
      MERGE (a)-[:参演 {角色:'主角'}]->(m)
      MERGE (m)-[:属于类型]->(t)
      MERGE (m)-[:出品国家]->(c)
      """
    Then the result should be empty
    And no side effects
    # 验证电影节点
    When executing query:
      """
      MATCH (m:电影 {片名:'新片测试'})
      RETURN m.片名 AS 片名, m.上映年 AS 上映年, m.豆瓣评分 AS 豆瓣评分, m.片长 AS 片长
      """
    Then the result should be, in any order:
      | 片名     | 上映年 | 豆瓣评分 | 片长 |
      | 新片测试 | 2024   | 7.5      | 100  |
    # 验证导演关系
    When executing query:
      """
      MATCH (p:人物)-[:导演]->(m:电影 {片名:'新片测试'})
      RETURN p.姓名 AS 导演
      """
    Then the result should be, in any order:
      | 导演   |
      | 新导演 |
    # 验证演员关系
    When executing query:
      """
      MATCH (p:人物)-[r:参演]->(m:电影 {片名:'新片测试'})
      RETURN p.姓名 AS 演员, r.角色 AS 角色
      """
    Then the result should be, in any order:
      | 演员   | 角色 |
      | 新演员 | 主角 |
    # 验证类型关系
    When executing query:
      """
      MATCH (m:电影 {片名:'新片测试'})-[:属于类型]->(g:类型)
      RETURN g.名称 AS 类型
      """
    Then the result should be, in any order:
      | 类型   |
      | 新类型 |
    # 验证国家关系
    When executing query:
      """
      MATCH (m:电影 {片名:'新片测试'})-[:出品国家]->(c:国家)
      RETURN c.名称 AS 国家
      """
    Then the result should be, in any order:
      | 国家   |
      | 新国家 |
