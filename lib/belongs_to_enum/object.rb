class Object
  # adds methods to the metaclass
  def meta_def name, &blk
    metaclass.instance_eval do
      define_method name, &blk
    end
  end
end
