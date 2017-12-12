execute 'resizeJenkinsMemorySettings' do
  command "sudo sed -i 's/JENKINS_JAVA_OPTIONS=.*.$/JENKINS_JAVA_OPTIONS=\"-Djava.awt.headless=true -Xmx1024m -XX:MaxPermSize=512m\"/' /etc/sysconfig/jenkins"
end

execute 'chmodservices' do
  command "chmod -R 755 /home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files;"
end
directory '/var/lib/jenkins/workspace' do
  owner 'jenkins'
  group 'jenkins'
  mode '0777'
  recursive true
  action :create
end
execute 'startjenkins' do
  command "sudo service jenkins start"
end
execute 'copyJenkinsClientJar' do
  command "cp #{node['client']['jar']} /home/#{node['jenkins']['SSH_user']}/jenkins-cli.jar; chmod 755 /home/#{node['jenkins']['SSH_user']}/jenkins-cli.jar"
end
execute 'createJobExecUser' do
  command "sleep 30;echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount(\"jobexec\", \"jenkinsadmin\")' | java -jar #{node['client']['jar']} -auth @#{node['authfile']} -s http://localhost:8080/ groovy ="
end
execute 'copyEncryptGroovyScript' do
  command "cp /home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/default/encrypt.groovy /home/#{node['jenkins']['SSH_user']}/encrypt.groovy"
end

execute 'copyXmls' do
  command "tar -xvf /home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/default/xmls.tar"
  cwd "/var/lib/jenkins"
end
execute 'copyConfigXml' do
  command "cp /home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/node/config.xml ."
  cwd "/var/lib/jenkins"
end
execute 'copyCredentialsXml' do
  command "cp /home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/credentials/credentials.xml ."
  cwd "/var/lib/jenkins"
end
# script approvals going in with  xmls.tar will be overwritten
execute 'copyScriptApprovals' do
  command "cp #{node['jenkins']['scriptApprovalfile']} #{node['jenkins']['scriptApprovalfiletarget']}"
end
service "jenkins" do
  supports [:stop, :start, :restart]
  action [:restart]
end


if (File.exist?("/home/#{node['jenkins']['SSH_user']}/jazz-core"))
	execute 'downloadgitproj' do
  		command "rm -rf /home/#{node['jenkins']['SSH_user']}/jazz-core"
  		cwd "/home/#{node['jenkins']['SSH_user']}"
	end
end
execute 'downloadgitproj' do
  command "/usr/local/git/bin/git clone -b #{node['git_branch']} https://github.com/tmobile/jazz.git jazz-core"

  cwd "/home/#{node['jenkins']['SSH_user']}"
end

execute 'copylinkdir' do
  command "cp -rf /home/#{node['jenkins']['SSH_user']}/jazz-core/aws-apigateway-importer /var/lib; chmod -R 777 /var/lib/aws-apigateway-importer"
end


execute 'createcredentials-jenkins1' do
  command "sleep 30;/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/credentials/jenkins1.sh localhost #{node['jenkins']['SSH_user']}"
end
execute 'createcredentials-jobexecutor' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/credentials/jobexec.sh localhost #{node['jenkins']['SSH_user']}"
end
execute 'createcredentials-aws' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/credentials/aws.sh localhost #{node['jenkins']['SSH_user']}"
end
execute 'createcredentials-cognitouser' do
  command "sleep 30;/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/credentials/cognitouser.sh localhost #{node['jenkins']['SSH_user']}"
end



execute 'createJob-create-service' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_create-service.sh localhost create-service #{node['bitbucketelb']} #{node['jenkins']['SSH_user']}"
end
execute 'createJob-delete-service' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_delete-service.sh localhost delete-service #{node['bitbucketelb']} #{node['jenkins']['SSH_user']}"
end
execute 'createJob-job_build_pack_api' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_build_java_api.sh localhost build_pack_api #{node['bitbucketelb']} #{node['jenkins']['SSH_user']}"
end
execute 'createJob-bitbucketteam_newService' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_bitbucketteam_newService.sh localhost bitbucketteam_newService #{node['bitbucketelb']}  #{node['jenkins']['SSH_user']}"
end
execute 'job_build-deploy-platform-service' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_build-deploy-platform-service.sh localhost build-deploy-platform-service  #{node['bitbucketelb']}  #{node['region']}  #{node['jenkins']['SSH_user']}"
end
execute 'job_cleanup_cloudfront_distributions' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_cleanup_cloudfront_distributions.sh localhost cleanup_cloudfront_distributions  #{node['bitbucketelb']} #{node['jenkins']['SSH_user']}"
end
execute 'job_deploy-all-platform-services' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_deploy-all-platform-services.sh localhost deploy-all-platform-services #{node['bitbucketelb']}  #{node['region']} #{node['jenkins']['SSH_user']}"
end
execute 'createJob-job-pack-lambda' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_build_pack_lambda.sh localhost build-pack-lambda #{node['bitbucketelb']}  #{node['jenkins']['SSH_user']}"
end
execute 'createJob-job-build-pack-website' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/job_build_pack_website.sh localhost build-pack-website #{node['bitbucketelb']}  #{node['jenkins']['SSH_user']}"
end
link '/usr/bin/aws-api-import' do
  to "/home/#{node['jenkins']['SSH_user']}/jazz-core/aws-apigateway-importer/aws-api-import.sh"
  owner 'jenkins'
  group 'jenkins'
  mode '0777'
end
link '/usr/bin/aws' do
  to '/usr/local/bin/aws'
  owner 'root'
  group 'root'
  mode '0777'
end

execute 'configureJenkinsProperites' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/node/configureJenkinsProps.sh localhost #{node['jenkins']['SSH_user']}"
end

execute 'configJenkinsLocConfigXml' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/node/configJenkinsLocConfigXml.sh  #{node['jenkinselb']} #{node['jenkins']['SES-defaultSuffix']}"
end


execute 'configJenkinsEmailExtXml' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/node/configJenkinsEmailExtXml.sh #{node['jenkins']['SES-defaultSuffix']} #{node['jenkins']['SES-smtpAuthUsername']} #{node['jenkins']['SES-smtpAuthPassword']} #{node['jenkins']['SES-smtpHost']} #{node['jenkins']['SES-useSsl']} #{node['jenkins']['SES-smtpPort']} #{node['jenkinselb']} #{node['jenkins']['user']} #{node['jenkins']['password']} #{node['jenkins']['SSH_user']}"

end

execute 'configJenkinsTaskMailerXml' do
  command "/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/node/configJenkinsTaskMailerXml.sh #{node['jenkins']['SES-smtpAuthUsername']} #{node['jenkins']['SES-smtpAuthPassword']} #{node['jenkins']['SES-smtpHost']} #{node['jenkins']['SES-useSsl']} #{node['jenkinselb']} #{node['jenkins']['user']} #{node['jenkins']['password']} #{node['jenkins']['SSH_user']}"
end

execute 'copyJenkinsPropertyfile' do
  command "cp #{node['jenkins']['propertyfile']} #{node['jenkins']['propertyfiletarget']};chmod 777  #{node['jenkins']['propertyfiletarget']}"
  cwd "/home/#{node['jenkins']['SSH_user']}"
end
execute 'chownJenkinsfolder' do
  command "chown jenkins:jenkins /var/lib/jenkins"
end

service "jenkins" do
  supports [:stop, :start, :restart]
  action [:restart]
end
execute 'copyJobBuildPackApi' do
  command "sleep 20;/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/copyJob.sh localhost build_pack_api build_pack_api_dev #{node['jenkins']['SSH_user']}"
end
execute 'copyJobBuildPackLambda' do
  command "sleep 20;/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/copyJob.sh localhost build-pack-lambda build-pack-lambda-dev #{node['jenkins']['SSH_user']}"
end
execute 'copyJobBuildPackLambda' do
  command "sleep 20;/home/#{node['jenkins']['SSH_user']}/cookbooks/jenkins/files/jobs/copyJob.sh localhost build-pack-website build-pack-website-dev #{node['jenkins']['SSH_user']}"
end