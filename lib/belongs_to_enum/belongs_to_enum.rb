module BelongsToEnum
  def self.included(base)
    base.send :extend, ClassMethods
  end
  
  module ClassMethods
    # See the README for how to use this method
    def belongs_to_enum(field, objects)
      fields_str = field.to_s.tableize
      field_id_str = field.to_s.foreign_key
      name_to_field_str = 'name_to_' + field.to_s

      #-------------------------------------------
      # name to field hash

      enum_fields = {}
      if objects.is_a?(Array)
        self.belongs_to field
        objects.each do |record| 
          enum_field = record
          enum_fields[enum_field.name] = enum_field
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

      cattr_accessor name_to_field_str
      self.send "#{name_to_field_str}=", enum_fields

      #-------------------------------------------

      eval_string = <<-EVAL
        class << self
          #---------------------------------------
          # fields method
          # User.statuses
          def #{fields_str}
            #{name_to_field_str}.values.sort
          end

          #---------------------------------------
          # User.status(1)
          # User.status(:new)
          def #{field}(object)
            if object.is_a?(Symbol)
              return #{name_to_field_str}[object]
            elsif object.is_a?(Integer)
              return #{name_to_field_str}.values.detect{|enum_field| enum_field.id == object}
            else
              raise "BUG: invalid argument " + object.class.name
            end
          end

          #---------------------------------------
          # default_field
          def default_#{field}
            #{fields_str}.detect{|enum_field| enum_field.default?}
          end
        end
      EVAL
      class_eval eval_string

      #---------------------------------------
      # instance methods

      # user.status
      define_method field do
        self.class.send(field, self.send(field_id_str)) unless self.send(field_id_str).nil?
      end

      # user.status = :new
      # user.status = 1
      define_method "#{field}=" do |object|
        if object.nil?
          self.send "#{field_id_str}=", nil
        elsif object.is_a?(Symbol)
          self.send "#{field_id_str}=", self.class.send(field, object).id
        elsif object.kind_of?(ActsAsEnumField::InstanceMethods)
          self.send "#{field_id_str}=", object.id
        else
          raise "BUG: invalid argument " + object.class.name
        end
      end

      # user.new?
      enum_fields.values.each do |enum_field|
        define_method("#{enum_field.name}?") do
          self.send(field).name == enum_field.name unless self.send(field).nil?
        end
      end

      send :include, InstanceMethods
    end

    # See the README for how to use this method
    def validates_inclusion_of_enum field_id_str, validate_inclusion_of_options={}
      field = field_id_str.to_s.humanize.underscore
      inclusion_options = validate_inclusion_of_options.clone
      inclusion_options[:in] = inclusion_options[:in].collect do |v|
        self.send(field, v).id
      end unless inclusion_options[:in].nil?
      
      inclusion_options.reverse_merge!(
      { :in => send(field.tableize).collect{|enum_field| enum_field.id},
        :message => "is not valid"
      })
      validates_inclusion_of field_id_str, inclusion_options
    end
  end

  module InstanceMethods
  end
end

ActiveRecord::Base.send :include, BelongsToEnum
