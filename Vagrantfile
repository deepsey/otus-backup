# Describe VMs
#home = ENV['HOME']
MACHINES = {
  # VM name "kernel update"
:"otus-bkps" => {
              # VM box
              :box_name => "generic/centos8",
              :ip_addr => '192.168.100.60',     
              # VM CPU count
              :cpus => 1,
              # VM RAM size (Mb)
              :memory => 512,
              # forwarded ports
              :ssh_port => 2260,
              :disks => {
              :sata1 => {
              :dfile => './disk1_backup.vdi',
              :size => 2048,
              :port => 1
              }
              }          
                           
   },
 :"otus-bkpc" => {
              # VM box
              :box_name => "generic/centos8",
              # IP address
              :ip_addr => '192.168.100.61',     
              # VM CPU count
              :cpus => 1,
              # VM RAM size (Mb)
              :memory => 512,
              # forwarded ports
              :ssh_port => 2261,
              :disks => {
              :sata1 => {
              :dfile => './disk2_backup.vdi',
              :size => 2048,
              :port => 1
              }
              }                   
              
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
      #box.vm.provision "shell", path: boxconfig[:script_sh]
      #box.vm.box_url = boxconfig[:box_url]
      #box.vm.box_download_checksum = boxconfig[:box_download_checksum]
      #box.vm.box_download_checksum_type = boxconfig[:box_download_checksum_type]
      box.vm.network "private_network", ip: boxconfig[:ip_addr]
      # Port-forward config if present
      box.vm.network "forwarded_port", id: "ssh", guest: 22, host: boxconfig[:ssh_port]
      box.vm.synced_folder "backup", "/root/backup", type: "virtualbox"
   
      # VM resources config
      
      box.vm.provider "virtualbox" do |v|
        # Set VM RAM size and CPU count
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
        v.name = boxname.to_s
        needsController = false
        boxconfig[:disks].each do |dname, dconf|
			  unless File.exist?(dconf[:dfile])
				v.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                needsController =  true
              end
	    end
        if needsController == true
                     v.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                     boxconfig[:disks].each do |dname, dconf|
                         v.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                     end
        end
      end
    end       
    
  end
  
         
end


