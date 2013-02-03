
module ::Hash::Compositing::HashInterface

  extend ::Module::Cluster

  ################
  #  initialize  #
  ################
  
  ###
  # @overload initialize( parent_instance, configuration_instance, hash_initialization_arg, ... )
  #
  #   @param [Hash::Compositing] parent_instance
  #   
  #          Instance from which instance will inherit elements.
  #   
  #   @param [Object] configuration_instance
  #   
  #          Instance associated with instance.
  #   
  #   @param hash_initialization_arg
  #   
  #          Arguments passed to Hash#initialize.
  #
  def initialize( parent_instance = nil, configuration_instance = nil, *hash_initialization_args )
    
    super( configuration_instance, *hash_initialization_args )
        
    @replaced_parents = { }
    @key_requires_lookup = { }

    # hashes from which we inherit
    @parents = [ ]
    
    # hashes that inherit from us
    @children = [ ]
    
    # track keys parents own
    # parent => [ keys ]
    @parent_keys = { }

    if parent_instance
      register_parent( parent_instance )
    end
    
  end

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
  cluster( :non_cascading_store ).before_include.cascade_to( :class ) do |hooked_instance|
    
    hooked_instance.class_eval do
      
      unless method_defined?( :non_cascading_store )
        alias_method :non_cascading_store, :[]=
      end
      
    end

  end

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
  cluster( :non_cascading_delete ).before_include.cascade_to( :class ) do |hooked_instance|
    
    hooked_instance.class_eval do
      
      unless method_defined?( :non_cascading_delete )
        alias_method :non_cascading_delete, :delete
      end
      
    end

  end
    
  ###################################  Sub-Hash Management  #######################################

  #####################
  #  register_parent  #
  #####################

  ###
  # Register a parent for element inheritance.
  #
  # @param [Hash::Compositing] parent_instance
  #
  #        Instance from which instance will inherit elements.
  #
  # @return [Hash::Compositing] 
  #
  #         Self.
  #
  def register_parent( parent_instance )

    unless @parents.include?( parent_instance )

      @parents.push( parent_instance )
      @parent_keys[ parent_instance ] = parent_keys = parent_instance.keys

      parent_instance.register_child( self )

      # @key_requires_lookup tracks keys that we have not yet received from parent
      parent_keys.each do |this_key|
        @key_requires_lookup[ this_key ] = parent_instance
        non_cascading_store( this_key, nil )
      end

    end
    
    return self
    
  end

  #######################
  #  unregister_parent  #
  #######################

  ###
  # Unregister a parent for element inheritance and remove all associated elements.
  #
  # @param [Hash::Compositing] parent_instance
  #
  #        Instance from which instance will inherit elements.
  #
  # @return [Hash::Compositing] 
  #
  #         Self.
  #
  def unregister_parent( parent_instance )
    
    @parents.delete( parent_instance )
    
    parent_instance.unregister_child( self )
    
    parent_keys = @parent_keys.delete( parent_instance )
    
    return self
    
  end

  ####################
  #  replace_parent  #
  ####################

  ###
  # Replace a registered parent for element inheritance with a different parent,
  #   removing all associated elements of the existing parent and adding those
  #   from the new parent.
  #
  # @param [Hash::Compositing] parent_instance
  #
  #        Existing instance from which instance is inheriting elements.
  #
  # @param [Hash::Compositing] parent_instance
  #
  #        New instance from which instance will inherit elements instead.
  #
  # @return [Hash::Compositing] 
  #
  #         Self.
  #
  def replace_parent( parent_instance, new_parent_instance  )
    
    unregister_parent( parent_instance )
    
    register_parent( new_parent_instance )
    
    return self
    
  end
    
  ####################
  #  register_child  #
  ####################

  ###
  # Register child instance that will inherit elements.
  #
  # @param [Hash::Compositing] child_composite_hash
  #
  #        Instance that will inherit elements from this instance.
  #
  # @return [Hash::Compositing] Self.
  #
  def register_child( child_composite_hash )

    @children.push( child_composite_hash )

    return self

  end

  ######################
  #  unregister_child  #
  ######################

  ###
  # Unregister child instance so that it will no longer inherit elements.
  #
  # @param [Hash::Compositing] child_composite_hash
  #
  #        Instance that should no longer inherit elements from this instance.
  #
  # @return [Hash::Compositing] 
  #
  #         Self.
  #
  def unregister_child( child_composite_hash )

    @children.delete( child_composite_hash )

    return self

  end

  ##################
  #  has_parents?  #
  ##################
  
  ###
  # Query whether instance has parent instances from which it inherits elements.
  #
  # @return [true,false] 
  #
  #         Whether instance has one or more parent instances.
  #
  def has_parents?
    
    return ! @parents.empty?
    
  end

  #############
  #  parents  #
  #############
  
  ###
  # @!attribute [r]
  #
  # Parents of instance from which instance inherits elements.
  #
  # @return [Hash<Hash::Compositing>]
  #
  #         Hash of parents.
  #
  attr_reader :parents

  #################
  #  is_parent?  #
  #################
  
  ###
  # Query whether instance has instance as a parent instance from which it inherits elements.
  #
  # @params [Hash::Compositing] potential_parent_instance
  # 
  #         Instance being queried.
  # 
  # @return [true,false] 
  #
  #         Whether potential_parent_instance is a parent of instance.
  #
  def is_parent?( parent_instance )
    
    return @parents.include?( parent_instance )
    
  end

  ######################################  Subclass Hooks  ##########################################

  ########################
  #  child_pre_set_hook  #
  ########################

  ###
  # A hook that is called before setting a value inherited from a parent set; 
  #   return value is used in place of object.
  #
  # @param [Object] key 
  #
  #        Key at which store is taking place.
  #
  # @param [Object] object 
  #
  #        Element being stored.
  #
  # @param [Hash::Compositing] parent_instance 
  #
  #        Instance that initiated set or insert.
  #
  # @return [true,false] 
  #
  #         Return value is used in place of object.
  #
  def child_pre_set_hook( key, object, parent_instance = nil )

    return object
    
  end

  #########################
  #  child_post_set_hook  #
  #########################

  ###
  # A hook that is called after setting a value inherited from a parent set.
  #
  # @param [Object] key 
  #
  #        Key at which set/insert is taking place.
  #
  # @param [Object] object 
  #
  #        Element being stored.
  #
  # @param [Hash::Compositing] parent_instance 
  #
  #        Instance that initiated set or insert.
  #
  # @return [Object] Ignored.
  #
  def child_post_set_hook( key, object, parent_instance = nil )
    
    return object
    
  end

  ###########################
  #  child_pre_delete_hook  #
  ###########################

  ###
  # A hook that is called before deleting a value inherited from a parent delete; 
  #   if return value is false, delete does not occur.
  #
  # @param [Object] key 
  #
  #        Key at which delete is taking place.
  #
  # @param [Hash::Compositing] parent_instance 
  #
  #        Instance that initiated delete.
  #
  # @return [true,false] 
  #
  #         If return value is false, delete does not occur.
  #
  def child_pre_delete_hook( key, parent_instance = nil )
    
    # false means delete does not take place
    return true
    
  end

  ############################
  #  child_post_delete_hook  #
  ############################

  ###
  # A hook that is called after deleting a value inherited from a parent delete.
  #
  # @param [Object] key 
  #
  #        Key at which delete took place.
  #
  # @param [Object] object 
  #
  #        Element deleted.
  #
  # @param [Hash::Compositing] parent_instance 
  #
  #        Instance that initiated delete.
  #
  # @return [Object] 
  #
  #         Object returned in place of delete result.
  #
  def child_post_delete_hook( key, object, parent_instance = nil )
    
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
  
  ###########
  #  []=    #
  #  store  #
  ###########

  def []=( key, object )

    @replaced_parents[ key ] = true
    
    @key_requires_lookup.delete( key )
    
    super
    
    parent_instance = self
    
    @children.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_for_parent_store( parent_instance, key )
      end
    end
        
    return object

  end

  alias_method :store, :[]=

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
        update_for_parent_delete( parent_instance, key, object )
      end
    end

    return object

  end

  #############
  #  freeze!  #
  #############

  ###
  # Unregisters parent(s) without removing values inherited from them.
  #
  # @param [Hash::Compositing] parent_instance
  #
  #        Freeze state only from parent instance if specified.
  #        Otherwise all parent's state will be frozen.
  #
  # @return [Hash::Compositing]
  #
  #         Self.
  #
  def freeze!( parent_instance = nil )
    
    # look up all values
    load_parent_state( parent_instance )
    
    if parent_instance
      
      parent_instance.unregister_child( self )
      
    else
      
      # unregister with parent composite so we don't get future updates from it
      @parents.each do |this_parent_instance|
        this_parent_instance.unregister_child( self )
      end
      
    end
    
    return self
    
  end

  #######################
  #  load_parent_state  #
  #######################

  ###
  # Load all elements not yet inherited from parent or parents (but marked to be inherited).
  #
  # @param [Hash::Compositing] parent_instance
  #
  #        Load state only from parent instance if specified.
  #        Otherwise all parent's state will be loaded.
  #
  # @return [Hash::Compositing]
  #
  #         Self.
  #
  def load_parent_state( parent_instance = nil )
    
    if parent_instance

      @key_requires_lookup.each do |this_key, this_parent_instance|
        if this_parent_instance == parent_instance
          self[ this_key ]
        end
      end
      
    else
      
      @key_requires_lookup.each do |this_key, this_parent_instance|
        self[ this_key ]
      end
      
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
  
  ###
  # Perform look-up of local key in parent or load value delivered from parent
  #   when parent delete was prevented in child.
  #
  # @overload lazy_set_parent_element_in_self( key, optional_object, ... )
  #
  #   @param [Object] key
  #
  #          Key in instance for which value requires look-up/set.
  #
  #   @param [Object] optional_object
  #
  #          If we deleted in parent and then child delete hook prevented local delete
  #          then we have an object passed since our parent can no longer provide it
  #
  # @return [Object]
  #
  #         Lazy set value.
  #
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
      object = child_pre_set_hook( key, object, parent_instance )
    end

    non_cascading_store( key, object )
  
    unless @without_child_hooks
      object = child_post_set_hook( key, object, parent_instance )
    end
    
    return object
    
  end

  #############################
  #  update_for_parent_store  #
  #############################

  ###
  # Perform #set in self inherited from #store requested on parent (or parent of parent).
  #
  # @param [Hash::Compositing] parent_instance
  #
  #        Instance where #store occurred that is now cascading downward.
  #
  # @param [Object] key
  #
  #        Key in parent where #store occurred.
  #
  # @param [Object] object
  #
  #        Object store at key.
  #
  # @return [Hash::Compositing]
  #
  #         Self.
  #
  def update_for_parent_store( parent_instance, key )
        
    unless @replaced_parents[ key ]
    
      @key_requires_lookup[ key ] = parent_instance
      
      non_cascading_store( key, nil )
      
      @children.each do |this_hash|
        this_hash.instance_eval do
          update_for_parent_store( parent_instance, key )
        end
      end
    
    end
    
    return self
    
  end
  
  ##############################
  #  update_for_parent_delete  #
  ##############################

  ###
  # Perform #set in self inherited from #delete requested on parent (or parent of parent).
  #
  # @param [Hash::Compositing] parent_instance
  #
  #        Instance where #delete occurred that is now cascading downward.
  #
  # @param [Object] key
  #
  #        Key in parent where #delete occurred.
  #
  # @param [Object] object
  #
  #        Object returned from parent #delete.
  #
  # @return [Hash::Compositing]
  #
  #         Self.
  #
  def update_for_parent_delete( parent_instance, key, object )

    unless @replaced_parents[ key ]
            
      if @without_child_hooks
        child_pre_delete_hook_result = true
      else
        child_pre_delete_hook_result = child_pre_delete_hook( key, parent_instance )
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
          child_post_delete_hook( key, object, parent_instance )
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
          update_for_parent_delete( parent_instance, key, object )
        end
      end
    
    end
    
  end
  
end
