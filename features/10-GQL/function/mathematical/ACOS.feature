#encoding: utf-8
#ACOS (反余弦) 函数
#参数取值范围: [-1, 1]（参数值超出此范围将返回 NaN 或触发错误）。
#有效数据类型:浮点数（Float）允许 NULL 值（返回 NULL）。
#返回值域：返回以弧度为单位的反余弦值，结果范围为 [0, π]

Feature: ACOS反余弦函数

  Scenario Outline: ACOS-正常计算
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                                   | a                      |
      | let x = ACOS(1) return x;             | 0                      |
      | let x = ACOS(-1) return x;            | 3.141592653589793      |
      | let x = ACOS(0) return x;             | 1.5707963267948966     |
      | let x = ACOS(0.1) return x;           | 1.4706289056333368     |
      | let x = ACOS(0.9999999999) return x;  | 1.4142136209205347e-05 |
      | let x = ACOS(-0.9999999999) return x; | 3.141578511453584      |
      | let x = ACOS(1.1) return x;           | NaN                    |
      | let x = ACOS(-1.1) return x;          | NaN                    |
      | let x = ACOS(NULL) return x;          | null                   |
      | return ACOS(NaN) as x;                | NaN                    |
      | return ACOS(Infinity) as x;           | NaN                   |
      | return ACOS(-Infinity) as x;          | NaN                  |

  Scenario Outline: ACOS-异常参数
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
      | let x = ACOS("abc"); | Type mismatch: expected Float but was String |
      | return ACOS(); | Insufficient parameters for function 'acos' |
      | let x = ACOS(1e309) return x; | floating point number is too large |
      | let x = ACOS(3.14, 2.71) return x; | Too many parameters for function 'ACOS' |
