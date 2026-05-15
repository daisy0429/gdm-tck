#encoding: utf-8
#参数取值范围: 任意实数（无上下限）。
#有效数据类型:浮点数（Float）允许 NULL 值（返回 NULL）。
#说明: 返回以弧度为单位的反正切值，结果范围为 (-π/2, π/2)。

Feature:ATAN反正切值

  Scenario Outline: ATAN-正常计算
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                              | a                   | 备注         |
      | let x = ATAN(0) return x;        | 0                   | 正常值        |
      | let x = ATAN(1) return x;        | 0.7853981633974483  | π/4        |
      | let x = ATAN(-1) return x;       | -0.7853981633974483 | -π/4       |
      | let x = ATAN(0.5) return x;      | 0.4636476090008061  | 正常值        |
      | let x = ATAN(-0.5) return x;     | -0.4636476090008061 | 正常值        |
      | let x = ATAN(1000000) return x;  | 1.5707953267948966  | 接近π/2      |
      | let x = ATAN(-1000000) return x; | -1.5707953267948966 | 接近-π/2     |
      | let x = ATAN(NULL) return x;     | null                | 处理NULL值    |
      | return ATAN(NaN) as x;           | NaN                 | 处理NaN值     |
      | return ATAN(Infinity) as x;      | 1.5707963267948966  | Infinity处理 |
      | return ATAN(-Infinity) as x;     | -1.5707963267948966 | Infinity处理 |

  Scenario Outline: ATAN-异常参数
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                                | error                                        | 备注             |
      | let x = ATAN("abc");               | Type mismatch: expected Float but was String | 输入为字符串         |
      | return ATAN();                     | Insufficient parameters for function 'atan'  | 缺少输入参数         |
      | let x = ATAN(1e309) return x;      | floating point number is too large           | 输入浮点数过大，超出支持范围 |
      | let x = ATAN(3.14, 2.71) return x; | Too many parameters for function             | 多参数输入          |