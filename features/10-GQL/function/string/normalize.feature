#encoding: utf-8
#将字符串按照指定的 Unicode 规范化形式进行标准化处理
#https://neo4j.com/docs/cypher-manual/current/functions/string/#functions-normalize

Feature: normalize

  Scenario Outline: normalize-positive-cases
    When executing queries without error:
  """
  <GQL>
  """
    Then the result should be:
  """
  <result>
  """
    Examples:
      | GQL                                                 | result            | 备注                       |
      | LET x = NORMALIZE('e\u0301', NFC) RETURN x;         | 'é'               | 将分解的组合字符标准化为 NFC 格式      |
      | LET x = NORMALIZE('e\u0301', NFD) RETURN x;         | 'é'               | 将字符分解为基字符和变音符            |
      | LET x = NORMALIZE('ê\u0323', NFKC) RETURN x;        | 'ệ'               | 标准化为兼容的规范形式（NFKC）        |
      | LET x = NORMALIZE('ê\u0323', NFKD) RETURN x;        | 'ệ'               | 分解为兼容形式的规范分解（NFKD）-bug?  |
      | LET x = NORMALIZE('  Test String  ', NFC) RETURN x; | '  Test String  ' | 输入没有组合字符，仅返回原字符串         |
      | LET x = NORMALIZE('A\u00AD', NFC) RETURN x;         | 'A'               | 软连字符在 NFC 规范中被移除-bug5514 |
      | LET x = NORMALIZE('', NFC) RETURN x;                | ''                | 空字符串输入，返回空字符串            |
      | LET x = NORMALIZE('中\u2FF5文', NFC) RETURN x;        | '中⿵文'             | East Asian 字符组合测试        |
      | LET x = NORMALIZE(null, NFC) RETURN x;              | null              |                          |

  Scenario Outline: normalize-negative-cases
    When executing queries:
  """
  <GQL>
  """
    Then the error should be contain:
  """
  <error>
  """
    Examples:
      | GQL                                               | error                                          | 备注        |
      | LET x = NORMALIZE('e\u0301', 'INVALID') RETURN x; | [2700]Invalid input                            | 不支持的规范化形式 |
      | RETURN normalize(1,NFC) AS s                      | Type mismatch: expected String but was Integer |           |
