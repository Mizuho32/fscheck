require 'test/unit'
require 'pp'

require_relative '../src/lib/types'

#Dir.chdir "test/"

class ChunkedSuperBlock_Test < Test::Unit::TestCase

  class << self
    attr_reader :fs, :bl
    def startup 
      @fs = FileSystem.new(image: [*0...28*2].pack("C*"), block_size: 28*2)
      @bl = FileSystem::ChunkedBlock.new(fs: fs, klass: FileSystem::SuperBlockChunk)
    end
    
    def shutdown
    end
  end
  
  test "super chunked block test" do
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

    puts "Blocck[0] Tset... "
    assert_equal(0x03020100, ChunkedSuperBlock_Test.bl[0].size)
    ChunkedSuperBlock_Test.bl[0].size        = assigs[0]

    assert_equal(0x07060504, ChunkedSuperBlock_Test.bl[0].nblocks)
    ChunkedSuperBlock_Test.bl[0].nblocks     = assigs[1]

    assert_equal(0x0B0A0908, ChunkedSuperBlock_Test.bl[0].ninodes)
    ChunkedSuperBlock_Test.bl[0].ninodes     = assigs[2]

    assert_equal(0x0F0E0D0C, ChunkedSuperBlock_Test.bl[0].nlog)
    ChunkedSuperBlock_Test.bl[0].nlog        = assigs[3]

    assert_equal(0x13121110, ChunkedSuperBlock_Test.bl[0].logstart)
    ChunkedSuperBlock_Test.bl[0].logstart    = assigs[4]

    assert_equal(0x17161514, ChunkedSuperBlock_Test.bl[0].inodestart)
    ChunkedSuperBlock_Test.bl[0].inodestart  = assigs[5]

    assert_equal(0x1B1A1918, ChunkedSuperBlock_Test.bl[0].bmapstart)
    ChunkedSuperBlock_Test.bl[0].bmapstart   = assigs[6]


    puts "Blocck[1] Tset... "
    assert_equal(0x1F1E1D1C, ChunkedSuperBlock_Test.bl[1].size)
    ChunkedSuperBlock_Test.bl[1].size        = assigs[7]

    assert_equal(0x23222120, ChunkedSuperBlock_Test.bl[1].nblocks)
    ChunkedSuperBlock_Test.bl[1].nblocks     = assigs[8]

    assert_equal(0x27262524, ChunkedSuperBlock_Test.bl[1].ninodes)
    ChunkedSuperBlock_Test.bl[1].ninodes     = assigs[9]

    assert_equal(0x2B2A2928, ChunkedSuperBlock_Test.bl[1].nlog)
    ChunkedSuperBlock_Test.bl[1].nlog        = assigs[10]

    assert_equal(0x2F2E2D2C, ChunkedSuperBlock_Test.bl[1].logstart)
    ChunkedSuperBlock_Test.bl[1].logstart    = assigs[11]

    assert_equal(0x33323130, ChunkedSuperBlock_Test.bl[1].inodestart)
    ChunkedSuperBlock_Test.bl[1].inodestart  = assigs[12]

    assert_equal(0x37363534, ChunkedSuperBlock_Test.bl[1].bmapstart)
    ChunkedSuperBlock_Test.bl[1].bmapstart   = assigs[13]


    expeted_image = assigs.pack("I14")
    assert_equal(expeted_image, ChunkedSuperBlock_Test.fs.image)
    #p "", Chunk_Test.fs.image[0...28]
  end

end
