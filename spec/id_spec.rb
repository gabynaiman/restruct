require 'minitest_helper'

describe Restruct::Id do

  Id = Restruct::Id

  it 'Return the namespace' do
    id = Id.new 'foo'
    id.must_equal 'foo'
  end

  it 'Prepend the namespace' do
    id = Id.new 'foo'
    id['bar'].must_equal 'foo:bar'
  end

  it 'Work in more than one level' do
    id_1 = Id.new 'foo'
    id_2 = Id.new id_1['bar']
    id_2['baz'].must_equal 'foo:bar:baz'
  end

  it 'Be chainable' do
    Id['foo']['bar']['baz'].must_equal 'foo:bar:baz'
  end

  it 'Accept symbols' do
    id = Id.new :foo
    id[:bar].must_equal 'foo:bar'
  end

  it 'Accept numbers' do
    id = Id.new 'foo'
    id[3].must_equal 'foo:3'
  end

  it 'Split in sections' do
    id = Id.new(:foo)[:bar][:buz]
    id.sections.must_equal %w(foo bar buz)
  end

  it 'Customize separator' do
    id = Id.new('foo', '|')['bar']['buz']
    id.must_equal 'foo|bar|buz'
  end
  
end