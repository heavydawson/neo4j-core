# Requires that an initialized `adaptor` variable be available
# Requires that `setup_query_subscription` is called
RSpec.shared_examples 'Neo4j::Core::CypherSession::Adaptor' do
  before(:all) { setup_query_subscription }

  # TODO: Test cypher errors

  describe '#query' do
    it 'Can make a query' do
      adaptor.query('MERGE path=n-[rel:r]->(o) RETURN n, rel, o, path LIMIT 1')
    end
  end

  describe 'transactions' do
    it 'lets you execute a query in a transaction' do
      expect_queries(1) do
        adaptor.start_transaction
        adaptor.query('MATCH n RETURN n LIMIT 1')
        adaptor.end_transaction
      end

      expect_queries(1) do
        adaptor.transaction do
          adaptor.query('MATCH n RETURN n LIMIT 1')
        end
      end
    end

    it 'does not allow transactions in the wrong order' do
      expect { adaptor.end_transaction }.to raise_error(RuntimeError, /Cannot close transaction without starting one/)
    end
  end

  describe 'results' do
    it 'handles array results' do
      result = adaptor.query("CREATE (a {b: 'c'}) RETURN [a]")

      expect(result.hashes).to be_a(Array)
      expect(result.hashes.size).to be(1)
      expect(result.hashes[0][:'[a]']).to be_a(Array)
      expect(result.hashes[0][:'[a]'][0]).to be_a(Neo4j::Core::Node)
      expect(result.hashes[0][:'[a]'][0].properties).to eq(b: 'c')
    end

#    it 'symbolizes keys for Neo4j objects' do
#      puts 1
#      result = adaptor.query('RETURN {a: 1} AS obj')
#
#      # Didn't output 2...
#      puts 2
#      expect(result.hashes).to eq([{obj: {a: 1}}])
#
#      puts 3
#      structs = result.structs
#      puts 4
#      expect(structs).to be_a(Array)
#      puts 5
#      expect(structs.size).to be(1)
#      puts 6
#      expect(structs[0].obj).to eq(a: 1)
#      puts 7
#    end

    context 'wrapper class exists' do
      before do
        stub_const 'WrapperClass', (Class.new do
          attr_reader :wrapped_object

          def initialize(obj)
            @wrapped_object = obj
          end
        end)

        Neo4j::Core::Node.wrapper_callback(->(obj) { WrapperClass.new(obj) })
        Neo4j::Core::Relationship.wrapper_callback(->(obj) { WrapperClass.new(obj) })
        Neo4j::Core::Path.wrapper_callback(->(obj) { WrapperClass.new(obj) })
      end

      after do
        Neo4j::Core::Node.clear_wrapper_callback
        Neo4j::Core::Path.clear_wrapper_callback
        Neo4j::Core::Relationship.clear_wrapper_callback
      end

      # Normally I don't think you wouldn't wrap nodes/relationships/paths
      # with the same class.  It's just expedient to do so in this spec
#      it 'Returns wrapped objects from results' do
#        result = adaptor.query('CREATE path=(n {a: 1})-[r:foo {b: 2}]->(b) RETURN n,r,path')
#
#        result_entity = result.hashes[0][:n]
#        expect(result_entity).to be_a(WrapperClass)
#        expect(result_entity.wrapped_object).to be_a(Neo4j::Core::Node)
#        expect(result_entity.wrapped_object.properties).to eq(a: 1)
#
#        result_entity = result.hashes[0][:r]
#        expect(result_entity).to be_a(WrapperClass)
#        expect(result_entity.wrapped_object).to be_a(Neo4j::Core::Relationship)
#        expect(result_entity.wrapped_object.properties).to eq(b: 2)
#
#        result_entity = result.hashes[0][:path]
#        expect(result_entity).to be_a(WrapperClass)
#        expect(result_entity.wrapped_object).to be_a(Neo4j::Core::Path)
#      end
    end
  end
end
