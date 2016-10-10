require 'active_record'

ActiveRecord::Base.establish_connection(
  adapter:   'sqlite3',
  database:  ':memory:'
)

class InitialSchema < ActiveRecord::Migration[4.2]
  def change
    create_table :accounts do |t|
      t.string :name
    end
    create_table :users do |t|
      t.string :name
      t.references :account
    end
    create_table :user_profiles do |t|
      t.string :body
      t.references :user
    end
    create_table :posts do |t|
      t.references :user
      t.text :body
    end
    create_table :post_tags do |t|
      t.text :name
    end
    create_table :post_taggings do |t|
      t.references :post
      t.references :post_tag
    end
  end
end

InitialSchema.verbose = false
InitialSchema.migrate(:up)

class Account < ActiveRecord::Base
  has_many :users, dependent: :destroy
end

class User < ActiveRecord::Base
  belongs_to :account
  has_one :user_profile, dependent: :destroy
  has_many :posts, dependent: :destroy
end

class UserProfile < ActiveRecord::Base
  belongs_to :user
end

class Post < ActiveRecord::Base
  belongs_to :user
  has_many :post_taggings, dependent: :destroy
  has_many :post_tags, through: :post_taggings
end

class PostTag < ActiveRecord::Base
  has_many :post_taggings, dependent: :destroy
  has_many :posts, through: :post_taggings
end

class PostTagging < ActiveRecord::Base
  belongs_to :post
  belongs_to :post_tag
end
