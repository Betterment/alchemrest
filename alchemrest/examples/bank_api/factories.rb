# frozen_string_literal: true

require 'factory_bot'

Alchemrest::FactoryBot.enable!

FactoryBot.define do
  alchemrest_factory :bank_api_user, class: 'BankApi::Data::User' do
    name { 'Kevin' }
    status { 'open' }
    date_of_birth { '2021-01-01T00:00:00' }
    account_ids { [1, 2] }
  end

  alchemrest_factory :bank_api_transaction, class: 'BankApi::Data::Transaction' do
    sequence(:user_id)
    amount_cents { 120_00 }
    status { "completed" }
    settled_at { "2023-10-10T00:00:00Z" }
    description { "check transaction" }
    source { association(:bank_api_check) }
    account_id { "123456789" }

    trait :from_ach do
      source { association(:bank_api_ach) }
    end

    trait :from_check do
      source { association(:bank_api_check) }
    end

    trait :from_card do
      source { association(:bank_api_card) }
    end
  end

  alchemrest_factory :bank_api_check, class: 'BankApi::Data::Check' do
    source_type { "check" }
    check_number { 100 }
    check_image_back_url { "http://bank.example.com/api/v1/check_images/100/back.png" }
    check_image_front_url { "http://bank.example.com/api/v1/check_images/100/front.png" }
  end

  alchemrest_factory :bank_api_ach, class: 'BankApi::Data::Ach' do
    source_type { "ach" }
    trace_number { '12354689' }
  end

  alchemrest_factory :bank_api_card, class: 'BankApi::Data::Card' do
    source_type { 'card' }
    card_number { '12346' }
    expiration_date { '2023-10-10T00:00:00' }
  end

  alchemrest_factory :bank_api_product, class: 'BankApi::Data::Product' do
    name { 'Savings Account' }
    interest_rate { "4.00%" }
    partner_revenue_rate { "0.0125" }
  end

  alchemrest_factory :bank_api_business_account, class: 'BankApi::Data::BusinessAccount' do
    name { 'ACME Inc' }
    status { 'open' }
    ein { '123456789' }

    id { SecureRandom.uuid }
  end
end
