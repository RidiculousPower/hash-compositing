
require 'hash/hooked'

# namespaces that have to be declared ahead of time for proper load order
require_relative './namespaces'

# source file requires
require_relative './requires.rb'

class ::CompositingHash < ::HookedHash

  include ::CompositingHash::HashInterface
  
end
