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
      | GQL | a |
      | let x = FLOOR(DEGREES(2.2/2)) return x; | 63 |
      | let x = DEGREES(FLOOR(3.14)) return x; | 171.88733853924697 |
      | let x = LOG(FLOOR(3.14),2) return x; | 0.6309297535714575 |
      | let x = LOG10(LOG(100,100)) return x; | 0 |

  Scenario Outline: SQRT-嵌套函数调用
    When executing queries without error:
      """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = SQRT(FLOOR(3.14)) return x; | 1.7320508075688772 |
      | let x = SQRT(ABS(-4)) return x; | 2 |

  Scenario Outline: TAN-动态表达式
    When executing queries without error:
      """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = TAN(PI()/3) return x; | 1.7320508075688767 |
      | let x = TAN(RADIANS(45)) return x; | 1 |
