class ApplicationController < ActionController::Base
  include Pundit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def after_sign_in_path_for(user)
    if user.developer.present? || user.business.present?
      super
    else
      new_role_path
    end
  end

  private

  def user_not_authorized
    flash[:alert] = I18n.t("pundit.errors.unauthorized")
    redirect_to(request.referrer || root_path)
  end
end
