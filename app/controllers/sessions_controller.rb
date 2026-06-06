class SessionsController < ApplicationController
  # Join the pool by name — no password, honor system.
  def create
    user = User.identify(params[:name])

    if user&.persisted?
      session[:user_id] = user.id
      redirect_to root_path, notice: "You're in, #{user.name}. Coupon claimed.", status: :see_other
    else
      redirect_to root_path, alert: "Stake a name to claim your ticket.", status: :see_other
    end
  end

  # Leave / switch player.
  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out. See you at kickoff.", status: :see_other
  end
end
