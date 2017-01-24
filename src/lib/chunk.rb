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
          newc.send(:define_singleton_method, :chunk_size){
            size
          }
          newc.send(:define_method, :initialize){|block: nil, index: 0|
              @chunk_size = size
              @unpack = unpack
              @block = block
              @index = index  # on block
              @base_on_block = index * @chunk_size
          }
          newc.send(:attr_reader, *[:chunk_size, :unpack, :block, :index, :base_on_block])
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

    def raw
      @block.raw[@base_on_block...(@base_on_block+@chunk_size)]
    end

  end
end
