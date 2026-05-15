#encoding: utf-8
#参数取值范围:任意实数（输入值为弧度制）。
#有效数据类型:浮点数（Float）、整数（Integer）、（会被隐式转换为 Float）。允许 NULL 值（返回 NULL）。
#说明:返回参数的正弦值，结果范围为 −1,1

Feature:SIN正弦值

  Scenario Outline: SIN-正常计算
    When executing queries without error:
      """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = SIN(0) return x; | 0 |
      | let x = SIN(30) return x; | -0.9880316240928618 |
      | let x = SIN(PI()/2) return x; | 1 |
      | let x = SIN(PI()) return x; | 1.2246467991473515e-16 |
      | let x = SIN(-PI()/2) return x; | -1 |
      | let x = SIN(NULL) return x; | null |
#      | let x = SIN([]) return x;      | expected Float but was List<Any> | bug5499        |



