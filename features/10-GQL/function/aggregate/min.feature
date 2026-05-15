#encoding: utf-8

Feature: min

  Scenario Outline: min-positive-cases
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x        |
      | <result> |

    Examples:
      | GQL                                                                                              | result       | 备注          |
      | UNWIND RANGE(1, 3) AS m LET x = MIN(ALL m) RETURN x;                                             | 1            | 整数集合        |
      | UNWIND [1.5, 3.5, 2.5] AS m LET x = MIN(ALL m) RETURN x;                                         | 1.5          | 浮点数集合       |
      | UNWIND ['a', 'c', 'b'] AS m LET x = MIN(ALL m) RETURN x;                                         | 'a'          | 字符串集合       |
      | UNWIND [date('2023-01-01'), date('2024-01-01'), date('2022-12-31')] AS m RETURN MIN(ALL m) AS x; | '2022-12-31' | 日期列表        |
      | UNWIND [] AS m LET x = MIN(ALL m) RETURN x;                                                      | null         | 空集合，返回 NULL |
      | UNWIND [true, false, true] AS m RETURN MIN(ALL m) AS x;                                          | false        | bool列表      |
      | UNWIND [duration('P1DT2H'), duration('P2DT4H'), duration('P0DT6H')] AS m RETURN MIN(ALL m) AS x; | 'PT6H'       | duration列表  |

