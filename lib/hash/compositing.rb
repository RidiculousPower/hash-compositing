# -*- encoding : utf-8 -*-

require 'module/cluster'

require 'hash/hooked'

# namespaces that have to be declared ahead of time for proper load order
require_relative './namespaces'

# source file requires
require_relative './requires.rb'

class ::Hash::Compositing < ::HookedHash

  ###################################  Non-Cascading Behavior  ####################################

  #########################
  #  non_cascading_store  #
  #########################

  ###
  # @method non_cascading_store( key, object )
  #
  # Perform Hash#[]= without cascading to children.
  #
  # @param [Object] key
  #
  #        Key for store.
  #
  # @param [Object] object
  #
  #        Object to set at key.
  #
  # @return [Object]
  #
  #         Object set.
  #
  alias_method :non_cascading_store, :[]=

  ##########################
  #  non_cascading_delete  #
  ##########################

  ###
  # @method non_cascading_delete( key, object )
  #
  # Perform Hash#delete without cascading to children.
  #
  # @param [Object] Key
  #
  #        Key for delete.
  #
  # @return [Object]
  #
  #         Object set.
  #
  alias_method :non_cascading_delete, :delete

  include ::Hash::Compositing::HashInterface
  
end
