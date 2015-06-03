require 'minitest_helper'

describe Restruct::Batch do

  let(:connection) { Redic.new }
  
  it 'Execute' do
    hash = Restruct::Hash.new connection: connection
    
    Restruct::Batch.execute do
      h = Restruct::Hash.new id: hash.id
      h.merge! a: 'x', b: 'y', c: 'z'
      
      hash.must_be_empty
    end

    hash.to_h.must_equal 'a' => 'x', 'b' => 'y', 'c' => 'z'
  end

  it 'Discard' do
    hash = Restruct::Hash.new connection: connection
    
    proc do
      Restruct::Batch.execute do
        h = Restruct::Hash.new id: hash.id
        h.merge! a: 'x', b: 'y', c: 'z'

        raise 'Test error'
      end
    end.must_raise RuntimeError

    hash.must_be_empty
  end

  it 'Nested' do
    hash = Restruct::Hash.new connection: connection
    
    Restruct::Batch.execute do
      h = Restruct::Hash.new id: hash.id
      h.merge! a: 'x', b: 'y'
      
      Restruct::Batch.execute do
        h[:c] = 'z'
        hash.must_be_empty
      end

      hash.must_be_empty
    end

    hash.to_h.must_equal 'a' => 'x', 'b' => 'y', 'c' => 'z'
  end

end