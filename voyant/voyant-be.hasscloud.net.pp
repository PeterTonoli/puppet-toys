node voyant-be {
	# unzip is used by puppet-archive to process the VoyantServer archive
        package { 'unzip':
                ensure => 'installed',
        }

	# Install Java
	class { 'java':
		distribution => 'jre',
	}

	# Install Apache Tomcat
	tomcat::install { '/opt/tomcat':
		source_url => 'http://mirror.ventraip.net.au/apache/tomcat/tomcat-8/v8.5.29/bin/apache-tomcat-8.5.29.tar.gz'
	}

	# Inform Apache Tomcat where Catalina lives
	tomcat::instance { 'default':
		catalina_home => '/opt/tomcat',
	}

	# Apache Tomcat listens on port 8080
	tomcat::config::server { 'default':
		catalina_base => '/opt/tomcat',
		port          => '8080',
	}

	# Create the mount-point for our persistent data store
	file { '/mnt/voyant':
		ensure => 'directory',
		owner  => 'tomcat',
		group  => 'tomcat',
		mode   => '0755',
	}

	# Mount the Voyant persistent data store
	mount { "/mnt/voyant":
		device  => "LABEL=voyant",
	        fstype  => "ext4",
	        ensure  => "mounted",
	        options => "defaults",
	        atboot  => true,
	}

	# Download and unzip VoyantServer binary
	archive { '/tmp/VoyantServer2_4-M4.zip':
		ensure        => present,
		extract       => true,
		extract_path  => '/opt/tomcat/webapps/',
		source        => 'https://github.com/sgsinclair/VoyantServer/releases/download/2.4.0-M3/VoyantServer2_4-M4.zip',
		creates       => '/tmp/voyantserver',
		cleanup       => true,
	}

	# Create a symlink to our binary - CHANGE THIS SYMLINK when the VoyantServer binary changes
	file { '/opt/tomcat/webapps/ROOT':
		ensure => 'link',
		target => '/opt/tomcat/webapps/VoyantServer2_4-M4/_app',
	}

	# Copy our bespoke Voyant configuration to the Voyant server 
	file { "/opt/tomcat/webapps/ROOT/server-settings.txt":
		mode => "0644",
	        owner => 'tomcat',
		group => 'tomcat',
	        source => 'puppet:///modules/voyant/server-settings.txt',
	}
}
