#encoding: utf-8
#https://neo4j.com/docs/cypher-manual/current/patterns/shortest-paths/#any

Feature: any

  Background:
    Given an empty graph
    And executing queries without error:
     """
      MATCH (n) DETACH DELETE n;
      CREATE (:Station {name: 'Pershore'});
      CREATE (:Station {name: 'Bromsgrove'});
      CREATE (:Station {name: 'A'});
      CREATE (:Station {name: 'B'});
      CREATE (:Station {name: 'C'});
      MATCH (a:Station {name: 'Pershore'}), (b:Station {name: 'Bromsgrove'}) CREATE (a)-[:LINK {distance: 5}]->(b);
      MATCH (a:Station {name: 'A'}), (b:Station {name: 'B'}) CREATE (a)-[:LINK {distance: 12}]->(b);
      MATCH (a:Station {name: 'B'}), (c:Station {name: 'C'}) CREATE (a)-[:LINK {distance: 8}]->(c);
    """
    And sleep (1)

  Scenario: 测试ANY关键字匹配特定条件路径（起点为 Pershore，终点为 Bromsgrove，距离小于 10）-bug5520挂起
    When executing queries without error:
      """
    MATCH path = ANY (:Station {name: 'Pershore'})-[l:LINK WHERE l.distance < 10]->(:Station {name: 'Bromsgrove'})
    RETURN [r IN relationships(path) | r.distance] AS distances;
    """
    Then the result should be, in any order:
      | x   |
      | [5] |

  Scenario: 测试ANY关键字匹配特定条件路径（起点为 A，终点为 B，距离小于 15）-bug5520挂起
    When executing queries without error:
      """
    MATCH path = ANY (:Station {name: 'A'})-[l:LINK WHERE l.distance < 15]->(:Station {name: 'B'})
    RETURN [r IN relationships(path) | r.distance] AS distances;
    """
    Then the result should be, in any order:
      | x    |
      | [12] |

  Scenario: 测试ANY关键字在路径条件无法满足时返回空结果-bug5520挂起
    When executing queries without error:
      """
    MATCH path = ANY (:Station {name: 'Pershore'})-[l:LINK WHERE l.distance > 50]->(:Station {name: 'Bromsgrove'})
    RETURN [r IN relationships(path) | r.distance] AS distances;
    """
    Then the result should be, in any order:
      | x  |
      | [] |

  Scenario: 测试ANY关键字在起点节点不存在时返回空结果-bug5520挂起
    When executing queries without error:
      """
    MATCH path = ANY (:Station {name: 'NonExistent'})-[l:LINK WHERE l.distance < 10]->(:Station {name: 'Bromsgrove'})
    RETURN [r IN relationships(path) | r.distance] AS distances;
    """
    Then the result should be, in any order:
      | x  |
      | [] |

  Scenario: ANY 检查多个属性的条件-使用ANY关键字匹配距离小于10的路径
    When executing queries without error:
      """
    MATCH (s:Station)-[l:LINK]->(t:Station)
    WHERE ANY(distance IN [l.distance] WHERE distance < 10)
    RETURN s.name AS start, t.name AS end, l.distance AS distance;
    """
    Then the result should be, in any order:
      | start      | end          | distance |
      | 'B'        | 'C'          | 8        |
      | 'Pershore' | 'Bromsgrove' | 5        |

  Scenario: ANY 检查单一属性的条件-检查是否存在LINK关系，其distance等于5
    When executing queries without error:
      """
    MATCH (s:Station)-[l:LINK]->(t:Station)
    WHERE ANY(x IN [l.distance] WHERE x = 5)
    RETURN s.name, t.name, l.distance;
    """
    Then the result should be, in any order:
      | s.name     | t.name       | l.distance |
      | 'Pershore' | 'Bromsgrove' | 5          |

  Scenario: ANY与复杂属性条件-检查是否存在 LINK 关系，distance 或起点/终点站名称长度中至少有一个大于8-关键字忽略大小写
    When executing queries without error:
      """
    MATCH (s:Station)-[l:LINK]->(t:Station)
    WHERE AnY(x IN [l.distance, size(s.name), size(t.name)] WHERE x > 8)
    RETURN s.name, t.name, l.distance;
    """
    Then the result should be, in any order:
      | s.name     | t.name       | l.distance |
      | 'Pershore' | 'Bromsgrove' | 5          |
      | 'A'        | 'B'          | 12         |

  Scenario: ANY应用在空列表
    When executing queries without error:
      """
    MATCH (s:Station)-[l:LINK]->(t:Station)
    WHERE ANY(x IN [] WHERE x > 10)
    RETURN s.name, t.name, l.distance;
    """
    Then the result should be empty

  Scenario: ANY异常用例 -any条件中返回非布尔值
    When executing queries:
      """
      MATCH (s:Station)-[l:LINK]->(t:Station)
    WHERE ANY(x IN [l.distance] WHERE x + 5)
    RETURN s.name, t.name, l.distance;
      """
    Then the error should be contain:
      """
    unsupported value type in CoercedPredicate
    """

  Scenario: RETURN any(x IN [1, 2, null] WHERE x IS NULL) AS containsNull
    Given an empty graph
    When executing queries without error:
      """
      RETURN any(x IN [1, 2, null] WHERE x IS NULL) AS containsNull
      """
    Then the result should be, in any order:
      | containsNull |
      | true         |