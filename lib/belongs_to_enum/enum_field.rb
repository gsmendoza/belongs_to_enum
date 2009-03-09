module BelongsToEnum
  class EnumField
    attr_accessor :id,  :name, :title, :position, :default

    def initialize(id, name, options ={})
      options = HashWithIndifferentAccess.new(options)
      @id = id
      @name = name
      @position = options[:position]
      @title = options[:title]
      @default = options[:default]
    end

    def [](field)
      instance_eval "@#{field}"
    end
  end
end
