require 'elasticsearch/model'

class Article < ActiveRecord::Base
  
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  def self.search(query)
	__elasticsearch__.search(
		{
			query: {
				multi_match: {
					query: query,
					fields: ['title^10', 'text'],
					fuzziness: 1,
					prefix_length: 1,
					operator: "and"
				}
			},
			highlight: {
				pre_tags: ['<em>'],
				post_tags: ['</em>'],
				fields: {
					title: {},
					text: {}
				}
			}
		}
	)
  end
	
  settings index: { number_of_shards: 1 },
		   analysis: {
			 filter: {
				nGram_filter: {
				   type: "nGram",
				   min_gram: 2,
				   max_gram: 20,
				   token_chars: ["letter", "digit", "punctuation", "symbol"]
				}
			 },
			 analyzer: {
				nGram_analyzer: {
				   type: "custom",
				   tokenizer: "whitespace",
				   filter: ["lowercase", "asciifolding", "nGram_filter"]
				},
				whitespace_analyzer: {
				   type: "custom",
				   tokenizer: "whitespace",
				   filter: ["lowercase", "asciifolding"]
				}
			 }
		   } do
	mappings dynamic: 'false' do
		indexes :title, analyzer: 'nGram_analyzer', search_analyzer: 'whitespace_analyzer', index_options: 'offsets'
		indexes :text, analyzer: 'nGram_analyzer', search_analyzer: 'whitespace_analyzer', index_options: 'offsets'
	end	
  end
  
  
end

# Delete the previous articles index in Elasticsearch
Article.__elasticsearch__.client.indices.delete index: Artice.index_name rescue nil

# Create the new index with the new mapping
# Article.__elasticsearch__.client.indices.create \
  # index: Article.index_name,
  # body: { settings: Article.settings.to_hash, mappings: Article.mappings.to_hash }
Article.__elasticsearch__.create_index! force: true
  
# Index all article records from the DB to Elasticsearch
Article.import force:true # for auto sync model with elastic search
