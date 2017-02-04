require 'test/unit'
require 'pp'

#require_relative 'types'
load 'types.rb'
load 'report.rb'

$fs = FileSystem.load_xv6_fs(fsimg: $image, block_size: 512, definition: {superblock: 1..1, inodeblock: 32..57})

module MainTest
  Report.puts "############## Main test ##############\n", :cyan

#=begin
  class A_SuperBlock_Test < Test::Unit::TestCase

    class << self
      def startup 
        Report.puts """

  ##############################
  # Super Block Coherence Test #
  ##############################

""", :cyan
      end
      
      def shutdown
      end
    end
    
    test "superblock size Test" do
      Report.puts "\nSuperblock: size test ", :yellow

      assert_equal(1000, $fs.superblock[0][0].size)

      Report.puts "\nSuperblock: size OK", :green
    end

    test "superblock nblocks Test" do
      Report.puts "\nSuperblock: nblocks test", :yellow

      assert_equal(941, $fs.superblock[0][0].nblocks)

      Report.puts "\nSuperblock: nblocks OK", :green
    end

    test "superblock  ninodes Test" do
      Report.puts "\nSuperblock: ninodes test", :yellow

      assert_equal(200, $fs.superblock[0][0].ninodes)

      Report.puts "\nSuperblock: ninodes OK", :green
    end

    test "superblock nlog Test" do
      Report.puts "\nSuperblock: nlog test", :yellow

      assert_equal(30, $fs.superblock[0][0].nlog)

      Report.puts "\nSuperblock: nlog OK", :green
    end

    test "superblock logstart Test" do
      Report.puts "\nSuperblock: logstart test", :yellow

      assert_equal(2, $fs.superblock[0][0].logstart)

      Report.puts "\nSuperblock: logstart OK", :green
    end

    test "superblock inodestart Test" do
      Report.puts "\nSuperblock: inodestart test", :yellow

      assert_equal(32, $fs.superblock[0][0].inodestart)

      Report.puts "\nSuperblock: inodestart OK", :green
    end

    test "superblock bmapstart Test" do
      Report.puts "\nSuperblock: bmapstart test", :yellow

      assert_equal(58, $fs.superblock[0][0].bmapstart)

      Report.puts "\nSuperblock: bmapstart OK", :green
    end

  end


#=end

#=begin
  class B_BlockUse_Test < Test::Unit::TestCase
    self.test_order = :defined

    class << self

      def startup 
        Report.puts """

  ######################################
  # Block Use and inode Coherence Test #
  ######################################

""", :cyan
      end
      
      def shutdown
      end
    end


    test "bitmapblock: block use Test" do
      Report.puts "\nBitmapblock: test", :yellow

      used_from_inode = $fs.inodeblocks.map{|inode| inode.all_using_blocks }.flatten
      used_from_bitmap = Init.bitmap_use

      tests = [
        [used_from_bitmap-used_from_inode, "bitmap flagged but no use from inode" ], 
        [used_from_inode-used_from_bitmap, "used from inode but no bitmap flag" ]
      ].map{|(dif, msg)|
        if dif.empty? then
          true
        else
          Report.puts " Incoherent block#{dif} use, #{msg}. FAILED", :red
        end
      }
        
      assert_true( tests.all? )

      Report.puts "\nBitmapblock: OK", :green
    end

    test "inodeblock: used block must referenced from only one inode test" do
      Report.puts "\nInodeblock: duplicate block use test", :yellow

      dups = Init.used_from_inode
        .inject({}){|h,(k,v)| 
          v.each{|block| h[block] = (h[block]||[]) << k}
          h
        }
        .delete_if{|k,v| v.one?}
        .each{|block, inodes|
          Report.puts " block[#{block}] is used by inode#{inodes.map{|inode| inode.inode_index}}. FAILED", :red
        }
          
      assert_true( dups.empty? )
      Report.puts "\nInodeblock: no duplicate block use. OK", :green
    end

    test "inodeblock: type test" do
      Report.puts "\nInodeblock: type test", :yellow

      result = Init.used_from_inode.keys.map{|inode|
        type = inode.type
        inum = inode.inode_index
        unless 1 <= type && type <= 3 then
          Report.puts " type of inode[#{inum}] is #{type}. FAILED", :red
          next(false)
        end

        if type == FileSystem::DinodeBlockChunk::T_DEV then
          maj,min = inode.major, inode.minor
          if maj.zero? || min.zero? then
            Report.puts " major and minor of dev inode[#{inum}] is #{maj},#{min}. FAILED", :red
            next(false)
          end
        end
        true
      }

      assert_true( result.all? )
      Report.puts "\nInodeblock: type OK", :green
    end

    test "inodeblock: nlink test" do
      Report.puts "\nInodeblock: nlink test", :yellow
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
            Report.puts " nlink of dir inode[#{inode_index}] is #{nlink} but dir inode[#{inode_index}] referenced from #{linkednum}. FAILED", :red
          end
        else
          if linkednum.size == nlink then 
            true
          else
            Report.puts " nlink of inode[#{inode_index}] is #{nlink} but inode[#{inode_index}] referenced from #{linkednum}. FAILED", :red
          end
        end
      }

      assert_true(result.all?)
      Report.puts "\nInodeblock: nlink OK", :green
    end

    test "inodeblock: addrs and size test" do
      Report.puts "\nInodeblock: addrs and size test", :yellow

      result = Init.used_from_inode.map{|inode, addr|
        #puts inode.inode_index
        #p addr, addr.size,  inode.size/512
        ceil = (inode.size/512.0).ceil 
        if ceil ==  addr.size then
          Init.coherent_inodes[inode.inode_index] = true
        else
          Report.puts " For inode[#{inode.inode_index}], addrs size is #{addr.size} and CEIL(size/BSIZE) is #{ceil}. FAILED", :red
        end
      }

      assert_true(result.all?)
      Report.puts "\nInodeblock: addrs and size OK", :green
    end

  end
#=end

#=begin
  class C_Directory_Test < Test::Unit::TestCase
    self.test_order = :defined

    class << self
      def startup 
        Report.puts """

  ############################
  # Directory Coherence Test #
  ############################

""", :cyan
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
      Report.puts "\nDirectory: valid inode num referenced from directory test", :yellow

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
                Report.puts " invalid inode[#{file.inum}](filename: #{file.name}) referenced from inode[#{inode.inode_index}]. FAILED", :red
              end
            } 
          end
        }

      assert_true( result.flatten.all? )
      Report.puts "\nDirectory: valid inode num referenced from directory OK\n", :green
    end

    test "for root, valid . and .. test" do
      Report.puts "\nDirectory: for root, valid . and .. test", :yellow

      root = C_Directory_Test.dir_inodes.select{|i| i.inode_index == 1}.first
      files = root.all_addrs.inject([]){|o, addr| 
        o + FileSystem::ChunkedBlock.new(fs:$fs, index: addr, klass:FileSystem::DirectoryBlockChunk).select{|file| !file.inum.zero?} 
      }
      result = files.select{|file| file.name == ?. || file.name == ".."}.map{|file|
        inum = file.inum
        if root.inode_index == inum then
          true
        else
          Report.puts " #{file.name} of inode[#{root.inode_index}] invalid. (points #{inum} but #{root.inode_index} expected). FAILED", :red
        end
      }
      
      assert_true( result.all? )
      Report.puts "\nDirectory: For root, valid . and .. OK\n", :green
    end

    test "for nonroots, valid . and .. test" do
      Report.puts "\nDirectory: for nonroots, valid . and .. test", :yellow

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
              Report.puts " . of inode[#{dir.inode_index}] invalid. (points #{inum} but #{dir.inode_index} expected. FAILED.", :red
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
              Report.puts " .. of inode[#{dir.inode_index}] invalid. (points #{inum} but inode[#{inum}] doesnt include me(inode[#{dir.inode_index}]). FAILED", :red
            end
          end
        }.all?
      }

      assert_true(result.all?)
      Report.puts "\nDirectory: For nonroots, valid . and .. OK\n", :green
      end

    test "A directory referenced from parent and child's .. test" do
      Report.puts "\nDirectory: A directory referenced from parent and child's .. test", :yellow

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
          Report.puts " None of parent, children, current inode(inode[#{diff.map{|i|i.inode_index}.join(", ")}]) points me(inode[#{inode.inode_index}]). FAILED", :red
        end
      }
        
      #p refed_refs_pair

      assert_true(result.all?)
      Report.puts "\nDirectory: A directory referenced from parent and child's ..  OK\n", :green
    end

    test ". not counted test" do
      Report.puts "\nDirectory: . not counted test", :yellow

      result = C_Directory_Test.dir_inodes.map{|inode|
        chi = C_Directory_Test.tmp[:inode_child][inode].size
        diff = (inode.nlink-1) - chi
        if diff.zero? then
          true
        elsif diff > 0
          Report.puts " nlink of inode[#{inode.inode_index}] too many. (#{inode.nlink} nlink, 1 parent and #{chi} children) FAILED", :red
        else # diff < 0
          Report.puts " nlink of inode[#{inode.inode_index}] too few. (#{inode.nlink} nlink, 1 parent and #{chi} children)FAILED", :red
        end
      }

      assert_true(result.all?)
      Report.puts "\nDirectory: . not counted OK\n", :green
    end

  end
#=end



end # module

class Init
  class << Init

    def init
      # correct bits
      @bitmap_use = $fs.bitmapblock.each_with_index
        .select{|bit, index| bit == 1 && index > 58}
        .map{|bit, index| index}

      # inode 
      @used_from_inode = $fs.inodeblocks.inject({}){|o, inode|
          next(o) if inode.type.zero?
          o[inode] = inode.all_addrs
          o
      }

      # dir init
      @used_from_inode.keys
        .select{|inode| inode.type == FileSystem::DinodeBlockChunk::T_DIR}
        .each{|inode| 
          inode.all_addrs.each do |block_index|
            $fs.blocks[block_index] = FileSystem::ChunkedBlock.new(fs: $fs, index: block_index, klass:FileSystem::DirectoryBlockChunk)
          end
        }
      @coherent_inodes = []
    end
    attr_reader :bitmap_use, :used_from_inode, :coherent_inodes

  end
end

Init.init()
Report.init()
Test::Unit::AutoRunner.run
Report.report()
