unless $DEBUG
require_relative 'block'
require_relative 'chunk'
require_relative 'superblock'
require_relative 'inodeblock'
require_relative 'directory'
else
load 'block.rb'
load 'chunk.rb'
load 'superblock.rb'
load 'inodeblock.rb'
load 'directory.rb'
end

class FileSystem

  attr_accessor :image, :block_size, :blocks, :size_block

  def initialize(image: nil, block_size: 512)
    @image = image
    @block_size = block_size
    @blocks = []
  end

  #SIZE_BLOCK = { superblock: 1..1, inodeblock: 32..57 }
  def self.load_xv6_fs(fsimg: nil, definition: nil, block_size: 512)
    fs = FileSystem.new(image: fsimg, block_size: block_size)
    fs.size_block = definition

    fs.blocks[ definition[:superblock] ] = FileSystem::ChunkedBlock.new(fs: fs, index: definition[:superblock].first, klass: FileSystem::SuperBlockChunk)
    definition[:inodeblock].each{|i|
      fs.blocks[i] = FileSystem::ChunkedBlock.new(fs: fs, index: i, klass: FileSystem::DinodeBlockChunk)
    }

    fs
  end

  def superblock
    @blocks[@size_block[:superblock]]
  end

  def inodeblock
    @blocks[@size_block[:inodeblock]]
  end

  def inodeblocks
    inodeblk = inodeblock()
    @inodeblocks = @inodeblocks || Enumerator.new{|chunk|
      (0...26).each do |block_index|
        (0...8).each { |inode_index|
          chunk << inodeblk[block_index][inode_index]
        }
      end
    }
  end

  def bitmapblock
    bitmap = self.[](58)
    @bitmapblock = @bitmapblock || Enumerator.new{|bit|
      (0...512).each do |byte_index|
        (0...8).each{|bit_shift|
          bit << ( (bitmap[byte_index]>>bit_shift)&1 )
        }
      end
    }
  end

  def [](i)
    cur = @blocks[i]

    if Range === i then
      any_nil = cur.any?(&:nil?)
      raise Exception.new("Unable to access chunked block") if(@size_block.values.any?{|r| r.include?(i.max) || r.include?(i.min) } && any_nil)
      if any_nil then
        cur.each_with_index.each{|el, cur_i| @blocks[idx=(cur_i + i.first)] = FileSystem::Block.new(fs: self, index: idx) if el.nil?
        }
        return @blocks[i]
      else
        return cur
      end
    end

    raise Exception.new("Unable to access chunked block") if(@size_block.values.any?{|r| r.include?(i) } && cur.nil?)

    cur = @blocks[i] = FileSystem::Block.new(fs: self, index: i) if cur.nil?
    cur
  end


end
