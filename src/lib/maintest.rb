require 'test/unit'
require 'pp'

#require_relative 'types'
load 'types.rb'

module MainTest
  puts "############## Main test ##############",""


  $fs = FileSystem.load_xv6_fs(fsimg: $image, block_size: 512, definition: {superblock: 1..1, inodeblock: 32..57})


#=begin
  class SuperBlock_Test < Test::Unit::TestCase

    class << self
      def startup 
        puts <<-"TEST"
\e[96m
  ##############################
  # Super Block Coherence Test #
  ##############################
\e[0m
  TEST
      end
      
      def shutdown
      end
    end
    
    test "superblock size Test" do
      assert_equal(1000, $fs.superblock[0][0].size)
      puts "\n\e[92mSuperblock size: OK\e[0m"
    end

    test "superblock nblocks Test" do
      assert_equal(941, $fs.superblock[0][0].nblocks)
      puts "\n\e[92mNblocks: OK\e[0m"
    end

    test "superblock  ninodes Test" do
      assert_equal(200, $fs.superblock[0][0].ninodes)
    end

    test "superblock nlog Test" do
      assert_equal(30, $fs.superblock[0][0].nlog)
    end

    test "superblock logstart Test" do
      assert_equal(2, $fs.superblock[0][0].logstart)
    end

    test "superblock inodestart Test" do
      assert_equal(32, $fs.superblock[0][0].inodestart)
    end

    test "superblock bmapstart Test" do
      assert_equal(58, $fs.superblock[0][0].bmapstart)
    end

  end


#=end

  class BlockUse_Test < Test::Unit::TestCase
    self.test_order = :defined

    class << self
      def useds(byte, base)
        (0..7).select{|i| (byte>>i)&1 == 1}.map{|i| i + base}
      end

      def startup 
        puts <<-"TEST"
\e[96m
############################
# Block Use Coherence Test #
############################
\e[0m
  TEST
        # correct bits
        @bitmap_use = (7...512).inject([]){|o, i|  o + useds($fs[58][i], i*8)}
        (56..58).each{|i| @bitmap_use.delete i}
        # inode 
        @used_from_inode = (0...26).inject([]){|o, block_index| 
          (0...8).inject(o) do |o, chunk_index|
            next(o) if (type = $fs.inodeblock[block_index][chunk_index].type).zero?
            addrs = $fs.inodeblock[block_index][chunk_index].addrs
            indirect = unless (tail = addrs[12]).zero? then
              puts "#{tail} type#{type} inode_index#{block_index*8+chunk_index}"
              $fs[tail][0..511, unpack:"I*"].select{|i| !i.zero? }
            else
              []
            end
            if type==FileSystem::DinodeBlockChunk::T_DIR then # file name
              #p addrs
              (0...32).each{|i| 
                b = i*16
                next if (inum = $fs[addrs[0]][b..b+1, unpack:"S"].first).zero?
                puts "#{inum} #{$fs[addrs[0]][b+2..b+15, unpack:"a*"].first.strip}"
              }
            end
            #p indirect
            o + addrs.select{|i| !i.zero? } + indirect
          end
        }
      end
      attr_reader :bitmap_use, :used_from_inode
      
      def shutdown
      end
    end


    test "bitmapblock: block use Test" do
      assert_true( (BlockUse_Test.bitmap_use-BlockUse_Test.used_from_inode).empty? )
      assert_true( (BlockUse_Test.used_from_inode-BlockUse_Test.bitmap_use).empty? )

      puts "\n\e[92mBitmapblock: OK\e[0m"
    end

    test "inodeblock: used block must referenced from only one inode" do
      assert_true( BlockUse_Test.used_from_inode.group_by{|i| i}.delete_if{|k,v| v.one?}.keys.empty? )
      puts "\n\e[92mInodebock: OK\e[0m"
    end

  end
end
Test::Unit::AutoRunner.run
