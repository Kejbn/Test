class AdminMailer < ApplicationMailer
  def new_developer_profile
    @user = params[:recipient]
    @developer = params[:developer]
    mail(to: @user.email, subject: "New developer profile added")
  end

  def new_business_profile
    @user = params[:recipient]
    @business = params[:business]
    mail(to: @user.email, subject: "New business profile added")
  end
end
