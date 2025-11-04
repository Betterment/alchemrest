# frozen_string_literal: true
# typed: true

module BankApi
  module Data
    class Transaction < Alchemrest::Data
      schema do |s|
        {
          required: {
            amount_cents: s.money(:cents),
            status: s.enum(%w(completed pending)),
            settled_at: s.from.string.to(Time).using(:local),
            description: s.string,
            account_id: s.string,
            user_id: s.number,
          },
          optional: {
            source: s.one_of(
              check: BankApi::Data::Check,
              card: BankApi::Data::Card,
              ach: BankApi::Data::Ach,
              discriminator: :source_type,
            ),
          },
        }
      end

      def source_identifer
        case (source = self.source)
        when BankApi::Data::Check
          source.check_number
        when BankApi::Data::Card
          source.card_number
        when BankApi::Data::Ach
          source.trace_number
        when nil
          nil
        else
          T.absurd(source)
        end
      end

      configure_response_capture do
        safe :account_id
        omitted :description
      end
    end
  end
end
