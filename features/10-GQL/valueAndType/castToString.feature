##encoding: utf-8
##cast(castOperand as castTarget)
##castOperand: valueExpression | nullLiteral;
##castTarget: valueType;
##https://neo4j.com/docs/cypher-manual/current/values-and-types/casting-data/
##作用：将指定值从一种数据类型转换为目标数据类型。主要用于类型转换，如将数值转换为字符串或布尔值等，以满足查询逻辑或操作需求。
##示例：MATCH (p:Person) RETURN CAST(p.age AS STRING); -- 将节点属性 `age`（假设为数字类型）转换为字符串类型。
## 和valueType用例存在部分重叠：valueType用例覆盖所有数据类型
##return toString(1);

Feature: cast类型转换函数-toString-bug5433

  Scenario Outline: castToString-positive-cases-LET
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                          | result           | 备注           |
      | LET x = CAST("hello" AS STRING) RETURN x;                    | 'hello'          | 字符串转字符串      |
      | LET x = CAST(true AS STRING) RETURN x;                       | 'true'           | 布尔转字符串-fixme |
      | LET x = CAST(123.45 AS STRING) RETURN x;                     | '123.45'         | 浮点数转字符串      |
      | LET x = CAST(123 AS STRING) RETURN x;                        | '123'            | 长整型转字符串      |
      | LET x = CAST(2*4 AS STRING) RETURN x;                        | '8'              | 表达式转字符串      |
      | LET x = CAST(DATE("2024-01-01") AS STRING) RETURN x;         | '2024-01-01'     | 日期转字符串       |
      | LET x = CAST(DURATION("P1Y2M3DT4H5M6S") AS STRING) RETURN x; | 'P1Y2M3DT4H5M6S' | bug-时间段转字符串  |
      | LET x = CAST(null AS STRING) RETURN x;                       | null             | bug-         |

  Scenario Outline: castToFloat-positive-cases-数值到STRING转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                    | result                 |
      | RETURN CAST(1 AS STRING) AS result;                    | '1'                    |
      | RETURN CAST(0 AS STRING) AS result;                    | '0'                    |
      | RETURN CAST(-1 AS STRING) AS result;                   | '-1'                   |
      | RETURN CAST(123456789 AS STRING) AS result;            | '123456789'            |
      | RETURN CAST(9223372036854775807 AS STRING) AS result;  | '9223372036854775807'  |
      | RETURN CAST(-9223372036854775807 AS STRING) AS result; | '-9223372036854775807' |
      | RETURN CAST(3.14 AS STRING) AS result                  | '3.14'                 |
      | RETURN CAST(2.718281828459045 AS STRING) AS result;    | '2.718281828459045'    |
      | RETURN CAST(-5.7 AS STRING) AS result;                 | '-5.7'                 |
      | RETURN CAST(0.0 AS STRING) AS result;                  | '0'                    |
      | RETURN CAST(1.5e10 AS STRING) AS result;               | '1.5e+10'              |
      | RETURN CAST(2.3e-5 AS STRING) AS result;               | '2.3e-05'              |

  Scenario Outline: castToFloat-positive-cases-布尔值到STRING转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                     | result  |
      | RETURN CAST(true AS STRING) AS result;  | 'true'  |
      | RETURN CAST(false AS STRING) AS result; | 'false' |
      | RETURN CAST(TRUE AS STRING) AS result;  | 'true'  |
      | RETURN CAST(FALSE AS STRING) AS result; | 'false' |

  Scenario Outline: castToFloat-positive-cases-字符串自身转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                              | result         |
      | RETURN CAST("hello" AS STRING) AS result;        | 'hello'        |
      | RETURN CAST("123" AS STRING) AS result;          | '123'          |
      | RETURN CAST("" AS STRING) AS result;             | ''             |
      | RETURN CAST("true" AS STRING) AS result;         | 'true'         |
      | RETURN CAST("hello world" AS STRING) AS result;  | 'hello world'  |
      | RETURN CAST("line1\nline2" AS STRING) AS result; | 'line1\nline2' |

  Scenario Outline: castToFloat-positive-cases-时间类型到STRING转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                               | result              |
      | RETURN CAST(DATE("2024-01-01") AS STRING) AS result;              | '2024-01-01'        |
      | RETURN CAST(TIME("12:00:00") AS STRING) AS result;                | '12:00Z'            |
      | RETURN CAST(DATETIME("2024-01-01T12:00:00") AS STRING) AS result; | '2024-01-01T12:00Z' |
      | RETURN CAST(DURATION("P1DT2H") AS STRING) AS result;              | 'P1DT2H'            |

  Scenario Outline: castToFloat-positive-cases-特殊值和边界情况
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                    | result |
      | RETURN CAST(null AS STRING) AS result; | null   |


  Scenario Outline: castToString-negative-cases
    When executing queries:
       """
       <GQL>
       """
    Then the error should be contain:
       """
       <error>
       """
    Examples:
      | GQL                                                                        | error                                           | 备注       |
      | LET x =  CAST(123, 456) RETURN x;                                          | unsupported value type in FunctionInvocation    | 参数数量错误   |
      | LET x = CAST(POINT({longitude: 13.4, latitude: 52.5}) AS STRING) RETURN x; | unsupported type in ConstructedValueType.CastTo | 坐标类型转字符串 |