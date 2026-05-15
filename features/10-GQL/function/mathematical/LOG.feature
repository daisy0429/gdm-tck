#encoding: utf-8
#参数取值范围: 参数值需大于 0（非正数会返回 NaN 或触发错误）。
#有效数据类型:浮点数（Float）、整数（Integer）（会被隐式转换为 Float）。允许 NULL 值（返回 NULL）。
#说明: 返回参数的自然对数值，底数为 e。
#generalLogarithmFunction(generalLogarithmBase, generalLogarithmArgument) 是一个数学函数，它表示以 generalLogarithmBase 为底数，generalLogarithmArgument 为对数值的对数运算。
# 其意义在于计算出 generalLogarithmBase 的多少次幂等于 generalLogarithmArgument

Feature:Log计算对数

  Scenario Outline: generalLogarithmFunction-正常计算-gql-bug5496
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x =  Log(2, 8) return x; | 3 |
      | let x = log(10, 1000) return x; | 3 |
      | let x =  log(0.5, 0.25) return x; | 2 |
      | let x =  log(1, 1) return x; | 1 |
      | let x =  log(1034.221,1034.221) return x; | 1 |
      | let x = log(2.718281828459045, 7.38905609893065) return x; | 2 |
      | let x =  log(-10, 100) return x; | NaN |
      | let x =  log(0, 100) return x; | NaN |
      | let x =  log(10, -100) return x; | NaN |
      | let x = log(10, 1e308) return x; | 308 |
      | let x =  log(10, 0) return x; | -Inf |
      | let x =  log(1, 100) return x; | Inf |
  Scenario Outline: commonLogarithm-LOG10-正常计算
    When executing queries without error:
      """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = LOG10(10) return x; | 1 |
      | let x = LOG10(1) return x; | 0 |
      | let x = LOG10(1000) return x; | 3 |
      | let x = LOG10(PI()) return x; | 0.49714987269413385 |
      | let x = LOG10(0.01) return x; | -2 |
      | let x = LOG10(123456.789) return x; | 5.091514977169271 |
      | let x = LOG10(NULL) return x; | null |
      | let x = LOG10(1e-10) return x; | -10 |
      | let x = LOG10(1e+10) return x; | 10 |
      | let x = LOG10(0) return x; | -Inf |
      | let x = LOG10(-1) return x; | NaN |

  Scenario Outline: commonLogarithm-LOG10-异常参数
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
      | let x = LOG10("abc"); | Type mismatch: expected Float but was String |
      | return LOG10(); | Insufficient parameters for function 'LOG10' |
      | let x = LOG10(1e309) return x; | floating point number is too large |
      | let x = LOG10(10, 2) return x; | Too many parameters for function |
      | return LOG10([]); | Type mismatch: expected Float but was List<Any> |


  Scenario Outline: LOG-正常计算-cypher
    When executing queries without error:
      """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | RETURN LOG(2.71828) as x; | 0.999999327347282 |
      | RETURN LOG(1) as x; | 0 |
      | RETURN LOG(10) as x; | 2.302585092994046 |
      | return LOG(0.5) as x; | -0.6931471805599453 |
      | return LOG(PI()) as x; | 1.1447298858494002 |
      | return LOG(123456.789) as x; | 11.723646487185881 |
      | return LOG(NULL) as x; | null |
      | return LOG(1e-10) as x; | -23.025850929940457 |
      | return LOG(1e+10) as x; | 23.025850929940457 |
      | return LOG(0) as x; | -Inf |
      | return LOG(-1) as x; | NaN |
  Scenario Outline: LOG-异常参数
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
      | return LOG("abc"); | Type mismatch: expected Float but was String |
      | return LOG(); | Insufficient parameters for function 'LOG' |
      | return LOG(1e309); | floating point number is too large |
      | return LOG([]); | Type mismatch: expected Float but was List<Any> |
