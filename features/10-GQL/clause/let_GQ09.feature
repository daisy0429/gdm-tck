#encoding: utf-8
#xzq
#http://10.13.4.249:8090/pages/viewpage.action?pageId=70453576
#https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/analogous-cypher/
#GQL let等价cypher with。但是不支持再附加 DISTINCT、ORDER、SKIP、LIMIT、WHERE 等子句
#LET 是一个用于定义和绑定变量的关键字，类似于 WITH 或其他语言中的局部变量声明。它允许将计算结果或表达式绑定到一个变量，然后在后续查询中使用该变量。
#功能要点：
#绑定变量：LET 可以将一个值、表达式或集合绑定到变量。
#可组合性：绑定的变量可以在查询后续部分使用。
#类似于 WITH，但更专注于声明和绑定，而非筛选上下文。
#http://10.13.4.249:8090/pages/viewpage.action?pageId=70453576
#https://neo4j.com/docs/cypher-manual/current/clauses/with/

Feature: let

  Scenario Outline: [1]验证let用于定义变量并简单赋值
    When executing query without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                              | result              | desc |
      | LET a = 5 RETURN a as x;                         | 5                   |      |
      | LET list = ['apple', 'banana'] return list as x; | ['apple', 'banana'] |      |

  Scenario: [2]验证let定义的变量在后续查询中的使用
    When executing query without error:
      """
      LET b = 10 RETURN b + 5
      """
    Then the result should be, in any order:
      | b + 5 |
      | 15    |

  Scenario: [3]验证let定义的变量在复杂表达式中的使用
    When executing query without error:
      """
        LET c = 16 RETURN sqrt(c)
      """
    Then the result should be, in any order:
      | sqrt(c) |
      | 4       |

    #fixme 预期输出（长度分别为5, 6, 6）
    #GQL标准规则不支持这个语法
   #LET d = ["apple", "banana", "cherry"] RETURN [FOR x IN d RETURN LENGTH(x)]
  Scenario: [4]验证let在嵌套查询中的使用-bug5374
    When executing query without error:
      """
    FOR x IN ["apple", ""] RETURN SIZE(x);
      """
    Then the result should be, in any order:
      | SIZE(x) |
      | 5       |
      | 0       |


  Scenario: [5]验证多个let定义多个变量及其联合使用-bug5530
    When executing query without error:
      """
      LET e = 3 let e1 = e , f = 4 RETURN f * e1;
      """
    Then the result should be, in any order:
      | f * e1 |
      | 12     |

  Scenario: []验证LET中定义多个变量-bug5530
    When executing query without error:
      """
      LET e = 3,f = 4 RETURN e * f
      """
    Then the result should be, in any order:
      | e * f |
      | 12    |

  Scenario: []LET条件表达式-SyntaxError (the `SearchedCase` syntax is not supported yet)
    When executing query without error:
      """
      LET score = 85
      LET result = CASE score
        WHEN 85 THEN "Pass"
        WHEN 50 THEN "Fail"
        ELSE "Unknown"
      END
      RETURN result;
      """
    Then the result should be, in any order:
      | result |
      | 'Pass'   |

  Scenario: [6]验证let与with子句的结合使用
    When executing query without error:
      """
      LET g = 2 WITH RANGE(1, g) AS numbers RETURN numbers;
      """
    Then the result should be, in any order:
      | numbers |
      | [1, 2]  |

  Scenario: [7]验证let在条件表达式中的使用
    When executing query without error:
      """
      LET h = 50
      RETURN CASE
          WHEN h > 40 THEN "Greater than 40"
          ELSE "40 or less"
      END AS result;
      """
    Then the result should be, in any order:
      | result            |
      | 'Greater than 40' |

  Scenario: [8]验证let在聚合函数中的使用
    When executing query without error:
      """
      LET numbers = [1, 2, 3, 4, 5]
      UNWIND numbers AS n
      RETURN SUM(n) AS total;
      """
    Then the result should be, in any order:
      | total |
      | 15    |

  Scenario Outline: [10]let绑定map/嵌套map-bug5517
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                        | result                     | 备注          |
      | LET x = {key:'value'} RETURN x;            | {key:'value'}              | 正常用例，日期记录对象 |
      | LET x = {key:'value', number:42} RETURN x; | {key: 'value', number: 42} |             |
      | LET x = {} RETURN x;                       | {}                         |             |


  Scenario: [21]let and for-for循环遍历列表并返回元素
    When executing query without error:
      """
    LET list = ['a', 'b', 'c']
    FOR element IN list
    RETURN element
      """
    Then the result should be, in any order:
      | element |
      | 'a'     |
      | 'b'     |
      | 'c'     |

    #fixme 返回三行数据：'Alice', 30; 'Bob', 25; 'Charlie', 35
  Scenario: [22]let and for-for循环遍历绑定表并返回行-bug5517
    When executing query without error:
      """
    LET table = {
      rows: [
        {name: 'Alice', age: 30},
        {name: 'Bob', age: 25},
        {name: 'Charlie', age: 35}
      ]
    }
    FOR row IN table.rows
    RETURN row.name, row.age
      """
    Then the result should be, in any order:
      | row.name  | row.age |
      | 'Alice'   | 30      |
      | 'Bob'     | 25      |
      | 'Charlie' | 35      |



