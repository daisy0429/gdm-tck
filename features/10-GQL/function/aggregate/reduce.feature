#encoding: utf-8

Feature: reduce

  Scenario: reduce-bug5529
    When executing queries without error:
    """
    WITH 3 AS a RETURN REDUCE(index = 0, x IN RANGE(1, a - 1) | index + 1) AS x;
    """
    Then the result should be, in any order:
      | x |
      | 2 |
    When executing queries without error:
    """
    RETURN REDUCE(index = 0, x IN RANGE(1, 2) | index + 1) AS x;
    """
    Then the result should be, in any order:
      | x |
      | 2 |

  Scenario: reduce 正向 - range 加法累加
    When executing queries without error:
  """
  WITH 3 AS a RETURN REDUCE(index = 0, x IN RANGE(1, a - 1) | index + 1) AS x;
  """
    Then the result should be, in any order:
      | x |
      | 2 |

  Scenario: reduce 正向 - 列表乘积
    When executing queries without error:
  """
  RETURN REDUCE(s = 1, x IN [2,3,4] | s * x) AS x;
  """
    Then the result should be, in any order:
      | x |
      | 24 |

  Scenario: reduce 正向 - 空列表返回初始值
    When executing queries without error:
  """
  RETURN REDUCE(s = 10, x IN [] | s + x) AS x;
  """
    Then the result should be, in any order:
      | x |
      | 10 |

  Scenario: reduce 正向 - 字符串拼接
    When executing queries without error:
  """
  RETURN REDUCE(r = "", x IN ["a", "b", "c"] | r + x) AS x;
  """
    Then the result should be, in any order:
      | x   |
      | 'abc' |

  Scenario: reduce 正向 - 1 到 100 求和
    When executing queries without error:
  """
  RETURN REDUCE(sum = 0, x IN RANGE(1, 100) | sum + x) AS x;
  """
    Then the result should be, in any order:
      | x    |
      | 5050 |

  Scenario: reduce 正向 - 所有元素小于5（布尔累积)bug7446
    When executing queries without error:
  """
  RETURN REDUCE(flag = TRUE, x IN [1,2,3] | flag AND x < 5) AS x;
  """
    Then the result should be, in any order:
      | x    |
      | true |

  Scenario: reduce字符串加数字
    When executing queries without error:
  """
  RETURN REDUCE(s = "str", x IN [1,2] | s + x) AS x;
  """
    Then the result should be, in any order:
      | x    |
      | 'str12' |


  Scenario: reduce 负向 - IN 为 NULL
    When executing queries:
  """
  RETURN REDUCE(s = 1, x IN NULL | s + x) AS x;
  """
    Then the error should be contain:
    """
    unsupported type in ReduceFunction
    """

  Scenario: reduce 负向 - IN 不是集合-bug7449
    When executing queries:
  """
  RETURN REDUCE(s = 1, x IN 5 | s + x) AS x;
  """
    Then the error should be contain:
    """
    Type mismatch: expected List<Any> but was Integer
    """

  Scenario: reduce 负向 - 表达式不完整
    When executing queries:
  """
  RETURN REDUCE(s = 1, x IN [1,2,3] | s + ) AS x;
  """
    Then the error should be contain:
    """
    Invalid input
    """

  Scenario: reduce 负向 - 使用未定义变量
    When executing queries:
  """
  RETURN REDUCE(s = 1, x IN [1,2,3] | s + y) AS x;
  """
    Then the error should be contain:
    """
    Variable `y` not defined
    """



  Scenario: reduce 负向 - 表达式结尾非法
    When executing queries:
  """
  RETURN REDUCE(s = 0, x IN [1,2] | s + x +) AS x;
  """
    Then the error should be contain:
    """
   Invalid input
    """

  Scenario: reduce 负向 - 缺失初始值
    When executing queries:
  """
  RETURN REDUCE( , x IN [1,2,3] | x) AS x;
  """
    Then the error should be contain:
    """
    Invalid input
    """



