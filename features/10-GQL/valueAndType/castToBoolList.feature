##encoding: utf-8

Feature: cast类型转换函数-toBoolList
  #支持bool/integer/str

  Scenario Outline: castToFloat-positive-cases-整数列表到布尔列表转换
    When executing queries without error:
       """
       <GQL>
       """
    #非零为true
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                   | result                |
      | RETURN CAST([1, 0, 1] AS LIST<BOOL>) AS result;       | [true, false, true]   |
      | RETURN CAST([0, 0, 0] AS LIST<BOOL>) AS result;       | [false, false, false] |
      | RETURN CAST([1, 1, 1] AS LIST<BOOL>) AS result;       | [true, true, true]    |
      | RETURN CAST([-1, -2, -3] AS LIST<BOOL>) AS result;    | [true, true, true]    |
      | RETURN CAST([100, 200, 300] AS LIST<BOOL>) AS result; | [true, true, true]    |
      | RETURN CAST([0, 999, 0] AS LIST<BOOL>) AS result;     | [false, true, false]  |

  Scenario Outline: castToFloat-positive-cases-字符串列表到布尔列表
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                             | result              |
      | RETURN CAST(["1", "0", "1"] AS LIST<BOOL>) AS result;           | [null, null, null]  |
      | RETURN CAST(["0", "0", "0"] AS LIST<BOOL>) AS result;           | [null, null, null]  |
      | RETURN CAST(["true", "false", "true"] AS LIST<BOOL>) AS result; | [true, false, true] |
      | RETURN CAST(["TRUE", "FALSE", "TRUE"] AS LIST<BOOL>) AS result; | [true, false, true] |
      | RETURN CAST(["True", "False", "True"] AS LIST<BOOL>) AS result; | [true, false, true] |
      | RETURN CAST(["yes", "no", "yes"] AS LIST<BOOL>) AS result;      | [null, null, null]  |

  Scenario Outline: castToFloat-positive-cases-布尔列表自身转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                         | result                |
      | RETURN CAST([true, false, true] AS LIST<BOOL>) AS result;   | [true, false, true]   |
      | RETURN CAST([false, false, false] AS LIST<BOOL>) AS result; | [false, false, false] |
      | RETURN CAST([true, True, true] AS LIST<BOOL>) AS result;    | [true, true, true]    |

  Scenario Outline: castToFloat-positive-cases-单元素列表转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                           | result  |
      | RETURN CAST([1] AS LIST<BOOL>) AS result;     | [true]  |
      | RETURN CAST([0] AS LIST<BOOL>) AS result;     | [false] |
      | RETURN CAST([true] AS LIST<BOOL>) AS result;  | [true]  |
      | RETURN CAST([false] AS LIST<BOOL>) AS result; | [false] |

  Scenario Outline: castToFloat-positive-cases-混合类型列表
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                      | result               |
      | RETURN CAST([1, true, "false"] AS LIST<BOOL>) AS result; | [true, true, false]  |
      | RETURN CAST([0, false, "yes"] AS LIST<BOOL>) AS result;  | [false, false, null] |

  Scenario Outline: castToFloat-positive-cases-特殊值和边界情况
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                      | result              |
      | RETURN CAST([1, null, 0] AS LIST<BOOL>) AS result;       | [true, null, false] |
      | RETURN CAST([null, 0, null] AS LIST<BOOL>) AS result;    | [null, false, null] |
      | RETURN CAST([null, null, null] AS LIST<BOOL>) AS result; | [null, null, null]  |
      | RETURN CAST([] AS LIST<BOOL>) AS result;                 | []                  |

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
      | LET x = CAST([DATE("2024-01-01")] AS LIST<BOOL>) RETURN x;              | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST([DATETIME("2024-01-01T12:00:00")] AS LIST<BOOL>) RETURN x; | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST([TIME("12:00:00")] AS LIST<BOOL>) RETURN x;                | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST([LOCALTIME("12:00:00")] AS LIST<BOOL>) RETURN x;           | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST([DURATION("P1DT2H")] AS LIST<BOOL>) RETURN x;              | unsupported type in TemporalType.CastTo           |          |
      | LET x = CAST([POINT({x: 1.0, y: 2.0})] AS LIST<BOOL>) RETURN x;         | unsupported type in ConstructedValueType.CastTo   |          |
      | LET x = CAST([-12.3] AS LIST<BOOL>) RETURN x;                           | unsupported type in ApproximateNumericType.CastTo | 非零浮点数转布尔 |
      | LET x = CAST([123.45] AS LIST<BOOL>) RETURN x;                          | unsupported type in ApproximateNumericType.CastTo | 非零浮点数转布尔 |
      | LET x = CAST([DATETIME("2024-01-01T12:00:00")] AS LIST<BOOL>) RETURN x; | unsupported type in TemporalType.CastTo           |          |


