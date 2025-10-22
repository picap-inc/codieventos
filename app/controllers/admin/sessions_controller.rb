module Admin
  class SessionsController < ApplicationController
    layout 'admin/layouts/auth'
    
    def new
      redirect_to admin_root_path if current_admin_user
    end

    def create
      admin_user = AdminUser.authenticate(params[:email], params[:password])
      
      if admin_user
        session[:admin_user_id] = admin_user.id.to_s
        redirect_to admin_root_path, notice: 'Successfully logged in!'
      else
        flash.now[:alert] = 'Invalid email or password'
        render :new
      end
    end

    def destroy
      session[:admin_user_id] = nil
      redirect_to admin_login_path, notice: 'Successfully logged out!'
    end

    private

    def current_admin_user
      @current_admin_user ||= AdminUser.find(session[:admin_user_id]) if session[:admin_user_id]
    rescue Mongoid::Errors::DocumentNotFound
      session[:admin_user_id] = nil
      nil
    end
  end
end