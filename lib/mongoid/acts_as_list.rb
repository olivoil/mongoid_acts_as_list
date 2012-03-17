module Mongoid
  module ActsAsList
    extend ActiveSupport::Concern

    included do
      include ::ActsAsList
    end

  end
end
