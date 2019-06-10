# nwton_infra
nwton Infra repository

# HW4. Локальное окружение инженера. ChatOps и визуализация рабочих процессов.
  Командная работа с Git. Работа в GitHub.

Для установки travis через gem нужны ещё и dev библиотеки, иначе крэшится
``` text
sudo apt-get update
sudo apt-get upgrade
sudo apt install ruby rubygems ruby-dev
sudo gem install travis
```


# HW5. Знакомство с облачной инфраструктурой и облачными сервисами.

IP адреса виртуальных машин:
``` text
bastion external IP = 34.77.245.202
bastion internal IP = 10.132.0.2
someinternalhost IP = 10.132.0.3
```

Подключение к bastion с прокидыванием SSH Agent Forwarding
``` bash
ssh -A nwton@34.77.245.202
ssh 10.132.0.3
```

Подключение к someinternalhost через bastion в одну команду
``` bash
ssh -A -J nwton@34.77.245.202 nwton@10.132.0.3
```

Важно: ключ -J отсутствует в старых версиях клиента OpenSSH
- Ubuntu 16.04 - OpenSSH_7.2p2 - *отсутствует*
- Ubuntu 18.04 - OpenSSH_7.6p1 - присутствует
- Cygwin - OpenSSH_7.9p1 - присутствует

Для старого клиента без ключа -J можно использовать следующий фикс
``` bash
ssh -o ProxyCommand="ssh -W %h:%p firewall.example.org" server2.example.org
```

Много разных вариантов использования ProxyJump и ProxyCommand
- https://en.wikibooks.org/wiki/OpenSSH/Cookbook/Proxies_and_Jump_Hosts


Использование алиасов в ~/.ssh/config
``` text
# for otus
Host otus-bastion
    Hostname 34.77.245.202
    User nwton
    ForwardAgent yes

Host otus-internal
    Hostname 10.132.0.3
    ProxyJump nwton@34.77.245.202
    User nwton

```

После этого работают команды коннекта к внутреннему хосту в два этапа
``` bash
ssh otus-bastion
ssh 10.132.0.3
```
И коннект к внутреннему хосту в один этап
``` bash
ssh otus-internal
```

Дополнительный сервис для тех, кто не имеет своего домена
- http://xip.io/ - для обычного применения
- https://sslip.io/faq.html - имеет wildcard сертификат

Доступ к панели управления Pritunl
- https://34-77-245-202.sslip.io/

Параметры для автоматической проверки HW через Travis CI
``` text
bastion_IP = 34.77.245.202
someinternalhost_IP = 10.132.0.3
```

