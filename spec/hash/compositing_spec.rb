
require_relative '../../lib/hash-compositing.rb'

describe ::Hash::Compositing do

  before :all do

    module ::Hash::Compositing::MockA
      # needed for ccv ancestor determination
      def self.some_configuration
      end
    end
    module ::Hash::Compositing::MockB
    end
      
    @configuration_instance = ::Hash::Compositing::MockA
    @sub_configuration_instance = ::Hash::Compositing::MockB
    
  end

  ################
  #  initialize  #
  ################

  it 'can add initialize with an ancestor, inheriting its values and linking to it as a child' do
  
    cascading_composite_hash = ::Hash::Compositing.new

    cascading_composite_hash.has_parents?.should == false
    cascading_composite_hash.parents.should == [ ]
    cascading_composite_hash.should == {}
    cascading_composite_hash[ :A ] = 1
    cascading_composite_hash[ :B ] = 2
    cascading_composite_hash[ :C ] = 3
    cascading_composite_hash[ :D ] = 4
    cascading_composite_hash.should == { :A => 1,
                                         :B => 2,
                                         :C => 3,
                                         :D => 4 }
    
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )
    sub_cascading_composite_hash.has_parents?.should == true
    sub_cascading_composite_hash.parents.should == [ cascading_composite_hash ]
    sub_cascading_composite_hash.has_parent?( cascading_composite_hash ).should == true
    sub_cascading_composite_hash.should == { :A => 1,
                                             :B => 2,
                                             :C => 3,
                                             :D => 4 }
    
    second_parent_hash = ::Hash::Compositing.new
    second_parent_hash[ :E ] = 5
    second_parent_hash[ :F ] = 6
    second_parent_hash[ :G ] = 7
    
    sub_cascading_composite_hash.register_parent( second_parent_hash )
    sub_cascading_composite_hash.parents.should == [ cascading_composite_hash, second_parent_hash ]
    sub_cascading_composite_hash.has_parent?( second_parent_hash ).should == true
    sub_cascading_composite_hash.should == { :A => 1,
                                             :B => 2,
                                             :C => 3,
                                             :D => 4,
                                             :E => 5,
                                             :F => 6,
                                             :G => 7 }
    
  end

  ##################################################################################################
  #    private #####################################################################################
  ##################################################################################################

  #########################################
  #  update_as_sub_hash_for_parent_store  #
  #########################################

  it 'can update for a parent store' do

    cascading_composite_hash = ::Hash::Compositing.new
    cascading_composite_hash[ :A ] = 1
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )
    
    sub_cascading_composite_hash.instance_eval do
      update_as_sub_hash_for_parent_store( cascading_composite_hash, :A )
      self.should == { :A => 1 }
    end
    
  end

  ##########################################
  #  update_as_sub_hash_for_parent_delete  #
  ##########################################

  it 'can update for a parent delete' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )
    
    cascading_composite_hash[ :A ] = 1
    cascading_composite_hash.should == { :A => 1 }
    sub_cascading_composite_hash.should == { :A => 1 }

    sub_cascading_composite_hash.instance_eval do
      update_as_sub_hash_for_parent_delete( cascading_composite_hash, :A, 1 )
      self.should == { }
    end
    
  end

  ##################################################################################################
  #    public ######################################################################################
  ##################################################################################################

  #########
  #  []=  #
  #########

  it 'can add elements' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )
    
    cascading_composite_hash[ :some_setting ] = :some_value
    cascading_composite_hash.should == { :some_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting => :some_value }

    cascading_composite_hash[ :other_setting ] = :some_value
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting  => :some_value,
                                             :other_setting => :some_value }

    sub_cascading_composite_hash[ :yet_another_setting ] = :some_value
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting        => :some_value,
                                             :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }

    cascading_composite_hash.method( :[]= ).should == cascading_composite_hash.method( :store )
    
  end

  ############
  #  delete  #
  ############

  it 'can delete elements' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.store( :some_setting, :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting   => :some_value }

    cascading_composite_hash.store( :other_setting, :some_value )
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting  => :some_value,
                                             :other_setting => :some_value }

    cascading_composite_hash.delete( :some_setting )
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting => :some_value }

    sub_cascading_composite_hash.store( :yet_another_setting, :some_value )
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }

    sub_cascading_composite_hash.delete( :other_setting )
    sub_cascading_composite_hash.should == { :yet_another_setting => :some_value }
    cascading_composite_hash.should == { :other_setting => :some_value }

  end

  ###############
  #  delete_if  #
  ###############

  it 'can delete elements with a block' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.store( :some_setting, :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting => :some_value }

    cascading_composite_hash.store( :other_setting, :some_value )
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting  => :some_value,
                                             :other_setting => :some_value }
    cascading_composite_hash.delete_if do |key, value|
      key == :some_setting
    end
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting => :some_value }

    sub_cascading_composite_hash.store( :yet_another_setting, :some_value )
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }
    sub_cascading_composite_hash.delete_if do |key, value|
      key == :other_setting
    end
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :yet_another_setting => :some_value }

  end

  #############
  #  reject!  #
  #############

  it 'can delete elements with a block' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.store( :some_setting, :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting => :some_value }

    cascading_composite_hash.store( :other_setting, :some_value )
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting  => :some_value,
                                             :other_setting => :some_value }
    cascading_composite_hash.reject! do |key, value|
      key == :some_setting
    end
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting => :some_value }

    sub_cascading_composite_hash.store( :yet_another_setting, :some_value )
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }
    sub_cascading_composite_hash.reject! do |key, value|
      key == :other_setting
    end
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :yet_another_setting => :some_value }

  end
  
  #############
  #  keep_if  #
  #############

  it 'can keep elements with a block' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.store( :some_setting, :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting => :some_value }

    cascading_composite_hash.store( :other_setting, :some_value )
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting  => :some_value,
                                             :other_setting => :some_value }
    cascading_composite_hash.keep_if do |key, value|
      key != :some_setting
    end
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting => :some_value }

    sub_cascading_composite_hash.store( :yet_another_setting, :some_value )
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }
    sub_cascading_composite_hash.keep_if do |key, value|
      key != :other_setting
    end
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :yet_another_setting => :some_value }

  end

  #############
  #  select!  #
  #############

  it 'can keep elements with a block' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.store( :some_setting, :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting => :some_value }

    cascading_composite_hash.store( :other_setting, :some_value )
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :some_setting  => :some_value,
                                             :other_setting => :some_value }
    cascading_composite_hash.select! do |key, value|
      key != :some_setting
    end
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting => :some_value }

    sub_cascading_composite_hash.store( :yet_another_setting, :some_value )
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }
    sub_cascading_composite_hash.select! do |key, value|
      key != :other_setting
    end
    cascading_composite_hash.should == { :other_setting => :some_value }
    sub_cascading_composite_hash.should == { :yet_another_setting => :some_value }

  end
  
  ############
  #  merge!  #
  #  update  #
  ############
  
  it 'can merge from another hash' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.merge!( :some_setting => :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    cascading_composite_hash.merge!( :other_setting => :some_value )
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }

    sub_cascading_composite_hash.should == { :some_setting    => :some_value,
                                             :other_setting   => :some_value }
    sub_cascading_composite_hash.merge!( :yet_another_setting => :some_value )
    sub_cascading_composite_hash.should == { :some_setting        => :some_value,
                                             :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }

  end
  
  #############
  #  replace  #
  #############
  
  it 'can replace existing elements with others' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.replace( :some_setting => :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    cascading_composite_hash.replace( :other_setting => :some_value )
    cascading_composite_hash.should == { :other_setting => :some_value }

    sub_cascading_composite_hash.should == { :other_setting   => :some_value }
    sub_cascading_composite_hash.replace( :yet_another_setting => :some_value )
    sub_cascading_composite_hash.should == { :yet_another_setting => :some_value }

  end

  ###########
  #  shift  #
  ###########
  
  it 'can shift the first element' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.store( :some_setting, :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    cascading_composite_hash.store( :other_setting, :some_value )
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    cascading_composite_hash.shift
    cascading_composite_hash.should == { :other_setting => :some_value }

    sub_cascading_composite_hash.should == { :other_setting   => :some_value }
    sub_cascading_composite_hash.store( :yet_another_setting, :some_value )
    sub_cascading_composite_hash.should == { :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }
    sub_cascading_composite_hash.shift
    sub_cascading_composite_hash.should == { :yet_another_setting => :some_value }
    cascading_composite_hash.should == { :other_setting => :some_value }

  end

  ###########
  #  clear  #
  ###########
  
  it 'can clear, causing present elements to be excluded' do

    cascading_composite_hash = ::Hash::Compositing.new
    sub_cascading_composite_hash = ::Hash::Compositing.new( cascading_composite_hash )

    cascading_composite_hash.store( :some_setting, :some_value )
    cascading_composite_hash.should == { :some_setting => :some_value }
    cascading_composite_hash.store( :other_setting, :some_value )
    cascading_composite_hash.should == { :some_setting  => :some_value,
                                         :other_setting => :some_value }
    cascading_composite_hash.clear
    cascading_composite_hash.should == { }
    cascading_composite_hash.store( :other_setting, :some_value )
    cascading_composite_hash.should == { :other_setting => :some_value }

    sub_cascading_composite_hash.should == { :other_setting   => :some_value }
    sub_cascading_composite_hash.store( :yet_another_setting, :some_value )
    sub_cascading_composite_hash.should == { :other_setting       => :some_value,
                                             :yet_another_setting => :some_value }
    sub_cascading_composite_hash.clear
    sub_cascading_composite_hash.should == { }
    cascading_composite_hash.should == { :other_setting => :some_value }

  end

  ##################
  #  pre_set_hook  #
  ##################

  it 'has a hook that is called before setting a value; return value is used in place of object' do
    
    class ::Hash::Compositing::SubMockPreSet < ::Hash::Compositing
      
      def pre_set_hook( key, object, is_insert = false )
        return :some_other_value
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockPreSet.new

    cascading_composite_hash[ :some_key ] = :some_value
    
    cascading_composite_hash.should == { :some_key => :some_other_value }
    
  end

  ###################
  #  post_set_hook  #
  ###################

  it 'has a hook that is called after setting a value' do

    class ::Hash::Compositing::SubMockPostSet < ::Hash::Compositing
      
      def post_set_hook( key, object, is_insert = false )
        unless key == :some_other_key
          self[ :some_other_key ] = :some_other_value
        end
        return object
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockPostSet.new

    cascading_composite_hash[ :some_key ] = :some_value
    
    cascading_composite_hash.should == { :some_key => :some_value,
                                          :some_other_key => :some_other_value }
    
  end

  ##################
  #  pre_get_hook  #
  ##################

  it 'has a hook that is called before getting a value; if return value is false, get does not occur' do
    
    class ::Hash::Compositing::SubMockPreGet < ::Hash::Compositing
      
      def pre_get_hook( key )
        return false
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockPreGet.new
    
    cascading_composite_hash[ :some_key ] = :some_value
    cascading_composite_hash[ :some_key ].should == nil
    
    cascading_composite_hash.should == { :some_key => :some_value }
    
  end

  ###################
  #  post_get_hook  #
  ###################

  it 'has a hook that is called after getting a value' do

    class ::Hash::Compositing::SubMockPostGet < ::Hash::Compositing
      
      def post_get_hook( key, object )
        self[ :some_other_key ] = :some_other_value
        return object
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockPostGet.new
    
    cascading_composite_hash[ :some_key ] = :some_value

    cascading_composite_hash.should == { :some_key => :some_value }
    
    cascading_composite_hash[ :some_key ].should == :some_value
    
    cascading_composite_hash.should == { :some_key => :some_value,
                                         :some_other_key => :some_other_value }
    
  end

  #####################
  #  pre_delete_hook  #
  #####################

  it 'has a hook that is called before deleting an key; if return value is false, delete does not occur' do
    
    class ::Hash::Compositing::SubMockPreDelete < ::Hash::Compositing
      
      def pre_delete_hook( key )
        return false
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockPreDelete.new
    
    cascading_composite_hash[ :some_key ] = :some_value
    cascading_composite_hash.delete( :some_key )
    
    cascading_composite_hash.should == { :some_key => :some_value }
    
  end

  ######################
  #  post_delete_hook  #
  ######################

  it 'has a hook that is called after deleting an key' do
    
    class ::Hash::Compositing::SubMockPostDelete < ::Hash::Compositing
      
      def post_delete_hook( key, object )
        unless key == :some_other_key
          delete( :some_other_key )
        end
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockPostDelete.new
    
    cascading_composite_hash[ :some_key ] = :some_value
    cascading_composite_hash[ :some_other_key ] = :some_other_value
    cascading_composite_hash.delete( :some_key )
    
    cascading_composite_hash.should == { }
    
  end

  ########################
  #  child_pre_set_hook  #
  ########################

  it 'has a hook that is called before setting a value that has been passed by a parent; return value is used in place of object' do
    
    class ::Hash::Compositing::SubMockChildPreSet < ::Hash::Compositing
      
      def child_pre_set_hook( key, object, is_insert = false, parent_instance = nil )
        return :some_other_value
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockChildPreSet.new
    sub_cascading_composite_hash = ::Hash::Compositing::SubMockChildPreSet.new( cascading_composite_hash )

    cascading_composite_hash[ :some_key ] = :some_value

    cascading_composite_hash.should == { :some_key => :some_value }
    sub_cascading_composite_hash.should == { :some_key => :some_other_value }
    
  end

  #########################
  #  child_post_set_hook  #
  #########################

  it 'has a hook that is called after setting a value passed by a parent' do

    class ::Hash::Compositing::SubMockChildPostSet < ::Hash::Compositing
      
      def child_post_set_hook( key, object, is_insert = false, parent_instance = nil )
        self[ :some_other_key ] = :some_other_value
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockChildPostSet.new
    sub_cascading_composite_hash = ::Hash::Compositing::SubMockChildPostSet.new( cascading_composite_hash )
    cascading_composite_hash[ :some_key ] = :some_value

    cascading_composite_hash.should == { :some_key => :some_value }
    sub_cascading_composite_hash.should == { :some_key => :some_value,
                                             :some_other_key => :some_other_value }
    
  end

  ###########################
  #  child_pre_delete_hook  #
  ###########################

  it 'has a hook that is called before deleting an key that has been passed by a parent; if return value is false, delete does not occur' do

    class ::Hash::Compositing::SubMockChildPreDelete < ::Hash::Compositing
      
      def child_pre_delete_hook( key, parent_instance = nil )
        false
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockChildPreDelete.new
    sub_cascading_composite_hash = ::Hash::Compositing::SubMockChildPreDelete.new( cascading_composite_hash )
    cascading_composite_hash[ :some_key ] = :some_value
    cascading_composite_hash.delete( :some_key )

    cascading_composite_hash.should == { }
    sub_cascading_composite_hash.should == { :some_key => :some_value }
    
  end

  ############################
  #  child_post_delete_hook  #
  ############################

  it 'has a hook that is called after deleting an key passed by a parent' do

    class ::Hash::Compositing::SubMockChildPostDelete < ::Hash::Compositing
      
      def child_post_delete_hook( key, object, parent_instance = nil )
        delete( :some_other_key )
      end
      
    end
    
    cascading_composite_hash = ::Hash::Compositing::SubMockChildPostDelete.new
    sub_cascading_composite_hash = ::Hash::Compositing::SubMockChildPostDelete.new( cascading_composite_hash )
    cascading_composite_hash[ :some_key ] = :some_value
    sub_cascading_composite_hash[ :some_other_key ] = :some_other_value
    cascading_composite_hash.delete( :some_key )

    cascading_composite_hash.should == { }
    sub_cascading_composite_hash.should == { }
    
  end
  
end
