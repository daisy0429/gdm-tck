#encoding: utf-8

Feature: MAX

  Scenario Outline: max-positive-cases
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                                                              | result                | 备注          |
      | UNWIND RANGE(1, 3) AS m LET x = MAX(ALL m) RETURN x;                                             | 3                     | 整数集合        |
      | UNWIND [1.5, 3.5, 2.5] AS m LET x = MAX(ALL m) RETURN x;                                         | 3.5                   | 浮点数集合       |
      | UNWIND [1, 2.5, 3, 4.7] AS m RETURN MAX(ALL m) AS x;                                             | 4.7                   | 混合数值类型      |
      | UNWIND ['a', 'c', 'b'] AS m LET x = MAX(ALL m) RETURN x;                                         | 'c'                   | 字符串集合       |
      | UNWIND [date('2023-01-01'), date('2024-01-01'), date('2022-12-31')] AS m RETURN MAX(ALL m) AS x; | '2024-01-01'          | 日期列表        |
      | UNWIND [true, false, true] AS m RETURN MAX(ALL m) AS x;                                          | true                  | bool列表      |
      | UNWIND [] AS m LET x = MAX(ALL m) RETURN x;                                                      | null                  | 空集合，返回 NULL |
      | UNWIND [duration('P1DT2H'), duration('P2DT4H'), duration('P0DT6H')] AS m RETURN max(ALL m) AS x; | 'P2DT4H'              | duration列表  |
      | UNWIND [duration('P1DT2H'), duration('P2DT4H'), duration('P0DT6H')] AS m RETURN max(ALL m) AS x; | 'P2DT4H'              | duration列表  |
      | UNWIND [null, null, null] AS m RETURN MAX(ALL m) AS x;                                           | null                  |             |
      | UNWIND [true, 42] AS m RETURN MAX(ALL m) AS x                                                    | 42                    |             |
      | UNWIND [2^63-1, -2^63] AS m RETURN MAX(ALL m) AS x;                                              | 9.223372036854776e+18 |             |

