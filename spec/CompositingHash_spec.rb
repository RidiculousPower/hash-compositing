
require_relative '../lib/compositing-hash.rb'

describe ::CompositingHash do

  before :all do

    module ::CompositingHash::MockA
      # needed for ccv ancestor determination
      def self.some_configuration
      end
    end
    module ::CompositingHash::MockB
    end
      
    @configuration_instance = ::CompositingHash::MockA
    @sub_configuration_instance = ::CompositingHash::MockB
    
  end

  ################
  #  initialize  #
  ################

  it 'can add initialize with an ancestor, inheriting its values and linking to it as a child' do
  
    cascading_composite_hash = ::CompositingHash.new

    cascading_composite_hash.instance_variable_get( :@parent_composite_hash ).should == nil
    cascading_composite_hash.should == {}
    cascading_composite_hash[ :A ] = 1
    cascading_composite_hash[ :B ] = 2
    cascading_composite_hash[ :C ] = 3
    cascading_composite_hash[ :D ] = 4
    cascading_composite_hash.should == { :A => 1,
                                         :B => 2,
                                         :C => 3,
                                         :D => 4 }
    
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )
    sub_cascading_composite_hash.instance_variable_get( :@parent_composite_hash ).should == cascading_composite_hash
    sub_cascading_composite_hash.should == { :A => 1,
                                             :B => 2,
                                             :C => 3,
                                             :D => 4 }

  end

  ##################################################################################################
  #    private #####################################################################################
  ##################################################################################################

  #########################################
  #  update_as_sub_hash_for_parent_store  #
  #########################################

  it 'can update for a parent store' do

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )
    
    sub_cascading_composite_hash.instance_eval do
      update_as_sub_hash_for_parent_store( :A, 1 )
      self.should == { :A => 1 }
    end
    
  end

  ##########################################
  #  update_as_sub_hash_for_parent_delete  #
  ##########################################

  it 'can update for a parent delete' do

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )
    
    cascading_composite_hash[ :A ] = 1
    cascading_composite_hash.should == { :A => 1 }
    sub_cascading_composite_hash.should == { :A => 1 }

    sub_cascading_composite_hash.instance_eval do
      update_as_sub_hash_for_parent_delete( :A )
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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )
    
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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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

    cascading_composite_hash = ::CompositingHash.new
    sub_cascading_composite_hash = ::CompositingHash.new( cascading_composite_hash )

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
  
end
