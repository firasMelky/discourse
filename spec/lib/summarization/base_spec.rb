# frozen_string_literal: true

describe Summarization::Base do
  subject(:summarization) { described_class.new }

  fab!(:user) { Fabricate(:user) }
  fab!(:group) { Fabricate(:group) }

  before { group.add(user) }

  describe "#can_request_summaries?" do
    it "returns true if the user group is present in the custom_summarization_allowed_groups_map setting" do
      SiteSetting.custom_summarization_allowed_groups = group.id

      expect(summarization.can_request_summaries?(user)).to eq(true)
    end

    it "returns false if the user group is not present in the custom_summarization_allowed_groups_map setting" do
      SiteSetting.custom_summarization_allowed_groups = ""

      expect(summarization.can_request_summaries?(user)).to eq(false)
    end
  end
end
