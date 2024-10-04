# frozen_string_literal: true

require 'prawn'

module Prawn
  module Blank
    autoload :Form, 'prawn/blank/form'
    autoload :Style, 'prawn/blank/style'
    autoload :FieldBase, 'prawn/blank/field_base'
    autoload :Field, 'prawn/blank/field'
    autoload :Appearance, 'prawn/blank/appearance'
    autoload :TextField, 'prawn/blank/text_field'
    autoload :Checkbox, 'prawn/blank/checkbox'
    autoload :Select, 'prawn/blank/select'
    autoload :Combo, 'prawn/blank/combo'
    autoload :RadioGroup, 'prawn/blank/radio_group'
    autoload :Radio, 'prawn/blank/radio'
    autoload :TextStyle, 'prawn/blank/text_style'

    def text_field(options = {})
      options[:at] = send(:map_to_absolute, options[:at]) if options[:at]
      f = TextField.create(self, options)
      yield(f) if block_given?
      add_field(f)
    end

    def select(options = {})
      options[:at] = send(:map_to_absolute, options[:at]) if options[:at]
      f = Select.create(self, options)
      yield(f) if block_given?
      add_field(f)
    end

    def checkbox(options = {})
      options[:at] = send(:map_to_absolute, options[:at]) if options[:at]
      f = Checkbox.create(self, options)
      yield(f) if block_given?
      add_field(f)
    end

    def radiogroup(options = {})
      f = RadioGroup.create(self, options)
      yield(f) if block_given?
      add_field(f)
    end

    def radio(options = {})
      options[:at] = send(:map_to_absolute, options[:at]) if options[:at]
      f = Radio.create(self, options)
      yield(f) if block_given?
      add_field(f)
    end

    def acroform
      state.store.root.data[:AcroForm] ||= ref!(Form.new(self))
      state.store.root.data[:AcroForm].data
    end

    attr_writer :default_appearance

    def default_appearance
      @default_appearance ||= Appearance.new(self)
    end

    def get_page_rotation(page)
      page_rotation = (page.dictionary.try(:data).try(:[], :Rotate) || 0).to_i
      # 360 is a valid page rotation
      page_rotation %= 360
      page_rotation
    end

    protected

    def handle_page_rotation(field)
      page_rotation = get_page_rotation(page)
      return if page_rotation == 0

      adjust_mk_rotate_on_page_rotation(field, page_rotation)
      adjust_rect_on_page_rotation(field, page_rotation, page)
    end

    def adjust_mk_rotate_on_page_rotation(field, page_rotation)
      field.data[:MK] ||= {}
      field.data[:MK][:R] = page_rotation
    end

    def get_actual_page_dimensions(page)
      page_dimensions = page.dimensions
      page_width = page_dimensions[2] - page_dimensions[0]
      page_height = page_dimensions[3] - page_dimensions[1]

      page_rotation = get_page_rotation(page)

      page_width, page_height = page_height, page_width if [90, 270].include?(page_rotation)

      [page_width, page_height]
    end

    def adjust_rect_on_page_rotation(field, rotation, page)
      page_width, page_height = get_actual_page_dimensions(page)

      left, bottom, right, top = field.rect

      case rotation
      when 90
        # origin is at top/left
        new_left   = page_height - top
        new_bottom = left
        new_right  = page_height - bottom
        new_top    = right

        field.rect = [new_left, new_bottom, new_right, new_top]
      when 180
        # origin is at top/right
        new_left   = page_width  - right
        new_bottom = page_height - top
        new_right  = page_width  - left
        new_top    = page_height - bottom

        field.rect = [new_left, new_bottom, new_right, new_top]
      when 270
        # origin is at bottom/right
        new_left   = bottom
        new_bottom = page_width - right
        new_right  = top
        new_top    = page_width - left

        field.rect = [new_left, new_bottom, new_right, new_top]
      else
        raise "Don't know how to handle a page rotation of #{rotation} degrees!"
      end
    end

    def add_field(field)
      field.finalize(self)
      handle_page_rotation(field)

      field.page = page.dictionary

      # Add field to AcroForm hash
      acroform.add_field(field) if field.root?

      # Add field to annots
      # (Unless it's a Radio Group - the parent group is only added to the acroform
      # since it's not an annotation, but each kid is added.)
      unless field.is_a? Prawn::Blank::RadioGroup
        state.page.dictionary.data[:Annots] ||= []

        if state.page.dictionary.data[:Annots].is_a?(PDF::Core::Reference)
          state.page.dictionary.data[:Annots].data << field
        else
          state.page.dictionary.data[:Annots] << field
        end
      end

      field
    end
  end

  def self.TextStyle(*args)
    Prawn::Blank::TextStyle.new(*args)
  end

  def self.BorderStyle(_doc, width, style = :S)
    {
      W: width,
      Type: :Border,
      S: style
    }
  end

  def self.ColorStyle(doc, fill, stroke)
    {
      BC: doc.send(:normalize_color, stroke),
      BG: doc.send(:normalize_color, fill)
    }
  end
end

require 'prawn/document'
Prawn::Document.extensions << Prawn::Blank
