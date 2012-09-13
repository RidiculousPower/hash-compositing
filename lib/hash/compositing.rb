
begin ; require 'development' ; rescue ; end

require 'module/cluster'

require 'hash/hooked'

# namespaces that have to be declared ahead of time for proper load order
require_relative './namespaces'

# source file requires
require_relative './requires.rb'

class ::Hash::Compositing < ::HookedHash

  include ::Hash::Compositing::HashInterface
  
end
