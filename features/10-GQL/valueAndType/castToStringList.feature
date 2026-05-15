#encoding: utf-8
# return toStringList([1,2]);
Feature: cast类型转换函数-toStringList

  Scenario Outline: castToFloat-positive-cases-数值列表到LIST<STRING>转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                       | result               |
      | RETURN CAST([1, 0, 1] AS LIST<STRING>) AS result;         | ['0', '1', '1']        |
      | RETURN CAST([-1, -2, -3] AS LIST<STRING>) AS result;      | ['-1', '-2', '-3']     |
      | RETURN CAST([123, 456, 789] AS LIST<STRING>) AS result;   | ['123', '456', '789']  |
      | RETURN CAST([1.5, 2.7, 3.1] AS LIST<STRING>) AS result;   | ['1.5', '2.7', '3.1']  |
      | RETURN CAST([0.0, -0.0, 3.14] AS LIST<STRING>) AS result; | ['0', '0', '3.14']     |
      | RETURN CAST([1, 2.5, -3, 0.0] AS LIST<STRING>) AS result; | ['-3', '0', '1', '2.5'] |

  Scenario Outline: castToFloat-positive-cases-布尔值列表到LIST<STRING>转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                           | result                    |
      | RETURN CAST([true, false, true] AS LIST<STRING>) AS result;   | ['false', 'true', 'true']   |
      | RETURN CAST([false, false, false] AS LIST<STRING>) AS result; | ['false', 'false', 'false'] |
      | RETURN CAST([TRUE, FALSE, TRUE] AS LIST<STRING>) AS result;   | ['false', 'true', 'true']   |

  Scenario Outline: castToFloat-positive-cases-字符串列表到LIST<STRING>转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                        | result             |
      | RETURN CAST(["hello", "world"] AS LIST<STRING>) AS result; | ['hello', 'world'] |
      | RETURN CAST(["1", "2", "3"] AS LIST<STRING>) AS result;    | ['1', '2', '3']    |
      | RETURN CAST(["true", "false"] AS LIST<STRING>) AS result;  | ['false', 'true']  |
      | RETURN CAST(["", " ", "  "] AS LIST<STRING>) AS result;    | ['  ', ' ', '']    |

  Scenario Outline: castToFloat-positive-cases-时间类型列表到LIST<STRING>转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                                                           | result                          |
      | RETURN CAST([DATE("2024-01-01"), TIME("12:00:00")] AS LIST<STRING>) AS result;                | ['2024-01-01', '12:00Z']        |
      | RETURN CAST([DATETIME("2024-01-01T12:00:00"), DURATION("P1DT2H")] AS LIST<STRING>) AS result; | ['2024-01-01T12:00Z', 'P1DT2H'] |

  Scenario Outline: castToFloat-positive-cases-混合类型列表转换
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                            | result                     |
      | RETURN CAST([1, "hello", true] AS LIST<STRING>) AS result;     | ['1', 'hello', 'true']     |
      | RETURN CAST([3.14, false, "world"] AS LIST<STRING>) AS result; | ['3.14', 'false', 'world'] |
      | RETURN CAST([0, "", null] AS LIST<STRING>) AS result;          | ['0', '', null]            |

  Scenario Outline: castToFloat-positive-cases-特殊值和边界情况
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | result   |
      | <result> |
    Examples:
      | GQL                                                           | result                |
      | RETURN CAST([1, null, 3] AS LIST<STRING>) AS result;          | ['1', null, '3']      |
      | RETURN CAST([null, "hello", null] AS LIST<STRING>) AS result; | [null, 'hello', null] |
      | RETURN CAST([] AS LIST<STRING>) AS result;                    | []                    |
      | RETURN CAST([""] AS LIST<STRING>) AS result;                  | ['']                  |
      | RETURN CAST(["", "", ""] AS LIST<STRING>) AS result;          | ['', '', '']          |
      | RETURN CAST([1] AS LIST<STRING>) AS result;                   | ['1']                 |
      | RETURN CAST([0] AS LIST<STRING>) AS result;                   | ['0']                 |
      | RETURN CAST([true] AS LIST<STRING>) AS result;                | ['true']              |
      | RETURN CAST(["hello"] AS LIST<STRING>) AS result;             | ['hello']             |

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
      | GQL | error |
      | RETURN CAST(1 AS LIST<STRING>) AS result; | unsupported type in BinaryExactNumericType.CastTo |
      | RETURN CAST("hello" AS LIST<STRING>) AS result; | unsupported type in StringType.CastTo |
      | RETURN CAST(true AS LIST<STRING>) AS result; | unsupported type in BoolType.CastTo |
      | RETURN CAST(DATE('2025-06-06') AS LIST<STRING>) AS result; | unsupported type in TemporalType.CastTo |
      | RETURN CAST([POINT({x: 13.4, y: 52.5})] AS LIST<STRING>) AS result; | unsupported type in ConstructedValueType.CastTo |
