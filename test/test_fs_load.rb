require 'test/unit'
require 'pp'

require_relative '../src/lib/types'

#Dir.chdir "test/"
class LoadFS_Test < Test::Unit::TestCase

  class << self
    attr_reader :fs
    def startup 
      image = [1000, 941, 200, 30, 2, 32, 58] + [0]*(64-28) + [*1..64] + [*65..128]
      @fs = FileSystem.load_xv6_fs(fsimg: image.pack("I7C*"), block_size: 64, definition: {superblock: 0..0, inodeblock: 1..2})
    end
    
    def shutdown
    end
  end
  
  test "load fs superblock test" do
    assert_equal(1000, LoadFS_Test.fs.superblock[0][0].size)
    assert_equal(941, LoadFS_Test.fs.superblock[0][0].nblocks)
    assert_equal(200, LoadFS_Test.fs.superblock[0][0].ninodes)
    assert_equal(30, LoadFS_Test.fs.superblock[0][0].nlog)
    assert_equal(2, LoadFS_Test.fs.superblock[0][0].logstart)
    assert_equal(32, LoadFS_Test.fs.superblock[0][0].inodestart)
    assert_equal(58, LoadFS_Test.fs.superblock[0][0].bmapstart)
  end


  test "load fs inodeblock1 test" do
    #p LoadFS_Test.fs.inodeblock[0].raw
    #p LoadFS_Test.fs.inodeblock[0][0].chunk_size
    #p LoadFS_Test.fs.inodeblock[0][0].raw
    #p LoadFS_Test.fs.inodeblock[0][0].addrs
    assert_equal(0x0201, LoadFS_Test.fs.inodeblock[0][0].type)
    assert_equal(0x4241, LoadFS_Test.fs.inodeblock[1][0].type)
  end

end
