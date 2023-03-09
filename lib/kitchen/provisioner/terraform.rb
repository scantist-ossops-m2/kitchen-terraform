# frozen_string_literal: true

# Copyright 2016-2021 Copado NCS LLC
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

require "kitchen"
require "kitchen/terraform/raise/action_failed"
require "kitchen/terraform/configurable"
require "kitchen/terraform/provisioner/converge"

module Kitchen
  # This namespace is defined by Kitchen.
  #
  # @see http://www.rubydoc.info/gems/test-kitchen/Kitchen/Provisioner
  module Provisioner
    # The Terraform provisioner applies changes to the Terraform state based on the configuration of the root module.
    #
    # === Commands
    #
    # The following command-line actions are provided by the provisioner.
    #
    # ==== kitchen converge
    #
    # {include:Kitchen::Terraform::Provisioner::Converge}
    #
    # === Configuration Attributes
    #
    # The provisioner has no configuration attributes, but the +provisioner+ mapping must be declared with the plugin name
    # within the {http://kitchen.ci/docs/getting-started/kitchen-yml Test Kitchen configuration file}.
    #
    #   provisioner:
    #     name: terraform
    #
    # === Ruby Interface
    #
    # This class implements the interface of Kitchen::Configurable which requires the following Reek suppressions:
    # :reek:MissingSafeMethod { exclude: [ finalize_config! ] }
    #
    # @example Describe the converge command
    #   kitchen help converge
    # @example Converge a Test Kitchen instance
    #   kitchen converge default-ubuntu
    # @version 2
    class Terraform < ::Kitchen::Provisioner::Base
      # UNSUPPORTED_BASE_ATTRIBUTES is the list of attributes inherited from
      # Kitchen::Provisioner::Base which are not supported by Kitchen::Provisioner::Terraform.
      UNSUPPORTED_BASE_ATTRIBUTES = [
        :command_prefix,
        :downloads,
        :http_proxy,
        :https_proxy,
        :ftp_proxy,
        :max_retries,
        :root_path,
        :retry_on_exit_code,
        :sudo,
        :sudo_command,
        :wait_for_retry,
      ]
      defaults.delete_if do |key|
        UNSUPPORTED_BASE_ATTRIBUTES.include? key
      end
      kitchen_provisioner_api_version 2

      include ::Kitchen::Terraform::Configurable

      # Converges a Test Kitchen instance.
      #
      # @param state [Hash] the mutable instance and provisioner state.
      # @raise [Kitchen::ActionFailed] if the result of the action is a failure.
      def call(state)
        driver = instance.driver
        transport = driver.transport

        ::Kitchen::Terraform::Provisioner::Converge.new(
          config: driver.send(:config),
          connection: transport.connection({}),
          debug_connection: transport.connection(logger: ::Kitchen::Terraform::DebugLogger.new(logger: logger)),
          logger: logger,
          version_requirement: version_requirement,
          workspace_name: workspace_name,
        ).call state: state
      rescue => error
        ::Kitchen::Terraform::Raise::ActionFailed.new(logger: logger).call message: error.message
      end
    end
  end
end
