#
# Author:: Seth Chisamore <schisamo@opscode.com>
# Cookbook Name:: mediawiki
# Recipe:: status
#
# Copyright 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

users = []

begin
  search(:users, 'groups:sysadmin').each do |u|
    h = {}
    h['username'] = u['id']
    if u['ssh_keys']
      # redundant since net-ssh is a dependency of chef...but you never know!
      chef_gem "net-ssh" do
        action :install
      end
      require 'net/ssh'
      h['key_fingerprint'] = Net::SSH::KeyFactory.load_data_public_key(u['ssh_keys']).fingerprint
    end
    users << h
  end
rescue Net::HTTPServerException # in case the data bag doesn't exist
end

title = "Mediawiki LAMP Stack Quick Start"
app = data_bag_item("apps", "mediawiki")
organization = Chef::Config[:chef_server_url].split('/').last
pretty_run_list = node.run_list.run_list_items.collect do |item|
  "#{item.name} (#{item.type.to_s})"
end.join(", ")

template "#{::File.join(app['deploy_to'], "current")}/status.html" do
  source "status.html.erb"
  owner app["owner"]
  group app["group"]
  mode "0755"
  variables(
    :app => app,
    :title => title,
    :organization => organization,
    :run_list => pretty_run_list,
    :users => users
  )
end
