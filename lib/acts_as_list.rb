$:.unshift File.expand_path(File.dirname(__FILE__))

require "mongoid/acts_as_list"
require "acts_as_list/version"

module ActsAsList
  extend ActiveSupport::Concern

  included do
    if embedded?
      include Embedded
    else
      include Relational
    end
  end

  autoload :Relational, 'acts_as_list/relational.rb'
  autoload :Embedded, 'acts_as_list/embedded.rb'
end
