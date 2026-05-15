#encoding: utf-8
#ABS 函数返回给定数值的绝对值。
#bug5492-数学函数对NULL参数未进行兼容性处理，报错unsupported Eval in function
#bug5493-数学函数未支持Infinity常量作为输入
#bug5494-数学函数使用NaN作为输入时报错Variable `NaN` not defined.

Feature: ABS绝对值

  Scenario Outline: ABS-正常计算
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                               | result |
      | let x = ABS(10) return x;         | 10     |
      | let x = ABS(0) return x;          | 0      |
      | let x = ABS(-0.0000001) return x; | 1e-07  |
      | let x = ABS(0.0) return x;        | 0.0    |
      | let x = ABS(NULL) return x;       | null   |
      | return ABS(NaN) as x;             | NaN    |
      | return ABS(Infinity) as x;        | Inf    |
      | return ABS(-Infinity) as x;       | Inf    |

  Scenario Outline: ABS-异常参数
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
      | let x = ABS("-5") return x; | Type mismatch: expected Float or Integer but was String |
      | return ABS(); | Insufficient parameters for function 'abs' |
      | return ABS(1e309) | floating point number is too large |
      | let x = ABS(3.14, 2.71) return x; | Too many parameters for function 'abs' |
