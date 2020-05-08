# frozen_string_literal: true

module GDK
  module Services
    class GitLabWorkhorse < Required
      def name
        'gitlab-workhorse'
      end

      def command
        %(/usr/bin/env PATH="#{settings.dir}:$PATH" gitlab-workhorse -authSocket #{gitlab_socket} -cableSocket #{gitlab_actioncable_socket} -listenAddr #{listen_address} -documentRoot #{gitlab_public_dir} -developmentMode -secretPath #{gitlab_workhorse_secret} -config #{settings.config_file})
      end

      private

      def settings
        @settings ||= config.workhorse
      end

      def listen_address
        "#{settings.__active_host}:#{settings.__active_port}"
      end

      def gitlab_socket
        config.gdk_root.join('gitlab.socket')
      end

      def gitlab_public_dir
        config.gdk_root.join('gitlab', 'public')
      end

      def gitlab_workhorse_secret
        config.gdk_root.join('gitlab', '.gitlab_workhorse_secret')
      end

      def gitlab_actioncable_socket
        config.gdk_root.join('gitlab_actioncable.socket')
      end
    end
  end
end
