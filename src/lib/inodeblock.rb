class FileSystem
  class DinodeBlockChunk < FileSystem::Chunk[size: 64, unpack: "ssssII13"]
    T_DIR = 1
    T_FILE = 2
    T_DEV = 3
    _methods = %w[type major minor nlink size]
    types = %w[s s s s I]
    ranges = [0..1, 2..3, 4..5, 6..7, 8..11]
    _methods.each_with_index{|name, i|
      r = ranges[i]
      t = types[i]
      define_method(name)do
        @block.indexer(to_onblock(r.first, r.last), unpack: t).first
      end

      define_method(name + ?=)do |v|
        @block.send(:indexer_asig, to_onblock(r.first, r.last),  v)
      end
    }

    def addrs
      @block.indexer(to_onblock(12, 63), unpack: 'I13')
    end

    def addrs=(v)
      @block.send(:indexer_asig, to_onblock(r.first, r.last),  v)
    end

  end

end
