# Домашнее задание по теме "Резервное копирование"

Поднимаем стенд, затем производим настройку поднятых машин через ansible. Структура проекта следующая:  

**data** - каталог с необходимыми файлами для настройки системы  
**inventories** - каталог с инвентори файлом (hosts.yml)  
**playbooks** - каталог с плейбуком (borg-backup.yml)  
ansible.cfg - файл с настройками ansible  
Vagrantfile  
readme.md  


Резервное копирование производим через borgbackup. Для создания ssh соединения между клиентом  
(otus-bkpc) и сервером (otus-bkps) используются заранее сгенерированные ключи (для упрощения).  
Также для упрощения работа производится от пользователя root на клиенте и сервере.  



Далее идет описание плэйбука borg-backup.yml, который настраивает поднятые вагрантом машины.  


#### Кофигурируем сервер

    - name: CONFIG BACKUP SERVER  
      hosts: otus-bkps  
      become: true  
    
      tasks:  
  


Добавляем в /etc/hosts клиентскую машину  
  
    - name: SERVER | CHANGE HOSTS FILE  
      lineinfile:   
        path: /etc/hosts  
        line: 192.168.100.61 otus-bkpc  
        state: present  
        
Настраиваем подключение по ssh между сервером и клиентом  
        
    - name: SERVER | CREATE DIR /root/.ssh    
      file:
        path: /root/.ssh
        state: directory
       
    - name: SERVER | COPY PRIVATE SSH KEY
      copy:
        src: ../data/server/id_rsa
        dest: /root/.ssh
        mode: '600'
      
    - name: SERVER | COPY PUB SSH KEY 
      copy:
        src: ../data/server/id_rsa.pub
        dest: /root/.ssh
        mode: '644'
    
    - name: SERVER | COPY PRIVATE SERVER KEY 
      copy:
        src: ../data/server/ssh_host_rsa_key
        dest: /etc/ssh
        mode: '640'
        
    - name: SERVER | COPY PUBLIC SERVER KEY   
      copy:
        src: ../data/server/ssh_host_rsa_key.pub
        dest: /etc/ssh
        mode: '644'
        
    - name: SERVER | CREATE /root/.ssh/authorized_keys  
      file:
        path: /root/.ssh/authorized_keys
        state: touch
        
    - name: SERVER | COPY THE KEYS TO FILES 
      shell: cat /vagrant/data/client/id_rsa.pub > /root/.ssh/authorized_keys ; cat /vagrant/data/known_hosts_s > /root/.ssh/known_hosts
      

Устанавливаем на сервере borgbackup  

      - name: SERVER | INSTALL BORGBACKUP
      yum:
        name: borgbackup
        state: present

Создаем директорию для создания бэкапов  

    - name: SERVER | CREATE DIR /var/backup   
      file:
        path: /var/backup
        state: directory 
        

Создаем файловую систему на диске для бэкапов  

    - name: SERVER | MAKE FS ON /dev/sdb
      filesystem:
        dev: /dev/sdb
        fstype: ext4
        

Копируем подготовленный файл юнита монтирования диска для бэкапов в /etc/systemd/system/  

    - name: SERVER | COPY var-backup.mount
      copy:
        src: ../data/server/var-backup.mount
        dest: /etc/systemd/system/
        
Перезапускаем демоны, активируем и запускаем var-backup.mount  

    - name: SERVER | DAEMON RELOAD
      systemd:
        daemon-reload: yes
        
    - name: SERVER | ENABLE var-backup.mount 
      systemd:
        name: var-backup.mount
        enabled: yes
        
    - name: SERVER | START var-backup.mount 
      systemd:
        name: var-backup.mount
        state: started    
      
      
#### Кофигурируем клиентскую машину (otus-bkpc)
      
    - name: CONFIG BACKUP CLIENT  
      hosts: otus-bkpc
      become: true
    
      tasks:


Добавляем в /etc/hosts серверную машину  

    - name: CLIENT | CHANGE HOSTS FILE
      lineinfile: 
        path: /etc/hosts
        line: 192.168.100.60 otus-bkps
        state: present

Настраиваем подключение по ssh между клиентом и сервером  
        
    - name: CLIENT | CREATE DIR /root/.ssh    
      file:
        path: /root/.ssh
        state: directory
       
    - name: CLIENT | COPY PRIVATE SSH KEY
      copy:
        src: ../data/client/id_rsa
        dest: /root/.ssh
        mode: '600'
      
    - name: CLIENT | COPY PUB SSH KEY 
      copy:
        src: ../data/client/id_rsa.pub
        dest: /root/.ssh
        mode: '644'
    
    - name: CLIENT | COPY PRIVATE SERVER KEY  
      copy:
        src: ../data/client/ssh_host_rsa_key
        dest: /etc/ssh
        mode: '640'
        
    - name: CLIENT | COPY PUBLIC SERVER KEY  
      copy:
        src: ../data/client/ssh_host_rsa_key.pub
        dest: /etc/ssh
        mode: '644'
        
    - name: CLIENT | CREATE /root/.ssh/authorized_keys  
      file:
        path: /root/.ssh/authorized_keys
        state: touch
        
    - name: CLIENT | COPY THE KEYS TO FILES 
      shell: cat /vagrant/data/server/id_rsa.pub > /root/.ssh/authorized_keys ; cat /vagrant/data/known_hosts_c > /root/.ssh/known_hosts      


Устанавливаем на клиенте borgbackup  
      
    - name: CLIENT | INSTALL BORGBACKUP
      yum:
        name: borgbackup
        state: present
 
Копируем подготовленный заранее скрипт резервного копирования в папку /root. Описание скрипта приведено ниже.   

    - name: CLIENT | COPY script-backup.sh
      copy:
        src: ../data/client/script-backup.sh
        dest: /root
        
Инициализируем репозиторий для бэкапов с защитой по ключу  
        
    - name: CLIENT | 
      shell: BORG_NEW_PASSPHRASE='' borg init --encryption=keyfile otus-bkps:/var/backup/otus-bkpc-etc
      
Копируем созданный во время инициализации ключевой файл на хостовую машину для копирования его на сервер.  
      
    - name: CLIENT | GET BORG REPOSITORY KEY
      fetch: 
        src: /root/.config/borg/keys/otus_bkps__var_backup_otus_bkpc_etc
        dest: ../

Копируем подготовленный файл юнита для запуска скрипта бэкапа в /etc/systemd/system/  

    - name: CLIENT | COPY borgback.service
      copy:
        src: ../data/client/borgback.service
        dest: /etc/systemd/system/ 
        
Копируем подготовленный файл юнита таймера для запуска borgback.service в /etc/systemd/system/  

    - name: CLIENT | COPY borgback.timer
      copy:
        src: ../data/client/borgback.timer
        dest: /etc/systemd/system/  
        
Создаем директорию для логов бэкапов
        
    - name: CLIENT | CREATE /var/log/borgback  
      file:
        path: /var/log/borgback
        state: touch 
    
Перезапускаем демоны, активируем и запускаем borgback.service и borgback.timer.  
        
    - name: CLIENT | DAEMON RELOAD
      systemd:
        daemon-reload: yes 
        
    - name: CLIENT | ENABLE borgback.service 
      systemd:
        name: borgback.service
        enabled: yes
        
    - name: CLIENT | START borgback.service 
      systemd:
        name: borgback.service
        state: started 
        
    - name: CLIENT | ENABLE borgback.timer 
      systemd:
        name: borgback.timer
        enabled: yes
        
    - name: CLIENT | START borgback.timer 
      systemd:
        name: borgback.timer
        state: started 
        
#### Дополнительно конфигурируем сервер        
        
        
    - name: CONFIG 2 BACKUP SERVER  
      hosts: otus-bkps
      become: true
    
      tasks:

Копируем ключевой файл репозитория на сервер в /root/.congig/borg/keys, чтобы работать с репозиторием на сервере  
  
    - name: SERVER | COPY BORG REPOSITORY KEY FROM CLIENT
      copy: 
        src: ../otus-bkpc/root/.config/borg/keys/otus_bkps__var_backup_otus_bkpc_etc
        dest: /root/.config/borg/keys/
      tags:
        - last-step

## Листинг прилагаемых к ansible файлов

#### data/client/script-backup.sh

    #!/bin/bash  
  
#Задаем имя сервера бэкапов  
  
    BORG_SERVER=otus-bkps  
  
#Задаем тип бэкапа, в нашем случае будет etc  
  
    TYPE_OF_BACKUP=etc  
  
#Задаем путь к репозиторию  
  
    REPOSITORY="${BORG_SERVER}:/var/backup/$(hostname)-${TYPE_OF_BACKUP}"  
  
#Пишем команду для создания бэкапа  
  
    borg create --list -v --stats \  
    $REPOSITORY::"etc-{now:%Y-%m-%d-%H-%M}" \  
    /etc  
  
#Задаем интервалы хранения бэкапов  
  
    borg prune -v --list \  
       --keep-within=7d \  
       --keep-weekly=4 \  
    $REPOSITORY  
    
    
#### data/client/borgback.service

    [Unit]  
    Description=BorgBackup Script  
  
    [Service]  
    ExecStart=/bin/bash /root/script-backup.sh  
    StandardOutput=append:/var/log/borgback  
    StandardError=append:/var/log/borgback  
  
    [Install]  
    WantedBy=multi-user.target  

#### data/client/borgback.timer

    [Unit]  
    Description=Timer For BorgBack service  
  
    [Timer]  
    OnUnitActiveSec=5m  
  
    [Install]  
    WantedBy=multi-user.target  

#### data/server/var-backup.mount

    [Unit]  
    Description=var-backup mount  
  
    [Mount]  
    What=/dev/sdb  
    Where=/var/backup  
    Type=ext4  
    Options=defaults  
  
    [Install]  
    WantedBy=multi-user.target  


## Описание работы стенда

 1. Запускаем vagrant, после поднятия машин запускам плэйбук **playbooks/borg-backup.yml**  
              
              ansible-playbook playbooks/borg-backup.yml  
              
 2. Проверяем создание бэкапов. На клиенте запускаем:
       
        # borg list otus-bkps:/var/backup/otus-bkpc-etc  
 
        etc-2021-07-20-18-05                 Tue, 2021-07-20 18:05:32 [ccc5bae3a160363d40d1bc8d4787bec7e15f275805cfa02cd4e4d33280317e10]  
        etc-2021-07-20-18-10                 Tue, 2021-07-20 18:10:32 [ed9f3d24b56e3bc928ec8c6ef5336ad67f2ecd4ffa827cbd301bbc4a363eb091]  
        etc-2021-07-20-18-16                 Tue, 2021-07-20 18:16:32 [a1f2d61790334f836cd7d78acd92d54067e173cd8a3dbf98d15ef75244793a0c]  
        etc-2021-07-20-18-22                 Tue, 2021-07-20 18:22:05 [45b733f98dad7e691a24ec68fa20b1fa33cf504f579e99c8c5b4e67b2b1a4605]  
        etc-2021-07-20-18-27                 Tue, 2021-07-20 18:27:32 [571c1f5b6b4d6466fa174c711746d52d8342d0f05585ca5d22d72a8e1cd2b22b]  
   
   
 3. Смотрим логи бэкапов:  
 
        #cat/var/log/borgback   

        ------------------------------------------------------------------------------  
        Archive name: etc-2021-07-20-18-27  
        Archive fingerprint: 571c1f5b6b4d6466fa174c711746d52d8342d0f05585ca5d22d72a8e1cd2b22b  
        Time (start): Tue, 2021-07-20 18:27:32  
        Time (end):   Tue, 2021-07-20 18:27:32  
        Duration: 0.46 seconds  
        Number of files: 423  
        Utilization of max. archive size: 0%  
        ------------------------------------------------------------------------------    
                                     Original size      Compressed size    Deduplicated size    
        This archive:               21.63 MB              8.22 MB                508 B  
        All archives:              908.95 MB            345.44 MB              8.58 MB
  
                                Unique chunks         Total chunks  
        Chunk index:                     460                17495  
   

Бэкапы создаются с указанным нами интервалом, логи пишутся.  

## Восстановление папки /etc 

 1. Установлено ssh соединение хостовой машины с otus-bkpc.  
 2. Удаляем папку /etc на otus-bkpc.  
 3. Запускаем восстановление бэкапа с сервера, перейдя предварительно в /.  
 Получаем ошибку о недоступности borg на сервере.  
 
       #borg extract otus-bkps:/var/backup/otus-bkpc-etc::etc-2021-07-21-09-00 etc  
       Connection closed by remote host. Is borg working on the server?  

При этом клиент и сервер не могут соединиться по ssh.  

 4. Восстанавливаем папку etc на сервере:
 
        #borg extract otus-bkps:/var/backup/otus-bkpc-etc::etc-2021-07-21-09-00 etc
  
 5. Копируем ее в папку /root/backup, которая является общей для обоих виртуальных машин.  
 
        #cp ./etc ./backup/etc  
 
 6. На клиенте создаем папку /etc   
 
        #mkdir /etc   
 
  и копируем в нее из папки /root/backup необходимые для восстановления работы ssh файлы:  
  
     #cp -r /root/backup/etc/ssh /root/backup/etc/passwd /root/backup/etc/shadow /root/backup/etc/hosts /etc  
  
 7. Проверяем ssh соединение с сервером:  
 
        #ssh otus-bkps  
        Last login: Tue Jul 20 16:40:52 2021 from 192.168.100.61  
  
 Соединение успешно установилось. Выходим, попадаем снова на otus-bkpc.  
  
 8. Теперь восстанавливаем папку /etc, находясь в /  
  
        #borg extract otus-bkps:/var/backup/otus-bkpc-etc::etc-2021-07-21-09-00 etc   
  
 9. После восстановления проверяем, запустился ли снова процесс создания бэкапов.  
  
        #borg list otus-bkps:/var/backup/otus-bkpc-etc  
  
        etc-2021-07-21-09-00                 Wed, 2021-07-21 09:00:04 [3a4b1881a960c2e68a7851862a3475cf067d3c423637e9055f347441c038a692]  
        etc-2021-07-21-09-10                 Wed, 2021-07-21 09:10:42 [dd2fa87c1df36a019b6ddaa9e1dab062f5245f4a8a6c359a8c16b15aa0503c6c]  
        etc-2021-07-21-09-15                 Wed, 2021-07-21 09:15:42 [f1fdf058ebb8da89bd5a9a594e1652397f43ea1c3b7d919dfa19a4c06ecfcad9]  
  
Бэкапы создаются, папка /etc на клиенте восстановлена.
 
 

 






