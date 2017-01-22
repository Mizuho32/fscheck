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

    assigs = [
      0x0000FF00,
      0x0000A0A0,
      0x0000D00D,
      0xAAAA0000,
      0xAAAA1111,
      0xAAAA2222,
      0xAAAA3333,

      0x12340000,
      0x0000CCCC,
      0x10100000,
      0x33001100,
      0xFF00FF00,
      0xABCDEF00,
      0x22002222
    ]
    assert_equal(0x03020100, ch0.size)
    ch0.size        = assigs[0]

    assert_equal(0x07060504, ch0.nblocks)
    ch0.nblocks     = assigs[1]

    assert_equal(0x0B0A0908, ch0.ninodes)
    ch0.ninodes     = assigs[2]

    assert_equal(0x0F0E0D0C, ch0.nlog)
    ch0.nlog        = assigs[3]

    assert_equal(0x13121110, ch0.logstart)
    ch0.logstart    = assigs[4]

    assert_equal(0x17161514, ch0.inodestart)
    ch0.inodestart  = assigs[5]

    assert_equal(0x1B1A1918, ch0.bmapstart)
    ch0.bmapstart   = assigs[6]


    assert_equal(0x1F1E1D1C, ch1.size)
    ch1.size        = assigs[7]

    assert_equal(0x23222120, ch1.nblocks)
    ch1.nblocks     = assigs[8]

    assert_equal(0x27262524, ch1.ninodes)
    ch1.ninodes     = assigs[9]

    assert_equal(0x2B2A2928, ch1.nlog)
    ch1.nlog        = assigs[10]

    assert_equal(0x2F2E2D2C, ch1.logstart)
    ch1.logstart    = assigs[11]

    assert_equal(0x33323130, ch1.inodestart)
    ch1.inodestart  = assigs[12]

    assert_equal(0x37363534, ch1.bmapstart)
    ch1.bmapstart   = assigs[13]


    expeted_image = assigs.pack("I14")
    assert_equal(expeted_image, Chunk_Test.fs.image)
    #p "", Chunk_Test.fs.image[0...28]
  end

end
