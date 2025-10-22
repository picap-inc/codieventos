module Admin
  class AdminApplicationController < ApplicationController
    layout 'admin/layouts/application'
    before_action :authenticate_admin!

    def index
    end

    private

    def authenticate_admin!
      redirect_to admin_login_path unless current_admin_user
    end

    def current_admin_user
      @current_admin_user ||= AdminUser.find(session[:admin_user_id]) if session[:admin_user_id]
    rescue Mongoid::Errors::DocumentNotFound
      session[:admin_user_id] = nil
      nil
    end

    helper_method :current_admin_user
  end
end