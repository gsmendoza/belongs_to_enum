module BelongsToEnum
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # See the README for how to use this method
    def belongs_to_enum(field_name, objects = nil)
      field = FieldWrapper.new(field_name)
      #-------------------------------------------
      # name to field hash

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

      #-------------------------------------------

      class_eval <<-EVAL
        #---------------------------------------
        # fields method
        # User.statuses
        def self.#{field.tableize}
          #{field.name_to_field_str}.values.sort
        end

        #---------------------------------------
        # User.status(1)
        # User.status(:new)
        def self.#{field.name}(object)
          if object.is_a?(Symbol)
            return #{field.name_to_field_str}[object]
          elsif object.is_a?(Integer)
            return #{field.name_to_field_str}.values.detect{|enum_field| enum_field.id == object}
          else
            raise "BUG: invalid argument " + object.class.name
          end
        end

        #---------------------------------------
        # default_field
        def self.default_#{field.name}
          #{field.tableize}.detect{|enum_field| enum_field.default?}
        end
      EVAL

      #---------------------------------------
      # instance methods

      # user.status
      define_method field.name do
        self.class.send(field.name, self.send(field.foreign_key)) unless self.send(field.foreign_key).nil?
      end

      # user.status = :new
      # user.status = 1
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

      # user.new?
      enum_fields.values.each do |enum_field|
        define_method("#{enum_field.name}?") do
          self.send(field.name).name == enum_field.name unless self.send(field.name).nil?
        end
      end

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
    def define_name_to_field_hash
    end
  end
end

ActiveRecord::Base.send :include, BelongsToEnum
