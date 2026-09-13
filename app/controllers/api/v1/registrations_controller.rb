module Api
  module V1
    class RegistrationsController < ApplicationController
      def create
        user = User.new(registration_params)

        if user.save
          render json: { id: user.id, email: user.email }, status: :created
        else
          render json: { errors: user.errors }, status: :unprocessable_content
        end
      end

      private

      def registration_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
    end
  end
end
