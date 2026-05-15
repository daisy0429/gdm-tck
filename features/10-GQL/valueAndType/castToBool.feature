##encoding: utf-8

Feature: cast类型转换函数-toBool
  #支持bool/integer/str

  Scenario Outline: castToFloat-positive-cases-整数到布尔
    When executing queries without error:
       """
       <GQL>
       """
    #非零为true
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                 | result |
      | RETURN CAST(1 AS BOOL) AS result;   | true   |
      | RETURN CAST(0 AS BOOL) AS result;   | false  |
      | RETURN CAST(-1 AS BOOL) AS result;  | true   |
      | RETURN CAST(100 AS BOOL) AS result; | true   |
      | RETURN CAST(-50 AS BOOL) AS result; | true   |

  Scenario Outline: castToFloat-positive-cases-字符串到布尔
    When executing queries without error:
       """
       <GQL>
       """
    #非零为true
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                     | result |
      | RETURN CAST("true" AS BOOL) AS result;  | true   |
      | RETURN CAST("false" AS BOOL) AS result; | false  |
      | RETURN CAST("TRUE" AS BOOL) AS result;  | true   |
      | RETURN CAST("FALSE" AS BOOL) AS result; | false  |
      | RETURN CAST("1" AS BOOL) AS result;     | null   |
      | RETURN CAST("0" AS BOOL) AS result;     | null   |
      | RETURN CAST("-1" AS BOOL) AS result;    | null   |
      | RETURN CAST("yes" AS BOOL) AS result;   | null   |
      | RETURN CAST("" AS BOOL) AS result;      | null   |

  Scenario Outline: castToFloat-positive-cases-布尔自身转换
    When executing queries without error:
       """
       <GQL>
       """
    #非零为true
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                   | result |
      | RETURN CAST(true AS BOOL) AS result;  | true   |
      | RETURN CAST(false AS BOOL) AS result; | false  |
      | RETURN CAST(TRUE AS BOOL) AS result;  | true   |
      | RETURN CAST(FALSE AS BOOL) AS result; | false  |

  Scenario Outline: castToFloat-positive-cases-特殊值和边界情况
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                             | result |
      | RETURN CAST(null AS BOOL) AS result;            | null   |
      | RETURN CAST(92233720368547 AS BOOL) AS result;  | true   |
      | RETURN CAST(-92233720368547 AS BOOL) AS result; | true   |

    #待bug-8226处理结果看是否支持其余类型转换为bool类型
  Scenario Outline: castToBool-negative-cases
    When executing queries:
       """
       <GQL>
       """
    Then the error should be contain:
       """
       <error>
       """
    Examples:
      | GQL                                                                | error                                             | 备注       |
      | LET x = CAST(DATE("2024-01-01") AS BOOLEAN) RETURN x;              | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST(DATETIME("2024-01-01T12:00:00") AS BOOLEAN) RETURN x; | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST(TIME("12:00:00") AS BOOLEAN) RETURN x;                | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST(LOCALTIME("12:00:00") AS BOOLEAN) RETURN x;           | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST(DURATION("P1DT2H") AS BOOLEAN) RETURN x;              | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST(POINT({x: 1.0, y: 2.0}) AS BOOLEAN) RETURN x;         | unsupported type in ConstructedValueType.CastTo   |          |
      | LET x = CAST(-12.3 AS BOOLEAN) RETURN x;                           | unsupported type in ApproximateNumericType.CastTo | 非零浮点数转布尔 |
      | LET x = CAST(123.45 AS BOOLEAN) RETURN x;                          | unsupported type in ApproximateNumericType.CastTo | 非零浮点数转布尔 |
      | LET x = CAST(DATETIME("2024-01-01T12:00:00") AS BOOLEAN) RETURN x; | unsupported type in TemporalType.CastTo           |          |