#encoding: utf-8
Feature: DATETIME


  Scenario: castToTemporal-positive-cases--手工验证查询当前时间类
    When executing queries without error:
       """
       LET x = CURRENT_TIME RETURN x;
       LET x = CURRENT_TIMESTAMP RETURN x;
       LET x = DATE() RETURN x;
       """

  Scenario Outline: castToTemporal-positive-cases-DATETIME
    When executing queries without error:
       """
       <GQL>
       """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                     | result                        | 备注       |
      | LET x = DATETIME('2012-01-01T10:12:11') RETURN x        | '2012-01-01T10:12:11Z'        | 基本日期时间格式 |
      | LET x = DATETIME('2012-01-01T10:12:11+08:00') RETURN x  | '2012-01-01T10:12:11+08:00'   | 带时区信息    |
      | LET x = DATETIME('2012-01-01T10:12:11Z') RETURN x       | '2012-01-01T10:12:11Z'        | UTC 时间   |
      | LET x = DATETIME('2012-02-29T10:12:11') RETURN x        | '2012-02-29T10:12:11Z'        | 闰年日期     |
      | LET x = DATETIME('2012-01-01T00:00:00') RETURN x        | '2012-01-01T00:00Z'           | 最小时间值    |
      | LET x = DATETIME('2012-01-01T23:59:59') RETURN x        | '2012-01-01T23:59:59Z'        | 最大时间值    |
      | LET x = DATETIME('20120101T101211') RETURN x            | '2012-01-01T10:12:11Z'        | 不带分隔符    |
      | LET x = DATETIME('2012-01-01T10:12:11.123') RETURN x    | '2012-01-01T10:12:11.123Z'    | 带毫秒精度    |
      | LET x = DATETIME('2012-01-01T10:12:11.123456') RETURN x | '2012-01-01T10:12:11.123456Z' | 带微秒精度    |
      | LET x = DATETIME('2012/01/01 10:12:11') RETURN x        | '2012-01-01T10:12:11Z'        | 混合格式     |

  Scenario Outline: castToTemporal-negative-cases-DATETIME
    When executing queries:
       """
       <GQL>
       """
    Then the error should be contain:
       """
       <error>
       """
    Examples:
      | GQL                                              | error                                                   | 备注         |
      | LET x = DATETIME('2012-13-01T10:12:11') RETURN x | Invalid value for MonthOfYear (valid values 1 - 12): 13 | 无效月份       |
      | LET x = DATETIME('2011-02-29T10:12:11') RETURN x | invalid date 'February 29' as '2011' is not a leap year | 无效日期 (非闰年) |
      | LET x = DATETIME('2012-01-01T24:12:11') RETURN x | Invalid value for HourOfDay (valid values 0 - 23): 24   | 无效时间       |


