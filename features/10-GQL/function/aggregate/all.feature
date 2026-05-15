#encoding: utf-8

# ALL对当前绑定的值（可能多行、多次出现）全部作为输入传递给聚合函数。换句话说，ALL 明确告诉系统不要做去重，而是用所有行的值来计算。
# MAX(m) → 等价于 MAX(ALL m)（ALL 是默认语义）.
Feature: all


  Scenario Outline: all-positive-cases
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                  | result | 备注 |
      | UNWIND RANGE (1,3) AS m LET x = MAX(ALL m) RETURN x; | 3      |    |
      | UNWIND RANGE (1,3) AS m LET x = MIN(ALL m) RETURN x; | 1      |    |

