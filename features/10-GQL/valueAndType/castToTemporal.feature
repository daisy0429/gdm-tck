#encoding: utf-8

Feature: cast类型转换函数-toTemporal

  #EOF为bug-8260，临时注释
  Scenario Outline: castToTemporal-positive-cases
    When executing queries without error:
      """
    <GQL>
    """
    Then the result should be, in any order:
      | x        |
      | <result> |
    Examples:
      | GQL | result |
      | LET x = CAST('2024-01-12' as ZONED DATETIME NOT NULL) RETURN x; | '2024-01-12T00:00Z' |
      | LET x = CAST('2024-01-12' as TIMESTAMP WITH TIME ZONE NOT NULL) RETURN x; | '2024-01-12T00:00Z' |
      | LET x = CAST('2024-01-12' as LOCAL DATETIME NOT NULL) RETURN x; | '2024-01-12T00:00' |
      | LET x = CAST('2024-01-12' as DATE NOT NULL) RETURN x; | '2024-01-12' |
      | LET x = CAST('12:12:12' as ZONED TIME NOT NULL) RETURN x; | '12:12:12Z' |
      | LET x = CAST('12:12:12' as TIME WITH TIME ZONE NOT NULL) RETURN x; | '12:12:12Z' |
      | LET x = CAST('12:12:12' as LOCAL TIME NOT NULL) RETURN x; | '12:12:12' |
      | LET x = CAST('12:12:12' as TIME WITHOUT TIME ZONE NOT NULL) RETURN x; | '12:12:12' |
      | LET x = CAST('PT1s' as DURATION(YEAR TO MONTH) NOT NULL) RETURN x; | 'PT1S' |
      | LET x = CAST('PT1s' as DURATION(DAY TO SECOND) NOT NULL) RETURN x; | 'PT1S' |
      | LET x = CAST(DATE("2024-01-01") AS date) RETURN x; | '2024-01-01' |

    #EOF为bug-8260，临时注释
  Scenario Outline: castToTemporal-negative-cases
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
      | LET x = CAST("invalid-date" AS DATE) RETURN x; | EOF |
      | LET x = CAST("25:61:00" AS TIME) RETURN x; | Invalid value for HourOfDay (valid values 0 - 23): 25) |
      | LET x = CAST("2024-02-30" AS DATE) RETURN x; | invalid date 'February 30') |
      | LET x = CAST("P1X" AS DURATION) RETURN x; | Text cannot be parsed to a Duration: P1X |
      | LET x = CAST(POINT({longitude: 13.4, latitude: 52.5}) AS DATE) RETURN x; | unsupported type in ConstructedValueType.CastTo |
      | LET x = CAST(POINT({x: 1, y: 2}) AS TIME) RETURN x; | unsupported type in ConstructedValueType.CastTo |
      | LET x = CAST(NULL, DATE) RETURN x; | [2701]Variable `DATE` not defined. |
      | LET x = CAST("2024-01-01", "extra") RETURN x; | unsupported value type in FunctionInvocation |
      | LET x = CAST(123 AS DATE) RETURN x; | unsupported type in BinaryExactNumericType.CastTo |
      | LET x = CAST(TRUE AS TIME) RETURN x; | unsupported type in BoolType.CastTo |
      | LET x = CAST("2024-01-01T12:34:56Z" AS DURATION) RETURN x; | Text cannot be parsed to a Duration: 2024-01-01T12:34:56Z |
      | LET x = CAST("P1DT2H" AS LOCALDATETIME) RETURN x; | Text cannot be parsed to a LocalDateTime: P1DT2H |
      | LET x = CAST('1231654231' as TIMESTAMP WITHOUT TIME ZONE NOT NULL) RETURN x; | unsupported type in StringType.CastTo |
      | LET x = CAST('2024-01-12T12:13:14' as TIMESTAMP NOT NULL) RETURN x; | unsupported type in StringType.CastTo |