module Babelicious

  class HashMap < BaseMap
    attr_accessor :path_translator

    class << self
      
      def initial_target
        {}
      end
      
      def filter_source(source)
        source
      end
      
    end

    def initialize(path_translator, opts={})
      @path_translator, @opts = path_translator, opts
    end
    
    def value_from(source)
      hash = {}
      element = ""
      @path_translator.inject_with_index(hash) do |hsh, element, index|
        return hsh[element.to_sym] if (index == @path_translator.last_index && index != 0)
        if hsh.empty?
          source_element(source, element)
        else 
          hsh[element.to_sym]
        end
      end

      rescue
        raise "There was a problem extracting the value from your hash.  It seems to be missing element '#{element}'"
    end

    protected

    def map_output(hash_output, source_value)
      catch :no_value do
        @path_translator.inject_with_index(hash_output) do |hsh, element, index|
          if(hsh[element])
            hsh[element]
          else
            hsh[element] = (index == @path_translator.last_index ? map_source_value(source_value) : {})
          end 
        end
      end 
    end 

    private
    
    def source_element(source, element)
      source[element.to_sym] || source[element.to_s]
    end
    
    def map_source_value(source_value)
      if(@customized_map)
        @customized_map.call(source_value)
      else 
        source_value
      end 
    end

  end
end
