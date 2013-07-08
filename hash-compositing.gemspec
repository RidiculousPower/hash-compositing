require 'date'

Gem::Specification.new do |spec|

  spec.name                      =  'hash-compositing'
  spec.rubyforge_project         =  'hash-compositing'
  spec.version                   =  '1.1.0'

  spec.summary                   =  "Provides Hash::Compositing."
  spec.description               =  "An implementation of Hash that permits chaining, where children inherit changes to parent and where parent settings can be overridden in children."

  spec.authors                   =  [ 'Asher' ]
  spec.email                     =  'asher@ridiculouspower.com'
  spec.homepage                  =  'http://rubygems.org/gems/hash-compositing'

  spec.required_ruby_version     = ">= 1.9.1"

  spec.add_dependency            'hash-hooked'

  spec.date                      =  Date.today.to_s
  
  spec.files                     = Dir[ '{lib,lib_ext,spec}/**/*',
                                        'README*', 
                                        'LICENSE*' ]

end
