require 'test_helper'

class ActsAsEnumFieldTest < ActiveSupport::TestCase
  load_schema

  class Status < ActiveRecord::Base
    acts_as_enum_field
  end
  
  test "the acts_as_enum_fields should override the methods of the status" do
    s = Status.create(:id => 1, :name => 'new')
    assert s.acts_as_enum_field?
    assert_equal :new, s.name 
    assert_equal 'New', s.title
    assert_equal s.id, s.position
  end

  test "enum field can be extended to act as the enum field" do
    s = BelongsToEnum::EnumField.new(1, :new)
    assert s.acts_as_enum_field?
    assert_equal :new, s.name 
    assert_equal 'New', s.title
    assert_equal s.id, s.position
  end
end

