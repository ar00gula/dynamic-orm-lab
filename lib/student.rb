require 'pry'

require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'interactive_record.rb'

class Student < InteractiveRecord

    def initialize(options={})
        options.each do |key, value|
        self.send("#{key}=", value)
        end
    end

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = "PRAGMA table_info('#{table_name}')" #why can you call the table name method like this?? we haven't declared a variable?? wait omg is this just some sql bullshit

        table_info_hash = DB[:conn].execute(sql)
        column_names = []

        table_info_hash.each do |column_hash|
            column_names << column_hash["name"]
        end
        column_names.compact #compact gets rid of any nil values
    end

    self.column_names.each do |col_name| #okay but why does this work? what is the scope of attr_accessor? what is the scope of a .each block?
        attr_accessor col_name.to_sym
    end

    def table_name_for_insert
        return self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end



    def values_for_insert
        values = []

        self.class.column_names.each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
            end 
    
        values.join(", ")
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
        DB[:conn].execute(sql)
      end

    def self.find_by(attribute)
        key, value = attribute.first
        sql = "SELECT * FROM #{self.table_name} WHERE #{key.to_s} = ?"
        DB[:conn].execute(sql, value)
    end

end
