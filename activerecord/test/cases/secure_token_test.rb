# frozen_string_literal: true

require "cases/helper"
require "models/user"

class SecureTokenTest < ActiveRecord::TestCase
  setup do
    @user = User.new
  end

  def test_token_values_are_generated_for_specified_attributes_and_persisted_on_save
    @user.save
    assert_not_nil @user.token
    assert_not_nil @user.auth_token
    assert_equal 24, @user.token.size
    assert_equal 36, @user.auth_token.size
  end

  def test_generating_token_on_initialize_does_not_affect_reading_from_the_column
    token = "abc123"

    @user.update! token: token

    assert_equal token, @user.reload.token
    assert_equal token, User.find(@user.id).token
  end

  def test_regenerating_the_secure_token
    @user.save
    old_token = @user.token
    old_auth_token = @user.auth_token
    @user.regenerate_token
    @user.regenerate_auth_token

    assert_not_equal @user.token, old_token
    assert_not_equal @user.auth_token, old_auth_token

    assert_equal 24, @user.token.size
    assert_equal 36, @user.auth_token.size
  end

  def test_token_value_not_overwritten_when_present
    @user.token = "custom-secure-token"
    @user.save

    assert_equal "custom-secure-token", @user.token
  end

  def test_token_length_cannot_be_less_than_24_characters
    assert_raises(ActiveRecord::SecureToken::MinimumLengthError) do
      @user.class_eval do
        has_secure_token :not_valid_token, length: 12
      end
    end
  end

  def test_token_on_callback
    User.class_eval do
      undef regenerate_token

      has_secure_token on: :initialize
    end

    model = User.new

    assert_predicate model.token, :present?
  end
end
