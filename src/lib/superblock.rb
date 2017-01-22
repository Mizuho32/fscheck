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
