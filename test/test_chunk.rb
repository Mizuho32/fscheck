require 'test/unit'
require 'pp'

require_relative '../src/lib/types'

#Dir.chdir "test/"

class Chunk_Test < Test::Unit::TestCase

  class << self
    attr_reader :fs, :bl0, :bl2
    def startup 
      @fs = FileSystem.new(image: [*0...28*2].pack("C*"), block_size: 28*2)
      @bl0 = FileSystem::Block.new(fs: fs)
      #@bl1 = FileSystem::Block.new(fs: fs, index: 1)
    end
    
    def shutdown
    end
  end
  
  test "chunk parent generate test" do
    C = FileSystem::Chunk[size: 10, unpack:"hello"]
    C2 = FileSystem::Chunk[size: 10, unpack:"hello"]
    c = C.new(block: nil, index: 1)
    assert_equal(C.object_id, C2.object_id)
    assert_equal(10, c.size)
    assert_equal("hello", c.unpack)
    assert_nil(c.block)
    assert_equal(1, c.index)
    assert_equal(10, c.base_on_block)
  end

  test "chunk to_onblock test" do
    ch = FileSystem::SuperBlockChunk.new(block: Chunk_Test.bl0, index: 1)
    r = ch.to_onblock(0, 3)
    assert_equal(28..31, r)
  end

  test "super block chunk test" do
    ch0 = FileSystem::SuperBlockChunk.new(block: Chunk_Test.bl0, index: 0)
    ch1 = FileSystem::SuperBlockChunk.new(block: Chunk_Test.bl0, index: 1)

    assert_equal(0x1F1E1D1C, ch1.size)
    ch1.size = 1

    assert_equal(0x03020100, ch0.size)
    ch0.size = 0x0000FF00
    p Chunk_Test.fs.image
  end

end
