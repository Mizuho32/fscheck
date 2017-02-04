require 'test/unit'
require 'pp'

require_relative '../src/types'

#Dir.chdir "test/"

class Block_IO_Test < Test::Unit::TestCase

  class << self
    def startup
    end
    
    def shutdown
    end
  end

  def image
    [*0...32]
  end

  def setup
    @fs = FileSystem.new(image: image().pack("C*"), block_size: 8)
    @bl0 = FileSystem::Block.new(fs: @fs)
    @bl2 = FileSystem::Block.new(fs: @fs, index: 2)
  end

  test "single range access test" do
    # read
    assert_equal(0, @bl0[0])
    assert_equal(7, @bl0[7])
    assert_raise(Exception, "Index out of Block range"){
      @bl0[8]
    }
    assert_equal([7], @bl0[7, unpack:"C"])

    assert_equal(16, @bl2[0])
    assert_equal(23, @bl2[7])
    assert_raise(Exception, "Index out of Block range"){
      @bl2[8]
    }
    assert_equal([23], @bl2[7, unpack:"C"])

    # write
    img = image()

    @bl0[0] = 123
    @bl0[3] = 255
    @bl0[7] = 0
    img[0] = 123
    img[3] = 255
    img[7] = 0
    assert_equal(img.pack("C*"), @fs.image)

    @bl2[-1] = 255
    @bl2[4]  = 10
    @bl2[-8] = 0
    img[23] = 255
    img[20]  = 10
    img[16] = 0
    assert_equal(img.pack("C*"), @fs.image)
  end

  test "range read test" do
    # read
    assert_equal(             0x0100, @bl0[-8..1])
    assert_equal(         0x05040302, @bl0[2..-3])
    assert_equal( 0x0706050403020100, @bl0[0..7])
    assert_equal(           0x020100, @bl0[0..2])
    assert_raise(Exception, "Index out of Block range"){
      @bl0[0..8]
    }
    assert_equal(           [0x0706],     @bl0[-2..-1, unpack:"S"])
    assert_equal(           [0x06, 0x07], @bl0[-2..-1, unpack:"C2"])

    assert_equal(             0x1110, @bl2[-8..1])
    assert_equal(         0x15141312, @bl2[2..-3])
    assert_equal( 0x1716151413121110, @bl2[0..7])
    assert_equal(           0x171615, @bl2[-3..-1])
    assert_raise(Exception, "Index out of Block range"){
      @bl2[0..8]
    }
    assert_equal(           [0x1716],     @bl2[-2..-1, unpack:"S"])
    assert_equal(           [0x16, 0x17], @bl2[-2..-1, unpack:"C2"])
  end

  test "range write2 test" do
    img = image()
    @bl0[-8..1] = 0x1145
    img[0..1] = [0x45, 0x11]
    assert_equal(img.pack("C*"), @fs.image)
  end

  test "range write4 test" do
    img = image()
    @bl0[2..-3] = 0x11451419
    img[2..5] = [0x19, 0x14, 0x45, 0x11]
    assert_equal(img.pack("C*"), @fs.image)
  end

  test "range write8 test" do
    img = image()
    @bl0[0..7] = 0x11451419_19810931
    img[0..7] = [0x31, 0x09, 0x81, 0x19, 0x19, 0x14, 0x45, 0x11]
    assert_equal(img.pack("C*"), @fs.image)
  end

  test "range write3 test" do
    img = image()
    @bl0[0..2] = 0x114514
    img[0..2] = [0x14, 0x45, 0x11]
    assert_equal(img.pack("C*"), @fs.image)
  end


  test "range write2 2 test" do
    img = image()
    @bl2[-8..1] = 0x1145
    img[16..17] = [0x45, 0x11]
    assert_equal(img.pack("C*"), @fs.image)
  end

  test "range write4 2 test" do
    img = image()
    @bl2[2..-3] = 0x11451419
    img[18..21] = [0x19, 0x14, 0x45, 0x11]
    assert_equal(img.pack("C*"), @fs.image)
  end

  test "range write8 2 test" do
    img = image()
    @bl2[0..7] = 0x11451419_19810931
    img[16..23] = [0x31, 0x09, 0x81, 0x19, 0x19, 0x14, 0x45, 0x11]
    assert_equal(img.pack("C*"), @fs.image)
  end

  test "range write3 2 test" do
    img = image()
    @bl2[-3..-1] = 0x114514
    img[21..23] = [0x14, 0x45, 0x11]
    assert_equal(img.pack("C*"), @fs.image)
  end

  test "range write pack test" do
    @bl0[0..7, pack: 'S4'] = img = [0x1145, 0x8100, 0x9310, 0x1919]
    assert_equal(img.map{|e| [e].pack("s")}.join , @fs.image[0..7])
  end

  test "Block index out of fs size test" do
    assert_raise(Exception, "Block index out of fs size") do
      FileSystem::Block.new(fs: @fs, index: 4)
    end
  end

end
