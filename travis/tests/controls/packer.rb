# encoding: utf-8

title 'packer validation'

control 'packer' do
  impact 1
  title 'Run packer validate'

  files_exist = [
    'packer/variables.json.example',
  ]

  files_exist.each do |path|
    describe file(path) do
      it { should exist }
      its('content') { should match(%r{\n\Z}) }
    end
  end

  files = command('find packer -maxdepth 1 -name "*.json" -type f').stdout.split("\n")

  files.each do |fname|
    describe command("packer validate -var-file=packer/variables.json.example #{fname}") do
      its('stdout') { should eq "Template validated successfully.\n" }
      its('stderr') { should eq '' }
      its('exit_status') { should eq 0 }
    end
  end
end
