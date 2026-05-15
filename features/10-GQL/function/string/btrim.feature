#encoding: utf-8
#作用: 删除字符串首尾指定字符。
#参数:
#string: 输入字符串，类型为 String。
#characters: 要删除的字符集合，类型为 String，默认为空格。
#返回结果: 删除首尾指定字符后的字符串，类型为 String。

Feature: string-btrim

  Scenario Outline: string-BTRIM-移除字符串两端的指定字符
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                           | result                  | 备注            |
      | LET x = BTRIM(' Hello GQL ', ' ') RETURN x ;                  | 'Hello GQL'             | 参数2空串         |
      | LET x = BTRIM(' Hello World ', 'Hello ') RETURN x;            | 'World'                 |               |
      | LET x = BTRIM('Hello', 'Hello ') RETURN x;                    | ''                      |               |
      | LET x = BTRIM('abcdef Hello World abcdef', 'fecd') RETURN x;  | 'abcdef Hello World ab' | 右侧匹配          |
      | LET x = BTRIM(' ', ' ') RETURN x;                             | ''                      | 参数1和参数2均空串    |
      | LET x = BTRIM(' Hello World ', 'Hello AA') RETURN x;          | 'World'                 | 部分匹配          |
      | LET x = BTRIM(' Hello World ', ' no') RETURN x;               | 'Hello World'           | 修剪字符与目标字符串不匹配 |
      | LET x = BTRIM(' Hello World ', ' Hello World test') RETURN x; | ''                      | 超出匹配          |
      | LET x = BTRIM('!@#$%^& Hello GQL !!!', '!@#$%^& ') RETURN x;  | 'Hello GQL'             |               |
      | LET x = BTRIM('!@#$%^&HelloGQL !!!', '!@#$%^& ') RETURN x;    | 'HelloGQL'              |               |
      | LET x = BTRIM('!@#$%^&HelloGQL!!!', '!@#$%^&') RETURN x;      | 'HelloGQL'              |               |
      | LET x = BTRIM('中文 Hello GQL 中文', '中文 ') RETURN x;             | 'Hello GQL'             | 中文            |

  Scenario: size(list)
    Given an empty graph
    And having executed:
      """
      LET x = BTRIM('\tHello GQL\n', '\t\n ') RETURN x;
      """
    Then the result should be, in any order:
      | x           |
      | 'Hello GQL' |

  Scenario Outline: string-BTRIM-移除字符串两端的空格
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                      | result        |
      | let x = BTRIM(' Hello World ') return x; | 'Hello World' |
      | let x = BTRIM('a') return x;             | 'a'           |
      | let x = BTRIM('') return x;              | ''            |

  Scenario Outline: string-BTRIM-异常参数
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                               | error                                          | 备注        |
      | LET x = BTRIM('22', 2) RETURN x ; | Type mismatch: expected String but was Integer | 参数2-类型不匹配 |
      | let x = LEFT(22, '2') return x;   | Type mismatch: expected String but was Integer | 参数1-类型不匹配 |
