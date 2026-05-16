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
      | GQL | result |
      | LET x = NORMALIZE('e\u0301', NFC) RETURN x; | 'é' |
      | LET x = NORMALIZE('e\u0301', NFD) RETURN x; | 'é' |
      | LET x = NORMALIZE('ê\u0323', NFKC) RETURN x; | 'ệ' |
      | LET x = NORMALIZE('ê\u0323', NFKD) RETURN x; | 'ệ' |
      | LET x = NORMALIZE('  Test String  ', NFC) RETURN x; | '  Test String  ' |
      | LET x = NORMALIZE('A\u00AD', NFC) RETURN x; | 'A' |
      | LET x = NORMALIZE('', NFC) RETURN x; | '' |
      | LET x = NORMALIZE('中\u2FF5文', NFC) RETURN x; | '中⿵文' |
      | LET x = NORMALIZE(null, NFC) RETURN x; | null |
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
      | GQL | error |
      | LET x = NORMALIZE('e\u0301', 'INVALID') RETURN x; | [2700]Invalid input |
      | RETURN normalize(1,NFC) AS s | Type mismatch: expected String but was Integer |