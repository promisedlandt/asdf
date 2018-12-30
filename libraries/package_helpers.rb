#
# Cookbook:: asdf
# Library:: package_helpers
#
# Copyright:: 2017-2018, 1000Bulbs, All Rights Reserved.

module Asdf
  module PackageHelpers
    def install_asdf_deps
      build_essential 'asdf'

      asdf_deps = %w(automake git grep libtool mlocate unzip)

      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        asdf_deps.concat %w(bzip2 libffi-devel libxslt-devel libyaml-devel readline-devel openssl-devel unixODBC-devel)
      when 'debian'
        asdf_deps.concat %w(libffi-dev libreadline-dev libssl-dev libxslt-dev libyaml-dev unixodbc-dev)
      end

      package asdf_deps
    end

    def install_package_deps
      package_deps = []

      case new_resource.package
      when 'R'
        package_deps.concat Array(r_deps)
      when 'clojure', 'gradle', 'sbt', 'scala'
        package_deps.concat Array(clojure_deps)
      when 'erlang'
        package_deps.concat Array(erlang_deps)
      when 'haskell'
        package_deps.concat Array(haskell_deps)
      when 'nodejs'
        package_deps.concat Array(nodejs_deps)
      when 'ocaml'
        package_deps.concat Array(ocaml_deps)
      when 'openresty'
        package_deps.concat Array(openresty_deps)
      when 'php'
        package_deps.concat Array(php_deps)
      when 'postgres'
        package_deps.concat Array(postgres_deps)
      when 'python'
        package_deps.concat Array(python_deps)
      when 'ruby'
        package_deps.concat Array(ruby_deps)

        user_path = ::File.expand_path("~#{asdf_user}")

        file "#{user_path}/.default-gems" do
          content 'bundler'
          owner asdf_user
          group asdf_user
          not_if { ::File.exist?("#{user_path}/.default-gems") }
        end
      end

      package package_deps unless package_deps.empty?
    end

    def r_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        %w(libcurl-devel libgfortran libXt-devel pcre2 pcre2-devel xz-devel)
      when 'debian'
        %w(gfortran libbz2-dev libcurl3-dev liblzma-dev libpcre3 libpcre3-dev libxt-dev)
      end
    end

    def clojure_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        'java-1.8.0-openjdk'
      when 'debian'
        'default-jre'
      end
    end

    def erlang_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        %w(gcc gcc-c++ glibc-devel java-1.8.0-openjdk-devel ncurses-devel openssl-devel wget wxBase.x86_64)
      when 'debian'
        deps = %w(libgl1-mesa-dev libglu1-mesa-dev libpng3 libssh-dev xsltproc fop libxml2-utils default-jdk)
        deps << 'libwxgtk3.0-dev' if node['platform'] == 'ubuntu'
        deps
      end
    end

    def gradle_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        'java-1.8.0-openjdk'
      when 'debian'
        'default-jre'
      end
    end

    def haskell_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        'gmp-devel'
      when 'debian'
        'libgmp-dev'
      end
    end

    def nodejs_deps
      deps = []

      script 'install nodejs package dependencies' do
        code 'bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring'
        only_if { ::Dir.exist?("#{asdf_path}/plugins/nodejs") }
      end

      deps
    end

    def ocaml_deps
      deps = []
      deps << 'aspcud' if node['platform_family'] == 'debian'
      deps
    end

    def openresty_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        %w(openssl openssl-devel pcre2 pcre2-devel)
      when 'debian'
        %w(openssl libssl-dev libpcre3 libpcre3-dev)
      end
    end

    def php_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        %w(libcurl libcurl-devel libcxx libcxx-devel libjpeg-turbo-devel libpng-devel openssl openssl-devel re2c readline-devel libedit-devel zlib-devel libicu-devel libxml2-devel postgresql-libs)
      when 'debian'
        # Fix for PHP bug
        link '/usr/local/include/curl' do
          to '/usr/include/x86_64-linux-gnu/curl'
          only_if { node['platform_version'] == '18.04' }
        end

        package 'bison' do
          action :purge
        end

        include_recipe 'ark'

        # PHP 5 fails to build on Bison 3
        ark 'bison' do
          url 'http://ftp.gnu.org/gnu/bison/bison-2.7.tar.gz'
          version '2.7'
          autoconf_opts %w(--with-libiconv-prefix=/usr/local/libiconv/)
          action :install_with_make
        end

        deps = %w(curl libjpeg-dev openssl libssl-dev libcurl4-openssl-dev pkg-config libreadline-dev libedit-dev zlib1g-dev libicu-dev libxml2-dev libmysqlclient-dev libpq-dev)

        if node['platform'] == 'ubuntu'
          deps << 'libpng16-dev' if node['platform_version'] == '16.04'
          deps.concat %w(libcurl4 libpng-dev re2c) if node['platform_version'] == '18.04'
        end

        deps
      end
    end

    def postgres_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        'readline-devel'
      when 'debian'
        'libreadline-dev'
      end
    end

    def python_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        %w(openssl-dev zlib-devel readline-devel sqlite-devel wget curl llvm)
      when 'debian'
        %w(libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm xz-utils tk-dev)
      end
    end

    def ruby_deps
      deps = []

      if node['platform_family'] == 'debian'
        deps << 'zlib1g-dev'
        deps << 'libssl1.0-dev' if node['platform_version'] == '18.04'
      end

      deps
    end

    def sbt_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        'java-1.8.0-openjdk'
      when 'debian'
        'default-jre'
      end
    end

    def scala_deps
      case node['platform_family']
      when 'amazon', 'fedora', 'rhel'
        'java-1.8.0-openjdk'
      when 'debian'
        'default-jre'
      end
    end
  end
end
