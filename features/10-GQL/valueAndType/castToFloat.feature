##encoding: utf-8
## todo test:扩展测试更多数字类型
## return toFloat("123");
Feature: cast类型转换函数-toFloat
  expected Float, Integer or String but was Boolean

  Scenario Outline: castToFloat-positive-cases-LET
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                   | result | 备注                                    |
      | LET x = CAST(13 / 4 AS FLOAT) RETURN x;               | 3      | 算术表达式结果转浮点数 ：先执行整数除法返回3，然后再将结果3转换为浮点数 |
      | LET x = CAST(NULL + 1 AS FLOAT) RETURN x;             | null   | 包含NULL的表达式结果转浮点数                      |
      | LET x = CAST("123" AS FLOAT) RETURN x;                | 123    | 纯数值类型的字符串                             |
      | LET x = CAST(123 AS FLOAT) RETURN x;                  | 123    | 整数转浮点数                                |
      | LET x = CAST(1.111 AS FLOAT) RETURN x;                | 1.111  | 浮点数转浮点数                               |
      | WITH null AS d RETURN toFloat(d) as x                 | null   |                                       |
      | WITH null AS d RETURN coalesce(toFloat(d), 0.0) as x; | 0      |                                       |
      | LET x = CAST(NULL + 1 AS FLOAT) RETURN x;             | null   |                                       |

  Scenario Outline: castToFloat-positive-cases-基础数值转换为浮点数
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                          | result       |
      | RETURN CAST(1 AS FLOAT64) AS result;         | 1.0          |
      | RETURN CAST(0 AS FLOAT64) AS result;         | 0.0          |
      | RETURN CAST(-1 AS FLOAT64) AS result;        | -1.0         |
      | RETURN CAST(123456789 AS FLOAT64) AS result; | 123456789.0  |
      | RETURN CAST(1 AS FLOAT32) AS result;         | 1.0          |
      | RETURN CAST(0 AS FLOAT32) AS result;         | 0.0          |
      | RETURN CAST(-1 AS FLOAT32) AS result;        | -1.0         |
      | RETURN CAST(123456789 AS FLOAT32) AS result; | 1.2345679e08 |

  Scenario Outline: castToFloat-positive-cases-浮点数精度和范围测试
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                        | result                  |
      | RETURN CAST(3.141592653589793 AS FLOAT64) AS result;       | 3.141592653589793       |
      | RETURN CAST(3.141592653589793 AS FLOAT32) AS result;       | 3.1415927               |
      | RETURN CAST(2.718281828459045 AS FLOAT64) AS result;       | 2.718281828459045       |
      | RETURN CAST(2.718281828459045 AS FLOAT32) AS result;       | 2.7182817               |
      | RETURN CAST(1.7976931348623157e+308 AS FLOAT64) AS result; | 1.7976931348623157e308  |
      | RETURN CAST(3.4028234663852886e+38 AS FLOAT32) AS result;  | 3.4028235e38            |
      | RETURN CAST(2.2250738585072014e-308 AS FLOAT64) AS result; | 2.2250738585072014e-308 |
      | RETURN CAST(1.1754943508222875e-38 AS FLOAT32) AS result;  | 1.1754944e-38           |

  Scenario Outline: castToFloat-positive-cases-字符串到浮点数转换
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                           | result   |
      | RETURN CAST("3.14" AS FLOAT64) AS result;     | 3.14     |
      | RETURN CAST("3.14" AS FLOAT32) AS result;     | 3.14     |
      | RETURN CAST("-42.5" AS FLOAT64) AS result;    | -42.5    |
      | RETURN CAST("0.001" AS FLOAT32) AS result;    | 0.001    |
      | RETURN CAST("1.23e-4" AS FLOAT64) AS result;  | 0.000123 |
      | RETURN CAST("6.022e23" AS FLOAT64) AS result; | 6.022e23 |
      | RETURN CAST("-1.5e10" AS FLOAT32) AS result;  | -1.5e10  |
      | RETURN CAST("123abc" AS FLOAT) AS result;     | null     |

  Scenario Outline: castToFloat-positive-cases-浮点数类型间转换
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                   | result    |
      | RETURN CAST(CAST(3.14 AS FLOAT32) AS FLOAT64) AS result;              | 3.14      |
      | RETURN CAST(CAST(3.141592653589793 AS FLOAT64) AS FLOAT32) AS result; | 3.1415927 |

  Scenario Outline: castToFloat-positive-cases-特殊值和边界情况
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                         | result |
      | RETURN CAST(0.0 AS FLOAT64) AS result;      | 0      |
      | RETURN CAST(-0.0 AS FLOAT64) AS result;     | 0      |
      | RETURN CAST(1.0/0.0 AS FLOAT64) AS result;  | Inf    |
      | RETURN CAST(-1.0/0.0 AS FLOAT64) AS result; | -Inf   |
      | RETURN CAST(0.0/0.0 AS FLOAT64) AS result;  | NaN    |
      | RETURN CAST(null AS FLOAT64) AS result;;    | null   |
      | RETURN CAST(null AS FLOAT32) AS result;     | null   |

  Scenario Outline: castToFloat-positive-cases-数学计算与比较
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                         | result             |
      | RETURN CAST(10 AS FLOAT64) / CAST(3 AS FLOAT64) AS result;  | 3.3333333333333335 |
      | RETURN CAST(10 AS FLOAT32) / CAST(3 AS FLOAT32) AS result;  | 3.3333333333333335 |
      | RETURN CAST(1.5 AS FLOAT64) > CAST(1 AS FLOAT64) AS result; | true               |
      | RETURN CAST(1.0 AS FLOAT32) = CAST(1 AS FLOAT32) AS result; | true               |

#字符串类型允许转float，但仅支持纯数值类型的字符串转换
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
      | GQL                                                              | error                                           | 备注             |
      | LET x = CAST(DATE("2024-01-01") AS FLOAT) RETURN x;              | unsupported type in TemporalType.CastTo         | Date类型转浮点数     |
      | LET x = CAST(TIME("12:00:00") AS FLOAT) RETURN x;                | unsupported type in TemporalType.CastTo         | Time类型转浮点数     |
      | LET x = CAST(DATETIME("2024-01-01T12:00:00") AS FLOAT) RETURN x; | unsupported type in TemporalType.CastTo         | DateTime类型转浮点数 |
      | LET x = CAST(DURATION("P1DT2H") AS FLOAT) RETURN x;              | unsupported type in TemporalType.CastTo         | Duration类型转浮点数 |
      | LET x = CAST(POINT({x: 1, y: 2}) AS FLOAT) RETURN x;             | unsupported type in ConstructedValueType.CastTo | Point类型转浮点数    |
      | LET x = CAST(false AS FLOAT) RETURN x;                           | unsupported type in BoolType.CastTo             | 空字符串无法转浮点数     |
      | LET x = CAST(true AS FLOAT) RETURN x;                            | unsupported type in BoolType.CastTo             | 空字符串无法转浮点数     |
      | RETURN CAST(1e400 AS FLOAT64) AS result;                         | floating point number is too large              | 超出范围的数值        |
      | RETURN CAST(1e400 AS FLOAT32) AS result;                         | floating point number is too large              |                |

