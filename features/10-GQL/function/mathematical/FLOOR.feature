#encoding: utf-8
#参数取值范围: 任意实数（无上下限）。
#有效数据类型:浮点数（Float）、整数（Integer）、允许 NULL 值（返回 NULL）。
#说明: 返回小于或等于参数的最大整数。


Feature:FLOOR向下取整

  Scenario Outline: FLOOR-正常计算
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = FLOOR(0) return x; | 0 |
      | let x = FLOOR(3.14) return x; | 3 |
      | let x = FLOOR(-3.14) return x; | -4 |
      | let x = FLOOR(1.9999) return x; | 1 |
      | let x = FLOOR(-1.0001) return x; | -2 |
      | let x = FLOOR(123456.789) return x; | 123456 |
      | let x = FLOOR(NULL) return x; | null |
      | return FLOOR(PI() * 2) as x; | 6 |
      | return FLOOR(NaN) as x; | NaN |
      | return FLOOR(Infinity) as x; | Inf |
      | return FLOOR(-Infinity) as x; | -Inf |


  Scenario Outline: FLOOR-异常参数
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
      | let x = FLOOR("abc"); | Type mismatch: expected Float but was String |
      | return FLOOR(); | Insufficient parameters for function 'FLOOR' |
      | let x = FLOOR(1e309) return x; | floating point number is too large |
      | let x = FLOOR(3.14, 2.71) return x; | Too many parameters for function |
      | let x = FLOOR([]) return x; | Type mismatch: expected Float but was list |




