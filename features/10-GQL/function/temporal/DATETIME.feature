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
      | GQL | result |
      | LET x = DATETIME('2012-01-01T10:12:11') RETURN x | '2012-01-01T10:12:11Z' |
      | LET x = DATETIME('2012-01-01T10:12:11+08:00') RETURN x | '2012-01-01T10:12:11+08:00' |
      | LET x = DATETIME('2012-01-01T10:12:11Z') RETURN x | '2012-01-01T10:12:11Z' |
      | LET x = DATETIME('2012-02-29T10:12:11') RETURN x | '2012-02-29T10:12:11Z' |
      | LET x = DATETIME('2012-01-01T00:00:00') RETURN x | '2012-01-01T00:00Z' |
      | LET x = DATETIME('2012-01-01T23:59:59') RETURN x | '2012-01-01T23:59:59Z' |
      | LET x = DATETIME('20120101T101211') RETURN x | '2012-01-01T10:12:11Z' |
      | LET x = DATETIME('2012-01-01T10:12:11.123') RETURN x | '2012-01-01T10:12:11.123Z' |
      | LET x = DATETIME('2012-01-01T10:12:11.123456') RETURN x | '2012-01-01T10:12:11.123456Z' |
      | LET x = DATETIME('2012/01/01 10:12:11') RETURN x | '2012-01-01T10:12:11Z' |

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
      | GQL | error |
      | LET x = DATETIME('2012-13-01T10:12:11') RETURN x | Invalid value for MonthOfYear (valid values 1 - 12): 13 |
      | LET x = DATETIME('2011-02-29T10:12:11') RETURN x | invalid date 'February 29' as '2011' is not a leap year |
      | LET x = DATETIME('2012-01-01T24:12:11') RETURN x | Invalid value for HourOfDay (valid values 0 - 23): 24 |


