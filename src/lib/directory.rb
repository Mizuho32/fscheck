class FileSystem
  class DirectoryBlockChunk < FileSystem::Chunk[size: 16, unpack: "Sa14"]

    def inum
      @block.indexer(to_onblock(0, 1), unpack: ?S).first
    end

    def inum=(v)
      @block.send(:indexer_asig, to_onblock(0, 1),  v)
    end

    def name
      @block.indexer(to_onblock(2, 15), unpack: 'a14').first.strip
    end

    def name=(v)
      raise Exception.new("file name too long #{v.size}") if v.size > 14
      @block.indexer_asig(to_onblock(2, 15),  [v], pack: "a14")
    end

    def inspect
      to_s
    end
    def to_s
      <<-"S"
<DirBlockChunk inum: #{inum}, name: #{name}>
S
    end

  end
end
