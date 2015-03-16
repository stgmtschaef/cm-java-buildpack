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
require 'java_buildpack/framework/http_proxy_agent'

describe JavaBuildpack::Framework::HttpProxyAgent do
  include_context 'component_helper'

  it 'detect always detect' do
    expect(component.detect).to eq('http-proxy-agent')
  end

  it 'download the proxy agent',
     cache_fixture: 'stub-download.jar' do

    component.compile

    expect(sandbox + 'http-proxy-agent.jar').to exist
  end

  it 'add the correct java opts', cache_fixture: 'stub-download.jar' do

    component.release
    expect(java_opts.last).to include('http-proxy-agent.jar')
  end
end
