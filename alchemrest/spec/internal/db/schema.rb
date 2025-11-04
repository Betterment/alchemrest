# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table(:alchemrest_kill_switches, id: :uuid, force: true) do |t|
    t.string  :service_name, null: false, index: { unique: true }
    t.boolean :enabled, null: false, default: false
    t.timestamps
  end
end
