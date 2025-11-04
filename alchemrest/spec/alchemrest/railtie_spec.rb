# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::Railtie do
  it "sets the filter parameters from the combustion testing app dropping duplicates" do
    expect(Alchemrest.filter_parameters).to match_array(%i(ssn password token foo bar))
  end

  it "sets the logger to Rails.logger" do
    expect(Alchemrest.logger).to be(Rails.logger)
  end
end
