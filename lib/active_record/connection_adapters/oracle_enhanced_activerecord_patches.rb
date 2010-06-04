# ActiveRecord 2.3 patches
if ActiveRecord::VERSION::MAJOR == 2 && ActiveRecord::VERSION::MINOR == 3
  ActiveRecord::Associations::ClassMethods.module_eval do
    private
    def tables_in_string(string)
      return [] if string.blank?
      # always convert table names to downcase as in Oracle quoted table names are in uppercase
      # ignore raw_sql_ that is used by Oracle adapter as alias for limit/offset subqueries
      string.scan(/([a-zA-Z_][\.\w]+).?\./).flatten.map(&:downcase).uniq - ['raw_sql_']
    end
  end

  ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.class_eval do
    protected
    def aliased_table_name_for(name, suffix = nil)
      # always downcase quoted table name as Oracle quoted table names are in uppercase
      if !parent.table_joins.blank? && parent.table_joins.to_s.downcase =~ %r{join(\s+\w+)?\s+#{active_record.connection.quote_table_name(name).downcase}\son}
        @join_dependency.table_aliases[name] += 1
      end

      unless @join_dependency.table_aliases[name].zero?
        # if the table name has been used, then use an alias
        name = active_record.connection.table_alias_for "#{pluralize(reflection.name)}_#{parent_table_name}#{suffix}"
        table_index = @join_dependency.table_aliases[name]
        @join_dependency.table_aliases[name] += 1
        name = name[0..active_record.connection.table_alias_length-3] + "_#{table_index+1}" if table_index > 0
      else
        @join_dependency.table_aliases[name] += 1
      end

      name
    end
  end

# ActiveRecord 3.0 patches
elsif ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0

  ActiveRecord::Relation.class_eval do
    private

    def references_eager_loaded_tables?
      # always convert table names to downcase as in Oracle quoted table names are in uppercase
      joined_tables = (tables_in_string(arel.joins(arel)) + [table.name, table.table_alias]).compact.map(&:downcase).uniq
      (tables_in_string(to_sql) - joined_tables).any?
    end

    def tables_in_string(string)
      return [] if string.blank?
      # always convert table names to downcase as in Oracle quoted table names are in uppercase
      # ignore raw_sql_ that is used by Oracle adapter as alias for limit/offset subqueries
      string.scan(/([a-zA-Z_][\.\w]+).?\./).flatten.map(&:downcase).uniq - ['raw_sql_']
    end
  end

  ActiveRecord::Associations::ClassMethods::JoinDependency::JoinAssociation.class_eval do
    protected

    def aliased_table_name_for(name, suffix = nil)
      # always downcase quoted table name as Oracle quoted table names are in uppercase
      if !parent.table_joins.blank? && parent.table_joins.to_s.downcase =~ %r{join(\s+\w+)?\s+#{active_record.connection.quote_table_name(name).downcase}\son}
        @join_dependency.table_aliases[name] += 1
      end

      unless @join_dependency.table_aliases[name].zero?
        # if the table name has been used, then use an alias
        name = active_record.connection.table_alias_for "#{pluralize(reflection.name)}_#{parent_table_name}#{suffix}"
        table_index = @join_dependency.table_aliases[name]
        @join_dependency.table_aliases[name] += 1
        name = name[0..active_record.connection.table_alias_length-3] + "_#{table_index+1}" if table_index > 0
      else
        @join_dependency.table_aliases[name] += 1
      end

      name
    end
  end

end
