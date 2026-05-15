Feature: DURATION_BETWEEN

  Scenario Outline: DURATION_BETWEEN
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                                                                  | result      | 备注               |
      | LET x = DURATION_BETWEEN(DATE('2024-10-10'),DATE('2023-11-11')) RETURN x;                            | 'P-10M-29D' |                  |
      | LET x = DURATION_BETWEEN(DATE('2024-10-10'),DATE('2024-11-11')) RETURN x;                            | 'P1M1D'     |                  |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), DATE('2023-01-01')) RETURN x;                           | 'P-1Y'      | 跨年               |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), DATE('2023-12-31')) RETURN x;                           | 'P-1D'      | 跨年+1天bug7444     |
      | LET x = DURATION_BETWEEN(DATE('2024-06-01'), DATE('2024-01-01')) RETURN x;                           | 'P-5M'      | 同年内跨月            |
      | LET x = DURATION_BETWEEN(DATE('2024-03-15'), DATE('2024-03-10')) RETURN x;                           | 'P-5D'      | 同月内              |
      | LET x = DURATION_BETWEEN(DATE('2024-03-10'), DATE('2024-03-15')) RETURN x;                           | 'P5D'       | 日期反向             |
      | LET x = DURATION_BETWEEN(DATETIME('2024-03-10T12:00:00'), DATETIME('2024-03-10T11:00:00')) RETURN x; | 'PT-1H'     | 小时差              |
      | LET x = DURATION_BETWEEN(DATETIME('2024-03-10T12:00:00'), DATETIME('2024-03-10T12:30:00')) RETURN x; | 'PT30M'     | 分钟差（负方向）         |
      | LET x = DURATION_BETWEEN(DATETIME('2024-03-10T12:00:00'), DATETIME('2024-03-10T12:00:05')) RETURN x; | 'PT5S'      | 秒差（负方向）          |
      | LET x = DURATION_BETWEEN(DATETIME('2024-01-01T00:00:00'), DATETIME('2023-01-01T00:00:00')) RETURN x; | 'P-1Y'      | 精确到时间的年份差        |
      | LET x = DURATION_BETWEEN(DATETIME('2024-01-01T10:00:00'), DATETIME('2023-12-31T23:00:00')) RETURN x; | 'PT-11H'    | 日期+小时复合差值bug7444 |
      | LET x = DURATION_BETWEEN(DATE('2024-02-29'), DATE('2020-02-29')) RETURN x;                           | 'P-4Y'      | 跨多个闰年            |
      | LET x = DURATION_BETWEEN(DATETIME('2024-03-01T00:00:00'), DATETIME('2024-02-28T23:59:59')) RETURN x; | 'P-1DT-1S'  | 几乎整天，秒级差         |
      | LET x = DURATION_BETWEEN(NULL, DATE('2024-01-01')) RETURN x;                                         | null        |                  |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), NULL) RETURN x;                                         | null        |                  |
      | return DURATION.BETWEEN(DATE('2024-01-01'), TIME('12:00:00')) as x;                                  | 'PT12H'     | DATE vs TIME     |

  Scenario Outline: DURATION_BETWEEN 异常处理
    When executing queries:
       """
       <GQL>
       """
    Then the error should be contain:
       """
       <error>
       """
    Examples:
      | GQL                                                                                            | error                                                | 备注            |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), '2024-01-01') RETURN x;                           | unsupported value type in ConvertToTime              | 第二个参数为字符串     |
      | LET x = DURATION_BETWEEN(DATE('invalid-date'), DATE('2024-01-01')) RETURN x;                   | Text cannot be parsed to a Date                      | 不合法的日期格式      |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01')) RETURN x;                                         | unsupported value type in FunctionInvocation         | 只有一个参数        |
      | LET x = DURATION_BETWEEN() RETURN x;                                                           | unsupported value type in FunctionInvocation         | 参数为空          |
      | LET x = DURATION_BETWEEN(TRUE, DATE('2024-01-01')) RETURN x;                                   | unsupported value type in ConvertToTime              | 第一个参数是布尔值     |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), [DATE('2023-01-01')]) RETURN x;                   | unsupported value type in ConvertToTime              | 第二个参数是数组      |
      | LET x = DURATION_BETWEEN(TIMESTAMP('2024-01-01T00:00:00Z'), TIMESTAMP('1999-12-31')) RETURN x; | parsing time "2024-01-01T00:00:00Z": extra text: "Z" | 跨世纪，可能涉及时区不一致 |

  Scenario Outline: DURATION_BETWEEN--DAY TO SECOND
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                                                                               | result        | 备注      |
      | LET x = DURATION_BETWEEN(DATE('2024-10-10'), DATE('2023-11-11')) DAY TO SECOND RETURN x;                          | 'P-29D'       | 基本日期差计算 |
      | LET x = DURATION_BETWEEN(DATE('2023-11-11'), DATE('2024-10-10')) DAY TO SECOND  RETURN x;                         | 'P29D'        | 日期顺序反转  |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), DATE('2024-01-01')) DAY TO SECOND RETURN x;                          | 'PT0S'        | 相同日期    |
      | LET x = DURATION_BETWEEN(DATE('2024-03-01'), DATE('2023-02-28')) DAY TO SECOND RETURN x;                          | 'P-3D'        | 跨闰年计算   |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), DATE('2000-01-01')) DAY TO SECOND RETURN x;                          | 'PT0S'        | 跨闰世纪计算  |
      | LET x = DURATION_BETWEEN(DATE('2024-03-01'), DATE('2024-02-28')) DAY TO SECOND  RETURN x;                         | 'P-2D'        | 月末日期计算  |
      | LET x = DURATION_BETWEEN(DATETIME('2024-10-10T15:30:45'),DATETIME('2023-11-11T08:15:20')) DAY TO SECOND RETURN x; | 'PT16H44M35S' | 仅时间差计算  |
      | LET x = DURATION_BETWEEN(null, DATE('2023-11-11')) DAY TO SECOND RETURN x                                         | null          | 空值      |

  Scenario Outline: DURATION_BETWEEN--DAY TO SECOND 异常处理
    When executing queries:
       """
       <GQL>
       """
    Then the error should be contain:
       """
       <error>
       """
    Examples:
      | GQL                                                                                      | error                                                   | 备注       |
      | LET x = DURATION_BETWEEN(DATE('2024-13-45'), DATE('2023-11-11')) DAY TO SECOND RETURN x; | Invalid value for MonthOfYear (valid values 1 - 12): 13 | 无效日期格式   |
      | LET x = DURATION_BETWEEN(DATE('2024-10-10'), DATE('2023-11-11')) WEEK TO DAY RETURN x;   | Invalid input 'WEEK'                                    | 不支持的精度单位 |


