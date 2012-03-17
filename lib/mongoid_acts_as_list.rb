require "mongoid/acts_as_list"

module ActsAsList
  extend ActiveSupport::Concern

  included do
    if embedded?
      include Embedded
    else
      include Relational
    end
  end

  autoload :Relational , 'acts_as_list/relational.rb'
  autoload :Embedded   , 'acts_as_list/embedded.rb'
  autoload :VERSION    , 'acts_as_list/version.rb'
end
