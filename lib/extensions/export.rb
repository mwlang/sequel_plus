#
# The export extension adds Sequel::Dataset#export
#
# Export with no options specified will export as tab-delimited w/o any quoting
#
# Date, Time, and DateTime are exported as ISO-8601
# http://en.wikipedia.org/wiki/ISO_8601
#
# Non-numerics are encased in given :quote_char (default is none)
# Columns are delimited by given :delimiter (default is tab character)
# Headers are emitted by default (suppress with :headers => false)
#
module Sequel
  class Dataset
    def export(fd = $stdout, options = {})

      opts[:delimiter]  = options[:delimiter] || "\t"
      opts[:quote_char] = options[:quote_char] || ''
      opts[:headers]    = options[:headers] != false
      opts[:paginate]   = options[:paginate] || false
      opts[:page_size]  = options[:page_size] || 5000
      
      Sequel.extension :pagination if opts[:paginate]

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

      def export_data(ds)
        quot = @options[:quote_char]
        ds.each do |row| 
          data = @columns.map do |col|
            case row[col]
            when Date then 
              "#{quot}#{row[col].strftime('%Y-%m-%d')}#{quot}"
            when DateTime then
              "#{quot}#{row[col].localtime.strftime('%Y-%m-%dT%H:%M%Z')}#{quot}"
            when Time then 
              "#{quot}#{row[col].localtime.strftime('%H:%M%Z')}#{quot}"
            when Float, BigDecimal then 
              row[col].to_f
            when BigDecimal, Bignum, Fixnum then 
              row[col].to_i
            else 
              "#{quot}#{row[col].to_s}#{quot}"
            end
          end
          @file.puts data.join(@options[:delimiter])
        end
      end
      
      def output 
        first_row = @dataset.first
        return unless first_row
        
        quot = @options[:quote_char]
        @columns ||= first_row.keys.sort_by{|x|x.to_s}

        if @options[:headers] == true
          @file.puts @columns.map{|col| "#{quot}#{col}#{quot}"}.join(@options[:delimiter])
        end

        if @options[:paginate]
          @dataset.each_page(@options[:page_size]){|paged_ds| export_data paged_ds}
        else
          export_data @dataset
        end
      end

      def build_row(row) 
        quot = @options[:quote_char] 
        @columns.map{|col| row[col].to_export(quot)}.join(@options[:delimiter])
      end
    end  # Writer
  end  # Export 
end  # Sequel 

