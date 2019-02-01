namespace :rpm do
  signing_dir = "out/rpm"
  rpm_source_dir = 'rpm'
  gpg_signing_id = '0xD8843F288816C449'

  desc "sign rpm binaries"
  task :sign => ['gpg:setup'] do
    rm_rf signing_dir
    mkdir_p signing_dir
    Dir["#{rpm_source_dir}/*.rpm"].each do |f|
      cp f, "#{signing_dir}"
    end

    cd signing_dir do
      Dir["#{signing_dir}/*.rpm"].each do |f|
        # wrap with `setsid ... </dev/null` to avoid attaching to TTY. This otherwise causes a password prompt
        sh(%Q{setsid sh -c "rpm --addsign --define '_gpg_name #{gpg_signing_id}' '#{f}' < /dev/null"})
      end
      sh("gpg --armor --output GPG-KEY-GOCD-#{Process.pid} --export #{gpg_signing_id}")
      sh("sudo rpm --import GPG-KEY-GOCD-#{Process.pid}")
      rm "GPG-KEY-GOCD-#{Process.pid}"
      Dir["#{signing_dir}/*.rpm"].each do |f|
        sh("rpm --checksig '#{f}'")
      end
    end

  end
end