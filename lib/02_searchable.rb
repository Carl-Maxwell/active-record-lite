require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    conditions = params.map { |column, value| "#{column} = :#{column}" }

    p params

    parse_all DBConnection.execute(<<-SQL, params)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{conditions.join(" AND ")}
    SQL
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
