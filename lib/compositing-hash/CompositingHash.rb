
class ::CompositingHash < ::HookedHash

  ################
  #  initialize  #
  ################
  
  def initialize( parent_composite_hash = nil, configuration_instance = nil )
    
    super( configuration_instance )
        
    @replaced_parents = { }

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

      @parent_composite_object.each do |this_key, this_object|
        update_as_sub_hash_for_parent_store( this_key, this_object )
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

  #########
  #  []=  #
  #########

  private
    alias_method :non_cascading_store, :store
  public
  
  def []=( key, object )

    @replaced_parents[ key ] = true

    super
    
    @sub_composite_hashes.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_as_sub_hash_for_parent_store( key, object )
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

    object = super

    @sub_composite_hashes.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_as_sub_hash_for_parent_delete( key )
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

  #########################################
  #  update_as_sub_hash_for_parent_store  #
  #########################################

  def update_as_sub_hash_for_parent_store( key, object )
        
    unless @replaced_parents[ key ]
    
      set_parent_element_in_self( key, object )
      
      @sub_composite_hashes.each do |this_hash|
        this_hash.instance_eval do
          update_as_sub_hash_for_parent_store( key, object )
        end
      end
    
    end
    
  end
  
  ################################
  #  set_parent_element_in_self  #
  ################################
  
  def set_parent_element_in_self( key, object )
    
    unless @without_hooks
      object = pre_set_hook( key, object )
      object = child_pre_set_hook( key, object )
    end
    
    non_cascading_store( key, object )
  
    unless @without_hooks
      object = post_set_hook( key, object )
      object = child_post_set_hook( key, object )
    end
    
  end

  ##########################################
  #  update_as_sub_hash_for_parent_delete  #
  ##########################################

  def update_as_sub_hash_for_parent_delete( key )

    unless @replaced_parents[ key ]
      
      if @without_hooks
        pre_delete_hook_result = true
        child_pre_delete_hook_result = true
      else
        pre_delete_hook_result = pre_delete_hook( key )
        child_pre_delete_hook_result = child_pre_delete_hook( key )
      end
      
      if pre_delete_hook_result and child_pre_delete_hook_result
         
        object = non_cascading_delete( key )
        
        unless @without_hooks
          post_delete_hook( key, object )
          child_post_delete_hook( key, object )
        end
        
      end
      
      @sub_composite_hashes.each do |this_hash|
        this_hash.instance_eval do
          update_as_sub_hash_for_parent_delete( key )
        end
      end
    
    end
    
  end
  
end
