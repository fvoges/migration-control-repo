class migration::cleanup {
  file { '/etc/puppetlabs/facter/facts.d/migration_stage.txt':
    ensure  => absent,
  }
}
