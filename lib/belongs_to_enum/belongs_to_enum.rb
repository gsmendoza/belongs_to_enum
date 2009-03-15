module BelongsToEnum
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # See the README for how to use this method
    def belongs_to_enum(field_name, objects = nil)
      field = FieldWrapper.new(field_name)
      define_name_to_field_hash(field, objects)

      # class methods
      define_fields_class_method field
      define_field_class_method field
      define_default_field_class_method field

      # instance methods
      define_field_method field
      define_set_field_method field
      define_is_field_method field

    end

    # See the README for how to use this method
    def validates_inclusion_of_enum field_id_str, validate_inclusion_of_options={}
      field = FieldWrapper.new(field_id_str.to_s.humanize.underscore)

      inclusion_options = validate_inclusion_of_options.clone
      inclusion_options[:in] = inclusion_options[:in].collect do |v|
        self.send(field.name, v).id
      end unless inclusion_options[:in].nil?

      inclusion_options.reverse_merge!(
      { :in => send(field.tableize).collect{|enum_field| enum_field.id},
        :message => "is not valid"
      })
      validates_inclusion_of field.foreign_key, inclusion_options
    end

  protected

    #Class.<fields>
    #    Task.statuses
    def define_fields_class_method(field)
      meta_def field.tableize do
        send(field.name_to_field_str).values.sort
      end
    end

    #Class.<field>(key)
    #    Task.status(1)
    #    Task.status(:new)
    def define_field_class_method(field)
      meta_def field.name do |object|
        if object.is_a?(Symbol)
          return send(field.name_to_field_str)[object]
        elsif object.is_a?(Integer)
          return send(field.name_to_field_str).values.detect{|enum_field| enum_field.id == object}
        else
          raise "BUG: invalid argument " + object.class.name
        end
      end
    end

    #Class.default_<field>
    #   Task.default_status
    def define_default_field_class_method(field)
      meta_def "default_#{field.name}" do
        send(field.tableize).detect{|enum_field| enum_field.default?}
      end
    end

    def define_name_to_field_hash(field, objects)
      enum_fields = {}
      if objects.nil?
        self.belongs_to field.name
        field.klass.all.each do |record|
          if record.kind_of?(ActsAsEnumField::InstanceMethods)
            enum_field = record
            enum_fields[enum_field.name] = enum_field
          else
            raise "#{record} is not an instance of ActsAsEnumField. Call acts_as_enum_field within class #{record.class}"
          end
        end
      elsif objects.is_a?(Hash)
        id_to_object_hash = objects
        id_to_object_hash.each do |id, object|
          if object.is_a?(Symbol)
            enum_field = EnumField.new(id, object)
          elsif object.is_a?(Hash)
            enum_field = EnumField.new(id, object[:name], object)
          else
            raise "BUG: invalid argument " + object.class.name
          end
          enum_fields[enum_field.name] = enum_field
        end
      else
        raise "BUG: invalid argument " + objects.class.name
      end

      cattr_accessor field.name_to_field_str
      self.send "#{field.name_to_field_str}=", enum_fields
      enum_fields
    end

    #object.<field>
    #   task.status
    def define_field_method(field)
      define_method field.name do
        self.class.send(field.name, self.send(field.foreign_key)) unless self.send(field.foreign_key).nil?
      end
    end

    #object.<field> = <key/enum_field>
    #   task.status = :new
    #   task.status = Task.status(1)
    def define_set_field_method(field)
      define_method "#{field.name}=" do |object|
        if object.nil?
          self.send "#{field.foreign_key}=", nil
        elsif object.is_a?(Symbol)
          self.send "#{field.foreign_key}=", self.class.send(field.name, object).id
        elsif object.kind_of?(ActsAsEnumField::InstanceMethods)
          self.send "#{field.foreign_key}=", object.id
        else
          raise "BUG: invalid argument " + object.class.name
        end
      end
    end

    #object.<field>?
    #   task.new?
    #   task.completed?
    def define_is_field_method field
      send(field.name_to_field_str).values.each do |enum_field|
        define_method("#{enum_field.name}?") do
          self.send(field.name).name == enum_field.name unless self.send(field.name).nil?
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, BelongsToEnum
