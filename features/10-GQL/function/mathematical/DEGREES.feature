#encoding: utf-8
#参数取值范围: 任意实数（无上下限）。
#有效数据类型:浮点数（Float）/整数（Integer）（会被隐式转换为 Float）。允许 NULL 值（返回 NULL）。
#说明: 将弧度制参数转换为角度制，公式为 x * (180 / π)。

Feature:DEGREES弧度转换为角度

  Scenario Outline: DEGREES-正常计算
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = DEGREES(0) return x; | 0 |
      | return DEGREES(PI()/2) as x; | 90 |
      | return DEGREES(PI()) as x; | 180 |
      | return DEGREES(-PI()) as x; | -180 |
      | return DEGREES(2 * PI()) as x; | 360 |
      | let x = DEGREES(1.5707963268) return x; | 90.00000000029242 |
      | let x = DEGREES(NULL) return x; | null |
#      | let x = DEGREES(NaN) return x;          | NaN               | NaN值处理                   |
#      | let x = DEGREES(Infinity) return x;     | NaN               | Infinity处理               |


  Scenario Outline: DEGREES-异常参数
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
      | let x = DEGREES("abc"); | Type mismatch: expected Float but was String |
      | return DEGREES(); | Insufficient parameters for function 'DEGREES' |
      | let x = DEGREES(1e309) return x; | floating point number is too large |
      | let x = DEGREES(3.14, 2.71) return x; | Too many parameters for function |
      | let x = DEGREES([]) return x; | Type mismatch: expected Float but was list |



