module BelongsToEnum
  module ActsAsEnumField
    def self.included(base)
      base.send :extend, ClassMethods
    end
    
    module ClassMethods
      def acts_as_enum_field
        send :include, InstanceMethods
      end
    end
    
    module InstanceMethods
      # the name is always a symbol
      def name
        self[:name].is_a?(Symbol) ? self[:name] : self[:name].to_s.intern
      end

      # titleized name, if the title is blank
      def title
        self[:title].blank? ? name.to_s.titleize : self[:title]
      end

      # the id if position is nil
      def position
        self[:position] || id
      end

      # enum fields are sorted by position
      def <=>(other)
        self.position <=> other.position
      end

      def default?
        !! self[:default]
      end

      def acts_as_enum_field?
        true
      end

      def inspect_attributes(*attributes)
        "#{self.class.name.demodulize}(" + attributes.collect{|a| "#{a}: #{self.send(a).inspect}"}.join(', ') + ")"
      end
    end
  end
end

ActiveRecord::Base.send :include, BelongsToEnum::ActsAsEnumField
