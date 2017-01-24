class FileSystem
  class Block
    SIZE_TYPE = {1=>?C, 2=>?S, 4=>?I, 8=>?Q}
    attr_reader :index, :base, :fs

    def initialize(fs:nil, index: 0)
      raise Exception.new("Block index out of fs size") if fs.image.size/fs.block_size <= index
      @fs = fs
      @index = index 
      @base = fs.block_size * @index
    end

    def raw
      @fs.image[@base..(@base+fs.block_size)]
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

    def indexer_asig(i, v, pack: nil)
      range, size = check_range(i)

      unless pack.nil? then
        @fs.image[range] = v.pack(pack)
        return
      end

      if type = SIZE_TYPE[size]
        @fs.image[range] = [v].pack(type)
      else
        @fs.image[range] = little_bytes(v, size).pack(?C + size.to_s)
      end
    end

    def [](i, unpack: nil) 
      indexer(i, unpack: unpack)
    end

    def []=(*i, v)
      if i.size == 1 then
        indexer_asig(*i, v)
      else
        indexer_asig(i.first, v, pack: i.last[:pack])
      end
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
          raise Exception.new("Index out of Block range: #{e}")
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
    include Enumerable

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

    def each(&block)
      (0...512/@klass.chunk_size).each{|i| block.call(self.[](i)) }
    end

  end

end
