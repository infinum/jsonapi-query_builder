# frozen_string_literal: true

require 'jsonapi/query_builder/paginator/keyset'

RSpec.describe Jsonapi::QueryBuilder::Paginator::Keyset do
  let(:collection) { Post.all }
  let(:paginator) { described_class.new }

  it "returns original collection when column isn't provided" do
    paginator = described_class.new
    paginated_collection, _details = paginator.paginate(collection, {})

    expect(paginated_collection.to_sql).to eq <<~SQL.squish
      SELECT "posts".*
      FROM "posts"
    SQL
  end

  it 'orders collection by the selected column' do
    params = { column: :id }
    paginated_collection, _details = paginator.paginate(collection, params)

    expect(paginated_collection.to_sql).to eq <<~SQL.squish
      SELECT "posts".*
      FROM "posts"
      ORDER BY "posts"."id" ASC
      LIMIT 25
    SQL
  end

  it 'applies selected limit' do
    params = { column: :id, limit: 10 }
    paginated_collection, _details = paginator.paginate(collection, params)

    expect(paginated_collection.to_sql).to eq <<~SQL.squish
      SELECT "posts".*
      FROM "posts"
      ORDER BY "posts"."id" ASC
      LIMIT 10
    SQL
  end

  context "when direction isn't provided" do
    it 'filters records after the selected position' do
      params = { column: :id, limit: 10, position: 5 }
      paginated_collection, _details = paginator.paginate(collection, params)

      expect(paginated_collection.to_sql).to eq <<~SQL.squish
        SELECT "posts".*
        FROM "posts"
        WHERE "posts"."id" > 5
        ORDER BY "posts"."id" ASC
        LIMIT 10
      SQL
    end
  end

  context 'when selecting records after the position' do
    it 'filters records after the selected position' do
      params = { column: :id, limit: 10, position: 5, direction: :after }
      paginated_collection, _details = paginator.paginate(collection, params)

      expect(paginated_collection.to_sql).to eq <<~SQL.squish
        SELECT "posts".*
        FROM "posts"
        WHERE "posts"."id" > 5
        ORDER BY "posts"."id" ASC
        LIMIT 10
      SQL
    end
  end

  context 'when selecting records before the position' do
    it 'filters records before the selected position' do
      params = { column: :id, limit: 10, position: 5, direction: :before }
      paginated_collection, _details = paginator.paginate(collection, params)

      expect(paginated_collection.to_sql).to eq <<~SQL.squish
        SELECT "posts".*
        FROM "posts"
        WHERE "posts"."id" < 5
        ORDER BY "posts"."id" ASC
        LIMIT 10
      SQL
    end
  end
end
