
## 3/17/12 ##

Initial release.

## 3/18/12 ##

Added hooks for subclassing.

## 3/19/12 ##

Moved parent initialization to separate method (with call to initialize so existing behavior remains).
Now parent can be initialized after object initialization.

## 3/24/12 ##

Added _without_hook methods to perform actions without calling hooks.

## 5/27/12 ##

Added common CompositingObject support.
Added :parent_composite_hash reader.

## 5/31/12 ##

Added :parent_composite_object and changed :parent_composite_hash to alias :parent_composite_object.

## 6/1/12 ##

Added :configuration_instance parameter to :initialize.

## 6/29/12 ##

Updates/fixes for hash-hooked.

## 6/30/12 ##

Key lookup from parents is now lazy.

## 7/14/12 ##

Fixes for lazy lookup.

## 7/26/12 ##

Insert nil for parent store as placeholder.

## 10/15/2012 ##

Updated to support multiple parents.

## 11/24/2012 ##

Minor changes to correspond to updates in Array packages.
Changes from has_parent?( ... ) to is_parent?( ... ).
Other minor updates.

## 2/15/2013 ##

Changed :is_parent? to check by equal? instead of include? which uses == and therefore loads parent state.

## 7/08/2013 ##

Removed module-cluster dependency so that module-cluster can use hooked and compositing objects.
