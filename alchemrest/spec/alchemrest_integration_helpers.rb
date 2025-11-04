# frozen_string_literal: true

module AlchemrestIntegrationHelpers
  @rescued_results = []
  @captured_responses = []

  def self.rescued_results
    @rescued_results
  end

  def self.captured_responses
    @captured_responses
  end

  def rescued_exceptions
    AlchemrestIntegrationHelpers.rescued_results
  end

  def captured_responses
    AlchemrestIntegrationHelpers.captured_responses
  end

  def self.reset!
    @rescued_results = []
    @captured_responses = []
  end

  def self.enable_test_adapter
    Alchemrest.on_result_rescued do |e|
      AlchemrestIntegrationHelpers.rescued_results << e
    end

    Alchemrest.on_response_captured do |identifier:, result:|
      case result
        in Alchemrest::Result::Ok(value)
          data = value
        in Alchemrest::Result::Error(err)
          error = err
      end

      AlchemrestIntegrationHelpers.captured_responses << { data:, identifier:, error: }
    end
  end

  def self.disable_test_adapter
    Alchemrest.restore_default_result_rescue_behavior
    Alchemrest.restore_default_response_capture_behavior
  end
end
