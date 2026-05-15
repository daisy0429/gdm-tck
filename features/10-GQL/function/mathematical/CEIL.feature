#encoding: utf-8
#参数取值范围: 任意实数（无上下限）。
#有效数据类型:浮点数（Float）/整数（Integer）/允许 NULL 值（返回 NULL）。
#说明: 返回大于或等于参数的最小整数。

Feature:CEIL/CEILING向上取整

  Scenario Outline: CEIL-正常计算
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = CEIL(0) return x; | 0 |
      | let x = CEIL(1) return x; | 1 |
      | let x = CEIL(-1) return x; | -1 |
      | let x = CEIL(0.5) return x; | 1 |
      | let x = CEIL(-0.5) return x; | -0 |
      | let x = CEIL(1.999) return x; | 2 |
      | let x = CEIL(-1.999) return x; | -1 |
      | let x = CEIL(12345.6789) return x; | 12346 |
      | let x = CEIL(NULL) return x; | null |
      | return CEIL(NaN) as x; | NaN |
      | return CEIL(Infinity) as x; | Inf |
      | return CEIL(-Infinity) as x; | -Inf |


  Scenario Outline: CEILING-正常计算
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = CEILING(0) return x; | 0 |
      | let x = CEILING(1) return x; | 1 |
      | let x = CEILING(-1) return x; | -1 |
      | let x = CEILING(0.5) return x; | 1 |
      | let x = CEILING(-0.5) return x; | -0 |
      | let x = CEILING(1.999) return x; | 2 |
      | let x = CEILING(-1.999) return x; | -1 |
      | let x = CEILING(12345.6789) return x; | 12346 |
      | let x = CEILING(NULL) return x; | null |
#      | let x = CEILING(NaN) return x;        | NaN       | 处理NaN值     |
#      | let x = CEILING(Infinity) return x;   | Infinity  | Infinity处理 |
#      | let x = CEILING(-Infinity) return x;  | -Infinity | Infinity处理 |


  Scenario Outline: CEIL-异常参数
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
      | let x = CEIL("abc"); | Type mismatch: expected Float but was String |
      | return CEIL(); | Insufficient parameters for function 'CEIL' |
      | let x = CEIL(1e309) return x; | floating point number is too large |
      | let x = CEIL(3.14, 2.71) return x; | Too many parameters for function |
