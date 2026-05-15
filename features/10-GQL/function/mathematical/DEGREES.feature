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
      | GQL                                     | a                 | 备注                       |
      | let x = DEGREES(0) return x;            | 0                 | 0 弧度 = 0 度               |
      | return DEGREES(PI()/2) as x;            | 90                | 动态计算。π/2 弧度 = 90 度       |
      | return DEGREES(PI()) as x;              | 180               | 动态计算。π 弧度 = 180 度        |
      | return DEGREES(-PI()) as x;             | -180              | 动态计算。负弧度处理               |
      | return DEGREES(2 * PI()) as x;           | 360               | 动态计算。一个完整周期 (2π) = 360 度 |
      | let x = DEGREES(1.5707963268) return x; | 90.00000000029242 | 浮点数精度测试                  |
      | let x = DEGREES(NULL) return x;         | null              | NULL值处理                  |
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
      | GQL                                   | error                                          | 备注             |
      | let x = DEGREES("abc");               | Type mismatch: expected Float but was String   | 输入为字符串         |
      | return DEGREES();                     | Insufficient parameters for function 'DEGREES' | 缺少输入参数         |
      | let x = DEGREES(1e309) return x;      | floating point number is too large             | 输入浮点数过大，超出支持范围 |
      | let x = DEGREES(3.14, 2.71) return x; | Too many parameters for function                            | 多参数输入          |
      | let x = DEGREES([]) return x;         | Type mismatch: expected Float but was list     | bug5499        |



