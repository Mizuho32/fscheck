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
