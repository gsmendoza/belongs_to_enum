require 'test_helper'

class BelongsToEnumTest < ActiveSupport::TestCase
  load_schema

  #-----------------------------------------------

  class Task < ActiveRecord::Base
    belongs_to_enum :status,
    { 1 => :new,
      2 => {:name => :in_progress, :title => 'Continuing'},
      3 => {:name => :completed, :position => 300},
      4 => {:name => :cancelled, :title => 'Ended', :position => 5}
    }
    validates_inclusion_of_enum :status_id
  end

  test "Schema has loaded correctly" do
    assert_equal [], Task.all
  end

  test "Task.default_status is nil if there is no default status" do
    assert_nil Task.default_status
  end

  test "Task.statuses should return an array of statuses sorted by position" do
    assert_equal 4, Task.statuses.size
    assert_equal Array, Task.statuses.class

    statuses = Task.statuses
    1.upto(3) do |i|
      assert statuses[i].position >= statuses[i-1].position
    end
  end

  test "Task.status(name/id) should return the status" do
    status = Task.status(1)
    assert_equal 1, status.id
    assert_equal :new, status.name

    status = Task.status(:cancelled)
    assert_equal :cancelled, status.name
  end

  test "Task.status(key) should raise an error if the key is not an integer or symbol" do
    assert_raise RuntimeError do
      status = Task.status('New')
    end
  end

  test "belongs_to_enum should raise an runtime error if a value in the hash is not a symbol or a hash" do
    assert_raise RuntimeError do
      Task.belongs_to_enum :status, {1 => 100}
    end
  end

  test "belongs_to_enum should base the position from the id if it is not provided" do
    status = Task.status(1)
    assert_equal 1, status.position
  end

  test "belongs_to_enum should base the display name from the name if it is not provided" do
    status = Task.status(:completed)
    assert_equal 'Completed', status.title
  end

  test "belongs_to_enum should set the position it is provided" do
    status = Task.status(:completed)
    assert_equal 300, status.position
  end

  test "belongs_to_enum should set the display name if it is provided" do
    status = Task.status(:cancelled)
    assert_equal 'Ended', status.title
  end

  test "I can set the status by EnumField object or by name" do
    task = Task.new(:status => Task.status(:new))
    assert_equal :new, task.status.name

    task.status = :completed
    assert_equal :completed, task.status.name

    task.status = nil
    assert_nil task.status
    assert_nil task.status_id
  end

  test "task should not be valid if I set the status to a status that is not in the belongs_to_enum list" do
    task = Task.new(:status_id => 5)
    assert ! task.valid?
    assert_equal 1, task.errors.size
    assert_match 'is not valid', task.errors.full_messages[0]
  end

  test "I can check if task.<status.name>? is true" do
    task = Task.new(:status => :completed)
    assert task.completed?
    assert ! task.new?
  end

  test "The methods added by belongs_to_enum should work fine if task.status_id is nil" do
    task = Task.new
    assert_nil task.status_id
    assert_nil task.status
    assert ! task.new?
  end

  #-----------------------------------------------

  class Comment < ActiveRecord::Base
    belongs_to_enum :status,
    { 1 => :new,
      2 => {:name => :in_progress, :title => 'Continuing'},
      3 => {:name => :completed, :position => 300, :default => true},
      4 => {:name => :cancelled, :title => 'Ended', :position => 5, :default => true}
    }

    validates_inclusion_of_enum :status_id, :in => [3, :cancelled], :message => "must be completed or ended", :allow_blank => true
  end

  # Note: there are two defaults in comment. 
  test "I can get the Comment.default_status" do
    assert Comment.status(:cancelled).default?
    assert_equal Comment.status(:cancelled), Comment.default_status
  end

  test "I can change the validates_inclusion_of options in belongs_to_enum" do
    comment = Comment.new(:status => :cancelled)
    assert comment.valid?

    comment = Comment.new(:status_id => '')
    assert comment.valid?
    
    comment = Comment.new(:status => :new)
    assert ! comment.valid?
    assert_equal 1, comment.errors.size
    assert_match 'must be completed or ended', comment.errors.full_messages[0]
  end

  #-----------------------------------------------

  class Status < ActiveRecord::Base
    has_many :posts
    acts_as_enum_field

    def inspect
      inspect_attributes :id, :name, :title, :position, :default?
    end

    def inspect_attributes(*attributes)
      "#{self.class.name.demodulize}(" + attributes.collect{|a| "#{a}: #{self.send(a).inspect}"}.join(', ') + ")"
    end
  end

  Status.create :name => 'new'
  Status.create :name => 'in_progress', :title => 'Continuing'
  Status.create :name => 'completed', :position => 300, :default => true
  Status.create :name => 'cancelled', :title => 'Ended', :position => 5

  class Post < ActiveRecord::Base
    belongs_to_enum :status
    validates_inclusion_of_enum :status_id, { :in => [:completed, :cancelled], :message => "must be completed or ended", :allow_blank => true}
  end

  test "using belongs_to_enum with an active record should not explode" do
    assert_equal 4, Post.statuses.size
    
    assert_equal :in_progress, Post.status(:in_progress).name
    assert_equal 300, Post.default_status.position

    post = Post.new

    post.status = :in_progress
    assert ! post.new?
    assert post.in_progress?

    assert ! post.valid?
    assert_equal 1, post.errors.size
    assert_match 'must be completed or ended', post.errors.full_messages[0]
  end
end
