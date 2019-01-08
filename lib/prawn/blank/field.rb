# frozen_string_literal: true

class Prawn::Blank::Field < Prawn::Blank::FieldBase
  protected

  def get_dict
    base = super
    if appearance

      app = Prawn::Blank::Appearance.cast(appearance)

      app.font.instance_eval do
        @references[0] ||= register(0)
        @document.acroform.add_resource(
          :Font,
          identifier_for(0), @references[0]
        )
      end

      base.merge! app.apply_to(self)
    end
    base
  end
end
