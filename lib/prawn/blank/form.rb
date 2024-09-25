# frozen_string_literal: true

class Prawn::Blank::Form < Hash
  def initialize(document)
    super
    # Variable text fields should not have appearance streams.
    # See the "Variable Text" section in the PDF reference.
    # We need to set NeedAppearances to true to render filled out text fields, and
    # update the appearances after user input.
    # UPDATE: Turn this off, since we are now properly generating initial appearance streams
    # for checkboxes and text fields, etc.
    # self[:NeedAppearances] = true

    self[:Fields] = []
    zadb_ref = document.ref!(
      Name: :ZaDb,
      Subtype: :Type1,
      BaseFont: :ZapfDingbats,
      Type: :Font
    )
    helv_ref = document.ref!(
      Name: :Helv,
      Subtype: :Type1,
      BaseFont: :Helvetica,
      Type: :Font
    )
    self[:DR] = {
      Font: {
        ZaDb: zadb_ref,
        Helv: helv_ref
      }
    }
    # Prawn encodes strings by default, and Acrobat Reader doesn't display checkboxes correctly when
    # the DA string is encoded. The following line would cause this bug:
    # self[:DA] = '/Helv 0 Tf 0 g')
    # So we need to wrap this in the LiteralString class to prevent encoding:
    self[:DA] = PDF::Core::LiteralString.new('/Helv 0 Tf 0 g')
  end

  def add_resource(type, name, dict)
    self[:DR][type] ||= {}
    self[:DR][type][name] ||= dict
  end

  def add_resources(hash)
    hash.each do |type, names|
      if names.is_a? Array
        self[:DR][type] ||= []
        self[:DR][type] = self[:DR][type] | names
      else
        names.each do |name, dict|
          add_resource(type, name, dict)
        end
      end
    end
  end

  def add_field(field)
    self[:Fields] << field
  end
end
