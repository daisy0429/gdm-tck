#encoding: utf-8

# =============================================================================
# Feature: Movie Scenario - Step 5: OPTIONAL MATCH Missing Data Handling
# =============================================================================
# 来源: GDMBASE 电影知识场景教学（初级）第5步
# 目标: 当部分电影没有奖项、部分人物没有导演关系时，也能稳定返回结果
# 前置条件: 需要完整的电影数据集
# =============================================================================

Feature: MovieScenario05 - OPTIONAL MATCH missing data handling

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
  # Scenario: 查询电影和奖项（没有奖项也返回电影）
  # 先用 MATCH (m:电影) 固定主结果集，再用 OPTIONAL MATCH 尝试扩展奖项信息
  # 即便某电影没有奖项，也不会被过滤掉，奖项列返回 NULL
  # ---------------------------------------------------------------------------
  Scenario: [1] Query movies with optional awards
    When executing query:
      """
      MATCH (m:电影)
      OPTIONAL MATCH (m)-[:获得奖项]->(a:奖项)
      RETURN m.片名 AS 片名, a.名称 AS 奖项名称, a.年份 AS 获奖年份
      ORDER BY m.片名
      """
    Then the result should be, in order:
      | 片名           | 奖项名称         | 获奖年份 |
      | 哪吒之魔童降世 | null             | null     |
      | 流浪地球       | null             | null     |
      | 流浪地球2      | 金鸡奖最佳故事片 | 2023     |
      | 让子弹飞       | null             | null     |
      | 我不是药神     | 百花奖最佳影片   | 2018     |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 查询人物及其导演作品（没有执导作品也返回人物）
  # 保证每个人都能出现，是否有导演作品由导演作品字段是否为 NULL 体现
  # ---------------------------------------------------------------------------
  Scenario: [2] Query persons with optional directed movies
    When executing query:
      """
      MATCH (p:人物)
      OPTIONAL MATCH (p)-[:导演]->(m:电影)
      RETURN p.姓名 AS 姓名, m.片名 AS 导演作品
      ORDER BY p.姓名, 导演作品
      """
    Then the result should be, in order:
      | 姓名   | 导演作品       |
      | 吴京   | null           |
      | 刘德华 | null           |
      | 姜文   | 让子弹飞       |
      | 徐峥   | null           |
      | 文牧野 | 我不是药神     |
      | 郭帆   | 流浪地球       |
      | 郭帆   | 流浪地球2      |
      | 饺子   | 哪吒之魔童降世 |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 先定电影，再可选匹配演员
  # 把电影作为主对象先锁定，再可选查询演员关系
  # 适合做"电影详情接口"
  # ---------------------------------------------------------------------------
  Scenario: [3] Query specific movie with optional actors
    When executing query:
      """
      MATCH (m:电影 {片名:'哪吒之魔童降世'})
      OPTIONAL MATCH (p:人物)-[r:参演]->(m)
      RETURN m.片名 AS 片名, p.姓名 AS 演员, r.角色 AS 角色名
      """
    Then the result should be, in any order:
      | 片名           | 演员 | 角色名 |
      | 哪吒之魔童降世 | null | null   |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 查询电影及其类型（所有电影都返回）
  # ---------------------------------------------------------------------------
  Scenario: [4] Query movies with optional genres
    When executing query:
      """
      MATCH (m:电影)
      OPTIONAL MATCH (m)-[:属于类型]->(g:类型)
      RETURN m.片名 AS 片名, g.名称 AS 类型
      ORDER BY m.片名, 类型
      """
    Then the result should be, in order:
      | 片名           | 类型 |
      | 哪吒之魔童降世 | 动画 |
      | 流浪地球       | 科幻 |
      | 流浪地球2      | 科幻 |
      | 让子弹飞       | 喜剧 |
      | 让子弹飞       | 剧情 |
      | 我不是药神     | 剧情 |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 查询电影及其出品国家（所有电影都返回）
  # ---------------------------------------------------------------------------
  Scenario: [5] Query movies with optional countries
    When executing query:
      """
      MATCH (m:电影)
      OPTIONAL MATCH (m)-[:出品国家]->(c:国家)
      RETURN m.片名 AS 片名, c.名称 AS 国家
      ORDER BY m.片名, 国家
      """
    Then the result should be, in order:
      | 片名           | 国家     |
      | 哪吒之魔童降世 | 中国大陆 |
      | 流浪地球       | 中国大陆 |
      | 流浪地球2      | 中国大陆 |
      | 让子弹飞       | 中国大陆 |
      | 让子弹飞       | 中国香港 |
      | 我不是药神     | 中国大陆 |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 多层 OPTIONAL MATCH
  # 查询所有电影，可选匹配导演和奖项
  # ---------------------------------------------------------------------------
  Scenario: [6] Multi-level OPTIONAL MATCH
    When executing query:
      """
      MATCH (m:电影)
      OPTIONAL MATCH (d:人物)-[:导演]->(m)
      OPTIONAL MATCH (m)-[:获得奖项]->(a:奖项)
      RETURN m.片名 AS 片名, d.姓名 AS 导演, a.名称 AS 奖项
      ORDER BY m.片名
      """
    Then the result should be, in order:
      | 片名           | 导演   | 奖项           |
      | 哪吒之魔童降世 | 饺子   | null           |
      | 流浪地球       | 郭帆   | null           |
      | 流浪地球2      | 郭帆   | 金鸡奖最佳故事片 |
      | 让子弹飞       | 姜文   | null           |
      | 我不是药神     | 文牧野 | 百花奖最佳影片   |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: OPTIONAL MATCH 与 WHERE 结合
  # 查询所有人物，可选匹配其导演的电影，并筛选评分大于8.0的
  # ---------------------------------------------------------------------------
  Scenario: [7] OPTIONAL MATCH combined with WHERE
    When executing query:
      """
      MATCH (p:人物)
      OPTIONAL MATCH (p)-[:导演]->(m:电影)
      WHERE m.豆瓣评分 > 8.0 OR m IS NULL
      RETURN p.姓名 AS 姓名, m.片名 AS 导演作品, m.豆瓣评分 AS 评分
      ORDER BY p.姓名, 导演作品
      """
    Then the result should be, in order:
      | 姓名   | 导演作品       | 评分 |
      | 吴京   | null           | null |
      | 刘德华 | null           | null |
      | 姜文   | 让子弹飞       | 8.9  |
      | 徐峥   | null           | null |
      | 文牧野 | 我不是药神     | 9.0  |
      | 郭帆   | 流浪地球2      | 8.3  |
      | 饺子   | 哪吒之魔童降世 | 8.4  |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 查询没有获奖的电影
  # 使用 OPTIONAL MATCH 找出奖项为 NULL 的电影
  # ---------------------------------------------------------------------------
  Scenario: [8] Query movies without awards using OPTIONAL MATCH
    When executing query:
      """
      MATCH (m:电影)
      OPTIONAL MATCH (m)-[:获得奖项]->(a:奖项)
      WITH m, a
      WHERE a IS NULL
      RETURN m.片名 AS 片名
      ORDER BY m.片名
      """
    Then the result should be, in order:
      | 片名           |
      | 哪吒之魔童降世 |
      | 流浪地球       |
      | 让子弹飞       |
    And no side effects

  # ---------------------------------------------------------------------------
  # Scenario: 查询没有参演记录的人物
  # ---------------------------------------------------------------------------
  Scenario: [9] Query persons without acting records
    When executing query:
      """
      MATCH (p:人物)
      OPTIONAL MATCH (p)-[:参演]->(m:电影)
      WITH p, m
      WHERE m IS NULL
      RETURN p.姓名 AS 姓名, p.职业 AS 职业
      ORDER BY p.姓名
      """
    Then the result should be, in order:
      | 姓名   | 职业 |
      | 文牧野 | 导演 |
      | 郭帆   | 导演 |
      | 饺子   | 导演 |
    And no side effects
