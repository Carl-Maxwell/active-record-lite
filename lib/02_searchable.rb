require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(new_params)
    if self.respond_to?(:params)
      params.merge!(new_params)
      self
    else
      Relation.new(self, new_params)
    end
  end

  # def joins(new_joins)
  #   if self.respond_to?(:join)
  #     joins << new_joins
  #   else
  #     Relation.new(self, {}).join(new_joins)
  #   end
  # end
end

class Relation
  include Searchable

  attr_accessor :model, :params, :joins

  def initialize(model, params)
    @model = model
    @params = params
    @joins = []
  end

  def build_where
    return "" unless params.length > 0

    conditions = params.map { |column, value| "#{column} = :#{column}" }

    <<-SQL
      WHERE
        #{conditions.join(" AND ")}
    SQL
  end

  # def join
  #   @join ||= []
  # end

  def build_joins
    ""
  end

  def run
    model.parse_all DBConnection.execute(<<-SQL, params)
      SELECT
        *
      FROM
        #{model.table_name}
      #{build_joins}
      #{build_where}
    SQL
  end

  def method_missing(method_sym, *arguments, &block)
    if model.respond_to?(method_sym)
      model.send(method_sym, *arguments, &block)
    else
      super
    end
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
