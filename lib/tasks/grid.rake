namespace :grid do
  namespace :db do
    desc "Prints a list of unindexed foreign keys so you can index them"
    task :missing_indexes => :environment do
      indexes = {}
      conn = ActiveRecord::Base.connection
      conn.tables.each do |table|
        indexed_columns = conn.indexes(table).map { |i| i.columns }.flatten
        conn.columns(table).each do |column|
          if column.name.match(/_id/) && !indexed_columns.include?(column.name)
            indexes[table] ||= []
            indexes[table] << column.name
          end
        end
      end

      if indexes.empty?
        puts "No missing foreign key indexes found."
      else
        puts "Foreign Keys:"
        indexes.each do |table, columns|
          puts columns.map { |c| "\s\sadd_index '#{table}', '#{c}'\n"}
        end
      end
    end
  end
end
