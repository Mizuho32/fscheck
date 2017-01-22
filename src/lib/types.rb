class FileSystem

  attr_accessor :image, :block_size

  def initialize(image: nil, block_size: 512)
    @image = image
    @block_size = block_size
  end


  class Block
    SIZE_TYPE = {1=>?C, 2=>?S, 4=>?I, 8=>?Q}
    attr_reader :index, :base, :fs

    def initialize(fs:nil, index: 0)
      raise Exception.new("Block index out of fs size") if fs.image.size/fs.block_size <= index
      @fs = fs
      @index = index
      @base = fs.block_size * @index
    end

    def indexer(i, unpack: nil)
      range, size = check_range(i)

      unless unpack.nil? then
        return @fs.image[range].unpack(unpack)
      end

      if type = SIZE_TYPE[size]
        @fs.image[range].unpack(type).first
      else
        little2num( @fs.image[range].unpack(?C + size.to_s) )
      end
    end

    def indexer_asig(i, v)
      range, size = check_range(i)
      if type = SIZE_TYPE[size]
        @fs.image[range] = [v].pack(type)
      else
        @fs.image[range] = little_bytes(v, size).pack(?C + size.to_s)
      end
    end

    def [](i, unpack: nil) 
      indexer(i, unpack: unpack)
=begin
      range, size = check_range(i)

      unless unpack.nil? then
        return @fs.image[range].unpack(unpack)
      end

      if type = SIZE_TYPE[size]
        @fs.image[range].unpack(type).first
      else
        little2num( @fs.image[range].unpack(?C + size.to_s) )
      end
=end
    end

    def []=(i, v)
      indexer_asig(i, v)
=begin
      range, size = check_range(i)
      if type = SIZE_TYPE[size]
        @fs.image[range] = [v].pack(type)
      else
        @fs.image[range] = little_bytes(v, size).pack(?C + size.to_s)
      end
=end
    end

    private
    def check_range(i)
      if Numeric === i then
        pair = [i,i]
      elsif Range === i
        pair = [i.first, i.last]
      else
        raise Exception.new("Index type Error")
      end

      raise Exception.new("Index Range Error of Block") unless pair.map!{|e| 
        @base + if 0 <= e && e < @fs.block_size then
          e
        elsif -@fs.block_size <= e && e <= -1 then # ring
          @fs.block_size + e
        else
          raise Exception.new("Index out of Block range")
        end
      }.each_slice(2).all?{|e| e.first <= e.last}
      return Range.new(*pair), pair.last - pair.first + 1
    end

    def little_bytes(int, size)
      [*0...size].map{|e| (int >> (8*e)) & 0xFF }
    end

    def little2num(l)
      l.each_with_index.map{|e, i| e * 256**i}.inject(:+)
    end
  end

  class ChunkedBlock < Block
    def initialize(fs:nil, index: 0, klass: nil)
      raise Exception.new("Chunk type Error of ChunkedBlock") unless klass < FileSystem::Chunk
      @klass = klass

      super(fs:fs, index:index)
      @chunks = []
    end

    def [](i)
      cur = @chunks[i]
      cur = @chunks[i] = @klass.new(block: self, index: i) if cur.nil?
      cur
    end

  end

end


class FileSystem
  module Chunk
    class << Chunk
      def [](size:0, unpack:"")
        s = unless klasss[size]
          klasss[size] = {unpack=>nil} 
        else
          klasss[size]
        end

        if c = s[unpack] then
          c
        else
          newc = Class.new
          newc.send(:define_method, :initialize){|block: nil, index: 0|
              @size = size
              @unpack = unpack
              @block = block
              @index = index  # on block
              @base_on_block = index * @size
          }
          newc.send(:attr_reader, *[:size, :unpack, :block, :index, :base_on_block])
          newc.include(FileSystem::Chunk)
          s[unpack] = newc
          newc
        end
      end

      private
      attr_writer :klasss
      def klasss
        @klasss = {} unless defined? @klasss
        @klasss
      end
    end

    def to_onblock(f,l)
      (f+@base_on_block)..(l+@base_on_block)
    end

  end
end


class FileSystem

  class SuperBlockChunk  < FileSystem::Chunk[size: 28, unpack: "I7"]
    # initialize |block: nil, index: 0|

    _methods = %w[size nblocks ninodes nlog logstart inodestart bmapstart]
    (0...28).step(4).each{|s|
      define_method(_methods[s/4])do
        @block.indexer(to_onblock(s, s+3), unpack:?I).first
      end

      define_method(_methods[s/4] + ?=)do |v|
        @block.send(:indexer_asig, to_onblock(s, s+3),  v)
      end
    }

  end

end


