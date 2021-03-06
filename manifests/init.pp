class sysctl($exclusive = false) {
  if $exclusive {
    file { ['/run/sysctl.d', '/etc/sysctl.d', '/usr/local/lib/sysctl.d', '/usr/lib/sysctl.d', '/lib/sysctl.d']:
      ensure  => directory,
      recurse => true,
      purge   => true
    }
  }

  concat { '/etc/sysctl.conf': }

  concat::fragment { 'sysctl_header':
    target  => '/etc/sysctl.conf',
    content => "# Managed by Puppet\n\n",
    order   => 01
  }

  case $::osfamily {
    'RedHat': {
      $packages = 'procps'

      exec { 'sysctl -p':
        subscribe   => File['/etc/sysctl.conf'],
        refreshonly => true,
      }
    }
    'Debian' : {
      case $::operatingsystem {
        'Ubuntu': {
          $packages = ['procps', 'upstart']

          service { 'procps':
            ensure    => running,
            enable    => true,
            require   => [Package['procps', 'upstart']],
            subscribe => File['/etc/sysctl.conf'],
          }
        }
        'Debian': {
          $packages = 'procps'

          service { 'procps':
            ensure    => running,
            enable    => true,
            require   => Package['procps'],
            subscribe => File['/etc/sysctl.conf'],
          }
        }
      }
    }
    default: {
      case $::operatingsystem {
        'Gentoo': {
          $packages = ['sys-process/procps', 'sys-apps/openrc']

          service { 'sysctl':
            ensure    => running,
            enable    => true,
            require   => [Package['sys-process/procps', 'sys-apps/openrc']],
            subscribe => File['/etc/sysctl.conf'],
          }
        }
      }
    }
  }

  package { $packages:
    ensure => installed,
  }
}
