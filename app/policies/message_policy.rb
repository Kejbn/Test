class MessagePolicy < ApplicationPolicy
  def create?
    if record.conversation.blocked?
      false
    elsif developer_sender?
      true
    elsif business_sender?
      permissions.can_message_developer?(role_type: developer.role_type)
    end
  end

  private

  def developer_sender?
    user.developer == developer
  end

  def business_sender?
    user.business == business
  end

  def business
    record.conversation.business
  end

  def developer
    record.conversation.developer
  end

  def permissions
    user.permissions
  end
end
