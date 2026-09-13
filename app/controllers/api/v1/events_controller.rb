module Api
  module V1
    class EventsController < ApplicationController
      before_action :set_animal, only: %i[index create]
      before_action :set_event, only: %i[show update destroy]

      def index
        render json: @animal.events.order(occurred_on: :desc)
      end

      def show
        render json: @event
      end

      def create
        event = @animal.events.new(event_params)

        if event.save
          render json: event, status: :created
        else
          render json: { errors: event.errors }, status: :unprocessable_content
        end
      end

      def update
        if @event.update(event_params)
          render json: @event
        else
          render json: { errors: @event.errors }, status: :unprocessable_content
        end
      end

      def destroy
        @event.destroy
        head :no_content
      end

      private

      def set_animal
        @animal = Animal.find(params[:animal_id])
      end

      def set_event
        @event = Event.find(params[:id])
      end

      def event_params
        params.require(:event).permit(
          :event_type, :occurred_on, :due_on, :notes,
          :weight_kg, :product_name, :sire_identification
        )
      end
    end
  end
end
