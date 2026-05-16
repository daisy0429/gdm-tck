#encoding: utf-8
# return toInteger("123");
Feature: cast类型转换函数-toInt64

  Scenario Outline: castToFloat-positive-cases-数值到INT64转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                   | result               |
      | RETURN CAST(1 AS INT64) AS result;                    | 1                    |
      | RETURN CAST(0 AS INT64) AS result;                    | 0                    |
      | RETURN CAST(-1 AS INT64) AS result;                   | -1                   |
      | RETURN CAST(123456789 AS INT64) AS result;            | 123456789            |
      | RETURN CAST(9223372036854775807 AS INT64) AS result;  | 9223372036854775807  |
      | RETURN CAST(-9223372036854775807 AS INT64) AS result; | -9223372036854775807 |
      | RETURN CAST(3.14 AS INT64) AS result;                 | 3                    |
      | RETURN CAST(2.99 AS INT64) AS result;                 | 2                    |
      | RETURN CAST(-5.7 AS INT64) AS result;                 | -5                   |
      | RETURN CAST(0.999 AS INT64) AS result;                | 0                    |
      | RETURN CAST(1.5e2 AS INT64) AS result;                | 150                  |

  Scenario Outline: castToFloat-positive-cases-字符串到INT64转换
    When executing queries without error:
       """
       <GQL>
       """
    #整数字符串才可以正常转换
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                          | result    |
      | RETURN CAST("1" AS INT64) AS result;         | 1         |
      | RETURN CAST("0" AS INT64) AS result;         | 0         |
      | RETURN CAST("-1" AS INT64) AS result;        | -1        |
      | RETURN CAST("123456789" AS INT64) AS result; | 123456789 |
      | RETURN CAST("+42" AS INT64) AS result;       | 42        |
      | RETURN CAST("-100" AS INT64) AS result;      | -100      |
      | RETURN CAST("3.14" AS INT64) AS result;      | null      |
      | RETURN CAST("2.99" AS INT64) AS result;      | null      |

  Scenario Outline: castToFloat-positive-cases-字符串到INT64转换
    When executing queries without error:
       """
       <GQL>
       """
    #整数字符串才可以正常转换
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                     | result |
      | RETURN CAST(null AS INT64) AS result;   | null   |
      | RETURN CAST(null+1 AS INT64) AS result; | null   |

  Scenario Outline: castToFloat-negative-cases
    When executing queries:
       """
       <GQL>
       """
    Then the error should be contain:
       """
       <error>
       """
    Examples:
      | GQL | error |
      | LET x = CAST(DATE("2024-01-01") AS INT64) RETURN x; | unsupported type in TemporalType.CastTo |
      | LET x = CAST(TIME("12:00:00") AS INT64) RETURN x; | unsupported type in TemporalType.CastTo |
      | LET x = CAST(DATETIME("2024-01-01T12:00:00") AS INT64) RETURN x; | unsupported type in TemporalType.CastTo |
      | LET x = CAST(DURATION("P1DT2H") AS INT64) RETURN x; | unsupported type in TemporalType.CastTo |
      | LET x = CAST(POINT({x: 1, y: 2}) AS INT64) RETURN x; | unsupported type in ConstructedValueType.CastTo |
      | LET x = CAST(false AS INT64) RETURN x; | unsupported type in BoolType.CastTo |
      | LET x = CAST(true AS INT64) RETURN x; | unsupported type in BoolType.CastTo |
      | RETURN CAST(1e400 AS INT64) AS result; | floating point number is too large |




