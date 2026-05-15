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
      | GQL | result |
      | LET x = DURATION_BETWEEN(DATE('2024-10-10'),DATE('2023-11-11')) RETURN x; | 'P-10M-29D' |
      | LET x = DURATION_BETWEEN(DATE('2024-10-10'),DATE('2024-11-11')) RETURN x; | 'P1M1D' |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), DATE('2023-01-01')) RETURN x; | 'P-1Y' |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), DATE('2023-12-31')) RETURN x; | 'P-1D' |
      | LET x = DURATION_BETWEEN(DATE('2024-06-01'), DATE('2024-01-01')) RETURN x; | 'P-5M' |
      | LET x = DURATION_BETWEEN(DATE('2024-03-15'), DATE('2024-03-10')) RETURN x; | 'P-5D' |
      | LET x = DURATION_BETWEEN(DATE('2024-03-10'), DATE('2024-03-15')) RETURN x; | 'P5D' |
      | LET x = DURATION_BETWEEN(DATETIME('2024-03-10T12:00:00'), DATETIME('2024-03-10T11:00:00')) RETURN x; | 'PT-1H' |
      | LET x = DURATION_BETWEEN(DATETIME('2024-03-10T12:00:00'), DATETIME('2024-03-10T12:30:00')) RETURN x; | 'PT30M' |
      | LET x = DURATION_BETWEEN(DATETIME('2024-03-10T12:00:00'), DATETIME('2024-03-10T12:00:05')) RETURN x; | 'PT5S' |
      | LET x = DURATION_BETWEEN(DATETIME('2024-01-01T00:00:00'), DATETIME('2023-01-01T00:00:00')) RETURN x; | 'P-1Y' |
      | LET x = DURATION_BETWEEN(DATETIME('2024-01-01T10:00:00'), DATETIME('2023-12-31T23:00:00')) RETURN x; | 'PT-11H' |
      | LET x = DURATION_BETWEEN(DATE('2024-02-29'), DATE('2020-02-29')) RETURN x; | 'P-4Y' |
      | LET x = DURATION_BETWEEN(DATETIME('2024-03-01T00:00:00'), DATETIME('2024-02-28T23:59:59')) RETURN x; | 'P-1DT-1S' |
      | LET x = DURATION_BETWEEN(NULL, DATE('2024-01-01')) RETURN x; | null |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), NULL) RETURN x; | null |
      | return DURATION.BETWEEN(DATE('2024-01-01'), TIME('12:00:00')) as x; | 'PT12H' |

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
      | GQL | error |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), '2024-01-01') RETURN x; | unsupported value type in ConvertToTime |
      | LET x = DURATION_BETWEEN(DATE('invalid-date'), DATE('2024-01-01')) RETURN x; | Text cannot be parsed to a Date |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01')) RETURN x; | unsupported value type in FunctionInvocation |
      | LET x = DURATION_BETWEEN() RETURN x; | unsupported value type in FunctionInvocation |
      | LET x = DURATION_BETWEEN(TRUE, DATE('2024-01-01')) RETURN x; | unsupported value type in ConvertToTime |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), [DATE('2023-01-01')]) RETURN x; | unsupported value type in ConvertToTime |
      | LET x = DURATION_BETWEEN(TIMESTAMP('2024-01-01T00:00:00Z'), TIMESTAMP('1999-12-31')) RETURN x; | parsing time "2024-01-01T00:00:00Z": extra text: "Z" |

  Scenario Outline: DURATION_BETWEEN--DAY TO SECOND
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | LET x = DURATION_BETWEEN(DATE('2024-10-10'), DATE('2023-11-11')) DAY TO SECOND RETURN x; | 'P-29D' |
      | LET x = DURATION_BETWEEN(DATE('2023-11-11'), DATE('2024-10-10')) DAY TO SECOND  RETURN x; | 'P29D' |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), DATE('2024-01-01')) DAY TO SECOND RETURN x; | 'PT0S' |
      | LET x = DURATION_BETWEEN(DATE('2024-03-01'), DATE('2023-02-28')) DAY TO SECOND RETURN x; | 'P-3D' |
      | LET x = DURATION_BETWEEN(DATE('2024-01-01'), DATE('2000-01-01')) DAY TO SECOND RETURN x; | 'PT0S' |
      | LET x = DURATION_BETWEEN(DATE('2024-03-01'), DATE('2024-02-28')) DAY TO SECOND  RETURN x; | 'P-2D' |
      | LET x = DURATION_BETWEEN(DATETIME('2024-10-10T15:30:45'),DATETIME('2023-11-11T08:15:20')) DAY TO SECOND RETURN x; | 'PT16H44M35S' |
      | LET x = DURATION_BETWEEN(null, DATE('2023-11-11')) DAY TO SECOND RETURN x | null |

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
      | GQL | error |
      | LET x = DURATION_BETWEEN(DATE('2024-13-45'), DATE('2023-11-11')) DAY TO SECOND RETURN x; | Invalid value for MonthOfYear (valid values 1 - 12): 13 |
      | LET x = DURATION_BETWEEN(DATE('2024-10-10'), DATE('2023-11-11')) WEEK TO DAY RETURN x; | Invalid input 'WEEK' |


