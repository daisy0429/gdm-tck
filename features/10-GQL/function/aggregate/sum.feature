#encoding: utf-8

Feature: sum

  Scenario Outline: sum-positive-cases
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                                                              | result    | 备注      |
      | UNWIND RANGE(1, 3) AS m LET x = SUM(ALL m) RETURN x;                                             | 6         | 整数集合    |
      | UNWIND [1.5, 2.5, 3.5] AS m LET x = SUM(ALL m) RETURN x;                                         | 7.5       | 浮点数集合   |
      | UNWIND [] AS m LET x = SUM(ALL m) RETURN x;                                                      | 0         | 空集合返回 0 |
      | UNWIND [duration('P1DT2H'), duration('P2DT4H'), duration('P0DT6H')] AS m RETURN SUM(ALL m) AS x; | 'P3DT12H' |         |

  Scenario Outline: sum-negative-cases
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                                                     | error                                                              | 备注      |
      | UNWIND ['a', 'b'] AS m LET x = SUM(ALL m) RETURN x;     | Type mismatch: expected Duration, Float or Integer but was String  | 非数值集合输入 |
      | UNWIND [true, false, true] AS m RETURN SUM(ALL m) AS x; | Type mismatch: expected Duration, Float or Integer but was Boolean |         |