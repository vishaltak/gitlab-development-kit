# frozen_string_literal: true

module MeasureHelper
  shared_examples 'it checks if Docker and GDK are running' do |args|
    context "when Docker isn't installed or running" do
      let(:docker_running) { false }

      it 'aborts' do
        expected_error = 'ERROR: Docker is not installed or running!'

        expect { subject.run(args) }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
      end
    end

    context "when GDK isn't running or ready" do
      let(:docker_running) { true }

      it 'aborts' do
        stub_gdk_check(is_running: false)

        expected_error = 'ERROR: GDK is not running locally on http://127.0.0.1:3000!'

        expect { subject.run(args) }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
      end
    end
  end

  shared_context 'Docker and GDK are running' do
    let(:docker_running) { true }

    before do
      stub_gdk_check(is_running: true)
      stub_const('GDK::Command::MeasureBase::SITESPEED_DOCKER_TAG', '1.2.3')
    end
  end

  shared_examples 'runs sitespeed via Docker' do |platform, args_type, args|
    let(:branch_name) { 'some-branch-name' }
    let(:is_linux) { platform == 'linux' }

    before do
      stub_git_rev_parse(branch_name: branch_name)
    end

    it "runs sitespeed via Docker on a #{platform} system", :hide_stdout do
      freeze_time do
        allow(GDK::Machine).to receive(:linux?).and_return(is_linux)
        report_file_path = "sitespeed-result/#{branch_name}_#{Time.now.strftime('%F-%H-%M-%S')}"
        network_host = is_linux ? '--network=host' : ''

        docker_command = case args_type
                         when 'urls'
                           docker_command_for_urls(args, network_host, report_file_path)
                         when 'workflows'
                           docker_command_for_workflows(args, network_host, report_file_path)
                         end

        shellout_docker_run_double = instance_double(Shellout, stream: '', success?: true)
        expect(Shellout).to receive(:new).with(docker_command).and_return(shellout_docker_run_double)

        shellout_open_double = instance_double(Shellout, run: true, success?: true)
        expect(Shellout).to receive(:new).with("open ./#{report_file_path}/index.html").and_return(shellout_open_double)

        subject.run(args)
      end
    end
  end

  def docker_command_for_urls(urls, network_host, report_file_path)
    url_paths = urls.map { |url| "http://host.docker.internal:3000#{url}" }.join(' ')
    %(docker run #{network_host} --cap-add=NET_ADMIN --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:1.2.3 -b chrome -n 4 -c cable --cookie perf_bar_enabled=false --cpu --outputFolder #{report_file_path} #{url_paths})
  end

  def docker_command_for_workflows(workflows, network_host, report_file_path)
    workflow_paths = workflows.map { |workflow| "support/measure_scripts/#{workflow}.js" }.join(' ')
    %(docker run #{network_host} --cap-add=NET_ADMIN --shm-size 2g --rm -v "$(pwd):/sitespeed.io" sitespeedio/sitespeed.io:1.2.3 -b chrome -n 4 -c cable --cookie perf_bar_enabled=false --cpu --outputFolder #{report_file_path} --multi --spa #{workflow_paths})
  end

  def stub_git_rev_parse(branch_name:)
    shellout_double = instance_double(Shellout, run: branch_name)
    allow(Shellout).to receive(:new).with('git rev-parse --abbrev-ref HEAD', chdir: GDK.config.gitlab.dir).and_return(shellout_double)
  end

  def stub_docker_check(is_running:)
    shellout_double = instance_double(Shellout, run: true, success?: is_running)
    allow(Shellout).to receive(:new).with('docker info').and_return(shellout_double)
  end

  def stub_gdk_check(is_running:)
    http_helper_double = instance_double(GDK::HTTPHelper, up?: is_running)
    allow(GDK::HTTPHelper).to receive(:new).with(GDK.config.__uri).and_return(http_helper_double)
  end
end
