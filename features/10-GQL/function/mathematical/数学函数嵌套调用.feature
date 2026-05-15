Feature:数学函数嵌套调用场景

  Scenario Outline: 数学函数部分嵌套调用-bug5498数学函数参数是表达式而非直接值时，报错interface conversion error,bug5496
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                                     | a                  | 备注               |
      | let x = FLOOR(DEGREES(2.2/2)) return x; | 63                 | 嵌套调用 DEGREES     |
      | let x = DEGREES(FLOOR(3.14)) return x;  | 171.88733853924697 | 嵌套调用 FLOOR       |
      | let x = LOG(FLOOR(3.14),2) return x;    | 0.6309297535714575 | 嵌套调用 FLOOR       |
      | let x = LOG10(LOG(100,100)) return x;   | 0                  | 嵌套调用 LOG 和 LOG10 |

  Scenario Outline: SQRT-嵌套函数调用
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                                 | a                  | 备注               |
      | let x = SQRT(FLOOR(3.14)) return x; | 1.7320508075688772 | 嵌套调用 FLOOR，计算平方根 |
      | let x = SQRT(ABS(-4)) return x;     | 2                  | 嵌套调用 ABS，计算平方根   |

  Scenario Outline: TAN-动态表达式
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                                | a                  | 备注              |
      | let x = TAN(PI()/3) return x;      | 1.7320508075688767 | 动态计算 π/3 的正切值   |
      | let x = TAN(RADIANS(45)) return x; | 1                  | 嵌套调用 RADIANS 函数 |
