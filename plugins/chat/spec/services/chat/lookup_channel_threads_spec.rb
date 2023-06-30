# frozen_string_literal: true

RSpec.describe Chat::LookupChannelThreads do
  describe Chat::LookupChannelThreads::Contract, type: :model do
    it { is_expected.to validate_presence_of :channel_id }
  end

  describe ".call" do
    subject(:result) { described_class.call(params) }

    fab!(:current_user) { Fabricate(:user) }
    fab!(:channel) { Fabricate(:chat_channel, threading_enabled: true) }
    fab!(:thread_1) { Fabricate(:chat_thread, channel: channel) }
    fab!(:thread_2) { Fabricate(:chat_thread, channel: channel) }
    fab!(:thread_3) { Fabricate(:chat_thread, channel: channel) }

    let(:guardian) { Guardian.new(current_user) }
    let(:params) { { guardian: guardian, channel_id: thread_1.channel_id } }

    context "when enable_experimental_chat_threaded_discussions is disabled" do
      before { SiteSetting.enable_experimental_chat_threaded_discussions = false }

      it { is_expected.to fail_a_policy(:threaded_discussions_enabled) }
    end

    context "when enable_experimental_chat_threaded_discussions is enabled" do
      before do
        SiteSetting.enable_experimental_chat_threaded_discussions = true
        [thread_1, thread_2, thread_3].each do |t|
          t.original_message.update!(created_at: 1.week.ago)
          t.add(current_user)
        end
      end

      context "when all steps pass" do
        before do
          msg_1 =
            Fabricate(:chat_message, user: current_user, chat_channel: channel, thread: thread_1)
          msg_1.update!(created_at: 10.minutes.ago)
          msg_2 =
            Fabricate(:chat_message, user: current_user, chat_channel: channel, thread: thread_2)
          msg_2.update!(created_at: 1.day.ago)
          msg_3 =
            Fabricate(:chat_message, user: current_user, chat_channel: channel, thread: thread_3)
          msg_3.update!(created_at: 2.seconds.ago)
        end

        it "sets the service result as successful" do
          expect(result).to be_a_success
        end

        it "returns the threads ordered by the last reply created_at date and time for the thread" do
          expect(result.threads.map(&:id)).to eq([thread_3.id, thread_1.id, thread_2.id])
        end

        it "orders threads with unread messages at the top even if their last reply created_at date and time is older" do
          unread_message = Fabricate(:chat_message, chat_channel: channel, thread: thread_2)
          unread_message.update!(created_at: 2.days.ago)
          expect(result.threads.map(&:id)).to eq([thread_2.id, thread_3.id, thread_1.id])
        end

        it "does not return threads where the original message is trashed" do
          thread_1.original_message.trash!
          expect(result.threads.map(&:id)).to eq([thread_3.id, thread_2.id])
        end

        it "does not return threads where the original message is deleted" do
          thread_1.original_message.destroy
          expect(result.threads.map(&:id)).to eq([thread_3.id, thread_2.id])
        end

        it "does not count deleted messages for sort order" do
          Chat::Message.where(thread: thread_3).each(&:trash!)
          expect(result.threads.map(&:id)).to eq([thread_1.id, thread_2.id])
        end

        it "only returns threads where the user has their thread notification level as tracking or regular" do
          new_thread_1 = Fabricate(:chat_thread, channel: channel)
          new_thread_2 = Fabricate(:chat_thread, channel: channel)
          new_thread_1.add(current_user)
          new_thread_1.membership_for(current_user).update!(
            notification_level: Chat::UserChatThreadMembership.notification_levels[:muted],
          )

          expect(result.threads.map(&:id)).to eq([thread_3.id, thread_1.id, thread_2.id])
        end

        it "does not return threads from another channel" do
          thread_4 = Fabricate(:chat_thread)
          Fabricate(
            :chat_message,
            user: current_user,
            thread: thread_4,
            chat_channel: thread_4.channel,
            created_at: 2.seconds.ago,
          )
          expect(result.threads.map(&:id)).to eq([thread_3.id, thread_1.id, thread_2.id])
        end
      end

      context "when params are not valid" do
        before { params.delete(:channel_id) }

        it { is_expected.to fail_a_contract }
      end

      context "when user cannot see channel" do
        fab!(:private_channel) { Fabricate(:private_category_channel, group: Fabricate(:group)) }

        before do
          thread_1.update!(channel: private_channel)
          private_channel.update!(threading_enabled: true)
        end

        it { is_expected.to fail_a_policy(:can_view_channel) }
      end

      context "when threading is not enabled for the channel" do
        before { channel.update!(threading_enabled: false) }

        it { is_expected.to fail_a_policy(:threading_enabled_for_channel) }
      end
    end
  end
end
