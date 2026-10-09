# typed: true

# `activerecord` is excluded in sorbet/tapioca/config.yml, but the alchemrest
# gem RBI subclasses `ActiveRecord::Base` for its kill switch adapter.
module ActiveRecord
  class Base; end
end
