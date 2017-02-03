require 'test/unit'
require 'pp'

#require_relative 'types'
load 'types.rb'

$fs = FileSystem.load_xv6_fs(fsimg: $image, block_size: 512, definition: {superblock: 1..1, inodeblock: 32..57})

module MainTest
  puts "\e[96m############## Main test ##############\e[0m",""

#=begin
  class A_SuperBlock_Test < Test::Unit::TestCase

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
      puts "\n\e[93mSuperblock: size test \e[0m"

      assert_equal(1000, $fs.superblock[0][0].size)

      puts "\n\e[92mSuperblock: size OK\e[0m"
    end

    test "superblock nblocks Test" do
      puts "\n\e[93mSuperblock: nblocks test\e[0m"

      assert_equal(941, $fs.superblock[0][0].nblocks)

      puts "\n\e[92mSuperblock: nblocks OK\e[0m"
    end

    test "superblock  ninodes Test" do
      puts "\n\e[93mSuperblock: ninodes test\e[0m"

      assert_equal(200, $fs.superblock[0][0].ninodes)

      puts "\n\e[92mSuperblock: ninodes OK\e[0m"
    end

    test "superblock nlog Test" do
      puts "\n\e[93mSuperblock: nlog test\e[0m"

      assert_equal(30, $fs.superblock[0][0].nlog)

      puts "\n\e[92mSuperblock: nlog OK\e[0m"
    end

    test "superblock logstart Test" do
      puts "\n\e[93mSuperblock: logstart test\e[0m"

      assert_equal(2, $fs.superblock[0][0].logstart)

      puts "\n\e[92mSuperblock: logstart OK\e[0m"
    end

    test "superblock inodestart Test" do
      puts "\n\e[93mSuperblock: inodestart test\e[0m"

      assert_equal(32, $fs.superblock[0][0].inodestart)

      puts "\n\e[92mSuperblock: inodestart OK\e[0m"
    end

    test "superblock bmapstart Test" do
      puts "\n\e[93mSuperblock: bmapstart test\e[0m"

      assert_equal(58, $fs.superblock[0][0].bmapstart)

      puts "\n\e[92mSuperblock: bmapstart OK\e[0m"
    end

  end


#=end

  class B_BlockUse_Test < Test::Unit::TestCase
    self.test_order = :defined

    class << self

      def startup 
        puts <<-"TEST"
\e[96m
  ######################################
  # Block Use and inode Coherence Test #
  ######################################
\e[0m
  TEST
      end
      
      def shutdown
      end
    end


#=begin
    test "bitmapblock: block use Test" do
      puts "\n\e[93mBitmapblock: test\e[0m"

      used_from_inode = $fs.inodeblocks.map{|inode| inode.all_using_blocks }.flatten
      used_from_bitmap = Init.bitmap_use

      tests = [
        [used_from_bitmap-used_from_inode, "bitmap flagged but no use from inode" ], 
        [used_from_inode-used_from_bitmap, "used from inode but no bitmap flag" ]
      ].map{|(dif, msg)|
        if dif.empty? then
          true
        else
          puts "\e[91m Incoherent block use, #{msg} block#{dif}. FAILED\e[0m"
        end
      }
        
      assert_true( tests.all? )

      puts "\n\e[92mBitmapblock: OK\e[0m"
    end
    test "inodeblock: used block must referenced from only one inode test" do
      puts "\n\e[93mInodeblock: use test\e[0m"
      assert_true( Init.used_from_inode.group_by{|i| i}.delete_if{|k,v| v.one?}.keys.empty? )
      puts "\n\e[92mInodeblock: use OK\e[0m"
    end

    test "inodeblock: type test" do
      puts "\n\e[93mInodeblock: type test\e[0m"

      result = Init.used_from_inode.keys.map{|inode|
        type = inode.type
        inum = inode.inode_index
        unless 1 <= type && type <= 3 then
          puts "\e[91m type of inode[#{inum}] is #{type}. FAILED\e[0m"
          next(false)
        end

        if type == FileSystem::DinodeBlockChunk::T_DEV then
          maj,min = inode.major, inode.minor
          if maj.zero? || min.zero? then
            puts "\e[91m major and minor of dev inode[#{inum}] is #{maj},#{min}. FAILED\e[0m"
            next(false)
          end
        end
        true
      }

      assert_true( result.all? )
      puts "\n\e[92mInodeblock: type OK\e[0m"
    end

    test "inodeblock: nlink test" do
      puts "\n\e[93mInodeblock: nlink test\e[0m"
      inum_to_linkednum = Init.used_from_inode.keys
        .select{|inode| inode.type == FileSystem::DinodeBlockChunk::T_DIR}
        .inject({}){|hash, inode| # inode that points dir
          #p inode.nlink, inode.addrs,inode.size
          inode_index = inode.inode_index
          inode.all_addrs.each{|ad|
              blk = FileSystem::ChunkedBlock.new(fs: $fs, index: ad, klass: FileSystem::DirectoryBlockChunk)
              blk
                .select{|file| !file.inum.zero?}
                .map{|file| file.inum}
                .each{|inum|
                  hash[inum] = (hash[inum]||[]) << inode_index
                }
          }
          hash
        }
      #p inum_to_linkednum
      #p $fs.inodeblock[0][1].size
      #Init.inodes.each{|inode| puts "#{inode.nlink} #{inode.type}"}

      result = inum_to_linkednum.map{|inode_index, linkednum|
        inode = $fs.inodeblock[inode_index/8][inode_index%8]
        nlink = inode.nlink
        if inode.type == FileSystem::DinodeBlockChunk::T_DIR then
          if linkednum.size - 1 == nlink then 
            true
          else
            puts "\e[91m nlink of dir inode[#{inode_index}] is #{nlink} but dir inode[#{inode_index}] referenced from #{linkednum}. FAILED\e[0m"
          end
        else
          if linkednum.size == nlink then 
            true
          else
            puts "\e[91m nlink of inode[#{inode_index}] is #{nlink} but inode[#{inode_index}] referenced from #{linkednum}. FAILED\e[0m"
          end
        end
      }

      assert_true(result.all?)
      puts "\n\e[92mInodeblock: nlink OK\e[0m"
    end
#=end
    test "inodeblock: addrs and size test" do
      puts "\n\e[93mInodeblock: addrs and size test\e[0m"

      result = Init.used_from_inode.map{|inode, addr|
        #puts inode.inode_index
        #p addr, addr.size,  inode.size/512
        ceil = (inode.size/512.0).ceil 
        if ceil ==  addr.size then
          Init.coherent_inodes[inode.inode_index] = true
        else
          puts "\e[91m For inode[#{inode.inode_index}], addrs size is #{addr.size} and CEIL(size/BSIZE) is #{ceil}. FAILED\e[0m"
        end
      }

      assert_true(result.all?)
      puts "\n\e[92mInodeblock: addrs and size OK\e[0m"
    end

  end

#=begin
  class C_Directory_Test < Test::Unit::TestCase
    self.test_order = :defined

    class << self
      def startup 
        puts <<-"TEST"
\e[96m
  ############################
  # Directory Coherence Test #
  ############################
\e[0m
TEST
        @dir_inodes = Init.used_from_inode.keys.select{|inode| inode.type == FileSystem::DinodeBlockChunk::T_DIR }
        @tmp = {}
      end
      
      def shutdown
      end

      attr_reader :dir_inodes, :tmp
    end

    def valid_inode?(num)
      Init.coherent_inodes[num]
    end

    test "valid inode num referenced from directory test" do
      puts "\n\e[93mDirectory: valid inode num referenced from directory test\e[0m"

        #.values
      result = Init.used_from_inode
        .select{|inode, addrs| inode.type == FileSystem::DinodeBlockChunk::T_DIR}
        .map{|inode, addrs| 
          addrs.map do |addr|
            files = FileSystem::ChunkedBlock.new(fs:$fs, index: addr, klass:FileSystem::DirectoryBlockChunk)
            files.select{|file| !file.inum.zero? }.map{|file| 
              if valid_inode?(file.inum) then
                true
              else
                puts "\e[91m invalid inode[#{file.inum}](filename: #{file.name}) referenced from inode[#{inode.inode_index}]. FAILED\e[0m"
              end
            } 
          end
        }

      assert_true( result.flatten.all? )
      puts "\n\e[92mDirectory: valid inode num referenced from directory OK\e[0m\n"
    end

    test "for root, valid . and .. test" do
      puts "\n\e[93mDirectory: for root, valid . and .. test\e[0m"

      root = C_Directory_Test.dir_inodes.select{|i| i.inode_index == 1}.first
      files = root.all_addrs.inject([]){|o, addr| 
        o + FileSystem::ChunkedBlock.new(fs:$fs, index: addr, klass:FileSystem::DirectoryBlockChunk).select{|file| !file.inum.zero?} 
      }
      result = files.select{|file| file.name == ?. || file.name == ".."}.map{|file|
        inum = file.inum
        if root.inode_index == inum then
          true
        else
          puts "\e[91m #{file.name} of inode[#{root.inode_index}] invalid. (points #{inum} but #{root.inode_index} expected). FAILED\e[0m"
        end
      }
      
      assert_true( result.all? )
      puts "\n\e[92mDirectory: For root, valid . and .. OK\e[0m\n"
    end

    test "for nonroots, valid . and .. test" do
      puts "\n\e[93mDirectory: for nonroots, valid . and .. test\e[0m"

      nonroots = C_Directory_Test.dir_inodes.select{|i| i.inode_index != 1}
      result = nonroots.map{|dir|

        dots = dir.all_addrs.inject([]){|o, addr| 
            o + FileSystem::ChunkedBlock.new(fs:$fs, index: addr, klass:FileSystem::DirectoryBlockChunk).select{|file| !file.inum.zero?}
          }
          .select{|file| file.name == ?. || file.name == ".."}

        dots.map{|dot|
          inum = dot.inum
          if dot.name == ?. then
            if inum == dir.inode_index then
              true
            else
              puts "\e[91m . of inode[#{dir.inode_index}] invalid. (points #{inum} but #{dir.inode_index} expected. FAILED.\e[0m"
            end
          else
            parents_childs = $fs.inodeblock[inum/8][inum%8]
              .all_addrs
              .select{|a| !a.zero?}
              .map{|a| FileSystem::ChunkedBlock.new(fs: $fs, index: a, klass: FileSystem::DirectoryBlockChunk)}
            parent_includes_me = parents_childs.any?{|bl| bl.any?{|file| file.inum == dir.inode_index}}
            if parent_includes_me then
              true
            else
              puts "\e[91m .. of inode[#{dir.inode_index}] invalid. (points #{inum} but inode[#{inum}] doesnt include me(inode[#{dir.inode_index}]). FAILED\e[0m"
            end
          end
        }.all?
      }

      assert_true(result.all?)
      puts "\n\e[92mDirectory: For nonroots, valid . and .. OK\e[0m\n"
      end

    test "A directory referenced from parent and child's .. test" do
      puts "\n\e[93mDirectory: A directory referenced from parent and child's .. test\e[0m"

      # { .. => [inodes] }
      #dotdot_points_inodes = Directory_Test.dir_inodes.group_by{|inode|
        #$fs[inode.addrs[0]].raw.unpack("x2x14S").first
      #}
      # { childdir => [parentdirs] }
      #childir_to_paredir = Directory_Test.dir_inodes.group_by{|inode|
        #$fs[inode.addrs[0]].raw.unpack("x2x14S").first
      #}
      inum_dir_pair = C_Directory_Test.dir_inodes.inject({}){|ar,inode| ar[inode.inode_index] = inode; ar}
      refed_refs_pair = C_Directory_Test.dir_inodes.inject({}){|h, inode|
        #refed_dirs.each
        inode.all_addrs
          .select{|addr| !addr.zero?}
          .map{|addr| FileSystem::ChunkedBlock.new(fs:$fs, index: addr, klass:FileSystem::DirectoryBlockChunk)}
          .inject([]){|ar, bl| ar + bl.map{|file| inum_dir_pair[file.inum]}.compact }
          .each{|refed_inode|
            h[refed_inode] = (h[refed_inode]||[]) << inode
          }
        h
      }

      C_Directory_Test.tmp[:inode_child] = {}
      result = C_Directory_Test.dir_inodes.map{|inode|
        parent = $fs[inode.addrs[0]].raw.unpack("x2x14S").first # parent inum
        children = inode.all_addrs
          .select{|addr| !addr.zero?}
          .map{|addr| FileSystem::ChunkedBlock.new(fs:$fs, index: addr, klass:FileSystem::DirectoryBlockChunk)}
          .inject([]){|ar, bl| 
            ar + bl.select{|file| 
              name=file.name; inum_dir_pair[file.inum] && name != ?. && name != ".."
            }.map{|file| file.inum }
          }
        current = inode.inode_index
        family = [parent, current]+children

        C_Directory_Test.tmp[:inode_child][inode] = children
        
        refs = refed_refs_pair[inode]
        diff = refs.delete_if{|inode| family.include?(inode.inode_index)}

        if diff.empty? then
          true
        else
          puts "\e[91m None of parent, children, current inode(inode[#{diff.map{|i|i.inode_index}.join(", ")}]) points me(inode[#{inode.inode_index}]). FAILED\e[0m"
        end
      }
        
      #p refed_refs_pair

      assert_true(result.all?)
      puts "\n\e[92mDirectory: A directory referenced from parent and child's ..  OK\e[0m\n"
    end

    test ". not counted test" do
      puts "\n\e[93mDirectory: . not counted test\e[0m"

      result = C_Directory_Test.dir_inodes.map{|inode|
        chi = C_Directory_Test.tmp[:inode_child][inode].size
        diff = (inode.nlink-1) - chi
        if diff.zero? then
          true
        elsif diff > 0
          puts "\e[91m nlink of inode[#{inode.inode_index}] too many. (#{inode.nlink} nlink, 1 parent and #{chi} children) FAILED\e[0m"
        else # diff < 0
          puts "\e[91m nlink of inode[#{inode.inode_index}] too few. (#{inode.nlink} nlink, 1 parent and #{chi} children)FAILED\e[0m"
        end
      }

      assert_true(result.all?)
      puts "\n\e[92mDirectory: . not counted OK\e[0m\n"
    end

  end
#=end



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
      @used_from_inode = $fs.inodeblocks.inject({}){|o, inode|
          next(o) if inode.type.zero?
          o[inode] = inode.all_addrs
          o
      }
      @coherent_inodes = []
    end
    attr_reader :bitmap_use, :used_from_inode, :coherent_inodes
  end
end

Init.init()
Test::Unit::AutoRunner.run
