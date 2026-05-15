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
      | GQL                                 | a      | 备注             |
      | let x = FLOOR(0) return x;          | 0      | 0 的向下取整为 0     |
      | let x = FLOOR(3.14) return x;       | 3      | 正浮点数向下取整       |
      | let x = FLOOR(-3.14) return x;      | -4     | 负浮点数向下取整       |
      | let x = FLOOR(1.9999) return x;     | 1      | 小数部分接近 1 的值取整  |
      | let x = FLOOR(-1.0001) return x;    | -2     | 小数部分接近 -1 的值取整 |
      | let x = FLOOR(123456.789) return x; | 123456 | 大数字测试          |
      | let x = FLOOR(NULL) return x;       | null   | NULL值处理        |
      | return FLOOR(PI() * 2) as x;        | 6      | 动态计算结果取整       |
      | return FLOOR(NaN) as x;             | NaN    | 处理NaN值         |
      | return FLOOR(Infinity) as x;        | Inf    | Infinity处理     |
      | return FLOOR(-Infinity) as x;       | -Inf   | Infinity处理     |


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
      | GQL                                 | error                                        | 备注             |
      | let x = FLOOR("abc");               | Type mismatch: expected Float but was String | 输入为字符串         |
      | return FLOOR();                     | Insufficient parameters for function 'FLOOR' | 缺少输入参数         |
      | let x = FLOOR(1e309) return x;      | floating point number is too large           | 输入浮点数过大，超出支持范围 |
      | let x = FLOOR(3.14, 2.71) return x; | Too many parameters for function                        | 多参数输入          |
      | let x = FLOOR([]) return x;         | Type mismatch: expected Float but was list   | bug5499        |




