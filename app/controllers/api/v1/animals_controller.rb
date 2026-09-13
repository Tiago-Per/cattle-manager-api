module Api
  module V1
    class AnimalsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_animal, only: %i[show update destroy]

      def index
        render json: current_user.animals
      end

      def show
        render json: @animal
      end

      def create
        animal = current_user.animals.new(animal_params)

        if animal.save
          render json: animal, status: :created
        else
          render json: { errors: animal.errors }, status: :unprocessable_content
        end
      end

      def update
        if @animal.update(animal_params)
          render json: @animal
        else
          render json: { errors: @animal.errors }, status: :unprocessable_content
        end
      end

      def destroy
        if @animal.destroy
          head :no_content
        else
          render json: { errors: @animal.errors }, status: :unprocessable_content
        end
      end

      private

      def set_animal
        @animal = current_user.animals.find(params[:id])
      end

      def animal_params
        params.require(:animal).permit(:identification, :category, :sex, :status, :birth_date)
      end
    end
  end
end
