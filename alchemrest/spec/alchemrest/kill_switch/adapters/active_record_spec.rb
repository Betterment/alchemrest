# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alchemrest::KillSwitch::Adapters::ActiveRecord do
  around do |ex|
    ActiveRecord::Base.transaction do
      ex.run
    ensure
      raise ActiveRecord::Rollback
    end
  end

  include_examples 'Alchemrest::KillSwitch::Adapters'

  it 'requires unique service name' do
    service_name = 'whatever-but-unique'
    record_class = described_class.const_get(:Record)

    record_class.create!(service_name:)
    expect { record_class.create!(service_name:) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe '#ready?' do
    subject { described_class.new }

    context 'when table exists' do
      it 'returns true' do
        expect(subject.ready?).to eq(true)
      end
    end

    context 'when table does not exist' do
      def with_table_dropped
        record_class = described_class.const_get(:Record)
        ActiveRecord::Migration.drop_table record_class.table_name
        record_class.connection.schema_cache.clear_data_source_cache!(record_class.table_name)
        yield
      end

      it 'returns false' do
        with_table_dropped do
          expect(subject.ready?).to eq(false)
        end
      end
    end
  end
end
