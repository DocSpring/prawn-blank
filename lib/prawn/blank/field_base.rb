# frozen_string_literal: true

class Prawn::Blank::FieldBase < PDF::Core::Reference
  # see pdf reference for documentation
  FF_FLAGS = {
    readonly: 1,
    required: 2,
    no_export: 3,

    # for text fields
    multiline: 13,
    password: 14,
    file_select: 21,
    do_not_spell_check: 23,
    do_not_scroll: 24,
    comb: 25,
    rich_text: 26,

    # for buttons
    no_toggle_to_off: 15,

    radio: 16,
    pushbutton: 17,
    combo: 18,
    edit: 19,
    sort: 20,
    radios_in_unison: 26,
    commit_on_select_change: 27
  }.freeze

  class << self
    def field_attr_accessor(name, key, inheritable: true)
      class_eval(
        # def rect
        #   if false && !@data.key?(:Rect) && self.parent?
        #     return self.parent.rect
        #   end
        #   @data[:Rect]
        # end
        # def rect=(value)
        #   @data[:Rect]=value
        # end
        # def delete_rect
        #   @data.delete :Rect
        # end
        # def rect?
        #   if false
        #     @data.key?(:Rect) || (self.parent? && self.parent.rect?)
        #   else
        #     @data.key? :Rect
        #   end
        # end
        # def own_rect?
        #   @data.key? :Rect
        # end
        <<~EVAL, __FILE__, __LINE__ + 1
          def #{name}
            if #{inheritable.inspect} && !@data.key?(#{key.to_sym.inspect}) && self.parent?
              return self.parent.#{name}
            end
            @data[#{key.to_sym.inspect}]
          end

          def #{name}=(value)
            @data[#{key.to_sym.inspect}]=value
          end
          def delete_#{name}
            @data.delete #{key.to_sym.inspect}
          end
          def #{name}?
            if #{inheritable.inspect}
              @data.key?(#{key.to_sym.inspect}) || (self.parent? && self.parent.#{name}?)
            else
              @data.key? #{key.to_sym.inspect}
            end
          end
          def own_#{name}?
            @data.key? #{key.to_sym.inspect}
          end
        EVAL
      )
    end

    def flag_accessor(name, bit, flag_name = 'flags')
      mask = (1 << (bit - 1))

      class_eval(
        # def invisible
        #   (self.aflags || 0) & 1
        # end
        #
        # alias invisible? invisible
        #
        # def invisible=(value)
        #   if value
        #     self.aflags = (self.aflags || 0) | 1
        #   else
        #     self.aflags = (self.aflags || 0) & ~1
        #   end
        # end
        <<~EVAL, __FILE__, __LINE__ + 1
          def #{name}
            (self.#{flag_name} || 0) & #{mask.inspect}
          end

          alias #{name}? #{name}

          def #{name}=(value)
            if value
              self.#{flag_name} = (self.#{flag_name} || 0) | #{mask.inspect}
            else
              self.#{flag_name} = (self.#{flag_name} || 0) & ~#{mask.inspect}
            end
          end
        EVAL
      )
    end
  end

  field_attr_accessor :rect, :Rect, inheritable: false
  field_attr_accessor :parent, :Parent, inheritable: false
  field_attr_accessor :children, :Kids, inheritable: false
  field_attr_accessor :type, :FT
  field_attr_accessor :aflags, :F
  field_attr_accessor :flags, :Ff
  field_attr_accessor :name, :T, inheritable: false
  field_attr_accessor :fullname, :TU, inheritable: false
  field_attr_accessor :value, :V
  field_attr_accessor :default_value, :DV
  field_attr_accessor :default_appearance, :DA
  field_attr_accessor :alignment, :Q
  field_attr_accessor :_app, :AP
  field_attr_accessor :border_style, :BS
  field_attr_accessor :style, :MK
  field_attr_accessor :page, :P
  field_attr_accessor :options, :Opt
  field_attr_accessor :max_length, :MaxLen

  attr_reader :text_style,
              :shrink_to_fit

  attr_accessor :text_box_opacity,
                :text_box_background_color,
                :text_box_align,
                :text_box_valign,
                :text_box_overflow,
                :text_box_single_line,
                :text_box_character_spacing,
                :text_box_text_direction,
                :text_box_strikethrough

  # Special case for text_style / default_appearance
  # When shrink_to_fit is true, the default_appearance font size is set to 0
  # But the appearance stream font size must be preserved
  def text_style=(value)
    @text_style = value
    set_default_appearance_from_text_style
  end

  def shrink_to_fit=(value)
    @shrink_to_fit = value
    set_default_appearance_from_text_style
    shrink_to_fit
  end

  def set_default_appearance_from_text_style
    return unless text_style

    ts = text_style
    font_size = shrink_to_fit ? 0 : ts.size
    @data[:DA] = Prawn::TextStyle(
      ts.document, ts.font, ts.style, font_size, ts.color, ts.font_subset
    )
  end

  def name=(value)
    @data[:T] = (value && PDF::Core::LiteralString.new(value.to_s))
  end

  flag_accessor :invisible, 1, 'aflags'
  flag_accessor :hidden, 2, 'aflags'
  flag_accessor :print, 3, 'aflags'
  flag_accessor :no_zoom, 4, 'aflags'

  flag_accessor :readonly, 1
  flag_accessor :required, 2
  flag_accessor :no_export, 3

  flag_accessor :multiline, 13
  flag_accessor :password, 14
  flag_accessor :no_toggle_to_off, 15
  flag_accessor :comb, 25

  flag_accessor :combo, 18
  flag_accessor :editable, 19

  alias _parent= parent=

  def parent=(p)
    parent.children.delete(self) if parent?
    p.children ||= []
    p.children << self
    self._parent = p
  end

  def appearance
    return @appearance if @appearance
    return parent.appearance if parent?

    nil
  end

  attr_writer :appearance

  def leaf?
    !children?
  end

  def root?
    !parent?
  end

  def self.create(document, ...)
    document.state.store.push(new(document.state.store.size + 1, ...))
  end

  def self.from_ref(ref)
    result = new(ref.identifier)
    result.data = ref.data
    result
  end

  def initialize(id, *args)
    super(id, default_options)

    # okay, we print this annot by default
    self.print = true

    options = (args.last.is_a?(Hash) ? args.pop : {})
    options.each do |k, v|
      send :"#{k}=", v
    end

    yield self if block_given?
  end

  def width
    r = rect
    (r[2] - r[0]).abs
  end

  def width=(w)
    rect[2] = rect[0] + w
  end

  def height
    r = rect
    (r[3] - r[1]).abs
  end

  def height=(h)
    rect[3] = rect[1] - h
  end

  def at
    rect[0..1]
  end

  def at=(*args)
    x, y = args.flatten
    self.rect = [x, y, x + width, y - height]
  end

  def validate!
    raise 'Blank: Type must be :Annot ' if data[:Type] != :Annot
    raise 'Blank: Subtype must be :Annot ' if data[:Subtype] != :Widget

    raise 'Blank: FT ( Field Type ) must be :Btn, :Tx, :Ch or :Sig ' if leaf? && !(%i[Btn Tx Ch Sig].include type)
  end

  def finalize(document); end

  def denormalize_color(color)
    s = color.size
    case s
    when 1 # gray
      return [0, 0, 0, color[0]]
    when 3 # rgb
      return Prawn::Graphics::Color.rgb2hex(color.map { |component| component * 255.0 })
    when 4 # cmyk
      return color.map { |component| component * 100.0 }
    end

    raise "Unknown color: #{color}"
  end

  protected

  def default_options
    {
      Type: :Annot,
      Subtype: :Widget,
      Rect: [0, 0, 0, 0]
    }
  end
end
