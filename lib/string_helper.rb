
module Uhuru
  class StringHelper
    def self.humanize (value, options = {})

      if options.empty?
        options[:format] = :sentence
      end

      values = []

      if value.include? '_'
        values = value.split('_')

        values.each_index do |index|

          # lower case each item in array
          values[index].downcase!

        end

        if options[:format] == :allcaps
          values.each do |value|
            value.capitalize!
          end

          if options.empty?
            options[:seperator] = " "
          end

          return values.join " "
        end

        if options[:format] == :class
          values.each do |value|
            value.capitalize!
          end

          return values.join ""
        end

        if options[:format] == :sentence
          values[0].capitalize!

          return values.join " "
        end

        if options[:format] == :nocaps
          return values.join " "
        end
      end
    end
  end
end
