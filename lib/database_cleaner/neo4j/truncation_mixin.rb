module DatabaseCleaner
  module Neo4j
    module TruncationMixin

      def clean
        if @only
          neo4j_models.each { |m| delete(m.name) if @only.include?(m.name) }
        else
          neo4j_models.each { |m| delete(m.name) unless @tables_to_exclude.include?(m.name) }
        end
        true
      end

      private
      
      def neo4j_models
        ::Neo4j::Rails::Model::OrmAdapter.model_classes
      end
      
      
      # this is a way to do it w/ cypher, but might be too brittle since it relies on index?
      #def delete_all_model_instances(neo_model)
      #  klass = neo_model.camelize.safe_constantize
      #  if klass && klass.index?(:exact) 
      #    index = klass.index_name_for_type(:exact)
      #    Neo4j._query("START n=node:#{index}_exact( '*:*') MATCH n-[r]-() DELETE n, r") 
      #  end
      # end
      
      def delete(model_name)
        ::Neo4j::Transaction.run do
          ::Neo4j.started_db.graph.getAllNodes.each do |n|
            if n.id != 0 && neo_classname(n) == model_name
              n.getRelationships.each { |r| r.delete unless r.nil? }
              n.delete unless n.nil?
            end
          end
        end
      end
      
      # take a neo4j node object and returns the _classname property, which the ORM uses.
      def neo_classname(node)
        if node.hasProperty("_classname")
          node.getProperty("_classname")
        else
          nil
        end
      end

    end
  end
end
