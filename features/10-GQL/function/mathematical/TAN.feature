#参数取值范围:任意实数，但不能为 π/2 + k·π（k 为整数），这些点是正切函数的奇点。（在奇点处可能返回 Infinity 或触发错误）。
#有效数据类型:浮点数（Float）、整数（Integer）、（会被隐式转换为 Float）。允许 NULL 值（返回 NULL）。
#说明:返回参数的正切值。

Feature:TAN计算正切值

  Scenario Outline: TAN-正常计算
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                            | a                      | 备注                          |
      | let x = TAN(0) return x;       | 0                      | TAN(0) = 0                  |
      | let x = TAN(22) return x;      | 0.00885165604168446    |                             |
      | let x = TAN(PI()/4) return x;  | 1                      | TAN(π/4) = 1                |
      | let x = TAN(-PI()/4) return x; | -1                     | TAN(-π/4) = -1              |
      | let x = TAN(NULL) return x;    | null                   | NULL 值处理                    |
      | let x = TAN(PI()/2) return x;  | 1.6331239353195392e+16 | 正切函数在 π/2 时无定义，理论上返回一个无穷大的值 |

  Scenario Outline: TAN-异常参数
    When executing queries:
  """
  <GQL>
  """
    Then the error should be contain:
  """
  <error>
  """
    Examples:
      | GQL                 | error                                        | 备注     |
      | let x = TAN("abc"); | Type mismatch: expected Float but was String | 输入为字符串 |
      | return TAN();       | Insufficient parameters for function 'TAN'   | 缺少输入参数 |


