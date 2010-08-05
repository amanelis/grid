require 'xml/parser'
require 'rforce/soap_pullable'

module RForce
  class SoapResponseExpat
    include SoapPullable

    def initialize(content)
      @content = content
    end

    def parse
      @current_value = nil
      @stack = []
      @parsed = OpenHash.new({})
      @done = false
      @namespaces = []

      edited_content = @content.gsub('&apos;', "'").gsub('&amp;', 'EscapedAND')

      XML::Parser.new.parse(edited_content) do |type, name, data|
        case type
          when XML::Parser::START_ELEM
            tag_start name, data
          when XML::Parser::CDATA
            the_data = data.gsub('EscapedAND', '&')
            text the_data
          when XML::Parser::END_ELEM
            tag_end name
        end

        break if @done
      end

      @parsed
    end

  end
end
