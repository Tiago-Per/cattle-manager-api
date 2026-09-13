module Api
  module V1
    class SessionsController < ApplicationController
      before_action :allow_params_authentication!, only: :create
      before_action :authenticate_user!, only: :destroy

      def create
        user = warden.authenticate!(scope: :user)

        render json: { id: user.id, email: user.email }, status: :ok
      end

      def destroy
        sign_out(current_user)
        head :no_content
      end
    end
  end
end
