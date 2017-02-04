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

    def inode_index
      @index + (@block.index-32)*8
    end

    def indirect
      unless (tail = addrs[12]).zero? then
        $fs[tail][0..511, unpack:"I*"].select{|i| !i.zero? }
      else
        []
      end
    end

    def all_addrs
      addrs[0...12].select{|i| !i.zero? } + indirect()
    end

    def all_using_blocks
      addrs[0..12].select{|i| !i.zero? } + indirect()
    end

    def inspect
      to_s
    end
    def to_s
      <<-"S"
inum:\t#{inode_index}
type:\t#{type}
major:\t#{major}
minor:\t#{minor}
nlink:\t#{nlink}
size:\t#{size}
addrs:\t#{addrs}
S
    end
  end

end
