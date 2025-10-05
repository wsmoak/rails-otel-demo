require 'rails_helper'

RSpec.describe CustomersController, type: :controller do
  describe "GET #index" do
    it "logs a message via RailsOTelDemo::Logger" do
      expect(RailsOTelDemo::Logger).to receive(:log).with(
        "A descriptive log message",
        hash_including("customer_id", "fruit", "original_fruit", "acorns")
      )

      get :index
    end
  end
end
