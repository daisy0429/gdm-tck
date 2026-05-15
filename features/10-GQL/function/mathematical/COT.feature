#encoding: utf-8
#参数取值范围: 任意实数，但不能为 0（参数为 0 时可能返回 Infinity 或触发错误）。
#有效数据类型:浮点数（Float）/整数（Integer）（会被隐式转换为 Float）。允许 NULL 值（返回 NULL）。
#说明: 返回参数的余切值，计算公式为 1 / tan(x)。
#
Feature:COT余切值

  Scenario Outline: COT-正常计算
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | return COT(PI()/4) as x; | 1 |
      | return COT(PI()/3) as x; | 0.577350269189626 |
      | return COT(-PI()/4) as x; | -1 |
      | return COT(PI()/2) as x; | 6.123233995736757e-17 |
      | let x = COT(1e-10) return x; | 1e10 |
      | let x = COT(123.456) return x; | 0.7397516203879331 |
      | let x = COT(NULL) return x; | null |
#      | let x = COT(NaN) return x;      | NaN                | NaN值处理       |
#      | let x = COT(Infinity) return x; | NaN                | Infinity处理   |
      | let x = COT(0) return x;       | Inf  |

  Scenario Outline: COT-异常参数
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
      | let x = COT("abc"); | Type mismatch: expected Float but was String |
      | return COT(); | Insufficient parameters for function 'COT' |
      | let x = COT(1e309) return x; | floating point number is too large |
      | let x = COT(3.14, 2.71) return x; | Too many parameters for function |


