require 'test_helper'
require 'active_record'
require 'setup_test_db'

class ToarTest < Minitest::Test

  def test_simple_deserialize_with_to_ar
    json = create_account_with_associations.users.first.to_json
    destroy_all
    user = Toar.to_ar(User, json)
    assert_equal('U1', user.name)
  end

  def test_has_one
    json = create_account_with_associations.users.first.to_json(include: [:user_profile])
    destroy_all
    user = Toar.to_ar(User, json)
    assert_equal('Profile1', user.user_profile.body)
  end

  def test_belongs_to
    json = create_account_with_associations.users.first.to_json(include: [:account])
    destroy_all
    user = Toar.to_ar(User, json)
    assert_equal('A1', user.account.name)
    assert_equal(user.account.id, user.account_id)
  end

  def test_has_many
    json = create_account_with_associations.users.first.to_json(include: [:posts])
    destroy_all
    user = Toar.to_ar(User, json)
    assert_equal('Post1', user.posts[0].body)
    assert_equal(3, user.posts.size)
  end

  def test_has_many_through
    json = create_account_with_associations.users.first
      .posts[2].to_json(include: [:post_tags])
    destroy_all
    post = Toar.to_ar(Post, json)
    assert_equal(%w(Tag1 Tag2), post.post_tags.map(&:name))
  end

  def test_has_many_through_without_through_data
    json = create_account_with_associations.users.first
      .posts[2].to_json(include: [{ post_taggings: { include: [:post_tag] }}])
    destroy_all
    post = Toar.to_ar(Post, json)
    assert_equal(2, post.post_taggings.size)
    assert_equal(%w(Tag1 Tag2), post.post_tags.map(&:name))
  end

  def test_multi_associations
    u1 = create_account_with_associations.users.first
    d = u1.as_json(include: [:account, :user_profile, posts: { include: [:post_tags, { post_taggings: { include: [:post_tag]}  }] }])
    destroy_all
    user = Toar.to_ar(User, d.to_json)
    assert_equal('U1', user.name)
    assert_equal('A1', user.account.name)
    assert_equal('Profile1', user.user_profile.body)
    assert_equal(user.posts.size, 3)
    assert_equal(user.posts[0].post_tags, [])
    assert_equal(user.posts[1].post_tags.map(&:name), %w(Tag1))
    assert_equal(user.posts[2].post_tags.map(&:name), %w(Tag1 Tag2))
    assert_equal(user.posts[0].post_taggings, [])
    assert_equal(user.posts[1].post_taggings
        .map(&:post_tag).map(&:name), %w(Tag1))
    assert_equal(user.posts[2].post_taggings
        .map(&:post_tag).map(&:name), %w(Tag1 Tag2))
  end

  private

  def create_account_with_associations
    ac = Account.create(name: 'A1')
    u1 = ac.users.create(name: 'U1')
    ac.users.create(name: 'U2')
    u1.create_user_profile(body: 'Profile1')
    post1 = u1.posts.create(body: 'Post1')
    post2 = u1.posts.create(body: 'Post2')
    post3 = u1.posts.create(body: 'Post3')
    tag1 = PostTag.create(name: 'Tag1')
    tag2 = PostTag.create(name: 'Tag2')
    post1.post_tags = []
    post2.post_tags = [tag1]
    post3.post_tags = [tag1, tag2]
    ac
  end

  def destroy_all
    [Account, User, Post, PostTag, PostTagging].map(&:destroy_all)
  end
end
