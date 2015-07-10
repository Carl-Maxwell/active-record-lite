require_relative '03_associatable'
require 'byebug'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through = self.class.assoc_options[through_name]
      source = through.model_class.assoc_options[source_name]

      through_table = through.table_name
      source_table = source.table_name

      rows = DBConnection.execute(<<-SQL, send(through.foreign_key))
        SELECT
          source_table.*
        FROM
          #{source_table} as source_table
        JOIN
          #{through_table} as through_table ON
          through_table.#{source.foreign_key} = source_table.#{source.primary_key}
        WHERE
          through_table.id = ?
      SQL

      source.model_class.parse_row rows.first
    end
  end
end
