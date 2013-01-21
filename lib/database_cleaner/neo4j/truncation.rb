require 'database_cleaner/neo4j/base'
require 'database_cleaner/generic/truncation'
require 'database_cleaner/neo4j/truncation_mixin'
module DatabaseCleaner
  module Neo4j
    class Truncation
      include ::DatabaseCleaner::Generic::Truncation
      include TruncationMixin
      include Base
      private

      def database
        db
      end
    end
  end
end
