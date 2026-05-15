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
      | GQL | result |
      | LET x = UPPER('hello gql') RETURN x; | 'HELLO GQL' |
      | LET x = UPPER('Hello World') RETURN x; | 'HELLO WORLD' |
      | LET x = UPPER('HELLO WORLD') RETURN x; | 'HELLO WORLD' |
      | LET x = UPPER('123 abc') RETURN x; | '123 ABC' |
      | LET x = UPPER('') RETURN x; | '' |
      | LET x = UPPER(NULL) RETURN x; | null |
      | LET x = UPPER('中文 english') RETURN x; | '中文 ENGLISH' |
      | LET x = UPPER('!@#$%^&*()') RETURN x; | '!@#$%^&*()' |
      | LET x = UPPER('hello123') RETURN x; | 'HELLO123' |
      | LET x = UPPER('a b c d') RETURN x; | 'A B C D' |
      | LET x = UPPER('  leading space') RETURN x; | '  LEADING SPACE' |
      | LET x = UPPER('trailing space  ') RETURN x; | 'TRAILING SPACE  ' |

  Scenario Outline: string-UPPER-正向用例-RETURN
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | result        |
      | <result> |
    Examples:
      | GQL | result |
      | RETURN UPPER('hello gql') as result; | 'HELLO GQL' |
      | RETURN UPPER('Hello World') as result; | 'HELLO WORLD' |
      | RETURN UPPER('HELLO WORLD') as result; | 'HELLO WORLD' |
      | RETURN UPPER('123 abc') as result; | '123 ABC' |
      | RETURN UPPER('') as result; | '' |
      | RETURN UPPER(NULL) as result; | null |
      | RETURN UPPER('中文 english') as result; | '中文 ENGLISH' |
      | RETURN UPPER('!@#$%^&*()') as result; | '!@#$%^&*()' |
      | RETURN UPPER('hello123') as result; | 'HELLO123' |
      | RETURN UPPER('a b c d') as result; | 'A B C D' |
      | RETURN UPPER('  leading space') as result; | '  LEADING SPACE' |
      | RETURN UPPER('trailing space  ') as result; | 'TRAILING SPACE  ' |

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
      | GQL | error |
      | LET x = UPPER(123) RETURN x; | Type mismatch: expected String but was Integer |
      | LET x = UPPER(true) RETURN x; | Type mismatch: expected String but was Boolean |



