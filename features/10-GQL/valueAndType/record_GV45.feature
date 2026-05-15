#encoding: utf-8
#作用: 创建或表示一个记录（行）对象。
#参数:
#各列的字段值，类型为 任意数据类型。
#返回结果: 一个记录对象，包含多个字段，返回范围取决于字段值
#https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/analogous-cypher/
#https://neo4j.com/docs/cypher-manual/current/values-and-types/maps/

Feature: recordType

  Scenario Outline: recordType-bug5518
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | LET x = DATE(RECORD{year:2024, month:10, day:10}) RETURN x; | '2024-10-10' |
      | let x = RECORD{a:1, b:2} return x; | {a:1, b:2} |
      | let x = RECORD{key:'value', number:'42'} return x; | {key: 'value', number: '42'} |
      | let x = RECORD{} return x; | {} |
      | let x = RECORD{null_key:NULL} return x; | {null_key: null} |
#      | let x = RECORD{a: 1, b: RECORD{c: 2, d: 3}} return x;       | {a: 1, b: {c: 2, d: 3}}      | 嵌套 Record |
      | let x = RECORD{`special@key`:'value'} return x; | {special@key: 'value'} |
      | let x = RECORD{emoji:'😊'} return x; | {emoji:'😊'} |
      | let x = RECORD{中文键:'中文值'} return x; | {中文键: '中文值'} |
#      | let x = RECORD{nested:RECORD{a:1, b:2}} return x;           | {nested: {a: 1, b: 2}}       | 嵌套 RECORD |

  Scenario Outline: recordType异常用例-用法错误时
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
      | return RECORD{year:NULL} as x; | [2701]Variable `RECORD` not defined |