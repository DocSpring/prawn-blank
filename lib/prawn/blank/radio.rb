# frozen_string_literal: true

module Prawn::Blank
  class Radio < Field
    attr_accessor :check_string, :check_style, :value

    def grouped_checkboxes=(value)
      if value
        # We must remove the /FT /Btn attribute from kids in a checkbox group. Otherwise,
        # IE Edge will treat them as independent checkboxes.
        data.delete :FT
        # Also need to remove the radio button flag
        data.delete :Ff
      end
    end

    def finalize(document)
      # render this field

      app = appearance || document.default_appearance

      @data[:AP] =
        if check_string
          { N: { :Off => app.checkbox_off(self), @value => app.checkbox_on(self) },
            # R: { :Off => app.checkbox_off_over(self), @value => app.checkbox_on_over(self) },
            D: { :Off => app.checkbox_off_down(self), @value => app.checkbox_on_down(self) } }
        else
          { N: { :Off => app.radio_off(self), @value => app.radio_on(self) },
            # R: { :Off => app.radio_off_over(self), @value => app.radio_on_over(self) },
            D: { :Off => app.radio_off_down(self), @value => app.radio_on_down(self) } }
        end

      @data[:AS] = parent.value == @value ? @value : :Off

      if check_string
        # Chrome and Adobe replace our appearance AP content stream with its own defaults.
        # and uses ZaDB (ZapfDingBats) for its font.
        @data[:MK] = @data[:MK] || {}
        @data[:MK][:CA] = PDF::Core::LiteralString.new(check_zapf_char)
      end

      nil
    end

    # protected

    # def default_options
    #   super.merge(Ff: 32_768) # FT: :Btn,
    # end
  end
end
