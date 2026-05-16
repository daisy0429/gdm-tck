#encoding: utf-8
# return toFloatList([1,2]);
Feature: cast类型转换函数-toFloatList

  Scenario Outline: castToFloat-positive-cases-整型列表到浮点数列表转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                   | result             |
      | RETURN CAST([1, 0, 1] AS LIST<FLOAT64>) AS result;    | [1.0, 0.0, 1.0]    |
      | RETURN CAST([1, 0, 1] AS LIST<FLOAT32>) AS result;    | [1.0, 0.0, 1.0]    |
      | RETURN CAST([0, 0, 0] AS LIST<FLOAT64>) AS result;    | [0.0, 0.0, 0.0]    |
      | RETURN CAST([0, 0, 0] AS LIST<FLOAT32>) AS result;    | [0.0, 0.0, 0.0]    |
      | RETURN CAST([-1, -2, -3] AS LIST<FLOAT64>) AS result; | [-1.0, -2.0, -3.0] |
      | RETURN CAST([-1, -2, -3] AS LIST<FLOAT32>) AS result; | [-1.0, -2.0, -3.0] |

  Scenario Outline: castToFloat-positive-cases-浮点数列表转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                             | result                                 |
      | RETURN CAST([1.5, 2.7, 3.1] AS LIST<FLOAT64>) AS result;                        | [1.5, 2.7, 3.1]                        |
      | RETURN CAST([-2.5, -1.8, 0.5] AS LIST<FLOAT32>) AS result;                      | [-2.5, -1.8, 0.5]                      |
      | RETURN CAST([3.141592653589793, 2.718281828459045] AS LIST<FLOAT64>) AS result; | [3.141592653589793, 2.718281828459045] |
      | RETURN CAST([3.141592653589793, 2.718281828459045] AS LIST<FLOAT32>) AS result; | [3.1415927, 2.7182817]                 |

  Scenario Outline: castToFloat-positive-cases-字符串数字列表转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                      | result                     |
      | RETURN CAST(["1", "0", "1"] AS LIST<FLOAT64>) AS result;                 | [1.0, 0.0, 1.0]            |
      | RETURN CAST(["3.14", "2.718", "1.414"] AS LIST<FLOAT32>) AS result;      | [3.14, 2.718, 1.414]       |
      | RETURN CAST(["1.5e2", "2.3e-3", "6.022e23"] AS LIST<FLOAT64>) AS result; | [150.0, 0.0023, 6.022e+23] |
      | RETURN CAST(["1.5e2", "2.3e-3", "6.022e23"] AS LIST<FLOAT32>) AS result; | [150.0, 0.0023, 6.022e+23] |
      | RETURN CAST([1,"123abc"] AS LIST<FLOAT64>) AS result;                    | [1, null]                  |

  Scenario Outline: castToFloat-positive-cases-混合数值类型列表转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                            | result                    |
      | RETURN CAST([1, 2.5, 3, 4.75] AS LIST<FLOAT64>) AS result;     | [1.0, 2.5, 3.0, 4.75]     |
      | RETURN CAST([1, 2.5, 3, 4.75] AS LIST<FLOAT32>) AS result;     | [1.0, 2.5, 3.0, 4.75]     |
      | RETURN CAST([-10, 0.5, 15, -2.25] AS LIST<FLOAT64>) AS result; | [-10.0, 0.5, 15.0, -2.25] |
      | RETURN CAST([-10, 0.5, 15, -2.25] AS LIST<FLOAT32>) AS result; | [-10.0, 0.5, 15.0, -2.25] |

  Scenario Outline: castToFloat-positive-cases-特殊值和边界情况
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                          | result                                              |
      | RETURN CAST([1, null, 3] AS LIST<FLOAT64>) AS result;                                        | [1.0, null, 3.0]                                    |
      | RETURN CAST([null, 2.5, null] AS LIST<FLOAT32>) AS result;                                   | [null, 2.5, null]                                   |
      | RETURN CAST([1.7976931348623157e+308, -1.7976931348623157e+308] AS LIST<FLOAT64>) AS result; | [-1.7976931348623157e308, 1.7976931348623157e308]   |
      | RETURN CAST([3.4028234663852886e+38, -3.4028234663852886e+38] AS LIST<FLOAT32>) AS result;   | [-3.4028235e38, 3.4028235e38]                       |
      | RETURN CAST([2.2250738585072014e-308, -2.2250738585072014e-308] AS LIST<FLOAT64>) AS result; | [-2.2250738585072014e-308, 2.2250738585072014e-308] |
      | RETURN CAST([1.1754943508222875e-38, -1.1754943508222875e-38] AS LIST<FLOAT32>) AS result;   | [-1.1754944e-38, 1.1754944e-38]                     |
      | RETURN CAST([0.0, -0.0, 0] AS LIST<FLOAT64>) AS result;                                      | [0, 0, 0]                                           |
      | RETURN CAST([0.0, -0.0, 0] AS LIST<FLOAT32>) AS result;                                      | [0, 0, 0]                                           |

  Scenario Outline: castToFloat-positive-cases-精度对比
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                             | result                                 |
      | RETURN CAST([3.141592653589793, 2.718281828459045] AS LIST<FLOAT64>) AS result; | [2.718281828459045, 3.141592653589793] |
      | RETURN CAST([3.141592653589793, 2.718281828459045] AS LIST<FLOAT32>) AS result; | [2.7182817, 3.1415927]                 |
      | RETURN CAST([0.123456789012345, 0.987654321098765] AS LIST<FLOAT64>) AS result; | [0.123456789012345, 0.987654321098765] |
      | RETURN CAST([0.123456789012345, 0.987654321098765] AS LIST<FLOAT32>) AS result; | [0.12345679, 0.9876543]                |

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
      | LET x = CAST([1,DATE("2024-01-01")] AS LIST<FLOAT64>) RETURN x; | unsupported type in TemporalType.CastTo |
      | LET x = CAST([1,TIME("12:00:00")] AS LIST<FLOAT32>) RETURN x; | unsupported type in TemporalType.CastTo |
      | LET x = CAST([1,DATETIME("2024-01-01T12:00:00")] AS LIST<FLOAT64>) RETURN x; | unsupported type in TemporalType.CastTo |
      | LET x = CAST([1,DURATION("P1DT2H")] AS LIST<FLOAT32>) RETURN x; | unsupported type in TemporalType.CastTo |
      | LET x = CAST([1,POINT({x: 1, y: 2})] AS LIST<FLOAT64>) RETURN x; | unsupported type in ConstructedValueType.CastTo |
      | LET x = CAST([true, false] AS LIST<FLOAT32>) RETURN x; | unsupported type in BoolType.CastTo |
      | RETURN CAST([1e400,-1e400] AS LIST<FLOAT64>) AS result; | floating point number is too large |
      | RETURN CAST([1e400,-1e400] AS LIST<FLOAT32>) AS result; | floating point number is too large |