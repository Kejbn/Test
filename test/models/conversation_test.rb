require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "messages are sorted oldest first" do
    conversation = conversations(:one)
    assert_equal conversation.messages.pluck(:body), [
      "Earlier message.",
      "One message.",
      "Two message."
    ]
  end

  test "visible does not include ones blocked by the developer" do
    conversation = conversations(:one)
    assert Conversation.visible.include?(conversation)

    conversation.blocked_by conversation.developer.user
    refute Conversation.visible.include?(conversation)
  end

  test "visible does not include ones blocked by the business" do
    conversation = conversations(:one)
    assert Conversation.visible.include?(conversation)

    conversation.blocked_by conversation.business.user
    refute Conversation.visible.include?(conversation)
  end

  test "other recipient is the business when the user is the developer" do
    user = users(:prospect_developer)
    conversation = conversations(:one)
    assert_equal conversation.other_recipient(user), conversation.business
  end

  test "other recipient is the developer when the user is the business" do
    user = users(:subscribed_business)
    conversation = conversations(:one)
    assert_equal conversation.other_recipient(user), conversation.developer
  end

  test "is blocked if blocked by the developer" do
    conversation = conversations(:one)
    refute conversation.blocked?

    conversation.blocked_by conversation.developer.user
    assert conversation.blocked?
  end

  test "is blocked if blocked by the business" do
    conversation = conversations(:one)
    refute conversation.blocked?

    conversation.blocked_by conversation.business.user
    assert conversation.blocked?
  end

  test "is eligible for the hiring fee when the developer has responded and it is 2+ weeks old" do
    conversation = conversations(:one)
    refute conversation.hiring_fee_eligible?

    conversation.update!(created_at: 2.weeks.ago - 1.day)
    assert conversation.hiring_fee_eligible?

    conversation.messages.from_developer.destroy_all
    refute conversation.hiring_fee_eligible?
  end
end
