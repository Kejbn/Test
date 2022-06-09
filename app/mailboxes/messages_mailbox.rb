class MessagesMailbox < ApplicationMailbox
  def process
    Message.new(conversation:, sender:, body: mail_body).save_and_notify
  end

  private

  def conversation
    @conversation ||= user.conversations
      .find_signed(signed_conversation_id, purpose: :message)
  end

  def user
    @user ||= User.find_by(email: mail.from)
  end

  # TODO: Extract somewhere - this is used in MessagesController, too.
  def sender
    if conversation.business?(user)
      user.business
    elsif conversation.developer?(user)
      user.developer
    end
  end

  def signed_conversation_id
    mail.to.first.split("@").first
  end

  def mail_body
    if mail.multipart?
      mail.parts.first.body.decoded
    else
      mail.decoded
    end
  end
end
