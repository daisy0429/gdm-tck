#encoding: utf-8
# todo 补充用例：考虑函数支持的所有数据类型 （其他函数需要做相同考虑）

Feature: avg

  Scenario Outline: avg-positive-cases-bug5489,bug5490
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                                                                                       | result                       | 备注                         |
      | UNWIND RANGE(1, 3) AS m LET x = AVG(ALL m) RETURN x;                                                                      | 2.0                          | 输入数值范围正常                   |
      | UNWIND [1.5, 2.5, 3.5] AS m LET x = AVG(ALL m) RETURN x;                                                                  | 2.5                          | 浮点数集合                      |
      | UNWIND [10] AS m LET x = AVG(ALL m) RETURN x;                                                                             | 10.0                         | 单个元素                       |
      | UNWIND [] AS m LET x = AVG(ALL m) RETURN x;                                                                               | null                         | 空集合，返回 NULL                |
      | UNWIND [DURATION('P1DT2H'), DURATION('P2DT4H'), DURATION('P3DT6H')] AS m LET x = AVG(ALL m) RETURN x;                     | 'P2DT4H'                     | 类型duration-fixme           |
      | UNWIND [DURATION('P1DT2H'), DURATION('PT36H45M30S'), DURATION('P0DT5H15M'),DURATION('PT0S')] AS m RETURN AVG(ALL m) AS x; | 'PT17H7.5S'                  | 类型duration:混合天、小时、分钟、秒     |
      | UNWIND [DURATION('P9999DT23H59M59S'), DURATION('P0D'), DURATION('P1D')] AS m LET x = AVG(ALL m) RETURN x;                 | 'P3333DT15H59M59.666666679S' | 类型duration边界值 - 超大值 -fixme |
      | UNWIND [DURATION('P1DT2H'), null, DURATION('P3DT6H')] AS m LET x = AVG(ALL m) RETURN x;                                   | 'P2DT4H'                     | 参数包含null                   |
      | LET x = AVG(ALL null) RETURN x;                                                                                           | null                         | 空输入                        |
      | UNWIND [1.5, 2.5, null] AS m LET x = AVG(ALL m) RETURN x;                                                                 | 2                            | 含null                      |
      | return AVG(ALL null) as x ;                                                                                               | null                         | 输入全部是null-fixme            |
      | UNWIND [null, null, null] AS m RETURN AVG(m) AS x;                                                                        | null                         | 输入集合中所有元素均为 null           |
      | UNWIND [] AS m RETURN AVG(m) AS x;                                                                                        | null                         | 输入集合为空                     |
      | UNWIND [DURATION('P-1DT-2H')] AS m LET x = AVG(ALL m) RETURN x;                                                           | 'P-1DT-2H'                   | duration负数                 |

  Scenario Outline: avg-negative-cases
    When executing queries:
  """
  <GQL>
  """
    Then the error should be contain:
  """
  <error>
  """
    Examples:
      | GQL                                                                                          | error                                                              | 备注      |
      | UNWIND ['a', 'b'] AS m LET x = AVG(ALL m) RETURN x;                                          | Type mismatch: expected Duration, Float or Integer but was String  | 非数值集合输入 |
      | UNWIND [true, false] AS m LET x = AVG(ALL m) RETURN x;                                       | Type mismatch: expected Duration, Float or Integer but was Boolean | 非数值集合输入 |
      | UNWIND [DURATION('P1DT2H'), 'Invalid', DURATION('P3DT6H')] AS m LET x = AVG(ALL m) RETURN x; | unsupported value.type in AvgFunction                              | 部分类型不支持 |
      | UNWIND [DURATION('P1DT2H'), 42] AS m LET x = AVG(ALL m) RETURN x;                            | unsupported type in MinusBinaryExactNumericType                    | 部分类型不支持 |

