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
      | GQL                                                        | a    | 备注                     |
      | let x =  Log(2, 8) return x;                               | 3    | 常规正数                   |
      | let x = log(10, 1000) return x;                            | 3    | 测试高精度结果                |
      | let x =  log(0.5, 0.25) return x;                          | 2    | 测试小数底数和小数结果            |
      | let x =  log(1, 1) return x;                               | 1    | 边界测试-以 1 为底数的对数结果始终为 0 |
      | let x =  log(1034.221,1034.221) return x;                  | 1    | 任何数的自身对数等于 1           |
      | let x = log(2.718281828459045, 7.38905609893065) return x; | 2    | 测试自然对数                 |
      | let x =  log(-10, 100) return x;                           | NaN  | 底数为负数时的处理-底数不能为负数      |
      | let x =  log(0, 100) return x;                             | NaN  | 底数为0时的处理-底数不能为0        |
      | let x =  log(10, -100) return x;                           | NaN  |                        |
      | let x = log(10, 1e308) return x;                           | 308  | 验证非常大的浮点数作为参数是否能处理     |
      | let x =  log(10, 0) return x;                              | -Inf |                        |
      | let x =  log(1, 100) return x;                             | Inf  |                        |

  Scenario Outline: commonLogarithm-LOG10-正常计算
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                                 | a                   | 备注                     |
      | let x = LOG10(10) return x;         | 1                   | 对数基准值 log10(10)=1      |
      | let x = LOG10(1) return x;          | 0                   | 对数的基准值 log10(1)=0      |
      | let x = LOG10(1000) return x;       | 3                   | 任意正数的 log10 计算         |
      | let x = LOG10(PI()) return x;       | 0.49714987269413385 | 动态计算 π 的 log10         |
      | let x = LOG10(0.01) return x;       | -2                  | 小于 1 的正数 log10 计算      |
      | let x = LOG10(123456.789) return x; | 5.091514977169271   | 大正数 log10 计算           |
      | let x = LOG10(NULL) return x;       | null                | NULL 值处理               |
      | let x = LOG10(1e-10) return x;      | -10                 | 非零极小正数 log10 计算        |
      | let x = LOG10(1e+10) return x;      | 10                  | 极大正数 log10 计算 。bug5497 |
      | let x = LOG10(0) return x;          | -Inf                | 输入为 0                  |
      | let x = LOG10(-1) return x;         | NaN                 | 输入为负数                  |

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
      | GQL                            | error                                           | 备注             |
      | let x = LOG10("abc");          | Type mismatch: expected Float but was String    | 输入为字符串         |
      | return LOG10();                | Insufficient parameters for function 'LOG10'    | 缺少输入参数         |
      | let x = LOG10(1e309) return x; | floating point number is too large              | 输入浮点数过大，超出支持范围 |
      | let x = LOG10(10, 2) return x; | Too many parameters for function                | 多参数输入          |
      | return LOG10([]);              | Type mismatch: expected Float but was List<Any> | 空集合处理          |


  Scenario Outline: LOG-正常计算-cypher
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL                          | a                   | 备注              |
      | RETURN LOG(2.71828) as x;    | 0.999999327347282   | 自然对数 e 的计算      |
      | RETURN LOG(1) as x;          | 0                   | 对数的基准值 log(1)=0 |
      | RETURN LOG(10) as x;         | 2.302585092994046   | 任意正数的对数计算       |
      | return LOG(0.5) as x;        | -0.6931471805599453 | 小于 1 的正数的对数     |
      | return LOG(PI()) as x;       | 1.1447298858494002  | 动态计算 π 的对数      |
      | return LOG(123456.789) as x; | 11.723646487185881  | 大正数的对数计算        |
      | return LOG(NULL) as x;       | null                | NULL 值处理        |
      | return LOG(1e-10) as x;      | -23.025850929940457 | 非零极小正数的对数       |
      | return LOG(1e+10) as x;      | 23.025850929940457            | 极大正数的对数         |
      | return LOG(0) as x;          | -Inf                |                 |
      | return LOG(-1) as x;         | NaN                 |                 |

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
      | GQL                | error                                           | 备注             |
      | return LOG("abc"); | Type mismatch: expected Float but was String    | 输入为字符串         |
      | return LOG();      | Insufficient parameters for function 'LOG'      | 缺少输入参数         |
      | return LOG(1e309); | floating point number is too large              | 输入浮点数过大，超出支持范围 |
      | return LOG([]);    | Type mismatch: expected Float but was List<Any> | 空集合处理          |
