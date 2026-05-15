#encoding: utf-8

Feature: path_length

  Scenario Outline: positive-cases-简单路径和方向-<备注>
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | len |
      | <result>   |
    Then drop all graph
    Examples:
      | GQL                                                                                                                | result |  备注         |
      | MATCH p = (:人{姓名: "王武"})-[]->(人{姓名: "周萌"}) LET len = PATH_LENGTH(p) RETURN len;                              | 1      |  单跳路径      |
      | MATCH p = (:人{姓名: "王武"})-[:朋友]-()-[:朋友]->() LET len =  PATH_LENGTH(p) RETURN len;                             | 2      |  两跳路径      |
      | MATCH p = (:人{姓名: "王武"})-[:朋友]-()-[:朋友]->()-[:籍贯]->() LET len =  PATH_LENGTH(p) RETURN len;                  | 3      |  三跳路径      |
      | MATCH p = (:人{姓名: "王武"})-[:朋友]-()-[:朋友]->() LET len =  PATH_LENGTH(p) RETURN len;                             | 2      |  单向路径      |
      | MATCH p = (:人{姓名: "李明"})-[:朋友]-(:人{姓名: "陈阳"})<-[:朋友]-() LET len =  PATH_LENGTH(p) RETURN len;              | 2      |  双向路径      |
      | MATCH p = (:人{姓名: "李明"})-[:朋友]-(:人{姓名: "陈阳"})<-[:朋友]-()-[:就读于]->() LET len =  PATH_LENGTH(p) RETURN len; | 3      |  混合方向路径   |

  Scenario: positive-cases-变长路径
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       MATCH p = (:人{姓名: "王武"})-[r*1..3]->(:人)
       LET len = PATH_LENGTH(p)
       RETURN len;
       """
    Then the result should be, in any order:
      | len |
      | 1   |
      | 2   |
      | 2   |
      | 3   |
      | 3   |

  Scenario: positive-cases-固定长度路径
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       MATCH p = (:人{姓名: "王武"})-[r*3]->(:人{姓名: "陈阳"})
       LET len = PATH_LENGTH(p)
       RETURN len;
       """
    Then the result should be, in any order:
      | len |
      | 3   |

  Scenario: positive-cases-最小长度路径
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       MATCH p = (:人{姓名: "王武"})-[r*2..]->(:人{姓名: "陈阳"})
       LET len = PATH_LENGTH(p)
       RETURN len;
       """
    Then the result should be, in any order:
      | len |
      | 2   |
      | 3   |

  Scenario: positive-cases-多种关系类型
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       MATCH p = (:人{姓名: "王武"})-[:朋友]->()-[:就职于]-()
       LET len = PATH_LENGTH(p)
       RETURN len;
       """
    Then the result should be, in any order:
      | len |
      | 2   |

  Scenario: positive-cases-或关系路径
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       MATCH p = (:人{姓名: "王武"})-[:朋友]->()-[:就职于|就读于]-()
       LET len = PATH_LENGTH(p)
       RETURN len;
       """
    Then the result should be, in any order:
      | len |
      | 2   |
      | 2   |

  Scenario Outline: positive-cases-<备注>
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | len        |
      | <result>   |
    Then drop all graph
    Examples:
      | GQL                                                                                                                | result |  备注         |
      | MATCH p = (:人{姓名: "王武"}) LET len = PATH_LENGTH(p) RETURN len;                                                   | 0      |  无关系类型    |
      | LET len = PATH_LENGTH(NULL) RETURN len;                                                                            | null   |  NULL路径参数  |

  Scenario: positive-cases-自环路径
    Given drop all graph
    Then executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:A),(:A)-[:R]->(:A)
       };
       """
    Given an already exist graph:
       """
       my_graph
       """
    When executing queries without error:
       """
       CREATE (a:A),(a)-[:R]->(a);
       """
    When executing queries without error:
       """
       MATCH p = (a)-[:R]->(a)
       LET len = PATH_LENGTH(p)
       RETURN len;
       """
    Then the result should be, in any order:
      | len |
      | 1   |

  Scenario: positive-cases-FILTER中使用路径长度过滤
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       MATCH p = (:人{姓名: "王武"})-[r*1..3]->(:人)
       LET len = PATH_LENGTH(p)
       FILTER len < 2
       RETURN len;
       """
    Then the result should be, in any order:
      | len |
      | 1   |

  Scenario: positive-cases-路径长度统计
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       MATCH p = (:人{姓名: "王武"})-[r*1..3]->(:人)
       LET len = PATH_LENGTH(p)
       RETURN len, COUNT(len) as count ORDER BY len;
       """
    Then the result should be, in any order:
      | len | count |
      | 1   | 1     |
      | 2   | 2     |
      | 3   | 2     |

  Scenario: positive-cases-最长路径查询
    Given drop all graph
    When executing queries without error:
       """
       CREATE GRAPH my_graph{
       (:人{姓名 STRING, 年龄 INT64, 性别 BOOLEAN}),
       (:公司 {名称 STRING, 成立时间 STRING}),
       (:学校 {名称 STRING, 创办时间 STRING}),
       (:城市 {名称 STRING}),
       (:人)-[:就读于 {入学时间 DATE, 毕业时间 DATE}]->(:学校),
       (:人)-[:朋友]->(:人),
       (:学校)-[:所属城市]->(:城市),
       (:人)-[:籍贯]->(:城市),
       (:人)-[:就职于 {入职时间 DATE, 离职时间 DATE}]->(:公司),
       (:人)-[:同事]->(:人)
       };
       """
    When login in user for USER["SYSDBA"]-PWD["SYSDBA"]-DB["my_graph"]
    Then init GraphRelationship by user["SYSDBA"]-[0]-DB["my_graph"]
    When executing queries without error:
       """
       MATCH p = (:人{姓名: "王武"})-[r*1..3]->(:人)
       LET len = PATH_LENGTH(p)
       RETURN MAX(len) as maxLength;
       """
    Then the result should be, in any order:
      | maxLength |
      | 3         |

  Scenario Outline: castToFloat-negative-cases-<备注>
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                                                  | error                                                  | 备注             |
      | LET len = PATH_LENGTH('not_a_path') RETURN len;      | [2725]Type mismatch: expected Path but was String      | 非路径类型         |
      | LET len = PATH_LENGTH(path) RETURN len;              | [2701]Variable `path` not defined                      | 未定义变量         |
      | LET len = PATH_LENGTH() RETURN len;                  | Insufficient parameters for function 'PathLength'      | 缺少参数          |
      | MATCH p = (a) LET len = PATH_LENGTH(p,p) RETURN len; | Too many parameters for function 'PathLength'          | 参数数量过多       |
      | LET len = PATH_LENGTH{} RETURN len;                  | [2700]Invalid input                                    | 语法错误          |