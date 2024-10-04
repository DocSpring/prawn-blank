# frozen_string_literal: true

module Prawn::Blank
  class TextStyle < PDF::Core::LiteralString
    attr_reader :document, :font, :font_subset, :color, :size, :style

    def initialize(document, font, style, size, color, font_subset = 0)
      @document = document
      @font = font
      @font_subset = font_subset
      @size = size
      @style = style || :normal
      @color = color
      @color = [@color] unless color.is_a? Array
      super(
        "/#{font_identifier} #{size} Tf " \
        "#{document.send(:color_to_s, *@color)} #{color_cmd(@color)}"
      )
      # super(
      #   "/CoBo #{size} Tf " \
      #   "#{document.send(:color_to_s, *@color)} #{color_cmd(@color)}"
      # )
    end

    def font_instance
      document.font(font, style: style)
    end

    def font_identifier
      font_instance.identifier_for(font_subset)
    end

    def color_cmd(color)
      if color[0].is_a? String
        'rg'
      else
        'k'
      end
    end
  end
end
