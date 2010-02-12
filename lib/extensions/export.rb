# The export extension adds Sequel::Dataset#export and the
# Sequel::Export class for creating plain-text data exports

module Sequel
  class Dataset
    # Pretty prints the records in the dataset as plain-text table.
    def export(delimiter="\t", *cols)
      Sequel::Export.output(delimiter, naked.all, cols.empty? ? columns : cols)
    end
  end

  module Export
    def self.output(delimiter, records, columns = nil) 
      rows = []
      columns ||= records.first.keys.sort_by{|x|x.to_s}
      rows << columns.join(delimiter)

      records.each {|r| rows << data_line(delimiter, columns, r)}
      rows.join("\n")
    end

    ### Private Module Methods ###
    
    # String for each data line
    def self.data_line(delimiter, columns, record) # :nodoc:
      columns.map {|c| format_cell(record[c])}.join(delimiter)
    end
    
    # Format the value so it takes up exactly size characters
    def self.format_cell(v) # :nodoc:
      case v
      when Bignum, Fixnum
        v.to_i.to_s
      when Float, BigDecimal
        v.to_f.to_s
      else
        v.to_s
      end
    end
    
    # private_class_method :column_sizes, :data_line, :format_cell, :header_line, :separator_line
  end
end

