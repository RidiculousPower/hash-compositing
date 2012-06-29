
class ::CompositingHash < ::HookedHash

  ################
  #  initialize  #
  ################
  
  def initialize( parent_composite_hash = nil, configuration_instance = nil )
    
    super( configuration_instance )
        
    @replaced_parents = { }
    @parent_key_lookup = { }

    # we may later have our own child composites that register with us
    @sub_composite_hashes = [ ]

    initialize_for_parent( parent_composite_hash )
    
  end

  #############################
  #  parent_composite_object  #
  #  parent_composite_hash    #
  #############################

  attr_accessor :parent_composite_object

  alias_method :parent_composite_hash, :parent_composite_object

  ###################################  Sub-Hash Management  #######################################

  ###########################
  #  initialize_for_parent  #
  ###########################

  def initialize_for_parent( parent_composite_hash )

    if @parent_composite_object = parent_composite_hash

      @parent_composite_object.register_sub_composite_hash( self )

      # @parent_key_lookup tracks keys that we have not yet received from parent
      @parent_composite_object.each do |this_key, this_object|
        @parent_key_lookup[ this_key ] = true
        non_cascading_store( this_key, nil )
      end
      
    end

  end
  
  #################################
  #  register_sub_composite_hash  #
  #################################

  def register_sub_composite_hash( sub_composite_hash )

    @sub_composite_hashes.push( sub_composite_hash )

    return self

  end

  ###################################
  #  unregister_sub_composite_hash  #
  ###################################

  def unregister_sub_composite_hash( sub_composite_hash )

    @sub_composite_hashes.delete( sub_composite_hash )

    return self

  end

  ######################################  Subclass Hooks  ##########################################

  ########################
  #  child_pre_set_hook  #
  ########################

  def child_pre_set_hook( key, object )

    return object
    
  end

  #########################
  #  child_post_set_hook  #
  #########################

  def child_post_set_hook( key, object )
    
    return object
    
  end

  ###########################
  #  child_pre_delete_hook  #
  ###########################

  def child_pre_delete_hook( key )
    
    # false means delete does not take place
    return true
    
  end

  ############################
  #  child_post_delete_hook  #
  ############################

  def child_post_delete_hook( key, object )
    
    return object
    
  end
  
  #####################################  Self Management  ##########################################
  
  ########
  #  ==  #
  ########

  def ==( object )
    
    @parent_key_lookup.each do |this_key, true_value|
      self[ this_key ]
    end
    
    super
    
  end
  
  ##########
  #  each  #
  ##########
  
  def each( *args, & block )
    
    @parent_key_lookup.each do |this_key, true_value|
      self[ this_key ]
    end

    super
    
  end

  ##########
  #  to_s  #
  ##########
  
  def to_s
   
    @parent_key_lookup.each do |this_key, true_value|
      self[ this_key ]
    end
   
    super
    
  end

  #############
  #  inspect  #
  #############
  
  def inspect
   
    @parent_key_lookup.each do |this_key, true_value|
      self[ this_key ]
    end
   
    super
    
  end
    
  ########
  #  []  #
  ########
  
  def []( key )
    
    return_value = nil

    if @parent_key_lookup.has_key?( key )
      return_value = set_parent_element_in_self( key, @parent_composite_object[ key ] )
      @parent_key_lookup.delete( key )
    else
      return_value = super
    end

    return return_value
    
  end
  
  #########
  #  []=  #
  #########

  private
    alias_method :non_cascading_store, :store
  public
  
  def []=( key, object )

    @replaced_parents[ key ] = true
    
    @parent_key_lookup.delete( key )
    
    super
    
    @sub_composite_hashes.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_as_sub_hash_for_parent_store( key )
      end
    end
        
    return object

  end
  alias_method :store, :[]=

  ############
  #  delete  #
  ############

  private
    alias_method :non_cascading_delete, :delete
  public
  
  def delete( key )

    @replaced_parents.delete( key )

    @parent_key_lookup.delete( key )

    object = super

    @sub_composite_hashes.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_as_sub_hash_for_parent_delete( key, object )
      end
    end

    return object

  end

  #############
  #  freeze!  #
  #############

  # freezes configuration and prevents ancestors from changing this configuration in the future
  def freeze!
    
    # unregister with parent composite so we don't get future updates from it
    if @parent_composite_object
      @parent_composite_object.unregister_sub_composite_hash( self )
    end
    
    return self
    
  end

  ##################################################################################################
      private ######################################################################################
  ##################################################################################################

  #########################  Self-as-Sub Management for Parent Updates  ############################

  ################################
  #  set_parent_element_in_self  #
  ################################
  
  def set_parent_element_in_self( key, object )

    unless @without_child_hooks
      object = child_pre_set_hook( key, object )
    end
    
    unless @without_hooks
      object = pre_set_hook( key, object )
    end
    
    non_cascading_store( key, object )
  
    unless @without_hooks
      object = post_set_hook( key, object )
    end

    unless @without_child_hooks
      object = child_post_set_hook( key, object )
    end
    
    return object
    
  end

  #########################################
  #  update_as_sub_hash_for_parent_store  #
  #########################################

  def update_as_sub_hash_for_parent_store( key )
        
    unless @replaced_parents[ key ]
    
      @parent_key_lookup[ key ] = true
      
      @sub_composite_hashes.each do |this_hash|
        this_hash.instance_eval do
          update_as_sub_hash_for_parent_store( key )
        end
      end
    
    end
    
  end
  
  ##########################################
  #  update_as_sub_hash_for_parent_delete  #
  ##########################################

  def update_as_sub_hash_for_parent_delete( key, object )

    unless @replaced_parents[ key ]
            
      if @without_child_hooks
        child_pre_delete_hook_result = true
      else
        child_pre_delete_hook_result = child_pre_delete_hook( key )
      end
      
      if @without_hooks
        pre_delete_hook_result = true
      else
        pre_delete_hook_result = pre_delete_hook( key )
      end

      if child_pre_delete_hook_result and pre_delete_hook_result
         
        @parent_key_lookup.delete( key )      
        object = non_cascading_delete( key )
        
        unless @without_hooks
          post_delete_hook( key, object )
        end

        unless @without_child_hooks
          child_post_delete_hook( key, object )
        end
      
      else
        
        # if we were told not to delete in child when parent delete
        # and the child does not yet have its parent value
        # then we need to get it now
        if @parent_key_lookup.delete( key )
          self[ key ] = object
        end
        
      end
      
      @sub_composite_hashes.each do |this_hash|
        this_hash.instance_eval do
          update_as_sub_hash_for_parent_delete( key, object )
        end
      end
    
    end
    
  end
  
end
