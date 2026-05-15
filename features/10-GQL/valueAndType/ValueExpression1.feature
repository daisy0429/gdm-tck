##encoding: utf-8
##http://10.13.4.249:8090/pages/viewpage.action?pageId=70454152
##https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/supported-mandatory/ ->20.2-Cypher expressions
##https://neo4j.com/docs/cypher-manual/current/expressions/
## 测试第一阶段：验证东西存在，用let开头测
## TODO 测试第二阶段（重点）：功能完善，融合到各种点边、邻接、聚合查询里面去，等等。
## TODO 标准文档中：目录20？
#
#Feature: ValueExpression1
#
#  Scenario Outline: []signedExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                   | result |
#      | LET x = + 1 RETURN x; | 1      |
#      | LET x = - 1 RETURN x; | -1     |
#
#  Scenario Outline: []multDivExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                     | result |
#      | LET x = 2 * 1 RETURN x; | 2      |
#      | LET x = 2 / 1 RETURN x; | 2      |
#      | LET x = 2 % 1 RETURN x; | 0      |
#
#  Scenario Outline: []addSubtractExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                     | result |
#      | LET x = 2 + 1 RETURN x; | 3      |
#      | LET x = 2 - 1 RETURN x; | 1      |
#
##  Scenario : []concatenationExprAlt
##    When executing queries without error:
##      """
##    LET x = 1 || 1 RETURN x;
##      """
##    Then the result should be, in any order:
##      | x |
##      | 2 |
#
#  Scenario Outline: []notExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                        | result |
#      | LET x = NOT null RETURN x; | null   |
#      | LET x = NOT true RETURN x; | false  |
#
#  Scenario Outline: []notExprAlt-negative
#    When executing queries:
#      """
#    <GQL>
#      """
#    Then the error should be contain:
#    """
#    <error>
#    """
#    Examples:
#      | GQL                     | error                                           |
#      | LET x = NOT 1 RETURN x; | Type mismatch: expected Boolean but was Integer |
#
#   #fixme code -the `IsNotExprAltContext` syntax is not supported yet
#  Scenario Outline: []isNotExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                             | result |
#      | LET x = 1 IS NOT true RETURN x; | true   |
#
#
#  Scenario Outline: []conjunctiveExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                              | result |
#      | LET x = true AND false RETURN x; | false  |
#      | LET x = true AND true RETURN x;  | true   |
#      | LET x = true AND null RETURN x;  | false  |
#
#
#  Scenario Outline: []disjunctiveExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                               | result |
#      | LET x = true OR false RETURN x;   | true   |
#      | LET x = false XOR false RETURN x; | false  |
#      | LET x = true XOR true RETURN x;   | false  |
#      | LET x = true XOR false RETURN x;  | true   |
#
#  Scenario Outline: []comparisonExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                      | result |
#      | LET x = 1 = 2 RETURN x;  | false  |
#      | LET x = 1 > 2 RETURN x;  | false  |
#      | LET x = 1 >= 2 RETURN x; | false  |
#      | LET x = 1 < 2 RETURN x;  | true   |
#      | LET x = 1 <= 2 RETURN x; | true   |
#
#
#  Scenario Outline: []existsPredicate-bug7477
#    When executing queries without error:
#      """
#    CREATE
#  (alice:Person {name: "Alice"}),
#  (bob:Person {name: "Bob"}),
#  (charlie:Person {name: "Charlie"}),
#  (company:Company {name: "Acme Corp"}),
#  (alice)-[:WORKS_AT]->(company),
#  (bob)-[:KNOWS]->(alice),
#  (charlie)-[:KNOWS]->(bob);
#      """
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                                        | result |
#      | RETURN EXISTS{ MATCH (n) RETURN n } AS x;                                                  | true   |
#      | RETURN EXISTS{ MATCH (n:Person) WHERE n.name IS NOT NULL RETURN n } AS x;                  | true   |
#      | RETURN EXISTS{ (n:Company) WHERE n.name = "Acme Corp" } AS x;                              | true   |
#      | RETURN EXISTS{ (n:Company) WHERE n.name = "Nonexistent Corp" } AS x;                       | false  |
#      | WITH 5 AS x WHERE EXISTS{ RETURN x } RETURN x;                                             | 5      |
#      | RETURN EXISTS{ WITH 1 AS a RETURN a } AS x;                                                | true   |
#      | RETURN EXISTS{ RETURN 1 } AS x;                                                            | true   |
#      | WITH 5 AS a RETURN EXISTS{ RETURN a } AS x;                                                | true   |
#      | RETURN EXISTS{ RETURN 1 WHERE 1 = 2 } AS x;                                                | false  |
#      | RETURN EXISTS{ RETURN 1 AS y WHERE y = 2 } AS x;                                           | false  |
#      | RETURN EXISTS{ RETURN 1 AS y WHERE y = 1 } AS x;                                           | true   |
#      | RETURN EXISTS{ WITH 1 AS z WHERE z > 10 RETURN z } AS x;                                   | false  |
#      | RETURN EXISTS{ (n:NoSuchLabel) RETURN n } AS x;                                            | false  |
#      | RETURN EXISTS{ MATCH (n:Person)-[:KNOWS]->(:Person) WHERE n.name = "Bob" RETURN n } AS x;  | true   |
#      | RETURN EXISTS{ RETURN 1 AS a, 2 AS b WHERE a + b = 3 } AS x;                               | true   |
#      | RETURN EXISTS{ RETURN 1 AS a, 2 AS b WHERE a + b = 4 } AS x;                               | false  |
#      | WITH 10 AS outerVar RETURN EXISTS{ RETURN outerVar + 5 AS result WHERE result = 15 } AS x; | true   |
#
#
#  Scenario Outline: []nullPredicate
#    When executing queries without error:
#      """
#    CREATE
#  (:Person {name: "Alice", age: 30}),
#  (:Person {name: "Bob"}),
#  (:Person {name: null}),
#  (:Person);
#      """
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                 | result |
#      | MATCH (n:Person {name: "Alice"}) RETURN n.age IS NULL AS x;         | false  |
#      | MATCH (n:Person {name: "Alice"}) RETURN n.age IS NOT NULL AS x;     | true   |
#      | MATCH (n:Person {name: "Bob"}) RETURN n.age IS NULL AS x;           | true   |
#      | MATCH (n:Person {name: "Bob"}) RETURN n.age IS NOT NULL AS x;       | false  |
#      | MATCH (n:Person) WHERE n.name IS NULL RETURN true AS x LIMIT 1;     | true   |
#      | MATCH (n:Person) WHERE n.name IS NOT NULL RETURN true AS x LIMIT 1; | true   |
#
##https://neo4j.com/docs/cypher-manual/current/expressions/predicates/type-predicate-expressions/
#  Scenario: []valueTypePredicate
#    When executing queries without error:
#      """
#      UNWIND [42, true, 'abc', null] AS val
#      RETURN val, val IS not :: INTEGER AS isNotInteger
#      """
#    Then the result should be, in any order:
#      | val   | isNotInteger |
#      | 42    | FALSE        |
#      | TRUE  | TRUE         |
#      | 'abc' | TRUE         |
#      | NULL  | TRUE         |
#
#
#  Scenario Outline: []directedPredicate-bug7478
#    When executing queries without error:
#    """
#    CREATE (:Node {name: 'A'});
#    CREATE (:Node {name: 'B'});
#    CREATE (:Node {name: 'C'});
#    MATCH (a:Node {name: 'A'}), (b:Node {name: 'B'}) CREATE (a)-[:KNOWS]->(b);
#    """
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                         | result |
#      | MATCH ()-[r]->() RETURN r IS DIRECTED AS x; | true   |
#
#  #MATCH ()-[r]->() LET x = r IS DIRECTED RETURN x;
#  Scenario: []directedPredicate2-bug7478
#    When executing queries without error:
#    """
#    CREATE (:Node {name: 'A'});
#    CREATE (:Node {name: 'B'});
#    CREATE (:Node {name: 'C'});
#    MATCH (a:Node {name: 'A'}), (b:Node {name: 'B'}) CREATE (a)-[:KNOWS]->(b);
#    """
#      # 先选择所有无向关系（NOT r IS DIRECTED）,然后又返回这些关系是否是有向的（总是false）
#    When executing queries without error:
#    """
#    MATCH ()-[r]-() WHERE NOT r IS DIRECTED RETURN r IS DIRECTED AS x;
#    """
#    Then the result should be, in any order:
#      | x     |
#      | false |
#      | false |
#    #过滤有向关系
#    When executing queries without error:
#    """
#    MATCH ()-[r]-() WHERE r IS DIRECTED RETURN type(r) AS rel_type;
#    """
#    Then the result should be, in any order:
#      | rel_type |
#      | KNOWS    |
#
#  #判断变量 a 是否**不具有某些标签（label）**的表达式。语法略带“模式匹配”的语义
#  Scenario Outline: []labeledPredicate-GQL标准草案暂不明确
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                              | result |
#      | LET x = a IS NOT LABELED % RETURN x;             | false  |
#      | LET x = a IS NOT LABELED !Person RETURN x;       | true   |
#      | LET x = a IS NOT LABELED !Post&Comment RETURN x; | true   |
#
##  Scenario : [] labeledPredicate-2
##    When executing queries without error:
##    """
##    LET x = a IS NOT LABELED !Post|Comment RETURN x;
##    """
##    Then the result should be, in any order:
##      | x    |
##      | true |
#
#  Scenario: [] labeledPredicate-3
#    When executing queries without error:
#    """
#    LET x = a IS NOT LABELED (Person|Message) RETURN x;
#    """
#    Then the result should be, in any order:
#      | x    |
#      | true |
#
#  Scenario: [] labeledPredicate-4
#    When executing queries without error:
#    """
#    LET x = a :Person|Message RETURN x;
#    """
#    Then the result should be, in any order:
#      | x    |
#      | true |
#
#    #判断某个节点是否是一个关系的起点（SOURCE）或终点（DESTINATION）。这些表达式主要用于有向关系（directed relationship）。
#  Scenario Outline: []sourceDestinationPredicate-用法暂不明确
#    When executing queries without error:
#    """
#    CREATE (:Node {name: 'm1'});
#    CREATE (:Node {name: 'm2'});
#    CREATE (:Node {name: 'm3'});
#    MATCH (a:Node {name: 'm1'}), (b:Node {name: 'm2'}), (c:Node {name: 'm3'})
#    CREATE (a)-[:R1]->(b),
#           (b)-[:R2]->(c);
#    """
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                                         | result |
#      | MATCH (a:Node {name: 'm1'})-[b:R1]->(c:Node) LET x = a IS NOT SOURCE OF b RETURN x;         | false  |
#      | MATCH (a:Node {name: 'm1'})-[b:R1]->(c:Node) LET x = a IS NOT DESTINATION OF b RETURN x;    | true   |
#      | MATCH (m:Node)-[r]-() WHERE m.name = 'm2' AND m IS NOT SOURCE OF r RETURN m.name AS x;      | m2     |
#      | MATCH (m:Node)-[r]-() WHERE m.name = 'm2' AND m IS NOT DESTINATION OF r RETURN m.name AS x; | m2     |
#
#
#  Scenario Outline: []all_differentPredicate
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                 | result |
#      | LET x = ALL_DIFFERENT(a, b) RETURN x;                               | true   |
#      | LET x = ALL_DIFFERENT(a, b, c) RETURN x;                            | true   |
#      | MATCH (m)-[r]->(n)-[r1]->(p) WHERE ALL_DIFFERENT(m, n, p) RETURN n; | n1     |
#
#  Scenario Outline: []samePredicate
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                     | result |
#      | LET x = SAME(a, b, c) RETURN x;                         | false  |
#      | MATCH (m)-[r]->(n)-[r1]->(p) WHERE SAME(m, n) RETURN n; | n2     |
#
#  Scenario Outline: []property_existsPredicate
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                | result |
#      | LET x = PROPERTY_EXISTS(Person, name) RETURN x;    | true   |
#      | MATCH (m) WHERE PROPERTY_EXISTS(m, name) RETURN m; | m1     |
#
#  Scenario Outline: []normalizedPredicateExprAlt
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                        | result |
#      | LET x = m IS NOT NFC NORMALIZED RETURN x;  | false  |
#      | LET x = m IS NOT NFD NORMALIZED RETURN x;  | true   |
#      | LET x = m IS NOT NFKC NORMALIZED RETURN x; | true   |
#      | LET x = m IS NOT NFKD NORMALIZED RETURN x; | false  |
#
#  Scenario Outline: []propertyGraphExprAlt
#    When executing queries without error:
#      """
#    <GQL>
#      """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                       | result   |
#      | LET x = PROPERTY GRAPH my_graph RETURN x; | my_graph |
#
#  Scenario Outline: []bindingTableExprAlt
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                      | result |
#      | LET x = BINDING TABLE my_table RETURN x; | true   |
#
#  Scenario Outline: []numericValueFunction
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                        | result    |
#      | LET x = CHAR_LENGTH('123') RETURN x;       | 3         |
#      | LET x = CHARACTER_LENGTH('123') RETURN x;  | 3         |
#      | LET x = BYTE_LENGTH('123') RETURN x;       | 3         |
#      | LET x = OCTET_LENGTH('0o123') RETURN x;    | 5         |
#      | MATCH p = ()-[]->() RETURN PATH_LENGTH(p); | 1         |
#      | LET x = CARDINALITY('123') RETURN x;       | 3         |
#      | LET x = SIZE('123') RETURN x;              | 3         |
#      | LET x = ABS(23) RETURN x;                  | 23        |
#      | LET x = MOD(23,2) RETURN x;                | 1         |
#      | LET x = SIN(60) RETURN x;                  | 0.866     |
#      | LET x = COS(60) RETURN x;                  | 0.5       |
#      | LET x = TAN(60) RETURN x;                  | 1.732     |
#      | LET x = COT(60) RETURN x;                  | 0.577     |
#      | LET x = SINH(60) RETURN x;                 | 2.349e+25 |
#      | LET x = COSH(60) RETURN x;                 | 2.349e+25 |
#      | LET x = TANH(60) RETURN x;                 | 1         |
#      | LET x = ASIN(60) RETURN x;                 | Error     |
#      | LET x = ACOS(60) RETURN x;                 | Error     |
#      | LET x = ATAN(60) RETURN x;                 | 1.560     |
#      | LET x = DEGREES(60) RETURN x;              | 3437.745  |
#      | LET x = RADIANS(60) RETURN x;              | 1.047     |
#      | LET x = LOG(100,10) RETURN x;              | 2         |
#      | LET x = LOG10(100) RETURN x;               | 2         |
#      | LET x = LN(100) RETURN x;                  | 4.605     |
#      | LET x = EXP(100) RETURN x;                 | 2.688e+43 |
#      | LET x = POWER(100,1) RETURN x;             | 100       |
#      | LET x = SQRT(100) RETURN x;                | 10        |
#      | LET x = FLOOR(101) RETURN x;               | 101       |
#      | LET x = CEIL(100) RETURN x;                | 100       |
#      | LET x = CEILING(100) RETURN x;             | 100       |
#
#  Scenario Outline: []datetimeSubtraction
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                         | result |
#      | LET x = DURATION_BETWEEN('2024-10-10','2023-11-11') YEAR TO MONTH RETURN x; | P11M   |
#      | LET x = DURATION_BETWEEN('2024-10-10','2023-11-11') DAY TO SECOND RETURN x; | P364D  |
#
#  Scenario Outline: []datetimeValueFunction
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                   | result                    |
#      | LET x = CURRENT_DATE RETURN x;                                        | 2024-12-24                |
#      | LET x = DATE() RETURN x;                                              | 2024-12-24                |
#      | LET x = DATE('2024-10-11') RETURN x;                                  | 2024-10-11                |
#      | LET x = DATE(RECORD{birth:'2024-10-10'}) RETURN x;                    | 2024-10-10                |
#      | LET x = CURRENT_TIME RETURN x;                                        | 12:00:00                  |
#      | LET x = ZONED_TIME() RETURN x;                                        | 12:00:00+00:00            |
#      | LET x = ZONED_TIME('12:12:12') RETURN x;                              | 12:12:12+00:00            |
#      | LET x = ZONED_TIME(RECORD{birth:'12:12:12'}) RETURN x;                | 12:12:12+00:00            |
#      | LET x = LOCAL_TIME() RETURN x;                                        | 12:00:00                  |
#      | LET x = LOCAL_TIME('12:12:12') RETURN x;                              | 12:12:12                  |
#      | LET x = LOCAL_TIME(RECORD{birth:'12:12:12'}) RETURN x;                | 12:12:12                  |
#      | LET x = CURRENT_TIMESTAMP RETURN x;                                   | 2024-12-24T12:00:00       |
#      | LET x = ZONED_DATETIME() RETURN x;                                    | 2024-12-24T12:00:00+00:00 |
#      | LET x = ZONED_DATETIME('2024-10-10T12:12:12') RETURN x;               | 2024-10-10T12:12:12+00:00 |
#      | LET x = ZONED_DATETIME(RECORD{birth:'2024-10-10T12:12:12'}) RETURN x; | 2024-10-10T12:12:12+00:00 |
#      | LET x = LOCAL_TIMESTAMP RETURN x;                                     | 2024-12-24T12:00:00       |
#      | LET x = LOCAL_DATETIME() RETURN x;                                    | 2024-12-24T12:00:00       |
#      | LET x = LOCAL_DATETIME('2024-10-10T12:12:12') RETURN x;               | 2024-10-10T12:12:12       |
#      | LET x = LOCAL_DATETIME(RECORD{birth:'2024-10-10T12:12:12'}) RETURN x; | 2024-10-10T12:12:12       |
#
#  Scenario Outline: []durationValueFunction
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                              | result |
#      | LET x = DURATION('PT0S') RETURN x;               | PT0S   |
#      | LET x = DURATION(RECORD{birth:'PT0S'}) RETURN x; | PT0S   |
#      | LET x = ABS('???') RETURN x;                     | Error  |
#
#  Scenario Outline: []characterOrByteStringFunction
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                      | result    |
#      | LET x = LEFT('HELLO GQL',5) RETURN x;                    | HELLO     |
#      | LET x = RIGHT('HELLO GQL',3) RETURN x;                   | GQL       |
#      | LET x = TRIM(' HELLO GQL ') RETURN x;                    | HELLO GQL |
#      | LET x = TRIM(LEADING 'HELLO' FROM 'HELLO GQL') RETURN x; | GQL       |
#      | LET x = TRIM(TRAILING 'GQL' FROM 'HELLO GQL') RETURN x;  | HELLO     |
#      | LET x = TRIM(BOTH 'GQL' FROM 'HELLO GQL') RETURN x;      | HELLO     |
#      | LET x = UPPER('Hello GQL') RETURN x;                     | HELLO GQL |
#      | LET x = LOWER('Hello GQL') RETURN x;                     | hello gql |
#      | LET x = BTRIM('Hello GQL','hello world') RETURN x;       | Hello GQL |
#      | LET x = LTRIM('Hello GQL','hello world') RETURN x;       | GQL       |
#      | LET x = RTRIM('Hello GQL','hello world') RETURN x;       | Hello     |
#      | LET x = NORMALIZE('Hello GQL', NFC) RETURN x;            | Hello GQL |
#      | LET x = NORMALIZE('Hello GQL', NFD) RETURN x;            | Hello GQL |
#      | LET x = NORMALIZE('Hello GQL', NFKC) RETURN x;           | Hello GQL |
#      | LET x = NORMALIZE('Hello GQL', NFKD) RETURN x;           | Hello GQL |
#
#  Scenario Outline: []listValueFunction
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                     | result |
#      | LET x = TRIM([1,2,3],1) RETURN x;       | [2,3]  |
#      | MATCH p = ()-[]->() RETURN ELEMENTS(p); | [r]    |
#
#  Scenario Outline: []parenthesizedValueExpression
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                     | result |
#      | LET x = (1+1) RETURN x; | 2      |
#
#  Scenario Outline: []aggregateFunction
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                       | result           |
#      | MATCH (n) LET x = COUNT(*) RETURN x;                      | 10               |
#      | MATCH (n)-[r]->(m) LET x = AVG(DISTINCT m.age) RETURN x;  | 30               |
#      | MATCH (n)-[r]->(m) LET x = AVG(ALL m.age) RETURN x;       | 25               |
#      | MATCH (n) LET x = COUNT(ALL n.age) RETURN x;              | 5                |
#      | MATCH (n) LET x = MAX(ALL n.age) RETURN x;                | 40               |
#      | MATCH (n) LET x = MIN(ALL n.age) RETURN x;                | 20               |
#      | MATCH (n) LET x = SUM(ALL n.age) RETURN x;                | 150              |
#      | MATCH (n) LET x = COLLECT_LIST(ALL n.age) RETURN x;       | [20,25,30,35,40] |
#      | MATCH (n) LET x = STDDEV_SAMP(ALL n.age) RETURN x;        | 7.071            |
#      | MATCH (n) LET x = STDDEV_POP(ALL n.age) RETURN x;         | 7.071            |
#      | LET x = PERCENTILE_CONT(ALL 1 + 1, 2 + 1 ) RETURN x;      | 3                |
#      | LET x = PERCENTILE_DISC(DISTINCT 1 + 1, 2 + 1 ) RETURN x; | 2                |
#
#  Scenario Outline: []unsignedValueSpecification
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                            | result |
#      | LET x = 1 RETURN x;            | 1      |
#      | LET x = TRUE RETURN x;         | true   |
#      | LET x = SESSION_USER RETURN x; | user1  |
#
#  Scenario Outline: []pathValueConstructor
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                               | result  |
#      | MATCH (m)-[r]->(n) LET x = PATH [m] RETURN x;     | [m]     |
#      | MATCH (m)-[r]->(n) LET x = PATH [m,r,n] RETURN x; | [m,r,n] |
#
#  Scenario Outline: []propertyReference
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                | result |
#      | MATCH (m) LET x = m.name RETURN x; | John   |
#
#  Scenario Outline: []valueQueryExpression
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                         | result |
#      | LET x = VALUE{MATCH (n) RETURN n} RETURN x; | [n]    |
#
#  Scenario Outline: []caseExpression
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                   | result |
#      | LET x = NULLIF(a,b) RETURN x;                                         | NULL   |
#      | LET x = COALESCE(a,b,c) RETURN x;                                     | a      |
#      | MATCH (a)-[]->(b) LET x = CASE a WHEN = b THEN 1 ELSE 2 END RETURN x; | 2      |
#
#  Scenario Outline: []element_idFunction
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                       | result |
#      | MATCH (a) LET x = ELEMENT_ID(a) RETURN x; | 123    |
#
#  Scenario Outline: []letValueExpression
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                             | result |
#      | LET x = LET a = 1, b = 2 IN a + b END RETURN x; | 3      |
