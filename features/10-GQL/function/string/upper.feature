#encoding: utf-8
#作用: 将字符串中所有字母转换为大写。
#参数:
#string: 输入字符串，类型为 String。
#返回结果: 全部大写的字符串，类型为 String。


Feature: string-upper

  Scenario Outline: string-UPPER-正向用例-LET
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                         | result             | 备注                 |
      | LET x = UPPER('hello gql') RETURN x;        | 'HELLO GQL'        | 全部小写转大写            |
      | LET x = UPPER('Hello World') RETURN x;      | 'HELLO WORLD'      | 部分小写转大写            |
      | LET x = UPPER('HELLO WORLD') RETURN x;      | 'HELLO WORLD'      | 全部大写保持不变           |
      | LET x = UPPER('123 abc') RETURN x;          | '123 ABC'          | 字符串包含数字，数字不变       |
      | LET x = UPPER('') RETURN x;                 | ''                 | 空字符串               |
      | LET x = UPPER(NULL) RETURN x;               | null               | NULL 值             |
      | LET x = UPPER('中文 english') RETURN x;       | '中文 ENGLISH'       | 中英文混合，英文转大写        |
      | LET x = UPPER('!@#$%^&*()') RETURN x;       | '!@#$%^&*()'       | 非字母字符不变            |
      | LET x = UPPER('hello123') RETURN x;         | 'HELLO123'         | 混合数字和字母，字母转大写，数字不变 |
      | LET x = UPPER('a b c d') RETURN x;          | 'A B C D'          | 大小写混合字符串           |
      | LET x = UPPER('  leading space') RETURN x;  | '  LEADING SPACE'  | 带前导空格的字符串          |
      | LET x = UPPER('trailing space  ') RETURN x; | 'TRAILING SPACE  ' | 带尾随空格的字符串          |

  Scenario Outline: string-UPPER-正向用例-RETURN
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | result        |
      | <result> |
    Examples:
      | GQL                                         | result             | 备注                 |
      | RETURN UPPER('hello gql') as result;        | 'HELLO GQL'        | 全部小写转大写            |
      | RETURN UPPER('Hello World') as result;      | 'HELLO WORLD'      | 部分小写转大写            |
      | RETURN UPPER('HELLO WORLD') as result;      | 'HELLO WORLD'      | 全部大写保持不变           |
      | RETURN UPPER('123 abc') as result;          | '123 ABC'          | 字符串包含数字，数字不变       |
      | RETURN UPPER('') as result;                 | ''                 | 空字符串               |
      | RETURN UPPER(NULL) as result;               | null               | NULL 值             |
      | RETURN UPPER('中文 english') as result;      | '中文 ENGLISH'      | 中英文混合，英文转大写        |
      | RETURN UPPER('!@#$%^&*()') as result;       | '!@#$%^&*()'       | 非字母字符不变            |
      | RETURN UPPER('hello123') as result;         | 'HELLO123'         | 混合数字和字母，字母转大写，数字不变 |
      | RETURN UPPER('a b c d') as result;          | 'A B C D'          | 大小写混合字符串           |
      | RETURN UPPER('  leading space') as result;  | '  LEADING SPACE'  | 带前导空格的字符串          |
      | RETURN UPPER('trailing space  ') as result; | 'TRAILING SPACE  ' | 带尾随空格的字符串          |

  Scenario Outline: string-UPPER-异常用例
    When executing queries:
    """
    <GQL>
    """
    Then the error should be contain:
    """
    <error>
    """
    Examples:
      | GQL                           | error                                          | 备注         |
      | LET x = UPPER(123) RETURN x;  | Type mismatch: expected String but was Integer | 参数1-非字符串参数 |
      | LET x = UPPER(true) RETURN x; | Type mismatch: expected String but was Boolean | 参数1-布尔值参数  |



