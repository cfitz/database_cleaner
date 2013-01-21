
# neo4j only runs on jruby
if defined?(Neo4j)

  require 'spec_helper'
  require 'database_cleaner/neo4j/base'
  require 'database_cleaner/shared_strategy'

  module DatabaseCleaner
    describe Neo4j do
      it { should respond_to(:available_strategies) }
    end

    module Neo4j
      class ExampleStrategy
        include ::DatabaseCleaner::Neo4j::Base
      end

      describe ExampleStrategy do

        it_should_behave_like "a generic strategy"

        describe "db" do
          it { should respond_to(:db=) }

          it "should store my desired db" do
            subject.db = :my_db
            subject.db.should == :my_db
          end

          it "should default to :default" do
            subject.db.should == :default
          end
        end
      end
    end
  end


end