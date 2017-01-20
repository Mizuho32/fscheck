require 'test/unit'
require 'pp'

require_relative '../src/lib/types'

#Dir.chdir "test/"

class Block_Test < Test::Unit::TestCase

  class << self
    attr_reader :fs, :bl0, :bl2
    def startup
      @fs = FileSystem.new(image: "0"*(512*3))
      @bl0 = FileSystem::Block.new(fs: fs)
      @bl2 = FileSystem::Block.new(fs: fs, index: 2)
    end
    
    def shutdown
    end
  end
  
  test "base value test" do
    assert_equal(0, Block_Test.bl0.base)
    assert_equal(512*2, Block_Test.bl2.base)
  end

  test "check_range ok test" do
    range0,size0 = Block_Test.bl0.send(:check_range, 0..-1)
    range2,size2 = Block_Test.bl2.send(:check_range, 2)

    assert_equal(0..511, range0)
    assert_equal(1026..1026, range2)

    assert_equal(512, size0)
    assert_equal(1, size2)
  end

  test "check_range failure test" do
    assert_raise(Exception, "index type Error"){
      Block_Test.bl0.send(:check_range, nil)
    }

    assert_raise(Exception, "Index Range Error of Block"){
      Block_Test.bl0.send(:check_range, -1..4)
    }

    assert_raise(Exception, "Index out of Block range"){
      Block_Test.bl0.send(:check_range, 0..513)
    }

    assert_raise(Exception, "Index out of Block range"){
      Block_Test.bl0.send(:check_range, 0..-513)
    }
  end

  test "little_bytes test" do
    num = 0x123456
    assert_equal( [0x56, 0x34, 0x12], tmp = Block_Test.bl0.send(:little_bytes, *[num, 3]) )
    assert_equal( 0x123456, Block_Test.bl0.send(:little2num, tmp) )
  end

end
