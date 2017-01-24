require 'test/unit'
require 'pp'

#require_relative 'types'
load 'types.rb'

$fs = FileSystem.load_xv6_fs(fsimg: $image, block_size: 512, definition: {superblock: 1..1, inodeblock: 32..57})

module MainTest
  puts "############## Main test ##############",""

=begin
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


=end

  class BlockUse_Test < Test::Unit::TestCase
    self.test_order = :defined

    class << self

      def startup 
        puts <<-"TEST"
\e[96m
  ############################
  # Block Use Coherence Test #
  ############################
\e[0m
  TEST
      end
      
      def shutdown
      end
    end


=begin
    test "bitmapblock: block use Test" do
      used_from_inode = Init.used_from_inode.values.flatten + Init.tails_of_addrs
      used_from_bitmap = Init.bitmap_use

      assert_true( (used_from_bitmap-used_from_inode).empty? )
      assert_true( (used_from_inode-used_from_bitmap).empty? )

      puts "\n\e[92mBitmapblock: OK\e[0m"
    end
    test "inodeblock: used block must referenced from only one inode test" do
      assert_true( Init.used_from_inode.group_by{|i| i}.delete_if{|k,v| v.one?}.keys.empty? )
      puts "\n\e[92mInodeblock use OK\e[0m"
    end

    test "inodeblock: type test" do
      Init.used_from_inode.keys.each{|inode|
        type = inode.type
        assert_true(1 <= type && type <= 3)

        if type == FileSystem::DinodeBlockChunk::T_DEV then
          assert_true(!inode.major.zero?)
          assert_true(!inode.minor.zero?)
        end
      }

      puts "\n\e[92mInodeblock type OK\e[0m"
    end

    test "inodeblock: nlink test" do
      inum_to_linkednum = Init.used_from_inode.keys
        .select{|inode| inode.type == FileSystem::DinodeBlockChunk::T_DIR}
        .inject({}){|hash, inode| # inode that points dir
          #p inode.nlink, inode.addrs,inode.size
          adds = inode.addrs[0...12].select{|ad| !ad.zero? } + if inode.addrs[12].zero? then
            []
          else
            $fs[addrs[12]][0..511, unpack: 'I*'].select{|ad| !ad.zero? }
          end
          inode_index = inode.index + (inode.block.index-32)*8
          adds.each{|ad|
              blk = FileSystem::ChunkedBlock.new(fs: $fs, index: ad, klass: FileSystem::DirectoryBlockChunk)
              (0...32)
                .select{|i| !blk[i].inum.zero?}
                .map{|i| blk[i].inum}
                .uniq # fixme?
                .each{|inum|
                  hash[inum] = (hash[inum]||[]) << inode_index
                }
            }
          hash
        }
      #p inum_to_linkednum
      #p $fs.inodeblock[0][1].size
      #Init.inodes.each{|inode| puts "#{inode.nlink} #{inode.type}"}

      inum_to_linkednum.each{|inode_index, linkednum|
        assert_equal( linkednum.size, $fs.inodeblock[inode_index/8][inode_index%8].nlink )
      }

      puts "\n\e[92mInodeblock nlink OK\e[0m"
    end
=end
    test "inodeblock: addrs and size test" do
      Init.used_from_inode.each{|inode, addr|
        #puts inode.inode_index
        #p addr, addr.size,  inode.size/512
        assert_equal((inode.size/512.0).ceil, addr.size)
        Init.coherent_inodes[inode.inode_index] = true
      }
      #puts $fs[60..64].map{|b| b[0..511, unpack: 'a*']}.join("\n"+"#"*20+"\n")
      puts "\n\e[92mInodeblock addrs and size OK\e[0m"
    end

  end

  class Directory_Test < Test::Unit::TestCase
    class << self
      def startup 
        puts <<-"TEST"
\e[96m
  ############################
  # Directory Coherence Test #
  ############################
\e[0m
TEST
      end
      
      def shutdown
      end
    end

    def valid_inode?(num)
      Init.coherent_inodes[num]
    end

    test "valid inode num referenced from directory test" do
      assert_true( 
        Init.used_from_inode
          .select{|inode, addrs| inode.type == FileSystem::DinodeBlockChunk::T_DIR}
          .values
          .all?{|addrs| 
            addrs.all? do |addr|
              dirs = FileSystem::ChunkedBlock.new(fs:$fs, index: addr, klass:FileSystem::DirectoryBlockChunk)
              dirs.select{|dir| !dir.inum.zero? }.all?{|dir| valid_inode?(dir.inum) } 
            end
          }
      )
      puts "\n\e[92mDirectory: valid inode num referenced from directory test\e[0m"
    end
  end



end # module

class Init
  class << Init

    def useds(byte, base)
      (0..7).select{|i| (byte>>i)&1 == 1}.map{|i| i + base}
    end

    def init
      # correct bits
      @bitmap_use = (7...512).inject([]){|o, i|  o + useds($fs[58][i], i*8)}
      (56..58).each{|i| @bitmap_use.delete i}

      # inode 
      @tails_of_addrs = []
      @used_from_inode = (0...26).inject({}){|o, block_index| 
        (0...8).inject(o) do |o, inode_index|
          next(o) if (type = (inode=$fs.inodeblock[block_index][inode_index]).type).zero?
          addrs = inode.addrs
          indirect = unless (tail = addrs[12]).zero? then
            puts "#{tail} type#{type} inode_index#{block_index*8+inode_index}"
            $fs[tail][0..511, unpack:"I*"].select{|i| !i.zero? }
          else
            []
          end

          if type==FileSystem::DinodeBlockChunk::T_DIR then # file name
            puts "abs inode_index #{inode_index + block_index*8}"
            dir_block = FileSystem::ChunkedBlock.new(fs: $fs, index: addrs[0], klass: FileSystem::DirectoryBlockChunk)
            #p addrs
            (0...32).each{|i| 
              next if dir_block[i].inum.zero?
              puts "#{dir_block[i].inum} #{dir_block[i].name}"
            }
          end
          @tails_of_addrs << tail unless tail.zero?
          o[inode] = addrs[0...12].select{|i| !i.zero? } + indirect
          o
        end
      }

      @coherent_inodes = []
    end
    attr_reader :bitmap_use, :used_from_inode, :tails_of_addrs, :coherent_inodes
  end
end

Init.init()
Test::Unit::AutoRunner.run
