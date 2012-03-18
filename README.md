# CompositingHash #

http://rubygems.org/gems/compositing-hash

# Description #

Provides CompositingHash.

# Summary #

An implementation of Hash that permits chaining, where children inherit changes to parent and where parent settings can be overridden in children.

# Install #

* sudo gem install compositing-hash

# Usage #

```ruby
compositing_hash = CompositingHash.new
sub_compositing_hash = CompositingHash.new( compositing_hash )

compositing_hash[ :some_key ] = :some_value
# compositing_hash
# => { :some_key => :some_value }
# sub_compositing_hash
# => { :some_key => :some_value }

compositing_hash.delete( :some_key )
# compositing_hash
# => { }
# sub_compositing_hash
# => { }

sub_compositing_hash[ :some_key ] = :some_value
# compositing_hash
# => { }
# sub_compositing_hash
# => { :some_key => :some_value }
```

# License #

  (The MIT License)

  Copyright (c) Asher

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  'Software'), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.