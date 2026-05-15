#encoding: utf-8
#jcy
# http://10.13.4.249:8090/display/GSQL/Procedure+calling
# https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/supported-optional/
# https://neo4j.com/docs/cypher-manual/current/subqueries/call-subquery/
# GQL inline procedure 等价于 cypher CALL subqueries
# call后面 不带 ()也可以生成内联过程语法，这个就要实际看语法树生成咋样，有可能是普通子句组合，也有可能会成内联过程子句

Feature: inline procedure

  Scenario: [1] basic example
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
      UNWIND [0, 1] AS x
      CALL () {
        RETURN 'hello' AS innerReturn
      }
      RETURN innerReturn
      """
    Then the result should be, in any order:
      | innerReturn |
      | 'hello'     |
      | 'hello'     |

  Scenario: [2] Incremental updates - set
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
      UNWIND [1, 2, 3] AS x
      CALL () {
          MATCH (p:Player {name: 'Player A'})
          SET p.age = p.age + 1
          RETURN p.age AS newAge
      }
      MATCH (p:Player {name: 'Player A'})
      RETURN x AS iteration, newAge, p.age AS totalAge;
      """
    Then the result should be, in any order:
      | iteration | newAge | totalAge |
      | 1         | 22     | 24       |
      | 2         | 23     | 24       |
      | 3         | 24     | 24       |

  Scenario: [3] Performance - return collect(p)
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
      MATCH (t:Team)
      CALL (t) {
        MATCH (p:Player)-[:PLAYS_FOR]->(t)
        RETURN collect(p) as players
      }
      RETURN t AS team, players
      """
    Then the result should be, in any order:
      | team                     | players                                                                        |
      | (:Team {name: 'Team A'}) | [(:Player {name: 'Player B', age: 23}), (:Player {name: 'Player A', age: 21})] |
      | (:Team {name: 'Team B'}) | [(:Player {name: 'Player D', age: 30})]                                        |
      | (:Team {name: 'Team C'}) | [(:Player {name: 'Player E', age: 25}), (:Player {name: 'Player F', age: 35})] |

  Scenario: [4] Import specific variables from the outer scope
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
      MATCH (p:Player), (t:Team)
        CALL (p) {
          WITH p.name AS name
          WITH name,
               CASE name
                 WHEN 'Player A' THEN 0.3
                 WHEN 'Player B' THEN 0.5
                 ELSE 0.7
               END AS fixedRating
          SET p.rating = fixedRating
          RETURN name AS playerName, fixedRating AS rating
        }
        RETURN playerName, rating, t AS team
        ORDER BY rating
        LIMIT 1;
      """
    Then the result should be, in any order:
      | playerName | rating | team                     |
      | 'Player A' | 0.3    | (:Team {name: 'Team C'}) |

  Scenario: [5] 不支持导入全部变量，来源于GQL标准的限制-call (*)-
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
      MATCH (p:Player), (t:Team)
    CALL {
      WITH p, t
      SET p.lastUpdated = timestamp()
      SET t.lastUpdated = timestamp()
    }
    RETURN p.name AS playerName,
           t.name AS teamName
    LIMIT 1;
      """
    Then the result should be, in any order:
      | playerName | teamName |
      | 'Player F' | 'Team C' |

  Scenario: [6] Import no variables - return count(p)
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
      MATCH (t:Team)
      CALL () {
        MATCH (p:Player)
        RETURN count(p) AS totalPlayers
      }
      RETURN count(t) AS totalTeams, totalPlayers
      """
    Then the result should be, in any order:
      | totalTeams | totalPlayers |
      | 3          | 6            |

  Scenario: [8] Ordering results before CALL subquery
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
      MATCH (p:Player)
      WITH p
      ORDER BY p.age ASC
      CALL {
        WITH p
        RETURN p.name AS playerName, p.age AS playerAge
      }
      RETURN playerName, playerAge
      LIMIT 1;
      """
    Then the result should be, in any order:
      | playerName | playerAge |
      | 'Player C' | 19        |

  Scenario: [9] Using UNION within a CALL subquery -Find the oldest and youngest players
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
      CALL {
      MATCH (p:Player)
      RETURN p
      ORDER BY p.age ASCENDING
      LIMIT 1
    UNION
      MATCH (p:Player)
      RETURN p
      ORDER BY p.age DESC
      LIMIT 1
    }
    RETURN p.name AS playerName, p.age AS age
      """
    Then the result should be, in any order:
      | playerName | age |
      | 'Player C' | 19  |
      | 'Player F' | 35  |

#  目标意图：
#  对每个球队（Team 节点）t，计算它欠别人的钱（负值）和别人欠它的钱（正值）的总和，从而得出每支球队的“净被欠金额”。
  Scenario: [9-1] Using UNION within a CALL subquery -Find how much every team is owed-bug7736
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
     MATCH (t:Team)
     CALL {
       with t
       OPTIONAL MATCH (t)-[o:OWES]->(other:Team)
       RETURN o.dollars * -1 AS moneyOwed
       UNION ALL
       OPTIONAL MATCH (other)-[o:OWES]->(t)
       RETURN o.dollars AS moneyOwed
     }
     RETURN t.name AS team, sum(moneyOwed) AS amountOwed
     ORDER BY amountOwed DESC;
      """
    Then the result should be, in any order:
      | team     | amountOwed |
      | "Team B" | 7800       |
      | "Team C" | -3300      |
      | "Team A" | -4500      |

  Scenario: [10] Aggregations-CALL subquery changing returned rows of outer query
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
     MATCH (p:Player)
      CALL (p) {
        MATCH (p)-[:PLAYS_FOR]->(team:Team)
        RETURN team.name AS team
      }
      RETURN p.name AS playerName, team
      """
    Then the result should be, in any order:
      | playerName | team     |
      | 'Player A' | 'Team A' |
      | 'Player B' | 'Team A' |
      | 'Player D' | 'Team B' |
      | 'Player E' | 'Team C' |
      | 'Player F' | 'Team C' |

  Scenario: [11] CALL subqueries and isolated aggregations
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
     MATCH (t:Team)
      CALL (t) {
        MATCH (t)-[o:OWES]->(t2:Team)
        RETURN sum(o.dollars) AS owedAmount, t2.name AS owedTeam
      }
      RETURN t.name AS owingTeam, owedAmount, owedTeam
      """
    Then the result should be, in any order:
      | owingTeam | owedAmount | owedTeam |
      | 'Team A'  | 4500       | 'Team B' |
      | 'Team B'  | 1700       | 'Team C' |
      | 'Team C'  | 5000       | 'Team B' |

  Scenario: [bug5372][12] Unit subqueries - Create cloned nodes
    Given drop all graph
    When  executing queries without error:
    """
      create database graph1;
    """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["graph1"]
    When init graphGQL by user["SYSDBA"]-[0]-DB["graph1"]
    When executing query by USER["SYSDBA"]-[0]-DB["graph1"] without error:
      """
     MATCH (p:Player)
      CALL (p) {
        UNWIND range (1, 3) AS i
        CREATE (:Person {name: p.name})
      }
      RETURN count(*);
      """
    Then the result should be, in any order:
      | count(*) |
      | 6        |

















