# frozen_string_literal: true

RSpec.describe "Topic summarization", type: :system, js: true do
  fab!(:user) { Fabricate(:admin) }

  # has_summary to force topic map to be present.
  fab!(:topic) { Fabricate(:topic, has_summary: true) }
  fab!(:post_1) { Fabricate(:post, topic: topic) }
  fab!(:post_2) { Fabricate(:post, topic: topic) }

  let(:plugin) { Plugin::Instance.new }

  let(:summarization_result) { { summary: "This is a summary", chunks: [] } }

  before do
    sign_in(user)
    strategy = DummyCustomSummarization.new(summarization_result)
    plugin.register_summarization_strategy(strategy)
    SiteSetting.summarization_strategy = strategy.model
  end

  it "returns a summary using the selected timeframe" do
    visit("/t/-/#{topic.id}")

    find(".topic-strategy-summarization", wait: 5).click

    expect(page.has_css?(".topic-summary-modal", wait: 5)).to eq(true)
  end
end
