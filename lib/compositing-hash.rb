
if $__compositing_array__spec__development
  require_relative '../../compositing-object/lib/compositing-object.rb'
else
  require 'compositing-object'
end

class ::CompositingHash < ::Hash
end

require_relative 'compositing-hash/CompositingHash.rb'

