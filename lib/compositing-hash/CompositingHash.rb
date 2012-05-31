
class ::CompositingHash < ::Hash

  include ::CompositingObject

  alias_method :parent_composite_hash, :parent_composite_object

  ################
  #  initialize  #
  ################
  
  def initialize( parent_composite_hash = nil )

    @replaced_parents = { }

    # we may later have our own child composites that register with us
    @sub_composite_hashes = [ ]

    initialize_for_parent( parent_composite_hash )
    
  end

  ###################################  Sub-Hash Management  #######################################

  ###########################
  #  initialize_for_parent  #
  ###########################

  def initialize_for_parent( parent_composite_hash )

    if @parent_composite_object = parent_composite_hash

      @parent_composite_object.register_sub_composite_hash( self )

      @parent_composite_object.each do |this_key, this_object|
        set_parent_element_in_self( this_key, this_object )
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

  ##################
  #  pre_set_hook  #
  ##################

  def pre_set_hook( key, object )
    
    return object
    
  end

  ###################
  #  post_set_hook  #
  ###################

  def post_set_hook( key, object )

    return object
    
  end

  ##################
  #  pre_get_hook  #
  ##################

  def pre_get_hook( key )
    
    return true
    
  end

  ###################
  #  post_get_hook  #
  ###################

  def post_get_hook( key, object )
    
    return object
    
  end

  #####################
  #  pre_delete_hook  #
  #####################

  def pre_delete_hook( key )
    
    return true
    
  end

  ######################
  #  post_delete_hook  #
  ######################

  def post_delete_hook( key, object )
    
    return object
    
  end

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
  #  []  #
  ########

  def []( key )

    object = nil
    
    if @without_hooks
      pre_get_hook_result = true
    else
      pre_get_hook_result = pre_get_hook( key )
    end
    
    if pre_get_hook_result
    
      object = super( key )
      
      unless @without_hooks
        object = post_get_hook( key, object )
      end
      
    end
      
    return object
    
  end

  #######################
  #  get_without_hooks  #
  #######################

  def get_without_hooks( key )
    
    @without_hooks = true
    
    object = self[ key ]
    
    @without_hooks = false
    
    return object
    
  end
  
  #########
  #  []=  #
  #########

  private
    alias_method :non_cascading_store, :store
  public
  
  def []=( key, object )

    @replaced_parents[ key ] = true
    
    unless @without_hooks
      object = pre_set_hook( key, object )
    end
    
    non_cascading_store( key, object )

    unless @without_hooks
      object = post_set_hook( key, object )
    end
    
    @sub_composite_hashes.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_as_sub_hash_for_parent_store( key, object )
      end
    end
        
    return object

  end
  alias_method :store, :[]=

  #########################
  #  store_without_hooks  #
  #########################

  def store_without_hooks( key, object )
    
    @without_hooks = true
    
    self[ key ] = object
    
    @without_hooks = false
    
    return object
    
  end

  ############
  #  delete  #
  ############

  private
    alias_method :super_non_cascading_delete, :delete
  public
  
  def delete( key )

    @replaced_parents.delete( key )

    object = non_cascading_delete( key )

    @sub_composite_hashes.each do |this_sub_hash|
      this_sub_hash.instance_eval do
        update_as_sub_hash_for_parent_delete( key )
      end
    end

    return object

  end

  ##########################
  #  delete_without_hooks  #
  ##########################

  def delete_without_hooks( key )
    
    @without_hooks = true
    
    object = delete( key )
    
    @without_hooks = false
    
    return object
    
  end

  ###############
  #  delete_if  #
  ###############

  def delete_if

    return to_enum unless block_given?

    indexes = [ ]
    
    self.each do |this_key, this_object|
      if yield( this_key, this_object )
        delete( this_key )
      end
    end
        
    return self

  end

  #############################
  #  delete_if_without_hooks  #
  #############################

  def delete_if_without_hooks( & block )
    
    @without_hooks = true
    
    delete_if( & block )
    
    @without_hooks = false
    
  end

  #############
  #  reject!  #
  #############

  def reject!

    return to_enum unless block_given?
    
    return_value = nil
    
    self.each do |this_key, this_object|
      if yield( this_key, this_object )
        delete( this_key )
        return_value = self
      end
    end
    
    return return_value

  end

  ###########################
  #  reject_without_hooks!  #
  ###########################

  def reject_without_hooks!
    
    @without_hooks = true
    
    return_value = reject!( & block )
    
    @without_hooks = false
    
    return return_value
    
  end

  #############
  #  keep_if  #
  #############

  def keep_if

    return to_enum unless block_given?

    indexes = [ ]
    
    self.each do |this_key, this_object|
      unless yield( this_key, this_object )
        delete( this_key )
      end
    end
        
    return self


  end
  
  ###########################
  #  keep_if_without_hooks  #
  ###########################

  def keep_if_without_hooks( & block )
    
    @without_hooks = true
    
    keep_if( & block )
    
    @without_hooks = false
    
    return self
    
  end
  
  #############
  #  select!  #
  #############

  def select!

    return to_enum unless block_given?
    
    return_value = nil
    
    self.each do |this_key, this_object|
      unless yield( this_key, this_object )
        delete( this_key )
        return_value = self
      end
    end
    
    return return_value

  end

  ###########################
  #  select_without_hooks!  #
  ###########################

  def select_without_hooks!( & block )
    
    @without_hooks = true
    
    return_value = select!( & block )
    
    @without_hooks = false
    
    return return_value
    
  end

  ############
  #  merge!  #
  #  update  #
  ############
  
  private
    alias_method :non_cascading_merge!, :merge!
  public

  def merge!( other_hash )

    other_hash.each do |this_key, this_object|
      if @compositing_proc
        self[ this_key ] = @compositing_proc.call( self, this_key, this_object )
      else
        self[ this_key ] = this_object
      end
    end

    return self

  end
  alias_method :update, :merge!
  
  ##########################
  #  merge_without_hooks!  #
  #  update_without_hooks  #
  ##########################

  def merge_without_hooks!
    
    @without_hooks = true
    
    merge!( other_hash )
    
    @without_hooks = false
    
    return self
    
  end
  alias_method :update_without_hooks, :merge_without_hooks!
  
  #############
  #  replace  #
  #############
  
  def replace( other_hash )

    # clear current values
    clear

    # merge replacement settings
    merge!( other_hash )

    return self

  end

  ###########################
  #  replace_without_hooks  #
  ###########################

  def replace_without_hooks( other_hash )
    
    @without_hooks = true
    
    replace( other_hash )
    
    @without_hooks = false
    
  end

  ###########
  #  shift  #
  ###########
  
  def shift
    
    object = nil
    
    unless empty?
      last_key = first[ 0 ]
      object = delete( last_key )
    end    

    return [ last_key, object ]

  end

  #########################
  #  shift_without_hooks  #
  #########################

  def shift_without_hooks
    
    @without_hooks = true
    
    object = shift
    
    @without_hooks = false
    
    return object
    
  end

  ###########
  #  clear  #
  ###########
  
  def clear

    keys.each do |this_key|
      delete( this_key )
    end

    return self

  end
  
  #########################
  #  clear_without_hooks  #
  #########################

  def clear_without_hooks
    
    @without_hooks = true
    
    clear
    
    @without_hooks = false
    
    return self
    
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

  ##########################
  #  non_cascading_delete  #
  ##########################

  def non_cascading_delete( key )
    
    object = nil
    
    if @without_hooks
      pre_delete_result = true
    else
      pre_delete_result = pre_delete_hook( key )
    end
    
    if pre_delete_result
    
      object = super_non_cascading_delete( key )
      
      unless @without_hooks
        object = post_delete_hook( key, object )
      end
      
    end
    
    return object
    
  end

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
