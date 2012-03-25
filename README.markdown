ActsAsList for Mongoid
=====================

## Description

Mongoid::ActsAsList provides the ability of ordering and sorting a number of objects in a list using Mongoid as an ODM.

[![Build Status](https://secure.travis-ci.org/olivoil/mongoid_acts_as_list.png)](http://travis-ci.org/olivoil/mongoid_acts_as_list)
[![Dependency Status](https://gemnasium.com/olivoil/mongoid_acts_as_list.png)](https://gemnasium.com/olivoil/mongoid_acts_as_list)

## Install

Place the following in your Gemfile:

``` ruby
gem 'mongoid_acts_as_list', '~> 0.0.3'
```

Then run `bundle install`


## Configure

Configure defaults values used by ActsAsList:


``` ruby
Mongoid::ActsAsList.configure do |config|

  # These are the default values. Modify as you see fit:

  config.default_position_field = :position
  config.start_list_at = 0

end
```

Make sure it is loaded before calling ` acts_as_list `. You can place this code in an initializer file for example.

## Use

Activate ActsAsList in your models.

In has_many/belongs_to associations, you will need to provide a `:scope` option:

``` ruby
class List
  include Mongoid::Document

  has_many :items
end

class Item
  include Mongoid::Document
  include Mongoid::ActsAsList

  belongs_to :list
  acts_as_list scope: :list
end
```

On embedded document, the scope option is not necessary:

``` ruby
class List
  include Mongoid::Document

  embeds_many :items
end

class Item
  include Mongoid::Document
  include Mongoid::ActsAsList

  embedded_in :list
  acts_as_list
end
```

The public API is composed of the following methods.
All of the API from the original ActiveRecord ActsAsList gem is also available.
Check the source and [documentation](http://rubydoc.info/github/olivoil/mongoid_acts_as_list/master/frames) to find out more!


``` ruby
## Class Methods

list.items.order_by_position #=> returns all items in `list` ordered by position

## Instance Methods

item.move to: 2              #=> moves item to position number 2
item.move to: :start         #=> moves item to the first position in the list
item.move to: :end           #=> moves item to the last position in the list
item.move before: other_item #=> moves item before other_item
item.move after:  other_item #=> moves item after other_item
item.move forward:  3        #=> move item 3 positions closer to the end of the list
item.move backward: 2        #=> move item 2 positions closer to the start of the list
item.move :forward           #=> same as item.move(forward:  1)
item.move :backward          #=> same as item.move(backward: 1)

item.in_list?                #=> true
item.remove_from_list        #=> sets the position to nil and reorders other items
item.not_in_list?            #=> true

item.first?
item.last?

item.next_item               #=> returns the item immediately following `item` in the list
item.previous_item           #=> returns the item immediately preceding `item` in the list
```



## Requirements

Tested with Mongoid 2.4.6 on Ruby 1.9.3-p125, Rails 3.2.2, and Mongo 2.x



## Contributing
 
- Fork the project
- Start a feature/bugfix branch
- Start writing tests
- Commit and push until all tests are green and you are happy with your contribution

## Copyright

Copyright (c) 2012 Olivier Melcher, released under the MIT license
