# Describe VMs
#home = ENV['HOME']
MACHINES = {
  # VM name "kernel update"
  :"otus-bkps" => {
              # VM box
              :box_name => "generic/centos8",
             # :box_url => 'https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-Vagrant-8.2.2004-20200611.2.x86_64.vagrant-          virtualbox.box',
             # :box_download_checksum => '698b0d9c6c3f31a4fd1c655196a5f7fc224434112753ab6cb3218493a86202de',
              #:box_download_checksum_type => 'sha256',   
              # IP address
              :ip_addr => '192.168.100.60',     
              # VM CPU count
              :cpus => 1,
              # VM RAM size (Mb)
              :memory => 512,
              # forwarded ports
              :forwarded_port => [],
              :script_sh => "otus-bkps.sh" 
              
   }, 
  :"otus-bkpc" => {
              # VM box
              :box_name => "generic/centos8",
             # :box_url => 'https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-Vagrant-8.2.2004-20200611.2.x86_64.vagrant-          virtualbox.box',
             # :box_download_checksum => '698b0d9c6c3f31a4fd1c655196a5f7fc224434112753ab6cb3218493a86202de',
              #:box_download_checksum_type => 'sha256',   
              # IP address
              :ip_addr => '192.168.100.61',     
              # VM CPU count
              :cpus => 1,
              # VM RAM size (Mb)
              :memory => 512,
              # forwarded ports
              :forwarded_port => [],
              :script_sh => "otus-bkpc.sh"     
              
   }
    
   
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Disable shared folders
    config.vm.synced_folder ".", "/vagrant", disabled: false
    # Apply VM config
    config.vm.define boxname do |box|
      # Set VM base box and hostname
      box.vm.box = boxconfig[:box_name]
      box.vm.host_name = boxname.to_s
      box.vm.provision "shell", path: boxconfig[:script_sh]
      #box.vm.box_url = boxconfig[:box_url]
      #box.vm.box_download_checksum = boxconfig[:box_download_checksum]
      #box.vm.box_download_checksum_type = boxconfig[:box_download_checksum_type]
      box.vm.network "private_network", ip: boxconfig[:ip_addr]
      # Port-forward config if present
      if boxconfig.key?(:forwarded_port)
        boxconfig[:forwarded_port].each do |port|
          box.vm.network "forwarded_port", port
        end
      end
      # VM resources config
      
      box.vm.provider "virtualbox" do |v|
        # Set VM RAM size and CPU count
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
        v.name = boxname.to_s
      end
      
    end
  end
end
