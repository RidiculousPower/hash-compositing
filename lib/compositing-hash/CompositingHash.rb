
class ::CompositingHash < ::Hash

  attr_reader :configuration_instance, :configuration_name

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

    if @parent_composite_hash = parent_composite_hash

      @parent_composite_hash.register_sub_composite_hash( self )

      @parent_composite_hash.each do |this_key, this_object|
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
    
    if pre_get_hook( key )
    
      object = super( key )
    
      object = post_get_hook( key, object )

    end
      
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
    
    object = pre_set_hook( key, object )

    non_cascading_store( key, object )

    object = post_set_hook( key, object )

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

  ###########
  #  clear  #
  ###########
  
  def clear

    keys.each do |this_key|
      delete( this_key )
    end

    return self

  end
  
  #############
  #  freeze!  #
  #############

  # freezes configuration and prevents ancestors from changing this configuration in the future
  def freeze!
    
    # unregister with parent composite so we don't get future updates from it
    if @parent_composite_hash
      @parent_composite_hash.unregister_sub_composite_hash( self )
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
    
    if pre_delete_hook( key )
    
      object = super_non_cascading_delete( key )

      object = post_delete_hook( key, object )

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

    object = pre_set_hook( key, object )
    object = child_pre_set_hook( key, object )
    
    non_cascading_store( key, object )
  
    object = post_set_hook( key, object )
    object = child_post_set_hook( key, object )
    
  end

  ##########################################
  #  update_as_sub_hash_for_parent_delete  #
  ##########################################

  def update_as_sub_hash_for_parent_delete( key )
    
    unless @replaced_parents[ key ]
    
      if pre_delete_hook( key )       and
         child_pre_delete_hook( key )
         
        object = non_cascading_delete( key )
      
        post_delete_hook( key, object )
        child_post_delete_hook( key, object )
      
      end
      
      @sub_composite_hashes.each do |this_hash|
        this_hash.instance_eval do
          update_as_sub_hash_for_parent_delete( key )
        end
      end
    
    end
    
  end
  
end
