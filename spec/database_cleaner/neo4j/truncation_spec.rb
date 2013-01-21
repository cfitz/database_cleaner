
# neo4j only runs on jruby
if defined?(Neo4j)


  require File.dirname(__FILE__) + '/../../spec_helper'
  require 'neo4j'
  require 'neo4j-core'
  require 'database_cleaner/neo4j/truncation'
  require File.dirname(__FILE__) + '/neo4j_examples'


  module DatabaseCleaner
    module Neo4j

      describe Truncation do
        let(:args) {{}}
        let(:truncation) { described_class.new(args).tap { |t| t.db=@db } }


        before(:each) do
           ::Neo4j.started_db.graph.getAllNodes.each do |n|
              ::Neo4j::Transaction.run do             
                if n.id != 0 
                  n.rels.each { |r| r.delete unless r.nil? }
                  n.delete unless n.nil?
                end
              end
            end
        end

         def ensure_counts(expected_counts)
            expected_counts.each do |model_class, expected_count|
              # weird issue with .count? 
              model_class.all.to_a.size.should equal(expected_count), "#{model_class} expected to have a count of #{expected_count} but was #{model_class.count}"
            end
        end

        def create_widget(attrs={})
          params = { :name => 'some widget'}.merge(attrs)
          Widget.create! params
        end

        def create_gadget(attrs={})
          params = {:name => 'some gadget'}.merge(attrs) 
          Gadget.create! params
        end

        # Neo4j.rb creates reference nodes. the first node 0, which is reference
        # for all nodes. When an object is made for each class, a reference node is made 
        # for the class. These are benign and can remain in neo4j, as one node will only be 
        # made for each class. 
        # also, neo4j does not allow relationships to hang freely. if the either node is removed, the relationship
        # is removed in storage. 
        it "should delete all the node except for the reference nodes" do
          (1..10).each { create_widget; }
          # 10 widgets nodes + node 0 + widget ref node = 12 nodes
          ::Neo4j.started_db.graph.getAllNodes.to_a.size.should == 12
          truncation.clean
          # node 0 + widget ref node
          ::Neo4j.started_db.graph.getAllNodes.to_a.size.should == 2
          (1..10).each { create_widget; create_gadget; }
          # 10 widgets + 10 gadgets + widget ref + gadget ref + node 0 = 23
          ::Neo4j.started_db.graph.getAllNodes.to_a.size.should == 23
          truncation.clean
          # widget + gadget + node 0 = 3
          ::Neo4j.started_db.graph.getAllNodes.to_a.size.should == 3    
          ::Neo4j.started_db.graph.getAllNodes.first.id.should == 0
          (1..10).each {  gadget =  create_gadget; gadget.widgets.create }
          # notice that relationship nodes do not get ref. 
          ::Neo4j.started_db.graph.getAllNodes.to_a.size.should == 23
          truncation.clean
          ::Neo4j.started_db.graph.getAllNodes.to_a.size.should == 3 
          ::Neo4j.started_db.graph.getAllNodes.first.id.should == 0
        end

        it "truncates all collections by default" do
          widget = create_widget
          widget.gadget = create_gadget
          widget.save
          ensure_counts(Widget => 1, Gadget => 1, Part => 1)
          truncation.clean
          ensure_counts(Widget => 0, Gadget => 0, Part => 0)
        end

        context "when collections are provided to the :only option" do
          let(:args) {{:only => ['Widget']}}
          it "only truncates the specified collections" do
            gadget =  create_gadget
            gadget.widgets.create
            ensure_counts(Widget => 1, Gadget => 1, Part => 1)
            truncation.clean
            ensure_counts(Widget => 0, Gadget => 1, Part => 0)
          end
        end

        context "when collections are provided to the :except option" do
          let(:args) {{:except => ['Widget']}}
          it "truncates all but the specified collections" do
            create_widget
            create_gadget
            ensure_counts( Widget => 1, Gadget => 1)
            truncation.clean
            ensure_counts(Widget => 1, Gadget => 0)
          end
        end
      
       context "should relationship" do
          let(:args) {{:except => ['Gadget']}}
          it "truncates all but the specified collections" do
            widget = create_widget
            widget.gadget = create_gadget
            widget.save
            ensure_counts( Widget => 1, Gadget => 1, Part => 1)
            truncation.clean
            ensure_counts(Widget => 0, Gadget => 1, Part => 0)
          end
        end

      end

    end
  end

end