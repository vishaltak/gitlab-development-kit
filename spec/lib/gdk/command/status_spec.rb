# frozen_string_literal: true

RSpec.describe GDK::Command::Status do
  context 'with no extra arguments' do
    context 'when rails_web.enabled is true' do
      it "displays 'GitLab available' message" do
        allow(GDK.config).to receive(:rails_web?).and_return(true)

        expect_runit_to_execute(command: 'status')

        expect { subject.run }.to output(/GitLab available at/).to_stdout
      end
    end

    context 'when rails_web.enabled is false' do
      it "does not display 'GitLab available' message" do
        allow(GDK.config).to receive(:rails_web?).and_return(false)

        expect_runit_to_execute(command: 'status')

        expect { subject.run }.not_to output(/GitLab available at/).to_stdout
      end
    end
  end

  context 'with extra arguments' do
    it 'queries runit for status to specific services only' do
      expect_runit_to_execute(command: 'status', args: ['rails-web'])

      expect { subject.run(%w[rails-web]) }.not_to output(/GitLab available at/).to_stdout
    end
  end

  def expect_runit_to_execute(command:, args: [])
    expect(Runit).to receive(:sv).with(command, args).and_return(true)
  end
end
