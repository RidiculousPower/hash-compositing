
module ::Hash::Compositing::HashInterface
    
  ##########################
  #  self.append_features  #
  ##########################
  
  def self.append_features( instance )
    
    instance.module_eval do
      
      private
        
        alias_method :non_cascading_store, :[]=

        alias_method :non_cascading_delete, :delete

    end
    
    super

  end
  
  ###################
  #  self.included  #
  ###################

  def self.included( instance )
    
    instance.module_eval do
      
      alias_method :store, :[]=
    
    end
    
    super
    
  end

  ################
  #  initialize  #
  ################
  
  def initialize( parent_instance = nil, configuration_instance = nil )
    
    super( configuration_instance )
        
    @replaced_parents = { }
    @key_requires_lookup = { }

    # hashes from which we inherit
    @parents = [ ]
    
    # hashes that inherit from us
    @children = [ ]

    if parent_instance
      register_parent( parent_instance )
    end
    
  end

  ###################################  Sub-Hash Management  #######################################

  #####################
  #  register_parent  #
  #####################

  def register_parent( parent_instance )

    unless @parents.include?( parent_instance )

      @parents.push( parent_instance )

      parent_instance.register_child( self )

      # @key_requires_lookup tracks keys that we have not yet received from parent
      parent_instance.each do |this_key, this_object|
        @key_requires_lookup[ this_key ] = parent_instance
        non_cascading_store( this_key, nil )
      end

    end
    
  end
  
  ####################
  #  register_child  #
  ####################

  def register_child( child_composite_hash )

    @children.push( child_composite_hash )

    return self

  end

  ##################
  #  has_parents?  #
  ##################
  
  def has_parents?
    
    return ! @parents.empty?
    
  end

  #############
  #  parents  #
  #############
  
  attr_reader :parents

  #################
  #  has_parent?  #
  #################
  
  def has_parent?( parent_instance )
    
    return @parents.include?( parent_instance )
    
  end

  ######################
  #  unregister_child  #
  ######################

  def unregister_child( child_composite_hash )

    @children.delete( child_composite_hash )

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
    
    load_parent_state
    
    super
    
  end
  
  ##########
  #  each  #
  ##########
  
  def each( *args, & block )

    load_parent_state

    super
    
  end

  ##########
  #  to_s  #
  ##########
  
  def to_s
   
    load_parent_state
   
    super
    
  end

  #############
  #  inspect  #
  #############
  
  def inspect
   
    load_parent_state
   
    super
    
  end
  
  ########
  #  []  #
  ########
  
  def []( key )
    
    return_value = nil

    if @key_requires_lookup[ key ]
      return_value = lazy_set_parent_element_in_self( key )
    else
      return_value = super
    end

    return return_value
    
  end
  
  #########
  #  []=  #
  #########

  def []=( key, object )

    @replaced_parents[ key ] = true
    
    @key_requires_lookup.delete( key )
    
    super
    
    parent_instance = self
    
    @children.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_as_sub_hash_for_parent_store( parent_instance, key )
      end
    end
        
    return object

  end

  ############
  #  delete  #
  ############
  
  def delete( key )

    @replaced_parents.delete( key )

    @key_requires_lookup.delete( key )

    object = super

    parent_instance = self
    
    @children.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_as_sub_hash_for_parent_delete( parent_instance, key, object )
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
    @parents.each do |this_parent|
      this_parent.unregister_child( self )
    end
    
    return self
    
  end

  ##################################################################################################
      private ######################################################################################
  ##################################################################################################

  #########################  Self-as-Sub Management for Parent Updates  ############################

  #####################################
  #  lazy_set_parent_element_in_self  #
  #####################################
  
  def lazy_set_parent_element_in_self( key, *optional_object )

    object = nil

    parent_instance = @key_requires_lookup.delete( key )
    
    case optional_object.count
      when 0
        object = parent_instance[ key ]
      when 1
        object = optional_object[ 0 ]
    end

    unless @without_child_hooks
      object = child_pre_set_hook( key, object )
    end

    non_cascading_store( key, object )
  
    unless @without_child_hooks
      object = child_post_set_hook( key, object )
    end
    
    return object
    
  end

  #########################################
  #  update_as_sub_hash_for_parent_store  #
  #########################################

  def update_as_sub_hash_for_parent_store( parent_instance, key )
        
    unless @replaced_parents[ key ]
    
      @key_requires_lookup[ key ] = parent_instance
      
      non_cascading_store( key, nil )
      
      @children.each do |this_hash|
        this_hash.instance_eval do
          update_as_sub_hash_for_parent_store( parent_instance, key )
        end
      end
    
    end
    
  end
  
  ##########################################
  #  update_as_sub_hash_for_parent_delete  #
  ##########################################

  def update_as_sub_hash_for_parent_delete( parent_instance, key, object )

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
        
        @key_requires_lookup.delete( key )
        
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
        if @key_requires_lookup.delete( key )
          lazy_set_parent_element_in_self( key, object )
        end
        
      end
      
      @children.each do |this_hash|
        this_hash.instance_eval do
          update_as_sub_hash_for_parent_delete( parent_instance, key, object )
        end
      end
    
    end
    
  end

  #######################
  #  load_parent_state  #
  #######################

  def load_parent_state

    @key_requires_lookup.each do |this_key, true_value|
      self[ this_key ]
    end
   
  end
  
end
