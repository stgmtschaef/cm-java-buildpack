# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'
require 'component_helper'
require 'java_buildpack/framework/app_dynamics_agent'

describe JavaBuildpack::Framework::AppDynamicsAgent do
  include_context 'component_helper'

  let(:configuration) { { 'tier_name' => 'test-tier-name' } }

  it 'should not detect without app-dynamics-n/a service' do
    expect(component.detect).to be_nil
  end

  context do

    let(:credentials) { {"node-name-prefix" => "cf"} }
    let(:sm_credentials) { {'smData' => { 'PortfolioName' => "Portfolio", 'CIName' => "Some CI - Development"} } }

    before do
      allow(services).to receive(:one_service?).with(/app-dynamics/).and_return(true)
      allow(services).to receive(:one_service?).with(/servicemanager-service/).and_return(true)
      allow(services).to receive(:find_service).with(/app-dynamics/).and_return('credentials' => credentials)
      allow(services).to receive(:find_service).with(/servicemanager-service/).and_return('credentials' => sm_credentials)
    end

    it 'should detect with app-dynamics-n/a service' do
      expect(component.detect).to eq("app-dynamics-agent=#{version}")
    end

    context do
      before do
        allow(services).to receive(:one_service?).with(/servicemanager-service/).and_return(nil)
      end
      
      it 'should not detect without servicemanager-service' do
        expect(component.detect).to be_nil
      end
    end

    it 'should expand AppDynamics agent zip',
       cache_fixture: 'stub-app-dynamics-agent.zip' do

      component.compile

      expect(sandbox + 'javaagent.jar').to exist
    end

    context do

      let(:credentials) { { 'host-name' => 'test-host-name', "node-name-prefix" => "cf" } }

      it 'should update JAVA_OPTS' do
        component.release

        expect(java_opts).to include('-javaagent:$PWD/.java-buildpack/app_dynamics_agent/app-dynamics-hack-pre.jar')
        expect(java_opts).to include('-javaagent:$PWD/.java-buildpack/app_dynamics_agent/app-dynamics-hack-post.jar')
        expect(java_opts).to include('-javaagent:$PWD/.java-buildpack/app_dynamics_agent/javaagent.jar')
        expect(java_opts).to include('-Dappdynamics.controller.hostName=test-host-name')
        expect(java_opts).to include("-Dappdynamics.agent.applicationName='Portfolio'")
        expect(java_opts).to include("-Dappdynamics.agent.tierName='Some CI - Development'")
        expect(java_opts).to include("-Dappdynamics.agent.nodeName='test-application-name[$(expr \"$VCAP_APPLICATION\" : '.*instance_index[\": ]*\\([0-9]\\+\\).*')]-[cf]'")
      end

      context do
        let(:credentials) { super().merge 'port' => 'test-port' }

        it 'should add port to JAVA_OPTS if specified' do
          component.release

          expect(java_opts).to include('-Dappdynamics.controller.port=test-port')
        end
      end

      context do
        let(:credentials) { super().merge 'ssl-enabled' => 'test-ssl-enabled' }

        it 'should add ssl_enabled to JAVA_OPTS if specified' do
          component.release

          expect(java_opts).to include('-Dappdynamics.controller.ssl.enabled=test-ssl-enabled')
        end
      end

      context do
        let(:credentials) { super().merge 'account-name' => 'test-account-name' }

        it 'should add account_name to JAVA_OPTS if specified' do
          component.release

          expect(java_opts).to include('-Dappdynamics.agent.accountName=test-account-name')
        end
      end

      context do
        let(:credentials) { super().merge 'account-access-key' => 'test-account-access-key' }

        it 'should add account_access_key to JAVA_OPTS if specified' do
          component.release

          expect(java_opts).to include('-Dappdynamics.agent.accountAccessKey=test-account-access-key')
        end
      end
    end

  end

end