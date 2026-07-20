class SessionsController < ApplicationController
  # Sign in by name — no password, honor system. The pool is closed, so this
  # only recognises players who were in it.
  def create
    user = User.identify(params[:name])

    if user&.persisted?
      session[:user_id] = user.id
      redirect_to picks_path, notice: "Welcome back, #{user.name}.", status: :see_other
    else
      redirect_to root_path, alert: "The pool is closed — that name isn't on the sheet.", status: :see_other
    end
  end

  # Leave / switch player.
  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out. See you at kickoff.", status: :see_other
  end
end
