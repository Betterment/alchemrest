# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Alchemrest::HashPath do
  describe "#build_collection" do
    context "simple hash refering to a single path" do
      let(:defintion) { { user: { accounts: [:transactions] } } }

      it "returns a single hash path with the right segments" do
        paths = described_class.build_collection(defintion)
        expect(paths.count).to eq(1)
        expect(paths.first.segments).to eq(%i(user accounts transactions))
      end
    end

    context "simple hash refering to multiple leaves" do
      let(:defintion) { { user: { accounts: %i(transactions account_id) } } }

      it "returns a single hash path with the right segments" do
        paths = described_class.build_collection(defintion)
        expect(paths.count).to eq(2)
        expect(paths[0].segments).to eq(%i(user accounts transactions))
        expect(paths[1].segments).to eq(%i(user accounts account_id))
      end
    end

    context "complex hash a mix of nested trees and leaves" do
      let(:defintion) { { user: { accounts: [{ transactions: [:transaction_id] }, :account_id] } } }

      it "returns a single hash path with the right segments" do
        paths = described_class.build_collection(defintion)
        expect(paths.count).to eq(2)
        expect(paths.first.segments).to eq(%i(user accounts transactions transaction_id))
        expect(paths[1].segments).to eq(%i(user accounts account_id))
      end
    end

    context "complex hash with nested trees" do
      let(:defintion) { { user: { accounts: { transactions: [:transaction_id], owners: [:user_id] } } } }

      it "returns a single hash path with the right segments" do
        paths = described_class.build_collection(defintion)
        expect(paths.count).to eq(2)
        expect(paths.first.segments).to eq(%i(user accounts transactions transaction_id))
        expect(paths[1].segments).to eq(%i(user accounts owners user_id))
      end
    end
  end

  describe "#walk" do
    subject { described_class.new(segments) }
    let(:paths) { [] }
    let(:nodes) { [] }
    let(:remaining) { [] }

    def collect_outputs(path, node, current_remaining)
      paths << path
      nodes << node
      remaining << current_remaining
    end

    context "with a simple hash" do
      let(:segments) { %i(user profile name) }
      let(:input) do
        { user: { profile: { name: "Betterbot" } } }
      end

      it "walks the hash and yields the right path, node, and remaining segment values" do
        subject.walk(input) { |path, node, remaining| collect_outputs(path, node, remaining) }
        expect(paths).to contain_exactly([], %i(user), %i(user profile), %i(user profile name))
        expect(nodes).to contain_exactly(
          { user: { profile: { name: "Betterbot" } } },
          { profile: { name: "Betterbot" } },
          { name: "Betterbot" },
          "Betterbot",
        )
        expect(remaining).to contain_exactly(%i(user profile name), %i(profile name), %i(name), [])
      end
    end

    context "with an array of hashes" do
      let(:segments) { %i(user profile name) }
      let(:input) do
        [
          { user: { profile: { name: "Betterbot" } } },
          { user: { profile: { name: "BetterBear" } } },
          { user: { profile: { name: "BetterBeaver" } } },
        ]
      end

      it "walks the hash and yields the right path, node, and remaining segment values" do
        subject.walk(input) { |path, node, remaining| collect_outputs(path, node, remaining) }

        expect(paths).to contain_exactly(
          [],
          [0],
          [0, :user],
          [0, :user, :profile],
          [0, :user, :profile, :name],
          [1],
          [1, :user],
          [1, :user, :profile],
          [1, :user, :profile, :name],
          [2],
          [2, :user],
          [2, :user, :profile],
          [2, :user, :profile, :name],
        )

        expect(nodes).to contain_exactly(
          [
            { user: { profile: { name: "Betterbot" } } },
            { user: { profile: { name: "BetterBear" } } },
            { user: { profile: { name: "BetterBeaver" } } },
          ],
          { user: { profile: { name: "Betterbot" } } },
          { profile: { name: "Betterbot" } },
          { name: "Betterbot" },
          "Betterbot",
          { user: { profile: { name: "BetterBear" } } },
          { profile: { name: "BetterBear" } },
          { name: "BetterBear" },
          "BetterBear",
          { user: { profile: { name: "BetterBeaver" } } },
          { profile: { name: "BetterBeaver" } },
          { name: "BetterBeaver" },
          "BetterBeaver",
        )

        expect(remaining).to contain_exactly(
          %i(user profile name),
          %i(user profile name),
          %i(profile name),
          %i(name),
          [],
          %i(user profile name),
          %i(profile name),
          %i(name),
          [],
          %i(user profile name),
          %i(profile name),
          %i(name),
          [],
        )
      end
    end

    context "with a segment that refers to a nested array of hashes" do
      let(:segments) { %i(user accounts transactions transaction_id) }

      let(:input) do
        {
          user: {
            accounts: [
              {
                name: "Checking",
                transactions: [
                  { transaction_id: 1, amount: 100 },
                  { transaction_id: 2, amount: 200 },
                ],
              },
              {
                name: "Savings",
                transactions: [
                  { transaction_id: 3, amount: 100 },
                  { transaction_id: 4, amount: 200 },
                ],
              },
            ],
          },
        }
      end

      it "walks the hash and yields the right path, node, and remaining segment values" do
        subject.walk(input) { |path, node, remaining| collect_outputs(path, node, remaining) }

        expect(paths).to contain_exactly(
          [],
          [:user],
          %i(user accounts),
          [:user, :accounts, 0],
          [:user, :accounts, 0, :transactions],
          [:user, :accounts, 0, :transactions, 0],
          [:user, :accounts, 0, :transactions, 0, :transaction_id],
          [:user, :accounts, 0, :transactions, 1],
          [:user, :accounts, 0, :transactions, 1, :transaction_id],
          [:user, :accounts, 1],
          [:user, :accounts, 1, :transactions],
          [:user, :accounts, 1, :transactions, 0],
          [:user, :accounts, 1, :transactions, 0, :transaction_id],
          [:user, :accounts, 1, :transactions, 1],
          [:user, :accounts, 1, :transactions, 1, :transaction_id],
        )

        expect(nodes).to contain_exactly(
          {
            user: {
              accounts: [
                {
                  name: "Checking",
                  transactions: [
                    { transaction_id: 1, amount: 100 },
                    { transaction_id: 2, amount: 200 },
                  ],
                },
                {
                  name: "Savings",
                  transactions: [
                    { transaction_id: 3, amount: 100 },
                    { transaction_id: 4, amount: 200 },
                  ],
                },
              ],
            },
          },
          {
            accounts: [
              {
                name: "Checking",
                transactions: [
                  { transaction_id: 1, amount: 100 },
                  { transaction_id: 2, amount: 200 },
                ],
              },
              {
                name: "Savings",
                transactions: [
                  { transaction_id: 3, amount: 100 },
                  { transaction_id: 4, amount: 200 },
                ],
              },
            ],
          },
          [
            {
              name: "Checking",
              transactions: [
                { transaction_id: 1, amount: 100 },
                { transaction_id: 2, amount: 200 },
              ],
            },
            {
              name: "Savings",
              transactions: [
                { transaction_id: 3, amount: 100 },
                { transaction_id: 4, amount: 200 },
              ],
            },
          ],
          {
            name: "Checking",
            transactions: [
              { transaction_id: 1, amount: 100 },
              { transaction_id: 2, amount: 200 },
            ],
          },
          [
            { transaction_id: 1, amount: 100 },
            { transaction_id: 2, amount: 200 },
          ],
          { transaction_id: 1, amount: 100 },
          1,
          { transaction_id: 2, amount: 200 },
          2,
          {
            name: "Savings",
            transactions: [
              { transaction_id: 3, amount: 100 },
              { transaction_id: 4, amount: 200 },
            ],
          },
          [
            { transaction_id: 3, amount: 100 },
            { transaction_id: 4, amount: 200 },
          ],
          { transaction_id: 3, amount: 100 },
          3,
          { transaction_id: 4, amount: 200 },
          4,
        )

        expect(remaining).to contain_exactly(
          %i(user accounts transactions transaction_id),
          %i(accounts transactions transaction_id),
          %i(transactions transaction_id),
          %i(transactions transaction_id),
          %i(transaction_id),
          %i(transaction_id),
          [],
          %i(transaction_id),
          [],
          %i(transactions transaction_id),
          %i(transaction_id),
          %i(transaction_id),
          [],
          %i(transaction_id),
          [],
        )
      end
    end

    context "with a segment that refers to a leaf node with an array of scalars" do
      let(:segments) { %i(user profile aliases) }
      let(:input) do
        { user: { profile: { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) } } }
      end

      it "walks the hash and yields the right path, node, and remaining segment values" do
        subject.walk(input) { |path, node, remaining| collect_outputs(path, node, remaining) }

        expect(paths).to contain_exactly([], %i(user), %i(user profile), %i(user profile aliases))
        expect(nodes).to contain_exactly(
          { user: { profile: { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) } } },
          { profile: { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) } },
          { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) },
          %w(BetterRobbot BetterAI),
        )

        expect(remaining).to contain_exactly(%i(user profile aliases), %i(profile aliases), %i(aliases), [])
      end
    end

    context "with an input that doesn't match part of the path" do
      let(:segments) { %i(user profile aliases) }

      let(:input) do
        { user: { settings: { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) } } }
      end

      it "walks part of the hash and yields the right path, node, and remaining segment values" do
        subject.walk(input) { |path, node, remaining| collect_outputs(path, node, remaining) }

        expect(paths).to contain_exactly([], %i(user))
        expect(nodes).to contain_exactly(
          { user: { settings: { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) } } },
          { settings: { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) } },
        )
        expect(remaining).to contain_exactly(%i(user profile aliases), %i(profile aliases))
      end
    end

    context "with an input that doesn't match any of the path" do
      let(:segments) { %i(user profile aliases) }

      let(:input) do
        { account: { settings: { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) } } }
      end

      it "walks none of the hash" do
        subject.walk(input) { |path, node, remaining| collect_outputs(path, node, remaining) }

        expect(paths).to contain_exactly([])
        expect(nodes).to contain_exactly({ account: { settings: { name: "Betterbot", aliases: %w(BetterRobbot BetterAI) } } })
        expect(remaining).to contain_exactly(%i(user profile aliases))
      end
    end
  end
end
