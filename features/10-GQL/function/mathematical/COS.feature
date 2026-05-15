#encoding: utf-8
#参数取值范围: 任意实数（输入值为弧度制）。
#有效数据类型:浮点数（Float）/整数（Integer）（会被隐式转换为 Float）。允许 NULL 值（返回 NULL）。
#说明: 返回参数的余弦值，范围为 [-1, 1]。

Feature:COS余弦值

  Scenario Outline: COS-正常计算-bug5495数学函数PI常量作为输入时，处理存疑
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                                    | a                     | 备注           |
      | let x = COS(0) return x;               | 1                     | COS(0) = 1   |
      | WITH PI() AS PI RETURN COS(PI/2) as x  | 6.123233995736757e-17 | COS(π/2) ≈ 0 |
      | WITH PI() AS PI RETURN COS(PI) as x    | -1                    | COS(π) = -1  |
      | WITH PI() AS PI RETURN COS(-PI/2) as x | 6.123233995736757e-17 | 负角度          |
      | WITH PI() AS PI RETURN COS(PI*2) as x  | 1                     | 一个完整周期 (2π)  |
      | let x = COS(3.14) return x;            | -0.9999987317275396   | 近似π          |
      | let x = COS(123.456) return x;         | -0.5947139710921575   | 大角度测试        |
      | let x = COS(NULL) return x;            | null                  | NULL值处理      |
#      | let x = COS(NaN) return x;           | NaN                   | NaN值处理            |
#      | let x = COS(Infinity) return x;      | NaN                   | Infinity处理         |


  Scenario Outline: COS-异常参数
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                               | error                                        | 备注             |
      | let x = COS("abc");               | Type mismatch: expected Float but was String | 输入为字符串         |
      | return COS();                     | Insufficient parameters for function 'COS'   | 缺少输入参数         |
      | let x = COS(1e309) return x;      | floating point number is too large           | 输入浮点数过大，超出支持范围 |
      | let x = COS(3.14, 2.71) return x; | Too many parameters for function             | 多参数输入          |


