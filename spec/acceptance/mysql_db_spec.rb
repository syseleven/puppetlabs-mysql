require 'spec_helper_acceptance'

describe 'mysql::db define' do
  describe 'creating a database' do
    let(:pp) do
      <<-MANIFEST
        class { 'mysql::server': 
          root_password => 'password',
          service_enabled => 'true',
          service_manage  => 'true', 
        }
        mysql::db { 'spec1':
          user            => 'root1',
          password        => 'password',
        }
      MANIFEST
    end

    it 'behaves idempotently' do
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'Checking exit code and stdout' do
      results = run_shell("mysql -e 'show databases;'")
      expect(results.first['result']['exit_code']).to eq 0
      expect(results.first['result']['stdout']).to match %r{^spec1$}
    end
  end

  describe 'creating a database with post-sql' do
    let(:pp) do
      <<-MANIFEST
        class { 'mysql::server': override_options => { 'root_password' => 'password' } }
        file { '/tmp/spec.sql':
          ensure  => file,
          content => 'CREATE TABLE table1 (id int);',
          before  => Mysql::Db['spec2'],
        }
        mysql::db { 'spec2':
          user     => 'root1',
          password => 'password',
          sql      => '/tmp/spec.sql',
        }
      MANIFEST
    end

    it 'behaves idempotently' do
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'Checking exit code and stdout' do
      results = run_shell("mysql -e 'show tables;' spec2")
      expect(results.first['result']['exit_code']).to eq 0
      expect(results.first['result']['stdout']).to match %r{^table1$}
    end
  end

  describe 'creating a database with dbname parameter' do
    let(:check_command) { ' | grep realdb' }
    let(:pp) do
      <<-MANIFEST
        class { 'mysql::server': override_options => { 'root_password' => 'password' } }
        mysql::db { 'spec1':
          user     => 'root1',
          password => 'password',
          dbname   => 'realdb',
        }
      MANIFEST
    end

    it 'behaves idempotently' do
      apply_manifest(pp, catch_failures: true)
      apply_manifest(pp, catch_changes: true)
    end

    it 'Checking exit code and stdout' do
      results = run_shell("mysql -e 'show databases;'")
      expect(results.first['result']['exit_code']).to eq 0
      expect(results.first['result']['stdout']).to match %r{^realdb$}
    end
  end
end
