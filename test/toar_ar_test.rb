require 'test_helper'
require 'active_record'
require 'setup_test_db'

class ToarArTest < Minitest::Test
  class ::User
    extend Toar::Ar
    toar includes: [:posts, :account]
  end

  def test_ar_model
    u = User.new
    u.build_account
    3.times { u.posts.build }
    u.save!
    u.reload
    json = u.toar_to_json
    assert_equal(u.to_json(Toar.convert_includes_option(:posts, :account)), json)
    destroy_all
    u2 = User.to_ar(json)
    assert_equal(3, u2.posts.size)
    assert_equal(Post, u2.posts[0].class)
    assert_equal(Account, u2.account.class)
  end
end
