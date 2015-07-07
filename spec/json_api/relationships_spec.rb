require 'spec_helper'

describe Her::JsonApi::Model do
  before do
    Her::API.setup :url => "https://api.example.com" do |connection|
      connection.use Her::Middleware::JsonApiParser
      connection.adapter :test do |stub|
        stub.get('/ballers') do |env|
          [
            200,
            {},
            {
              data: [
                {
                  id:    1,
                  type: 'ballers',
                  attributes: { name: "Jeremy Lin", },
                  relationships: {
                    teammates: {
                      data: [
                        {
                          type: 'teammates',
                          id: 1,
                        },
                        {
                          type: 'teammates',
                          id: 2,
                        }
                      ]
                    },
                    team: {
                      data: {
                        type: 'teams',
                        id: 1,
                      }
                    }
                  }
                },
                {
                  id: 2,
                  type: 'ballers',
                  attributes: { name: 'Carmelo Anthony' },
                },
              ],
            }.to_json,
          ]
        end

        stub.get('ballers/1/teammates') do
          [ 200, {}, { data: [] }.to_json ]
        end

        stub.get('ballers/2/teammates') do
          [ 200, {}, { data: [] }.to_json ]
        end

        stub.get("/players") do |env|
          [
            200,
            {},
            {
              data: [
                {
                  id:    1,
                  type: 'players',
                  attributes: { name: "Roger Federer", },
                  relationships: {
                    sponsors: {
                      data: [
                        {
                          type: 'sponsors',
                          id: 1,
                        },
                        {
                          type: 'sponsors',
                          id: 2,
                        }
                      ]
                    },
                    racquet: {
                      data: {
                        type: 'racquets',
                        id: 1,
                      }
                    }
                  }
                },
                {
                  id:    2,
                  type: 'players',
                  attributes: { name: "Kei Nishikori", },
                  relationships: {
                    sponsors: {
                      data: [
                        {
                          type: 'sponsors',
                          id: 2,
                        },
                        {
                          type: 'sponsors',
                          id: 3,
                        }
                      ]
                    },
                    racquet: {
                      data: {
                        type: 'racquets',
                        id: 2,
                      }
                    }
                  }
                },
                {
                  id: 3,
                  type: 'players',
                  attributes: { name: 'Hubert Huang', racquet_id: nil },
                  relationships: {}
                },
              ],
              included: [
                {
                  type: 'sponsors',
                  id: 1,
                  attributes: {
                    company: 'Nike',
                  }
                },
                {
                  type: 'sponsors',
                  id: 2,
                  attributes: {
                    company: 'Wilson',
                  },
                },
                {
                  type: 'sponsors',
                  id: 3,
                  attributes: {
                    company: 'Uniqlo',
                  },
                },
                {
                  type: 'racquets',
                  id: 1,
                  attributes: {
                    name: 'Wilson Pro Staff',
                  },
                },
                {
                  type: 'racquets',
                  id: 2,
                  attributes: {
                    name: 'Wilson Steam',
                  }
                },
              ]
            }.to_json
          ]
        end

        stub.get("/players/3/sponsors") do |env|
          [
            200,
            {},
            { data: [] }.to_json
          ]
        end
      end
    end
  end

  context 'document with relationships' do
    before do
      spawn_model("Foo::Teammate", type: Her::JsonApi::Model)
      spawn_model("Foo::Team",  type: Her::JsonApi::Model)
      spawn_model("Foo::Baller", type: Her::JsonApi::Model) do
        has_many :teammates
        belongs_to :team
      end
    end

    it 'parses included documents into object if relationship specifies a resource linkage' do
      players = Foo::Baller.all
      lin = players.detect { |p| p.name == 'Jeremy Lin' }
      expect(lin.team).to be_nil
      expect(lin.teammates).to be_empty

      melo = players.detect { |p| p.name == 'Carmelo Anthony' }
      expect(melo.teammates).to eq []
      expect(melo.team).to be_nil
    end
  end

  context 'compound document' do
    before do
      spawn_model("Foo::Sponsor", type: Her::JsonApi::Model)
      spawn_model("Foo::Racquet", type: Her::JsonApi::Model)
      spawn_model("Foo::Player",  type: Her::JsonApi::Model) do
        has_many :sponsors
        belongs_to :racquet
      end
    end

    it 'parses included documents into object if relationship specifies a resource linkage' do
      players = Foo::Player.all.to_a
      fed = players.detect { |p| p.name == 'Roger Federer' }
      expect(fed.sponsors.map(&:company)).to match_array ['Nike', 'Wilson']
      expect(fed.racquet.name).to eq 'Wilson Pro Staff'

      kei = players.detect { |p| p.name == 'Kei Nishikori' }
      expect(kei.sponsors.map(&:company)).to match_array ['Uniqlo', 'Wilson']
      expect(kei.racquet.name).to eq 'Wilson Steam'

      hubert = players.detect { |p| p.name == 'Hubert Huang' }
      expect(hubert.sponsors).to eq []
      expect(hubert.racquet).to be_nil
    end
  end
end

