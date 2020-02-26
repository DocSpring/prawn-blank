# frozen_string_literal: true

module Prawn::Blank
  class Appearance
    class Item
      def self.arguments(args = {})
        @arguments = args
      end

      def cache_key(elem); end
    end

    attr_reader :document

    STYLE = {
      border_color: '202020',
      background_color: 'ffffff',
      border_width: 1
    }.freeze

    def initialize(document)
      @document = document
      @cache = {}
      @font_cache = {}
      # @style = STYLE.dup
    end

    def render(dict)
      dict = {
        Type: :XObject,
        Subtype: :Form,
        Resources: { ProcSet: %i[PDF ImageC ImageI ImageB] }
      }.merge(dict)

      result = @document.ref!(dict)
      @document.state.page.stamp_stream(result) do
        yield
      end
      @document.acroform.add_resources(result.data[:Resources])
      result
    end

    def button(element)
      element.width = 10 if !element.width || (element.width <= 0)
      element.height = 10 if !element.height || (element.height <= 0)
      width = element.width
      height = element.height
      style = element.style ||= Prawn::ColorStyle(@document, 'ffffff', '000000')
      border_style = element.border_style ||= Prawn::BorderStyle(@document, 0)
      cached(:checkbox_off, width, height, style, border_style) do
        render(BBox: [0, 0, width, height]) do
          document.canvas do
            # render background
            document.fill_color(*denormalize_color(style[:BG]))
            document.stroke_color(*denormalize_color(style[:BC]))
            document.line_width(border_style[:W])
            bw = border_style[:W] / 2.0
            document.fill_and_stroke_rectangle([bw, height - bw], width - border_style[:W], height - border_style[:W])
          end
        end
      end
    end

    alias button_over button
    alias button_down button

    def checkbox_off(element, _cache_key = :checkbox_off, mousedown = false)
      element.width = 10 if !element.width || (element.width <= 0)
      element.height = 10 if !element.height || (element.height <= 0)
      width = element.width
      height = element.height
      # style = element.style ||= Prawn::ColorStyle(@document, 'ffffff', '888888')

      style = element.style ||= {
        BC: [0],
        BG: [1]
      }

      stream_dict = {
        BBox: [0, 0, width, height],
        FormType: 1,
        Matrix: [1.0, 0.0, 0.0, 1.0, 0.0, 0.0],
        Type: :XObject,
        Subtype: :Form,
        Resources: {
          ProcSet: %i[PDF Text]
        }
      }
      stream_ref = document.ref!(stream_dict)

      bg_color = mousedown ? '0.75293' : '1'
      stream_ref.stream << %(
#{bg_color} g
0 0 #{width} #{height} re
f
0.5 0.5 #{width - 1} #{height - 1} re
s
      )
      stream_ref
    end

    alias checkbox_off_over checkbox_off
    # alias checkbox_off_down checkbox_off
    def checkbox_off_down(element)
      checkbox_off(element, :checkbox_off_down, :down)
    end

    def checkbox_on(element, _cache_key = :checkbox_on, mousedown = false)
      element.width = 10 if !element.width || (element.width <= 0)
      element.height = 10 if !element.height || (element.height <= 0)
      width = element.width
      height = element.height
      # style = element.style ||= Prawn::ColorStyle(@document, 'ffffff', '888888')
      # border_style = element.border_style ||= Prawn::BorderStyle(@document, 4)
      style = element.style ||= {
        BC: [0],
        BG: [1]
      }

      # Need ZaDb font alias
      unless @font_cache[:ZaDb]
        font_dict = {
          BaseFont: :ZapfDingbats,
          Name: :ZaDb,
          Subtype: :Type1,
          Type: :Font
        }
        @font_cache[:ZaDb] = document.ref!(font_dict)
      end

      stream_dict = {
        BBox: [0, 0, width, height],
        FormType: 1,
        Matrix: [1.0, 0.0, 0.0, 1.0, 0.0, 0.0],
        Type: :XObject,
        Subtype: :Form,
        Resources: {
          ProcSet: %i[PDF Text],
          Font: { ZaDb: @font_cache[:ZaDb] }
        }
      }

      stream_ref = document.ref!(stream_dict)
      document.acroform.add_resources(stream_ref.data[:Resources])

      # Approximate formulas figured out in this spreadsheet:
      # https://docs.google.com/spreadsheets/d/15QzWSex3xwE_DmjbZ4ouUco-m5jGOknW69W47Ir45m4/edit#gid=0
      sq_width = [width, height].min
      sq_x_offset = (width - sq_width) / 2
      sq_y_offset = (height - sq_width) / 2

      fontsize_a = (sq_width * 1.05) - 4.4
      fontsize_b = fontsize_a - 0.59
      tdx = sq_x_offset + 2.853
      tdy = (sq_y_offset * 0.9) + 1.7 + (sq_width * 0.13)

      bg_color = mousedown ? '0.75293' : '1'

      # PDF Reference 1.7 - page 219 - TABLE 4.7 Graphics state operators
      # a b c d e f cm: Modify the current transformation matrix (CTM)
      #
      # page 226 - TABLE 4.9 Path construction operators
      # x y m: Begin a new subpath by moving the current point to coordinates (x, y)
      # x1 y1 x2 y2 x3 y3 c: Append a cubic Bézier curve to the current path
      # x y l: Append a straight line segment from the current point to the point (x, y)
      # h: Close the current subpath by appending a straight line segment from the current point to the starting point of the subpath.

      stream_ref.stream << %(
#{bg_color} g
0 0 #{width.round(4)} #{height.round(4)} re
f
0.5 0.5 #{(width - 1).round(4)} #{(height - 1).round(4)} re
s
q
1 1 #{(width - 2).round(4)} #{(height - 2).round(4)} re
W
n
0 g
BT
/ZaDb #{fontsize_a.round(4)} Tf
#{tdx.round(4)} #{tdy.round(4)} Td
#{fontsize_b.round(4)} TL
0 0 Td
(4) Tj
ET
Q
      )
      stream_ref
    end

    alias checkbox_on_over checkbox_on
    # alias checkbox_on_down checkbox_on
    def checkbox_on_down(element)
      checkbox_on(element, :checkbox_on_down, :down)
    end

    def radio_off(element, cache_key = :radio_off, mousedown = false)
      element.width = 10 if !element.width || (element.width <= 0)
      element.height = 10 if !element.height || (element.height <= 0)
      width = element.width
      height = element.height
      style = element.style ||= Prawn::ColorStyle(@document, 'ffffff', '000000')
      # border_style = element.border_style ||= Prawn::BorderStyle(@document, 0)
      cached(cache_key, width, height, style) do
        render(
          BBox: [0, 0, width, height],
          FormType: 1,
          Matrix: [1.0, 0.0, 0.0, 1.0, 0.0, 0.0],
          Type: :XObject,
          Subtype: :Form,
          Resources: { ProcSet: %i[PDF Text] }
        ) do
          bg_color = mousedown ? '0.75293' : '1'
          document.add_content %(
#{bg_color} g
q
1 0 0 1 9 9 cm
9 0 m
9 4.9708 4.9708 9 0 9 c
-4.9708 9 -9 4.9708 -9 0 c
-9 -4.9708 -4.9708 -9 0 -9 c
4.9708 -9 9 -4.9708 9 0 c
f
Q
q
1 0 0 1 9 9 cm
8.5 0 m
8.5 4.6946 4.6946 8.5 0 8.5 c
-4.6946 8.5 -8.5 4.6946 -8.5 0 c
-8.5 -4.6946 -4.6946 -8.5 0 -8.5 c
4.6946 -8.5 8.5 -4.6946 8.5 0 c
s
Q
0.501953 G
q
0.7071 0.7071 -0.7071 0.7071 9 9 cm
7.5 0 m
7.5 4.1423 4.1423 7.5 0 7.5 c
-4.1423 7.5 -7.5 4.1423 -7.5 0 c
S
Q
0.75293 G
q
0.7071 0.7071 -0.7071 0.7071 9 9 cm
-7.5 0 m
-7.5 -4.1423 -4.1423 -7.5 0 -7.5 c
4.1423 -7.5 7.5 -4.1423 7.5 0 c
S
Q
          )
        end
      end
    end

    alias radio_off_over radio_off
    # alias radio_off_down radio_off
    def radio_off_down(element)
      radio_off(element, :radio_off_down, :down)
    end

    def radio_on(element, _cache_key = :radio_on, mousedown = false)
      element.width = 10 if !element.width || (element.width <= 0)
      element.height = 10 if !element.height || (element.height <= 0)
      width = element.width
      height = element.height
      style = element.style ||= Prawn::ColorStyle(@document, 'ffffff', '000000')
      # border_style = element.border_style ||= Prawn::BorderStyle(@document, 4)
      cached(:radio_on, width, height, style) do
        render(BBox: [0, 0, width, height]) do
          bg_color = mousedown ? '0.75293' : '1'
          document.add_content %(
#{bg_color} g
q
1 0 0 1 9 9 cm
9 0 m
9 4.9708 4.9708 9 0 9 c
-4.9708 9 -9 4.9708 -9 0 c
-9 -4.9708 -4.9708 -9 0 -9 c
4.9708 -9 9 -4.9708 9 0 c
f
Q
q
1 0 0 1 9 9 cm
8.5 0 m
8.5 4.6946 4.6946 8.5 0 8.5 c
-4.6946 8.5 -8.5 4.6946 -8.5 0 c
-8.5 -4.6946 -4.6946 -8.5 0 -8.5 c
4.6946 -8.5 8.5 -4.6946 8.5 0 c
s
Q
0.501953 G
q
0.7071 0.7071 -0.7071 0.7071 9 9 cm
7.5 0 m
7.5 4.1423 4.1423 7.5 0 7.5 c
-4.1423 7.5 -7.5 4.1423 -7.5 0 c
S
Q
0.75293 G
q
0.7071 0.7071 -0.7071 0.7071 9 9 cm
-7.5 0 m
-7.5 -4.1423 -4.1423 -7.5 0 -7.5 c
4.1423 -7.5 7.5 -4.1423 7.5 0 c
S
Q
0 g
q
1 0 0 1 9 9 cm
3.5 0 m
3.5 1.9331 1.9331 3.5 0 3.5 c
-1.9331 3.5 -3.5 1.9331 -3.5 0 c
-3.5 -1.9331 -1.9331 -3.5 0 -3.5 c
1.9331 -3.5 3.5 -1.9331 3.5 0 c
f
Q
          ).strip
        end
      end
    end

    alias radio_on_over radio_on
    # alias radio_on_down radio_on
    def radio_on_down(element)
      radio_on(element, :radio_on_down, :down)
    end

    # For DA instead of AP
    def text_field_default_appearance(element)
      text_style = element.text_style ||= Prawn::TextStyle(
        @document, 'Helvetica', :normal, 9, '000000'
      )
      border_style = element.border_style ||= Prawn::BorderStyle(@document, 0)

      element.width = 100 if !element.width || (element.width <= 0)
      element.height = text_style.size + 6 + 2 * border_style[:W] if !element.height || (element.height <= 0)
      width = element.width
      height = element.height
      style = Prawn::ColorStyle(@document, 'ffffff', '000000')
      multiline = element.multiline
      value = element.value

      # cached(:text_field, width, height, style, border_style, text_style, multiline, value) do
      render(BBox: [0, 0, width, height]) do
        document.canvas do
          document.save_font do
            # resources = (document.page.dictionary.data[:Resources] ||= {})
            # resources[:Font] ||= []
            # resources[:Font] << pdf.find_font('Helvetica')

            # render background
            document.fill_color(*denormalize_color(style[:BG]))
            document.stroke_color(*denormalize_color(style[:BC]))
            document.line_width(border_style[:W])
            if border_style[:W] > 0
              bw = border_style[:W] / 2.0
              document.fill_and_stroke_rectangle(
                [bw, height - bw], width - border_style[:W], height - border_style[:W]
              )
            else
              document.fill_rectangle(
                [0, height], width, height
              )
            end
            document.font(text_style.font, size: text_style.size, style: text_style.style)
            document.fill_color(*text_style.color)

            if value
              document.draw_text(
                value,
                at: [
                  0,
                  [1, height - document.font_size - 1.5].max
                ]
              )
            end
          end
        end
      end
      # end
    end

    protected

    def cached(*args)
      @cache[args] ||= yield
    end

    def denormalize_color(color)
      s = color.size
      if s == 1 # gray
        return [0, 0, 0, color[0]]
      elsif s == 3 # rgb
        return Prawn::Graphics::Color.rgb2hex(color.map { |component| component * 255.0 })
      elsif s == 4 # cmyk
        return color.map { |component| component * 100.0 }
      end

      raise "Unknown color: #{color}"
    end
  end
end
