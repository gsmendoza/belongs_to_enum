module BelongsToEnum
  class FieldWrapper
    attr_accessor :name

    def initialize(name)
      @name = name.to_s
    end

    def tableize
      name.tableize
    end

    def foreign_key
      name.foreign_key
    end

    def name_to_field_str
      'name_to_' + name
    end

    def class_str
      tableize.classify
    end

    def klass
      class_str.constantize
    end
  end
end
