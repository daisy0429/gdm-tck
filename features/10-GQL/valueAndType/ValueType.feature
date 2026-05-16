##encoding: utf-8
##http://10.13.4.249:8090/pages/viewpage.action?pageId=70454147
##https://neo4j.com/docs/cypher-manual/current/appendix/gql-conformance/supported-mandatory/ ->4.16
##https://neo4j.com/docs/cypher-manual/current/values-and-types/property-structural-constructed/#types-synonyms
## TODO 标准文档中：目录18？
##fixme code cast()不支持？
##数据类型：存储GQL标准数据类型
##valueType:使用GQL标准数据类型进行计算
## 和cast()用例存在部分重叠
#
#Feature: ValueType
#
#  Scenario Outline: []cast to booleanType
#    When executing queries without error:
#    """
#     CREATE (:Test {num: 1})
#    """
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                             | result |
#      | match (a) LET x = CAST(a.num as bool) RETURN x; | true   |
#      | LET x = CAST(true as boolean) RETURN x;         | true   |
#
#  Scenario Outline: []characterStringType
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                 | result |
#      | LET x = CAST(true as string(1,2)) RETURN x;         | 'true' |
#      | LET x = CAST(true as CHAR(2)) RETURN x;             | 'true' |
#      | LET x = CAST(true as VARCHAR(2) NOT NULL) RETURN x; | 'true' |
#
#  Scenario Outline: []byteStringType
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                    | result     |
#      | LET x = CAST(true as BYTES(1,10) NOT NULL) RETURN x;   | 0x74727565 |
#      | LET x = CAST(true as BINARY(10) NOT NULL) RETURN x;    | 0x74727565 |
#      | LET x = CAST(true as VARBINARY(10) NOT NULL) RETURN x; | 0x74727565 |
#
#  Scenario Outline: []numericType
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                           | result |
#      | LET x = CAST(true as INT8 NOT NULL) RETURN x;                 | 1      |
#      | LET x = CAST(true as INT16 NOT NULL) RETURN x;                | 1      |
#      | LET x = CAST(true as INT32 NOT NULL) RETURN x;                | 1      |
#      | LET x = CAST(true as INT64 NOT NULL) RETURN x;                | 1      |
#      | LET x = CAST(true as INT128 NOT NULL) RETURN x;               | 1      |
#      | LET x = CAST(true as INT256 NOT NULL) RETURN x;               | 1      |
#      | LET x = CAST(true as SMALLINT NOT NULL) RETURN x;             | 1      |
#      | LET x = CAST(true as INT(7) NOT NULL) RETURN x;               | 1      |
#      | LET x = CAST(true as BIGINT NOT NULL) RETURN x;               | 1      |
#      | LET x = CAST(true as SIGNED INTEGER8 NOT NULL) RETURN x;      | 1      |
#      | LET x = CAST(true as SIGNED INTEGER16 NOT NULL) RETURN x;     | 1      |
#      | LET x = CAST(true as SIGNED INTEGER32 NOT NULL) RETURN x;     | 1      |
#      | LET x = CAST(true as SIGNED INTEGER64 NOT NULL) RETURN x;     | 1      |
#      | LET x = CAST(true as SIGNED INTEGER128 NOT NULL) RETURN x;    | 1      |
#      | LET x = CAST(true as SIGNED INTEGER256 NOT NULL) RETURN x;    | 1      |
#      | LET x = CAST(true as SIGNED SMALL INTEGER NOT NULL) RETURN x; | 1      |
#      | LET x = CAST(true as SIGNED INTEGER(10) NOT NULL) RETURN x;   | 1      |
#      | LET x = CAST(true as SIGNED BIG INTEGER NOT NULL) RETURN x;   | 1      |
#      | LET x = CAST(true as DECIMAL(1,10) NOT NULL) RETURN x;        | 1.0    |
#      | LET x = CAST(true as DEC(1,10) NOT NULL) RETURN x;            | 1.0    |
#      | LET x = CAST(true as FLOAT16 NOT NULL) RETURN x;              | 1.0    |
#      | LET x = CAST(true as FLOAT32 NOT NULL) RETURN x;              | 1.0    |
#      | LET x = CAST(true as FLOAT64 NOT NULL) RETURN x;              | 1.0    |
#      | LET x = CAST(true as FLOAT128 NOT NULL) RETURN x;             | 1.0    |
#      | LET x = CAST(true as FLOAT256 NOT NULL) RETURN x;             | 1.0    |
#      | LET x = CAST(true as FLOAT(1,2) NOT NULL) RETURN x;           | 1.0    |
#      | LET x = CAST(true as REAL NOT NULL) RETURN x;                 | 1.0    |
#      | LET x = CAST(true as DOUBLE PRECISION NOT NULL) RETURN x;     | 1.0    |
#
#  Scenario Outline: []temporalType
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                          | result                    |
#      | LET x = CAST('2024-01-12' as ZONED DATETIME NOT NULL) RETURN x;              | 2024-01-12T00:00:00+00:00 |
#      | LET x = CAST('2024-01-12' as TIMESTAMP WITH TIME ZONE NOT NULL) RETURN x;    | 2024-01-12T00:00:00+00:00 |
#      | LET x = CAST('2024-01-12' as LOCAL DATETIME NOT NULL) RETURN x;              | 2024-01-12T00:00:00       |
#      | LET x = CAST('2024-01-12T12:13:14' as TIMESTAMP NOT NULL) RETURN x;          | 2024-01-12T12:13:14       |
#      | LET x = CAST('1231654231' as TIMESTAMP WITHOUT TIME ZONE NOT NULL) RETURN x; | 2009-01-12T12:13:51       |
#      | LET x = CAST('2024-01-12' as DATE NOT NULL) RETURN x;                        | 2024-01-12                |
#      | LET x = CAST('12:12:12' as ZONED TIME NOT NULL) RETURN x;                    | 12:12:12+00:00            |
#      | LET x = CAST('12:12:12' as TIME WITH TIME ZONE NOT NULL) RETURN x;           | 12:12:12+00:00            |
#      | LET x = CAST('12:12:12' as LOCAL TIME NOT NULL) RETURN x;                    | 12:12:12                  |
#      | LET x = CAST('12:12:12' as TIME WITHOUT TIME ZONE NOT NULL) RETURN x;        | 12:12:12                  |
#      | LET x = CAST('PT1s' as DURATION(YEAR TO MONTH) NOT NULL) RETURN x;           | P0Y0M0DT0H0M1S            |
#      | LET x = CAST('PT1s' as DURATION(DAY TO SECOND) NOT NULL) RETURN x;           | P0DT0H0M1S                |
#
#  Scenario Outline: []referenceValueType
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                   | result |
#      | LET x = CAST(1 as ANY PROPERTY GRAPH) RETURN x;                       | 1      |
#      | LET x = CAST(1 as PROPERTY GRAPH {(:Person{name::string})}) RETURN x; | 1      |
#
#  Scenario Outline: []immaterialValueType
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                  | result |
#      | LET x = CAST(1 as null) RETURN x;    | null   |
#      | LET x = CAST(1 as NOTHING) RETURN x; | null   |
#
#  Scenario Outline: []pathValueTypeLabel
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                | result    |
#      | LET x = CAST([1,2,2,3] as PATH NOT NULL) RETURN x; | [1,2,2,3] |
#
#  Scenario Outline: []listValueTypeAlt1
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                 | result |
#      | LET x = CAST([1,2,2,3] as GROUP LIST<string>[2] NOT NULL) RETURN x; | [1,2]  |
#
#  Scenario Outline: []listValueTypeAlt2
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                 | result |
#      | LET x = CAST([1,2,2,3] as string GROUP LIST [2] NOT NULL) RETURN x; | [1,2]  |
#
#  Scenario Outline: []listValueTypeAlt3
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                             | result    |
#      | LET x = CAST([1,2,2,3] as GROUP LIST) RETURN x; | [1,2,2,3] |
#
#  Scenario Outline: []recordTypeLabel
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                                          | result          |
#      | LET x = CAST([1,2,2,3] as ANY RECORD NOT NULL) RETURN x;                     | [1,2,2,3]       |
#      | LET x = CAST([1,2] as RECORD {name::string,age::integer} NOT NULL) RETURN x; | {name:1, age:2} |
#
#  Scenario Outline: []openDynamicUnionTypeLabel
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                     | result    |
#      | LET x = CAST([1,2,2,3] as ANY VALUE NOT NULL) RETURN x; | [1,2,2,3] |
#
#  Scenario Outline: []dynamicPropertyValueTypeLabel
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                              | result    |
#      | LET x = CAST([1,2,2,3] as ANY PROPERTY VALUE NOT NULL) RETURN x; | [1,2,2,3] |
#
#  Scenario Outline: []closedDynamicUnionTypeAtl1
#    When executing queries without error:
#    """
#    <GQL>
#    """
#    Then the result should be, in any order:
#      | x        |
#      | <result> |
#    Examples:
#      | GQL                                                     | result    |
#      | LET x = CAST([1,2,2,3] as ANY VALUE <string>) RETURN x; | [1,2,2,3] |
#
##  Scenario : []closedDynamicUnionTypeAtl2
##    When executing queries without error:
##    """
##    LET x = CAST([1,2,2,3] as string	integer	float) RETURN x;
##    """
##    Then the result should be, in any order:
##      | x         |
##      | [1,2,2,3] |
#
