#参数取值范围:参数值必须为非负数（≥ 0）。（负数输入将返回 NaN 或触发错误）。
#有效数据类型:浮点数（Float）、整数（Integer）、（会被隐式转换为 Float）。允许 NULL 值（返回 NULL）。
#说明:返回参数的平方根。

Feature:SQRT计算平方根

  Scenario Outline: SQRT-正常计算
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                          | a                  | 备注         |
      | let x = SQRT(0) return x;    | 0                  | 0 的平方根     |
      | let x = SQRT(1) return x;    | 1                  | 1 的平方根     |
      | let x = SQRT(4) return x;    | 2                  | 完全平方数的平方根  |
      | let x = SQRT(2) return x;    | 1.4142135623730951 | 非完全平方数的平方根 |
      | let x = SQRT(NULL) return x; | null               | NULL 值处理   |


