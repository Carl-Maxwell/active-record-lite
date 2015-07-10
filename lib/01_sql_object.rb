require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns_has_run if @columns_has_run

    columns = DBConnection.execute(<<-SQL)
      PRAGMA table_info(#{table_name})
    SQL

    columns.map! { |column| column["name"].to_sym }

    @columns_has_run = columns
  end

  def self.finalize!
    columns.each do |column|
      define_method(column) { attributes[column] }
      define_method("#{column}=".to_sym) { |value| attributes[column] = value }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    parse_all DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
  end

  def self.parse_row(row)
    self.new( row )
  end

  def self.parse_all(rows)
    rows.map do |row|
      parse_row(row)
    end
  end

  def self.find(id)
    row = DBConnection.execute(<<-SQL, id).first
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL

    row ? parse_row(row) : nil
  end

  def initialize(params = {})
    params.each do |key, value|
      key = key.to_sym

      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key)
      attributes[key] = value
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    DBConnection.execute(<<-SQL, attributes)
      INSERT INTO
        #{self.class.table_name} (#{self.class.columns.join(",")})
      VALUES
        (#{self.class.columns.map { |column| ":" + column.to_s }.join(",")})
    SQL

    attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    set_these = attributes.keys.map { |column| "#{column} = :#{column}" }

    DBConnection.execute(<<-SQL, attributes)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_these.join(",")}
      WHERE
        id = :id
    SQL
  end

  def save
    attributes.include?(:id) ? update : insert
  end
end
