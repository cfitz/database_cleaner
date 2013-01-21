require 'neo4j'
class Part < Neo4j::Rails::Relationship
  property :part_number
end


class Gadget  < Neo4j::Rails::Model
  has_n(:widgets).from(:Widget, :gadget).relationship(Part)
  property :name
end


class Widget  < Neo4j::Rails::Model
  property :name
  has_one(:gadget).to(Gadget).relationship(Part)  
end



