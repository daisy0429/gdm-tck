#encoding: utf-8
#去除前导字符

Feature: string-leading

#  用法说明：TRIM(LEADING 'HEL' FROM 'HELHELLO GQL')
#  TRIM 的 LEADING/TRAILING 删除，是按字符集合来删，不是按子串来删。
#  而是把开头所有属于字符集 {H, E, L} 的字符，全部删掉。
#  一直删，直到遇到第一个不在 {H, E, L} 里的字符为止。
#  所以最终的结果为：'O GQL'
#  Neo4j这个语法中仅支持单个字符，我们支持多个字符，所以这并不是一个BUG
  Scenario Outline: LEADING 正向用例测试-bug5510
    When executing queries without error:
    """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL                                                       | result      | 备注                               |
      | LET x = TRIM(LEADING 'H' FROM 'HELLO GQL') RETURN x;      | 'ELLO GQL'  | 移除首个字符 `H`                       |
      | LET x = TRIM(LEADING 'HELLO' FROM 'HELLOGQL') RETURN x;   | 'GQL'       | 移除前导字符串 `HELLO`                  |
      | LET x = TRIM(LEADING ' ' FROM '  HELLO GQL') RETURN x;    | 'HELLO GQL' | 移除前导空格                           |
      | LET x = TRIM(LEADING '' FROM 'HELLO GQL') RETURN x;       | 'HELLO GQL' | 不移除任何字符，结果保持原样                   |
      | LET x = TRIM(LEADING '123' FROM '123123GQL') RETURN x;    | 'GQL'       | 移除重复的前导字符串 `123`                 |
      | LET x = TRIM(LEADING 'HEL' FROM 'HELHELLO GQL') RETURN x; | 'O GQL'     | 逐个移除每个匹配的前导字符 `HEL` bug5510不是bug |
      | LET x = TRIM(LEADING ' ' FROM '') RETURN x;               | ''          | 空字符串输入，结果仍为空字符串                  |
      | LET x = TRIM(LEADING 'A' FROM NULL) RETURN x;             | null        | 对 `NULL` 值进行操作，结果返回 `NULL`       |


  Scenario Outline: LEADING 反向用例测试
    When executing queries:
    """
    <GQL>
    """
    Then the error should contain:
    """
    <error>
    """
    Examples:
      | GQL                                                       | error                                 | 备注             |
      | LET x = TRIM(LEADING 123 FROM 'HELLO GQL') RETURN x;      | ERROR: Type mismatch: expected String | 前导字符参数必须为字符串类型 |
      | LET x = TRIM(LEADING 'H', 'E' FROM 'HELLO GQL') RETURN x; | ERROR: Invalid input                  | 不支持多个前导字符参数    |
      | LET x = TRIM(LEADING 'HEL' FROM 12345) RETURN x;          | ERROR: Type mismatch: expected String | 操作的目标字段必须为字符串  |
      | LET x = TRIM(LEADING 'H' FROM TRUE) RETURN x;             | ERROR: Type mismatch: expected String | 操作的目标字段为布尔值，非法 |
      | LET x = TRIM(LEADING NULL FROM 'HELLO GQL') RETURN x;     | ERROR: Invalid input                  | 前导字符参数不能为 NULL |
      | LET x = TRIM(LEADING 'H' FROM 'HELLO' OR 'GQL') RETURN x; | ERROR: Invalid input                  | 不支持逻辑操作符       |
      | LET x = TRIM(LEADING 'H') RETURN x;                       | ERROR: Missing required parameter     | 缺少目标字符串参数      |
