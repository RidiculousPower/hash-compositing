require 'date'

Gem::Specification.new do |spec|

  spec.name                      =  'compositing-hash'
  spec.rubyforge_project         =  'compositing-hash'
  spec.version                   =  '1.0.14'

  spec.summary                   =  "Provides CompositingHash."
  spec.description               =  "An implementation of Hash that permits chaining, where children inherit changes to parent and where parent settings can be overridden in children."

  spec.authors                   =  [ 'Asher' ]
  spec.email                     =  'asher@ridiculouspower.com'
  spec.homepage                  =  'http://rubygems.org/gems/compositing-hash'

  spec.add_dependency            'hooked-hash'

  spec.date                      =  Date.today.to_s
  
  spec.files                     = Dir[ '{lib,spec}/**/*',
                                        'README*', 
                                        'LICENSE*' ]

end
