#encoding: utf-8
#参数取值范围:任意实数（无上下限）。
#有效数据类型:浮点数（Float）、整数（Integer）、（会被隐式转换为 Float）。允许 NULL 值（返回 NULL）。
#说明:将角度制参数转换为弧度制，公式为 x * (π / 180)。
#

Feature:RADIANS将角度转换为弧度

  Scenario Outline: RADIANS-正常计算
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                               | a                   | 备注             |
      | let x = RADIANS(0) return x;      | 0                   | 0° 转换为弧度       |
      | let x = RADIANS(180) return x;    | 3.141592653589793   | 180° 转换为 π 弧度  |
      | let x = RADIANS(-90) return x;    | -1.5707963267948966 | -90° 转换为负弧度    |
      | let x = RADIANS(360) return x;    | 6.283185307179586   | 360° 转换为 2π 弧度 |
      | let x = RADIANS(123.45) return x; | 2.154608961587      | 任意正角度转换弧度      |
      | let x = RADIANS(NULL) return x;   | null                | NULL 值处理       |


  Scenario Outline: RADIANS-异常参数
    When executing queries:
  """
  <GQL>
  """
    Then the error should be contain:
  """
  <error>
  """
    Examples:
      | GQL                              | error                                          | 备注             |
      | let x = RADIANS("abc");          | Type mismatch: expected Float but was String   | 输入为字符串         |
      | return RADIANS();                | Insufficient parameters for function 'RADIANS' | 缺少输入参数         |
      | let x = RADIANS(1e309) return x; | floating point number is too large             | 输入浮点数过大，超出支持范围 |


