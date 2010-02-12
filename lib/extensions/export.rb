# The export extension adds Sequel::Dataset#export and the
# Sequel::Export class for creating plain-text data exports

module Sequel
  class Dataset
    # outputs the records in the dataset as plain-text table.
    def export(fd = $stdout, options = {})
      opts[:delimiter] = options[:delimiter] || "\t"
      opts[:quote_char] = options[:quote_char] || '"'
      opts[:headers] = options[:headers] != false
      Sequel::Export::Writer.new(fd, self, opts).output
    end
  end

  module Export

    class Writer
      def initialize(fd, dataset, options)
        @file = fd
        @dataset = dataset
        @options = options
      end
    
      class ::Date; def to_export(q); ; end; end
      class ::DateTime; def to_export(q); "#{q}#{iso8601}#{q}"; end; end
      class ::Time; def to_export(q); "#{q}#{iso8601}#{q}"; end; end
      class ::Float; def to_export(q); to_f.to_s; end; end
      class ::BigDecimal; def to_export(q); to_f.to_s; end; end
      class ::Bignum; def to_export(q); to_i.to_s; end; end
      class ::Fixnum; def to_export(q); to_i.to_s; end; end
      class ::Object; def to_export(q); "#{q}#{to_s}#{q}"; end; end

      def output 
        quot = @options[:quote_char]
        @columns ||= @dataset.first.keys.sort_by{|x|x.to_s}

        if @options[:headers] == true
          @file.puts @columns.map{|col| "#{quot}#{col}#{quot}"}.join(@options[:delimiter])
        end
        
        @dataset.each do |row| 
          data = @columns.map do |col|
            case row[col]
            when Date, DateTime, Time then "#{quot}#{row[col].iso8601}#{quot}"
            when Float, BigDecimal then row[col].to_f
            when BigDecimal, Bignum, Fixnum then row[col].to_i
            else "#{quot}#{row[col].to_s}#{quot}"
            end
          end
          @file.puts data.join(@options[:delimiter])
        end
      end

      def build_row(row) 
        quot = @options[:quote_char] 
        @columns.map{|col| row[col].to_export(quot)}.join(@options[:delimiter])
      end
    end  # Writer
  end  # Export 
end  # Sequel 

