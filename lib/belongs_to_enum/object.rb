class Object
  def metaclass
    class << self
      self
    end
  end

  def meta_eval &blk
    metaclass.instance_eval &blk
  end

  # adds methods to the metaclass
  def meta_def name, &blk
    meta_eval {define_method name, &blk}
  end

  # instance method
  def class_def name, &blk
    class_eval {define_method name, &blk}
  end
end
