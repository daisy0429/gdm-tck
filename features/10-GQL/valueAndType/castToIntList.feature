#encoding: utf-8
# return toIntegerList([1,2]);
Feature: cast类型转换函数-toIntegerList

  Scenario Outline: castToFloat-positive-cases-整型列表到LIST<INT64>转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                | result                                      |
      | RETURN CAST([1, 0, 1] AS LIST<INT64>) AS result;                                   | [1, 0, 1]                                   |
      | RETURN CAST([0, 0, 0] AS LIST<INT64>) AS result;                                   | [0, 0, 0]                                   |
      | RETURN CAST([-1, -2, -3] AS LIST<INT64>) AS result;                                | [-1, -2, -3]                                |
      | RETURN CAST([123, 456, 789] AS LIST<INT64>) AS result;                             | [123, 456, 789]                             |
      | RETURN CAST([9223372036854775807, -9223372036854775807] AS LIST<INT64>) AS result; | [9223372036854775807, -9223372036854775807] |

  Scenario Outline: castToFloat-positive-cases-浮点数列表到LIST<INT64>转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                          | result      |
      | RETURN CAST([1.0, 2.5, 3.9] AS LIST<INT64>) AS result;       | [1, 2, 3]   |
      | RETURN CAST([0.1, 0.9, 1.1] AS LIST<INT64>) AS result;       | [0, 0, 1]   |
      | RETURN CAST([-2.7, -1.2, 4.5] AS LIST<INT64>) AS result;     | [-2, -1, 4] |
      | RETURN CAST([0.0, -0.0, 0.999] AS LIST<INT64>) AS result;    | [0, 0, 0]   |
      | RETURN CAST([1.999, 2.001, 3.499] AS LIST<INT64>) AS result; | [1, 2, 3]   |

  Scenario Outline: castToFloat-positive-cases-字符串列表到LIST<INT64>转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                            | result             |
      | RETURN CAST(["1", "0", "1"] AS LIST<INT64>) AS result;         | [1, 0, 1]          |
      | RETURN CAST(["123", "456", "789"] AS LIST<INT64>) AS result;   | [123, 456, 789]    |
      | RETURN CAST(["-5", "-10", "15"] AS LIST<INT64>) AS result;     | [-5, -10, 15]      |
      | RETURN CAST(["+42", "-100", "0"] AS LIST<INT64>) AS result;    | [42, -100, 0]      |
      | RETURN CAST(["3.14", "2.99", "0.5"] AS LIST<INT64>) AS result; | [null, null, null] |

  Scenario Outline: castToFloat-positive-cases-混合类型列表转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                   | result     |
      | RETURN CAST([1, 2.5, 3] AS LIST<INT64>) AS result;    | [1, 2, 3]  |
      | RETURN CAST([0, 1.9, -2.1] AS LIST<INT64>) AS result; | [0, 1, -2] |
      | RETURN CAST([1, "2", 3] AS LIST<INT64>) AS result;    | [1, 2, 3]  |

  Scenario Outline: castToFloat-positive-cases-特殊值和边界情况
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                       | result             |
      | RETURN CAST([1, null, 3] AS LIST<INT64>) AS result;       | [1, null, 3]       |
      | RETURN CAST([null, null, null] AS LIST<INT64>) AS result; | [null, null, null] |
      | RETURN CAST([] AS LIST<INT64>) AS result;                 | []                 |
      | RETURN CAST([1] AS LIST<INT64>) AS result;                | [1]                |
      | RETURN CAST([0] AS LIST<INT64>) AS result;                | [0]                |
      | RETURN CAST([-5] AS LIST<INT64>) AS result;               | [-5]               |

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
      | GQL                                                                          | error                                           | 备注             |
      | LET x = CAST([1,DATE("2024-01-01")] AS  LIST<INT64>) RETURN x;              | unsupported type in TemporalType.CastTo         | Date类型转浮点数     |
      | LET x = CAST([1,TIME("12:00:00")] AS  LIST<INT64>) RETURN x;                | unsupported type in TemporalType.CastTo         | Time类型转浮点数     |
      | LET x = CAST([1,DATETIME("2024-01-01T12:00:00")] AS LIST<INT64>) RETURN x; | unsupported type in TemporalType.CastTo         | DateTime类型转浮点数 |
      | LET x = CAST([1,DURATION("P1DT2H")] AS LIST<INT64>) RETURN x;              | unsupported type in TemporalType.CastTo         | Duration类型转浮点数 |
      | LET x = CAST([1,POINT({x: 1, y: 2})] AS  LIST<INT64>) RETURN x;             | unsupported type in ConstructedValueType.CastTo | Point类型转浮点数    |
      | LET x = CAST([true, false] AS LIST<INT64>) RETURN x;                       | unsupported type in BoolType.CastTo             | boolean类型转浮点数  |
      | RETURN CAST([1e400,-1e400] AS LIST<INT64>) AS result;                      | floating point number is too large              | 超出范围的数值        |