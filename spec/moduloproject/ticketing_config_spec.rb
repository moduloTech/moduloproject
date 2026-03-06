# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Moduloproject::TicketingConfig do
  describe '.resolve' do
    context 'with ticket_provider in options' do
      it 'builds from CLI options' do
        config = described_class.resolve(ticket_provider: 'gitlab', gitlab_project: 'group/project')
        expect(config.provider).to eq('gitlab')
        expect(config.gitlab_project).to eq('group/project')
      end
    end

    context 'when stdin is a TTY' do
      before do
        allow($stdin).to receive(:tty?).and_return(true)
      end

      it 'prompts interactively' do
        prompt = instance_double(TTY::Prompt)
        allow(TTY::Prompt).to receive(:new).and_return(prompt)
        allow(prompt).to receive(:select).with('Ticketing provider?', described_class::PROVIDERS).and_return('none')

        config = described_class.resolve({})
        expect(config.provider).to eq('none')
      end
    end

    context 'when stdin is not a TTY' do
      before do
        allow($stdin).to receive(:tty?).and_return(false)
      end

      it 'defaults to none' do
        config = described_class.resolve({})
        expect(config.provider).to eq('none')
        expect(config.enabled?).to be false
      end
    end
  end

  describe '.from_cli' do
    it 'builds gitlab config' do
      config = described_class.from_cli(
        ticket_provider: 'gitlab',
        gitlab_project: 'mygroup/myproject',
        gitlab_host: 'gitlab.example.com'
      )
      expect(config.provider).to eq('gitlab')
      expect(config.gitlab_project).to eq('mygroup/myproject')
      expect(config.gitlab_host).to eq('gitlab.example.com')
      expect(config.gitlab?).to be true
    end

    it 'builds jira config' do
      config = described_class.from_cli(
        ticket_provider: 'jira',
        jira_url: 'https://myorg.atlassian.net',
        jira_project: 'PROJ',
        jira_email: 'dev@example.com'
      )
      expect(config.provider).to eq('jira')
      expect(config.jira_url).to eq('https://myorg.atlassian.net')
      expect(config.jira_project).to eq('PROJ')
      expect(config.jira_email).to eq('dev@example.com')
      expect(config.jira?).to be true
    end

    it 'builds roadmap config' do
      config = described_class.from_cli(ticket_provider: 'roadmap')
      expect(config.provider).to eq('roadmap')
      expect(config.roadmap_file).to eq('ROADMAP.md')
      expect(config.roadmap?).to be true
    end

    it 'defaults gitlab_host to gitlab.com' do
      config = described_class.from_cli(ticket_provider: 'gitlab')
      expect(config.gitlab_host).to eq('gitlab.com')
    end

    it 'defaults roadmap_file to ROADMAP.md' do
      config = described_class.from_cli(ticket_provider: 'roadmap', roadmap_file: 'TODO.md')
      expect(config.roadmap_file).to eq('TODO.md')
    end
  end

  describe '.from_prompt' do
    let(:prompt) { instance_double(TTY::Prompt) }

    before do
      allow(TTY::Prompt).to receive(:new).and_return(prompt)
    end

    it 'prompts for gitlab details' do
      allow(prompt).to receive(:select).and_return('gitlab')
      allow(prompt).to receive(:ask).with('GitLab project path (e.g. group/project):').and_return('g/p')
      allow(prompt).to receive(:ask).with('GitLab hostname:', default: 'gitlab.com').and_return('gitlab.com')

      config = described_class.from_prompt
      expect(config.gitlab?).to be true
      expect(config.gitlab_project).to eq('g/p')
    end

    it 'prompts for jira details' do
      allow(prompt).to receive(:select).and_return('jira')
      allow(prompt).to receive(:ask).with('Jira instance URL:').and_return('https://jira.example.com')
      allow(prompt).to receive(:ask).with('Jira project key:').and_return('PRJ')
      allow(prompt).to receive(:ask).with('Jira API email:').and_return('a@b.com')

      config = described_class.from_prompt
      expect(config.jira?).to be true
      expect(config.jira_url).to eq('https://jira.example.com')
    end

    it 'prompts for roadmap file' do
      allow(prompt).to receive(:select).and_return('roadmap')
      allow(prompt).to receive(:ask).with('Roadmap file path:', default: 'ROADMAP.md').and_return('ROADMAP.md')

      config = described_class.from_prompt
      expect(config.roadmap?).to be true
    end

    it 'returns none without further prompts' do
      allow(prompt).to receive(:select).and_return('none')

      config = described_class.from_prompt
      expect(config.enabled?).to be false
    end
  end

  describe '#enabled?' do
    it 'returns false for none' do
      expect(described_class.new(provider: 'none').enabled?).to be false
    end

    it 'returns true for gitlab' do
      expect(described_class.new(provider: 'gitlab').enabled?).to be true
    end

    it 'returns true for jira' do
      expect(described_class.new(provider: 'jira').enabled?).to be true
    end

    it 'returns true for roadmap' do
      expect(described_class.new(provider: 'roadmap').enabled?).to be true
    end
  end

  describe 'provider predicates' do
    it 'gitlab? returns true only for gitlab' do
      expect(described_class.new(provider: 'gitlab').gitlab?).to be true
      expect(described_class.new(provider: 'jira').gitlab?).to be false
    end

    it 'jira? returns true only for jira' do
      expect(described_class.new(provider: 'jira').jira?).to be true
      expect(described_class.new(provider: 'gitlab').jira?).to be false
    end

    it 'roadmap? returns true only for roadmap' do
      expect(described_class.new(provider: 'roadmap').roadmap?).to be true
      expect(described_class.new(provider: 'none').roadmap?).to be false
    end
  end

  describe 'validation' do
    it 'raises for invalid provider' do
      expect { described_class.new(provider: 'trello') }.to raise_error(ArgumentError, /Invalid ticketing provider/)
    end

    it 'accepts all valid providers' do
      described_class::PROVIDERS.each do |provider|
        expect { described_class.new(provider: provider) }.not_to raise_error
      end
    end
  end
end
