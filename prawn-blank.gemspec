# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'prawn-blank'
  s.version = '0.0.3'
  s.authors = ['HannesG']
  s.email = 'hannes.georg@googlemail.com'
  s.summary = 'This is a experimental library. See the basic example for usage and abilities.'

  s.description = 'prawn-blank adds forms to prawn'
  s.files = Dir.glob('{lib}/**/**/*') + ['Rakefile']
  s.require_path = 'lib'
  s.add_dependency 'prawn'
  s.add_development_dependency('rspec')
  s.add_development_dependency('rubocop')
  s.add_development_dependency('rubocop-rspec')
  # s.has_rdoc = true
  s.metadata['rubygems_mfa_required'] = 'true'
end
