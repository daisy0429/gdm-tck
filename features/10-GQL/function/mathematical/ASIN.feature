#encoding: utf-8
#参数取值范围:−1,1（参数值超出此范围将返回 NaN 或触发错误）。
#有效数据类型:浮点数（Float）、允许 NULL 值（返回 NULL）。
#说明:返回以弧度为单位的反正弦值，结果范围为 −π/2,π/2−π/2,π/2。
# fixme 特殊值处理：输入值超出支持范围或为特殊值（如 null、NaN、Infinity）。

Feature: ASIN反正弦值

  Scenario Outline: ASIN-正常计算
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x   |
      | <a> |
    Examples:
      | GQL | a |
      | let x = ASIN(0) return x; | 0 |
      | let x = ASIN(1) return x; | 1.5707963267948966 |
      | let x = ASIN(-1) return x; | -1.5707963267948966 |
      | let x = ASIN(0.5) return x; | 0.5235987755982989 |
      | let x = ASIN(-0.5) return x; | -0.5235987755982989 |
      | let x = ASIN(0.9999999999) return x; | 1.5707821846586874 |
      | let x = ASIN(-0.9999999999) return x; | -1.5707821846586874 |
      | let x = ASIN(1.1) return x; | NaN |
      | let x = ASIN(-1.1) return x; | NaN |
      | let x = ASIN(NULL) return x; | null |
      | return ASIN(NaN) as x; | NaN |
      | return ASIN(Infinity) as x; | NaN |
      | return ASIN(-Infinity) as x; | NaN |

  Scenario Outline: ASIN-异常参数
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
      | let x = ASIN("abc"); | Type mismatch: expected Float but was String |
      | return ASIN(); | Insufficient parameters for function 'asin' |
      | let x = ASIN(1e309) return x; | floating point number is too large |
      | let x = ASIN(3.14, 2.71) return x; | Too many parameters for function |
