#encoding: utf-8

Feature: range

  Scenario: range 正向 - 默认步长（正向）
    When executing queries without error:
      """
  RETURN range(1, 5) AS x;
  """
    Then the result should be, in any order:
      | x              |
      | [1, 2, 3, 4, 5] |

  Scenario: range 正向 - 指定正步长
    When executing queries without error:
      """
  RETURN range(0, 10, 2) AS x;
  """
    Then the result should be, in any order:
      | x             |
      | [0, 2, 4, 6, 8, 10] |

  Scenario: range 正向 - 递减步长
    When executing queries without error:
      """
  RETURN range(5, 1, -1) AS x;
  """
    Then the result should be, in any order:
      | x           |
      | [5, 4, 3, 2, 1] |

  Scenario: range 正向 - 单值区间
    When executing queries without error:
      """
  RETURN range(3, 3) AS x;
  """
    Then the result should be, in any order:
      | x    |
      | [3]  |

  Scenario: range 正向 - 空区间（正向步长但起点 > 终点）
    When executing queries without error:
      """
  RETURN range(10, 5, 1) AS x;
  """
    Then the result should be, in any order:
      | x |
      | [] |

  Scenario: range 正向 - 空区间（负向步长但起点 < 终点）
    When executing queries without error:
      """
  RETURN range(1, 10, -1) AS x;
  """
    Then the result should be, in any order:
      | x |
      | [] |

#  Scenario: range 负向 - 步长为 0-PASS
#    When executing queries:
#  """
#  RETURN range(1, 5, 0) AS x;
#  """
#    Then the error should be contain:
#    """
#    Step argument to 'range()' cannot be zero
#    """

  Scenario: range 负向 - 步长为 NULL-bug7448
    When executing queries:
      """
  RETURN range(1, 5, NULL) AS x;
  """
    #neo4j: Expected a numeric value but got: NO_VALUE
    Then the error should be contain:
      """
    Step argument to 'range()' isn't Integer
    """

  Scenario: range 负向 - 参数个数超过 3 个
    When executing queries:
      """
  RETURN range(1, 5, 1, 1) AS x;
  """
    Then the error should be contain:
      """
    Too many parameters for function 'range'
    """

  Scenario: range 负向 - 非整数参数
    When executing queries:
      """
  RETURN range("1", 5) AS x;
  """
    Then the error should be contain:
      """
    expected Integer but was String
    """

  Scenario: range 负向 - 缺少必需参数
    When executing queries:
      """
  RETURN range(1) AS x;
  """
    Then the error should be contain:
      """
    Insufficient parameters for function 'range'
    """

