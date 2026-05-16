#encoding: utf-8
#如果节点上存在关系（边），NODETACH DELETE 将导致错误，因为它不会自动删除节点的关联边。用户需要在删除节点前手动处理这些边。
#https://neo4j.com/docs/cypher-manual/current/clauses/delete/#delete-nodetach


Feature: nodetach

  Scenario Outline: 节点不存在关联关系时nodetach delete节点，删除成功
    When executing queries without error:
      """
      MATCH (n) DETACH DELETE n;
      CREATE (:Person {name: 'user1'});
      CREATE (:Person {name: 'user2'});
      CREATE (:Movie {title: 'movie1'});
      MATCH (p:Person {name: 'user1'}), (m:Movie {title: 'movie1'}) CREATE (p)-[:ACTED_IN]->(m);
      """
    When executing queries without error:
      """
    <GQL>
    """
    When executing queries without error:
      """
    call db.meta.count() yield type,count where type in ['vertices','edges'] return type,count;
    """
    Then the result should be, in any order:
      | type       | count |
      | 'vertices' | 2     |
      | 'edges'    | 1     |
    Examples:
      | GQL |
      | MATCH (m:Person {name: 'user2'}) NODETACH DELETE m; |

  Scenario Outline: 节点存在关联关系时nodetach delete节点,删除失败，抛出提示-本用例适用于事务模式下验证
    When executing queries:
      """
      MATCH (n) DETACH DELETE n;
      CREATE (:Person {name: 'user1'});
      CREATE (:Person {name: 'user2'});
      CREATE (:Movie {title: 'movie1'});
      MATCH (p:Person {name: 'user1'}), (m:Movie {title: 'movie1'}) CREATE (p)-[:ACTED_IN]->(m);
      """
    When executing queries:
      """
      <GQL>
      """
    Then the error should be contain:
      """
      <error>
      """
    #事务模式下：操作回滚
    When executing queries:
      """
    call db.meta.count() yield type,count where type in ['vertices','edges'] return type,count;
    """
    Then the result should be, in any order:
      | type       | count |
      | 'vertices' | 3     |
      | 'edges'    | 1     |
    Examples:
      | GQL | error |
      | match (n) where n.title= 'movie1' nodetach delete n; | [2750]Cannot delete node |
      | match (n) nodetach delete n; | [2750]Cannot delete node |
  Scenario Outline: 节点存在关联关系时nodetach delete节点,删除失败，抛出提示--本用例适用于非事务模式下验证
    When executing queries:
      """
      MATCH (n) DETACH DELETE n;
      CREATE (:Person {name: 'user1'});
      CREATE (:Person {name: 'user2'});
      CREATE (:Movie {title: 'movie1'});
      MATCH (p:Person {name: 'user1'}), (m:Movie {title: 'movie1'}) CREATE (p)-[:ACTED_IN]->(m);
      """
    When executing queries:
      """
      <GQL>
      """
    Then the error should be contain:
      """
      <error>
      """
    When executing queries:
      """
    call db.meta.count() yield type,count where type in ['vertices','edges'] return type,count;
    """
    #非事务模式下：部分成功
    Then the result should be, in any order:
      | type       | count |
      | 'vertices' | 2     |
      | 'edges'    | 1     |
    Examples:
      | GQL | error |
      | match (n) nodetach delete n; | [2750]Cannot delete node |