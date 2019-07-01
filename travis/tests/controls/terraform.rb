# encoding: utf-8

title 'terraform validation'

control 'terraform' do
  impact 1
  title 'Run terraform validate for stage & prod'

  environments = ['/', 'stage/', 'prod/']

  environments.each do |fname|
    describe file("terraform/#{fname}/terraform.tfvars.example") do
      it { should exist }
      its('content') { should match(%r{\n\Z}) }
    end

    describe command('cd terraform/#{fname} && terraform init -backend=false && terraform validate -var-file=terraform.tfvars.example') do
      its('stdout') { should match "Terraform has been successfully initialized!" }
      its('stderr') { should eq '' }
      its('exit_status') { should eq 0 }
    end

    describe command("cd terraform/#{fname} && tflint --var-file=terraform.tfvars.example --deep -q") do
      its('stdout') { should eq "" }
      its('stderr') { should eq "" }
      its('exit_status') { should eq 0 }
    end
  end
end
