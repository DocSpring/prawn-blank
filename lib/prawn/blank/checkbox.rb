# frozen_string_literal: true

class Prawn::Blank::Checkbox < Prawn::Blank::Field
  attr_accessor :check_string, :check_style

  def initialize(id, *_args)
    super
    @check_string ||= '✔'
  end

  def checked
    @data[:AS] == :Yes
  end

  def checked=(value)
    if value
      @data[:AS] = :Yes
      @data[:V] = :Yes
      @data[:DV] = :Yes
    else
      @data[:AS] = :Off
      # @data[:V] = :Off
      # @data.delete :V
    end
  end

  def finalize(document)
    # @data[:Opt] = [:Yes]
    # @data[:DA] = '/Helvetica 12 Tf 0 g'

    # render this field

    app = appearance || document.default_appearance

    # PDF Reference v1.7.pdf, page 614
    # N: Normal appearance
    # R: Rollover appearance (mouse hover)
    # D: Down appearance (mouse down)
    @data[:AP] = { N: { Off: app.checkbox_off(self), Yes: app.checkbox_on(self) },
                   # R: { Off: app.checkbox_off_over(self), Yes: app.checkbox_on_over(self) },
                   D: { Off: app.checkbox_off_down(self), Yes: app.checkbox_on_down(self) } }

    # Chrome and Adobe replace our appearance AP content stream with its own defaults.
    # and uses ZaDB (ZapfDingBats) for its font.
    # @data[:DA] = PDF::Core::LiteralString.new('/ZaDb 0 Tf 0 g')
    @data[:MK] = @data[:MK] || {}
    @data[:MK][:CA] = PDF::Core::LiteralString.new(check_zapf_char)

    nil
  end

  protected

  def default_options
    super.merge(F: 0, FT: :Btn) # , Ff: 0)
  end
end
