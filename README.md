# nwton_infra
nwton Infra repository

[![Build Status](https://travis-ci.com/otus-devops-2019-02/nwton_infra.svg?branch=master)](https://travis-ci.com/otus-devops-2019-02/nwton_infra)


# HW4. Локальное окружение инженера. ChatOps и визуализация рабочих процессов.
  Командная работа с Git. Работа в GitHub.

Для установки travis через gem нужны ещё и dev библиотеки, иначе крэшится
``` text
sudo apt-get update
sudo apt-get upgrade
sudo apt install ruby rubygems ruby-dev
sudo gem install travis
```

Дальше устанавливаем пакет, логинимся и добавляем шифрованную
ссылку для доступа в чат
``` text
gem install travis
travis login --com
travis encrypt "devops-team-otus:<ваш_токен>#<имя_вашего_канала>" \
       --add notifications.slack.rooms --com

wget https://bit.ly/otus-travis-yaml-2019-02 -O .travis.yml
wget http://bit.ly/otus-pr-template -O .github/PULL_REQUEST_TEMPLATE.md
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


# HW6. Основные сервисы Google Cloud Platform (GCP).

Установка GCP SDK
- https://cloud.google.com/sdk/docs/
``` text
apt-get install apt-transport-https ca-certificates

echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

sudo apt-get update && sudo apt-get install google-cloud-sdk

gcloud init

gcloud info
gcloud auth list
```

Параметры для автоматической проверки HW через Travis CI
``` text
testapp_IP = 34.77.57.229
testapp_port = 9292
```

Быстрый запуск готового инстанса с сервисом PUMA из express42/reddit
с использованием [startup script](https://cloud.google.com/compute/docs/startupscript):
``` bash
$ gcloud compute instances create reddit-app-autofile \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --metadata-from-file startup-script=puma-go.sh \
  --restart-on-failure
```

Использование URL на github вместо локального файла
``` bash
$ gcloud compute instances create reddit-app-autourl \
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --metadata=startup-script-url=https://raw.githubusercontent.com/otus-devops-2019-02/nwton_infra/cloud-testapp/puma-go.sh \
  --restart-on-failure
```

Создание правила фаервола для работы приложения PUMA
``` bash
$ gcloud compute firewall-rules create default-puma-server-auto \
  --direction=INGRESS --priority=1000 \
  --network=default --action=ALLOW \
  --rules=tcp:9292 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=puma-server
```


# HW7. Модели управления инфраструктурой.

Для WSL нормально работает packer версии linux 64-bit
- https://www.packer.io/downloads.html
- https://releases.hashicorp.com/packer/1.4.1/packer_1.4.1_linux_amd64.zip
- https://releases.hashicorp.com/packer/
- https://releases.hashicorp.com/packer/1.2.4/packer_1.2.4_linux_amd64.zip
Для совместимости с тестами ДЗ - использовал packer 1.2.4

Установка ADC
- `gcloud auth application-default login`

Примечание: в JSON для packer нельзя в массивах заканчивать список элементов
запятой, после последнего элемента запятая должна обязательно отсутствовать,
иначе packer validate ругается.
Пути внутри JSON отсчитываются относительно текущего рабочего каталога.

Полезные опции set для скриптов деплоя на bash (сразу после shebang)
``` text
-e вызывает немедленный выход из скрипта, если выходное состояние команды не нулевое
-u выводит сообщение об ошибке и завершает скрипт, при попытке использования не инициализированной переменной
-v выводит в стандартный поток ошибок (stderr) выполняемые команды/программы
```

Прочие опции: help set и https://habr.com/ru/post/221273/

Создаём образ с ruby и mongo, а приложение деплоим через startup-script,
для постоянной работы ВМ надо заменить preemptible на restart-on-failure

При этом для сборки образа можно использовать example файл и
переопределить некоторые переменные в командной строке, если прочие
дефолтные значения нас устраивают.
``` bash
$ cd packer && packer build \
    -var-file=variables.json \
    ubuntu16.json

$ cd packer && packer build \
    -var-file=variables.json.example \
    -var 'my_project_id=infra-243222' \
    ubuntu16.json

==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: reddit-base-1560357455

$ gcloud compute instances create reddit-app-packer \
  --boot-disk-size=10GB \
  --image=reddit-base-1560357455 \
  --machine-type=g1-small \
  --tags puma-server \
  --preemptible \
  --metadata-from-file startup-script=config-scripts/deploy.sh
```

Примечание по packer:
- в Travis CI используется версия 1.2.4, в которой нет опции timeouts
- в версии 1.4.1 нужно использовать timeouts, иначе билд обрывается,
  т.к. скрипты сборки выполняются очень долго из-за apt update

Примечание:
- tags применяет метки только при сборке образа, при запуске ВМ
  нужно добавлять тэги через gcloud
- https://www.packer.io/docs/builders/googlecompute.html
- https://cloud.google.com/vpc/docs/add-remove-network-tags

Быстрый запуск из самого последнего образа в семействе,
с дефолтными параметрами ВМ, запечеными в образ :
``` bash
$ gcloud compute instances create reddit-app-pack-base \
  --image-family reddit-base \
  --tags puma-server \
  --preemptible \
  --metadata-from-file startup-script=config-scripts/deploy.sh

$ gcloud compute instances create reddit-app-pack-full \
  --image-family reddit-full \
  --tags puma-server \
  --preemptible
```


# HW8. Практика Infrastructure as a Code (IaC).

Для WSL нормально работает terraform версии linux 64-bit
- https://www.terraform.io/downloads.html
- https://releases.hashicorp.com/terraform/0.12.3/terraform_0.12.3_linux_amd64.zip
- https://releases.hashicorp.com/terraform/
- https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip
- https://releases.hashicorp.com/terraform/0.11.11/terraform_0.11.11_linux_amd64.zip
Для совместимости с тестами ДЗ - использовал terraform 0.11.11

Примечание: в штатных образах Ubuntu уже установлен git,
дополнительно устанавливать не нужно.

Если штатная версия не устраивает (например, нужно использовать
дополнительно includeif.gitdir или что-то подобное), то можно
обновиться до последнего стабильного релиза:
``` text
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-cache policy git
sudo apt-get install git
```

## Примечания по terraform
terraform fmt - использует табуляцию в 2 пробела

Неоходимо проверять, какие переменные возвращаются, со временем
в google provider всё меняется:
- assigned_nat_ip - как указано в ДЗ, но такой переменной сейчас нет
- nat_ip - сейчас содержит внешний IP адрес инстанса

На уровне google_compute_instance для connection можно указать
файл приватного ключа только БЕЗ passphrase, что грустно.

Нельзя просто скопировать один файл с расширением .tf в файл с
другим именем в этом же каталоге, т.к. terraform обрабатывает
*ВСЕ* файлы в каталоге и легко получить ошибку о совпадающем
ресурсе или что-то подобное.

Внутри value можно использовать двойные кавычки несколько раз
без каких-либо проблем, не нужно метаться между одинарными
и двойными или ескейпить. Необычно, но удобно.

## Дополнительные задания

### Эксперименты с SSH
При экспериментах с SSH легко получить бан, для проверки нужно
зайти через веб-консоль и проверить:
``` text
sudo iptables -L --line-numbers
sudo iptables -D sshguard 1
```

### Примечания по формату ключей в GCP

Если ключ в файле не соответствует требуемому формату:
``` text
<protocol> <key-blob> <username@example.com>
<protocol> <key-blob> google-ssh {"userName":"<username@example.com>","expireOn":"<date>"}
```
например, отсутствует комментарий ключа в конце строки,
то при попытке отредактировать инстанс можно увидеть соообщение
Недопустимый ключ. Требуемый формат ...

При этом если задан только один ключ, то он нормально пробрасывается
внутрь инстанса в файл authorized_keys.
Но если задано несколько ключей, то в инстанс не
пробрасывается ни один.

### Примечания по добавлению нескольких ключей SSH

Перед именем пользователя не должно быть пробелов, иначе в
веб-интерфейсе всё выглядит хорошо, но внутрь инстанса
добавляется только первый пользователь со своим ключём, но
остальные пользователи не добавляются.

Для этого нужно использовать слитное написание, либо конструкцию
с использованием EOF или ескапированный символ n

Вот так работать не будет:
``` text
ssh-keys = "appuser:${file(var.public_key_path)} appuser1:${file(var.public_key_path)}"
ssh-keys = <<EOF
    appuser:${file(var.public_key_path)}
    appuser1:${file(var.public_key_path)}
EOF
```

Правильные варианты:
``` text
ssh-keys = "appuser:${file(var.public_key_path)}appuser1:${file(var.public_key_path)}"
ssh-keys = "appuser:${file(var.public_key_path)}\nappuser1:${file(var.public_key_path)}"
ssh-keys = <<EOF
appuser:${file(var.public_key_path)}
appuser1:${file(var.public_key_path)}
EOF
```

Документация по синтаксису текстовых переменных:
- https://www.terraform.io/docs/configuration-0-11/syntax.html
- https://www.terraform.io/docs/configuration-0-11/interpolation.html

### Вопросы по дополнительным заданиям с одной звездочкой

При использовании списка ключей внутри terraform - все
добавленные вручную через UI ключи будут удалены при следующем
выполнении terraform apply.

Внутри инстанса лишние ключи из authorized_keys удалённых пользователей
будут сразу же удалены (но сами пользователи могут остаться на месте).
При добавлении ключа - внутри инстанса сразу же добавляется пользователь.
- google_compute_project_metadata_item - проектные ключи
- google_compute_instance - дополнительные ключи инстанса

### Вопросы по дополнительным заданиям с двумя звездочками

В текущем варианте LoadBalancer есть проблема с тем, что на
каждом инстансе своя база данных и они не синхронизируются.

Дополнительно: в текущем варианте остановленные вручную инстансы
автоматически при прогоне terraform не запускаются.

Добавление инстансов методом copy-paste приводит к дублированию
кода и возможности пропустить мелкие изменения, т.к. если мы меняем
потом какой-то инстанс, то в длинной портянке можем пропустить
какой-то другой.

Для использования параметра ресурса count необходимо заранее
планировать возможность создания нескольких похожих инстансов,
т.к. если создать сначала инстанс с одним именем, а потом
добавить в его имя параметр count, то terraform apply легко
сначала удалит старый инстанс, а потом создаст новый пул
из нескольких инстансов.
В случае, если это была база данных или что-то похожее, то
может быть очень неловкая ситуация.

Запуск с дополнительными параметрами на 2 инстанса:
``` text
terraform apply -var 'apps_count=2'
```

Полезная документация:
- https://cloud.google.com/load-balancing/docs/https/
- https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts
- https://www.terraform.io/docs/providers/google/r/compute_http_health_check.html
- https://www.terraform.io/docs/providers/google/r/compute_health_check.html
- https://www.terraform.io/docs/providers/google/r/compute_target_pool.html


# HW9. Принципы организации инфраструктурного кода и работа над инфраструктурой в команде на примере Terraform.

``` bash
cd packer
packer build -var-file=variables.json app.json
packer build -var-file=variables.json db.json
```

При добавлении в main.tf дополнительного модуля при запуске
terraform validate предлается запускать terraform init,
но это неверно, нужно использовать terraform get.

При переносе ресурсов в модули - будет происходить удаление
старых ресурсов и создание новых с другим именем.

При подключении модуля указывается, какие переменные из основной
конфигурации следует передать ему (можно оставить то же самое
имя переменных, а можно и изменить, но это разные переменные).

Сейчас prod и stage окружения в terraform пересекаются, нельзя
использовать их оба одновременно. При этом дополнительным
введением переменной environment со значением имени окружения
в качестве суффикса имён ресурсов проблему не решить.
Например, созданием ещё одного правила доступа к SSH со всех
IP адресов для staging окружения мы одновременно откроем и
для product окружения. Необходимо делать отдельные ресурсы
сети для разных окружений и навешивать тэги правильно.

## Запуск полностью с нуля

Запуск чистом каталоге (с импортом части ресурсов из GCP и
пересозданием других, если что-то пошло не так):
``` text
rm -rf .terraform/
rm terraform.tfstate

terraform get
terraform init
terraform refresh
terraform plan

terraform import module.vpc.google_compute_firewall.firewall_ssh default-allow-ssh
terraform import module.app.google_compute_firewall.firewall_puma allow-puma-default
terraform import module.db.google_compute_firewall.firewall_mongo allow-mongo-default
terraform import module.app.google_compute_address.app_ip reddit-app-ip

terraform taint module.db.google_compute_instance.db
terraform taint module.app.google_compute_instance.app

terraform apply
```

## Переход на remote backend

При переходе с файла на remote backend - данные из
terraform.tfstate перегружаются в удалённое хранилище и
больше локально не требуются
- https://www.terraform.io/docs/backends/types/gcs.html
``` text
$ terraform plan
Backend reinitialization required. Please run "terraform init".
Reason: Initial configuration of the requested backend "gcs"
...

$ terraform init
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "gcs" backend. An existing non-empty state already exists in
  the new backend. The two states have been saved to temporary files that will be
  removed after responding to this query.
```


Одновременный запуск нескольких terraform блокируется
с сообщением об ошибке и наличием state lock.
``` text
Terraform acquires a state lock to protect the state from being written
by multiple users at the same time. Please resolve the issue above and try
again. For most commands, you can disable locking with the "-lock=false"
flag, but this is not recommended.
```

## Запуск рабочего места с нуля и remote backend

При использовании переменных при описании backend
сталкиваемся с проблемой начальной инициализации
рабочего каталога с нуля
- https://github.com/hashicorp/terraform/issues/13022
``` text
  backend "gcs" {
    bucket  = "tf-state-${var.project}"
    prefix  = "${var.apps_env}"
  }
```

И можно инициализировать примерно так, тогда будет создан
файл .terraform/terraform.tfstate и всё будет ок:
``` text
terraform init \
     -backend-config "bucket=tf-state-infra-12345" \
     -backend-config "prefix=prod"
```


# HW10. Управление конфигурацией.

Примечание для WSL и не только: надо внимательно смотреть
на warnings в ansible, иногда там находится полезная информация.
После чего быстро фиксим одним из трёх вариантов:
``` text
$ ansible-config dump --only-changed
[WARNING] Ansible is being run in a world writable directory
(/home/...), ignoring it as an ansible.cfg source.

$ chmod 755 .
$ export ANSIBLE_CONFIG=./ansible.cfg
$ ln -s /mnt/c/..._infra/ansible/ansible.cfg ~/.ansible.cfg
```

Полный фикс WSL:
- https://docs.ansible.com/ansible/devel/reference_appendices/config.html#cfg-in-world-writable-dir
- https://devblogs.microsoft.com/commandline/chmod-chown-wsl-improvements/
- https://docs.microsoft.com/en-us/windows/wsl/wsl-config
- https://github.com/ansible/ansible/issues/42388

## Основное задание
Запуск (git clone ...) через модуль shell - не является идемпотентным.
При повторном запуске - ломается из-за уже существующего каталога.

Результат выполнения модуля git в ansible (через playbook или вручную) - идемпотентный.
При повторном запуске ничего не ломается.

При запуске через playbook выводится краткая информация
по хостам, где проходил запуск ansible и результат что
были проведены изменения отображается в поле *changed*
(при запуске модуля git - выдается json, отображаемый разным
цветом в зависимости от наличия изменений)


Запуск приложения:
``` text
cd terraform/stage && terraform apply
cd -
cd ansible
vi inventory

ansible app -m git -a 'repo=https://github.com/express42/reddit.git dest=/home/appuser/reddit'

или

ansible-playbook clone.yml
```

## Дополнительное задание
Преобразуем обычный yaml в статический json
``` text
sudo apt install jq
sudo -H pip install yq

cd ansible && cat inventory.yml | yq . > inventory_static.json
```

Документация по dynamic inventory
- https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html
- https://docs.ansible.com/ansible/devel/plugins/inventory.html
- https://docs.ansible.com/ansible/devel/plugins/inventory/script.html
- https://medium.com/@Nklya/динамическое-инвентори-в-ansible-9ee880d540d6

Основные отличия dynamic inventory json от обычного
преобразованного из yaml:
- В группе хостов содержатся ТОЛЬКО hostnames/IP addresses.
  Вложенные группы не поддерживаются. И поэтому нельзя обращаться
  к каждому серверу по отдельности (а если не нужны vars, то можно сбросить
  уровень hosts и сразу передать в группу список).
- Необходимо наличие секции meta и/или поддержка в скрипте
  опции --host для передачи дополнительных параметров для
  хостов (отсутствует в обычном static).
  В моём скрипте при запросе опций для любого хоста отдаётся
  пустой JSON список, иначе - содержимое JSON.

Для добавления поддержки dynamic inventory необходимо установить в ansible.cfg
для опции enable_plugins значение script (или добавить несколько значений),
по умолчанию в некоторых поставках ansible это уже включено.
И после этого заменить опцию inventory с файла на скрипт, или же указывать
в качестве опции при запуске ansible.

Добавлены скрипты:
- ansible/my_tf2dyn.sh - получаем IP для app и db из terraform и вставляем в
  простейший шаблон JSON (ожидаем получить только один IP для каждой группы,
  если будет несколько IP в каждой группе или ни одного - будет создан
  неправильный JSON) и сохраняем как inventory.json
- ansible/my_inv.sh - отображаем inventory.json для опции --list или
  пустой список для опции --host
- оба скрипта можно объединить в один и обойтись без промежуточного файла


Запуск приложения:
``` text
cd terraform/stage && terraform apply
cd -
cd ansible
./my_tf2dyn.sh
ansible all -m ping -i ./my_inv.sh
ansible-playbook clone.yml -i ./my_inv.sh
```


# HW11. Продолжение знакомства с Ansible: templates, handlers, dynamic inventory, vault, tags.

В конфиге ansible установлена опция dynamic inventory на базе json
из вывода terrform из предыдущего ДЗ, поэтому перед выполнением
команд ansible из ДЗ просто собираем стенд (и разбираем потом):
``` text
cd terraform/stage && terraform apply
cd ../../ansible && ./my_tf2dyn.sh
...
cd terraform/stage && terraform destroy
```

Примечание: добавление новых output переменных в terraform
требует дополнительного прогона plan + apply.

## Основное задание

Деплой из одного плейбука с одним сценарием по хостам и тэгам
``` text
ansible-playbook reddit_app_one_play.yml --limit db
ansible-playbook reddit_app_one_play.yml --limit app --tags app-tag
ansible-playbook reddit_app_one_play.yml --limit app --tags deploy-tag
```

Деплой из одного плейбука с разными сценариями по тэгам
``` text
ansible-playbook reddit_app_multiple_plays.yml --tags db-tag
ansible-playbook reddit_app_multiple_plays.yml --tags app-tag
ansible-playbook reddit_app_multiple_plays.yml --tags deploy-tag
```

## Дополнительное задание

### Использование скрипта gce.py

Документация:
- https://cloud.google.com/iam/docs/creating-managing-service-account-keys
- https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html
- https://docs.ansible.com/ansible/2.5/scenario_guides/guide_gce.html

Использование *gce.py* является очень устаревшим вариантом и ограниченным
по возможностями из-за JSON (как рассматривалось в предыдущем ДЗ), для инстансов
передаётся только IP адрес и группировка только по тэгам.
Цитата: _All of the created instances in GCE are grouped by tag.
Since this is a cloud, it’s probably best to ignore hostnames and
just focus on group management._

Настройка усложнена, необходимо иметь много лишних файлов.

### Использование плагина gcp_compute

Документация:
- https://cloud.google.com/iam/docs/creating-managing-service-account-keys
- https://docs.ansible.com/ansible/latest/plugins/inventory.html
- https://docs.ansible.com/ansible/latest/scenario_guides/guide_gce.html
- https://docs.ansible.com/ansible/latest/plugins/inventory/gcp_compute.html
- http://matthieure.me/2018/12/31/ansible_inventory_plugin.html

Стильно, модно, молодёжно. Рекомендуется в свежей документации.

Просто и логично настраивается:
- получаем json service account key (и назначаем роль Наблюдателя)
  * https://console.developers.google.com/iam-admin/serviceaccounts
- добавляем библиотеки через pip (если ещё не установлены)
- создаём inventory.gcp.yml файл, где описываем служебные параметры
  (проект, регион, путь к ключу) и параметры навешивания
  групп/тэгов для инстансов исходя из их региона и hostname.
- позволяет создавать ресурсы GCP в ansible tasks

Дополнительно можно миксовать статический и динамический
inventory (сложить несколько файлов в каталог и указывать его)

Распределение хостов по группам - как на основе hostname, так и
через тэги, навешенные через terraform (аналогично можно будет
группировать и с использованием другой информации)
``` text
$ ansible-inventory --list -i inventory.gcp.yml

$ tail inventory.gcp.yml
keyed_groups:
  - prefix: tag
    separator: '-'
    key: tags['items']
groups:
  named_app: "'reddit-app-' in name"
  named_db: "'reddit-db-' in name"
  tagged_app: "'reddit-app' in tags['items']"
  tagged_db: "'reddit-db' in tags['items']"
```

Чтобы работало быстро, а не обращалось в GCP на каждый
запуск - обязательно необходимо включить кэширование в
настройках ansible (по-умолчанию 3600 секунд).

Теперь создание инфраструктуры и выкатывание приложения
упрощается и избавляется от ручной работы по копированию
IP адреса из вывода terraform в файл inventory:
``` bash
packer build -var-file=packer/variables.json packer/app.json
packer build -var-file=packer/variables.json packer/db.json

cd terraform/stage && terraform apply
cd ../../ansible && ansible-playbook site.yml
```

### Альтернативные методы без обращения к GCP

Ссылки:
- https://alex.dzyoba.com/blog/terraform-ansible/
- https://otus.ru/nest/post/118/
- https://github.com/express42/terraform-ansible-example
- https://github.com/adammck/terraform-inventory
- https://github.com/radekg/terraform-provisioner-ansible

Два разных подхода:
- Генерирование inventory из файла состояния terraform
  (аналогично тому, что было реализовано в дополнительном
  задании из предыдущего ДЗ на скриптах, но выше уровнем)
- Плагин для terraform для запуска provisioners
  (больше подходит для первичных опраций с хостами при
  развертывания окружения, но не постоянных операций с
  хостами, например, обновления или бэкапа)


## Основное задание по provision в packer

Документация
- https://docs.ansible.com/ansible/latest/modules/list_of_all_modules.html
- https://docs.ansible.com/ansible/latest/modules/apt_module.html
- https://docs.ansible.com/ansible/latest/user_guide/playbooks_loops.html

В последних версиях ansible очень сильно рекомендуют использовать
список для apt вместо цикла (в документации и в консоли) для повышения
производительности.
``` text
When used with a loop: each package will be processed individually,
it is much more efficient to pass the list directly to the name option.

[DEPRECATION WARNING]: Invoking "apt" only once while using a loop via
squash_actions is deprecated. Instead of using a loop to supply multiple items
and specifying `name: "{{ item }}"`, please use `name: ['ruby-full', 'ruby-
bundler', 'build-essential']` and remove the loop. This feature will be removed
 in version 2.11. Deprecation warnings can be disabled by setting
deprecation_warnings=False in ansible.cfg.

changed: [default] => (item=[u'ruby-full', u'ruby-bundler', u'build-essential'])
```

Собираем образы, создаем окружение, генерим dynamic inventory,
указываем внутренний IP базы данных в playbook ansible,
затем деплоим:
``` bash
packer build -var-file=packer/variables.json packer/app.json
packer build -var-file=packer/variables.json packer/db.json

cd terraform/stage && terraform apply
cd ../../ansible &&
./my_tf2dyn.sh
vi app.yml
ansible-playbook site.yml
```

Примечание: для успешной сборки необходимо активное правило
по доступу через SSH, которое в нашем окружении постоянно
добавляется и удаляется через terraform.


# HW12. Принципы организации кода для управления конфигурацией.

## Дополнительное задание по dynamic inventory

Проблема с одновременной работой с разными окружениями в одном
проекте встаёт в полный рост: сейчас очень легко через terraform
создать окружение prod, а IP адреса в ansible использовать как
для окружения staging.
При ручном копировании из вывода terraform в inventory - это
случится рано или поздно. При использовании dynamic inventory
в текущем варианте - нет чёткого определения хостов для
каждого окружения.
Варианты решения:
- самое простое и правильное: *делить по разным проектам*
- работать только с одним окружением и создавать его в начале работ и
  делать destroy по окончании (получается что у смещается уровень и
  вместо prod/staging используем staging/testing окружения)
- использовать генерирование inventory из файла состояния
  terraform и указывать правильное окружение
- проверять наличие суффикса в hostname с именем окружения (prod
  или staging), для этого необходимо писать условие.

Пример разделения окружения, при этом в группы app и db попадают только
те хосты, которые относятся к этому окружению (но нужно помнить, что в
группу all попадут вообще все хосты, даже не относящиеся к этому окружению)
``` text
$ grep -r " in name" -- environments/
environments/prod/inventory.gcp.yml:  app: "'reddit-app' in tags['items'] and '-prod' in name"
environments/prod/inventory.gcp.yml:  db: "'reddit-db' in tags['items'] and '-prod' in name"
environments/stage/inventory.gcp.yml:  app: "'reddit-app' in tags['items'] and '-stage' in name"
environments/stage/inventory.gcp.yml:  db: "'reddit-db' in tags['items'] and '-stage' in name"

$ ansible-inventory --list -i environments/stage/inventory.gcp.yml
$ ansible-inventory --list -i environments/prod/inventory.gcp.yml
```

Дополнение: *более правильный способ - использовать labels*
- https://cloud.google.com/blog/products/gcp/labelling-and-grouping-your-google-cloud-platform-resources
- https://cloud.google.com/resource-manager/docs/creating-managing-labels

И тогда достаточно добавить в inventory.gcp.yml фильтр вида:
```
filters:
  - labels.env = stage
```


## Дополнительное задание по TravisCI

Бейдж вставляем в начало README.md
- https://docs.travis-ci.com/user/status-images/

Установка и работа с ansible-lint локально
``` text
sudo pip install ansible-lint
ansible-lint playbooks/site.yml --exclude=roles/jdauphant.nginx
```

Работа с TravisCI
- https://medium.com/@Nklya/локальное-тестирование-в-travisci-2b5ef9adb16e
- https://medium.com/@Nklya/новая-интеграция-travisci-с-github-или-travis-ci-org-vs-travis-ci-com-bc9833753461
- https://github.com/sethmlarson/trytravis

Простое добавление последовательности запуска скриптов с проверками не подходит:
при любой ошибке тут же выполнение прерывается и дальнейшие проверки провести
ну удаётся, в результате чего последовательно нужно будет исправлять каждую
ошибку и ждать когда получим сообщение о следующей. Сбор кодов возврата каждой
утилиты и вывод в конце, если хоть одно приложение упало - выглядит точно
так же, как написание bash скриптов для деплоя вместо использования ansible.

Поэтому был взят InSpec, который используется и при проверке ДЗ.
При использовании собственного проекта - нужно будет добавить в скрипт
создание docker инстанса (или использовать штатные средства Travis CI)

Скрипты и документация по InSpec:
- https://github.com/express42/otus-homeworks/tree/2019-02
- https://raw.githubusercontent.com/express42/otus-homeworks/2019-02/run.sh
- https://github.com/express42/otus-homeworks/blob/2019-02/homeworks/ansible-3/run.sh
- https://www.inspec.io/tutorials/

Из нюансов - нужно следить за кавычками (одинарными/двойными, проблема
аналогичная использованию puppet), чтобы переменные внутри строки
разворачивались в их значение как ожидается.


## В процессе сделано:
- Перевели плейбуки для app и db на использование ролей
  созданных по шаблону по образу ansible galaxy
  `ansible-galaxy init app` и `ansible-galaxy init db`
- Создали окружения stage и prod с разными inventory и добавили
  в вывод debug отображение окружения в запуск плейбуков
- Почистили рабочий каталог от старых файлов и организовали
  расположение файлов плейбуков согласно ansible best practies
- Шаблоны packer поправлены на новые пути в ansible
- Добавили окружение по-умолчанию и немного дополнительных
  настроек в ansible.cfg
- Добавили роль jdauphant.nginx из galaxy через requirements и
  настроили проксирование до нашего приложения
- Добавили в terraform правило фаервола для 80 порта
- Теперь приложение доступно по HTTP порту 80
  `https://github.com/jdauphant/ansible-role-nginx`
- Добавили поддержку Ansible Vault и зашифрованные файлы
  со списком пользователей и их паролями

``` text
ansible-vault encrypt environments/prod/credentials.yml
ansible-vault encrypt environments/stage/credentials.yml

ansible-vault edit environments/stage/credentials.yml

ansible-vault decrypt environments/stage/credentials.yml
```

## Дополнительное задание
- Настроил использование dynamic inventory для окружений stage и
  prod с дополнительной проверкой по наличию суффикса в hostname.
- Добавил тесты и линтеры на базе InSpec с запуском Travis CI

## Как запустить проект:

Полная сборка образов, установка зависимостей и раскатывание
приложения в stage окружении с чисткой кэша:
``` bash
packer build -var-file=packer/variables.json packer/app.json
packer build -var-file=packer/variables.json packer/db.json

cd ansible && ansible-galaxy install -r environments/stage/requirements.yml
cd ..

rm /tmp/infra_inventory/gcp_compute_*
cd terraform/stage && terraform apply -auto-approve=false
cd ../../ansible && ansible-playbook playbooks/site.yml

cd ../terraform/stage && terraform destroy
```

Раскатывание приложения в prod окружении:
``` bash
rm /tmp/infra_inventory/gcp_compute_*
cd terraform/prod && terraform apply -auto-approve=false
cd ../../ansible && ansible-playbook playbooks/site.yml -i environments/prod/inventory.gcp.yml

cd ../terraform/prod && terraform destroy
```

## Как проверить работоспособность:
- Перейти по ссылке http://app_external_ip где
  app_external_ip взять из вывода terraform (или ansible)

[![Build Status](https://travis-ci.com/otus-devops-2019-02/nwton_infra.svg?branch=ansible-3)](https://travis-ci.com/otus-devops-2019-02/nwton_infra)


# HW13. Локальная разработка Ansible ролей с Vagrant. Тестирование конфигурации.

## Работа с vagrant
``` bash
vagrant init
vagrant box list

vagrant up
vagrant status

vagrant provision dbserver
vagrant provision appserver

vagrant ssh dbserver
vagrant ssh appserver

vagrant halt
vagrant destroy

vagrant destroy -f
rm -rf .vagrant
```

Примечание: если есть две vm, но vm.provision указан только
в одной, то при запуске с нуля через `vagrant up` будет
создана только эта vm (актуально при полном перезапуске
лабы в середине ДЗ).

Примечание: vagrant сохраняет свой inventory в плоском файле,
поэтому нужно включить соответствующий плагин в ansible.cfg

Примечание: vagrant запускает ansible плейбуки от имени
пользователя vagrant, а пользователь ubuntu хоть и создан
в системе, но не используется для этого:
- https://docs.ansible.com/ansible/latest/scenario_guides/guide_vagrant.html
- https://www.vagrantup.com/docs/provisioning/ansible_intro.html
- https://www.vagrantup.com/docs/provisioning/ansible_common.html
- https://www.vagrantup.com/docs/provisioning/ansible.html

Примечание: при изменении systemd юнит-файла обязательно
запускать `systemctl daemon-reload`, иначе возможна ситуация
что файл обновился, а сервис не может перезапуститься.
При создании файла с нуля systemd отрабатывает нормально, хоть
и ругается на это, но при изменении путей при смене deploy_user
это является обязательным (или рестартовать VM целиком).


## Дополнительное задание
Проблема из-за того, что нет переменной, задающей параметры nginx,
т.к. она у нас задаётся в файле переменных окружения.

Берём содержимое файла environments/stage/group_vars/app и
переделываем под язык ruby, следя за стрелочками и правильным
применением квадратных и фигурных скобок. Из плюсов - в списках
последний элемент можно оставлять с запятой в конце.

Добавлять - обязательно в *ansible.extra_vars*


## Работа с Vagrant под Windows
Vagrant под Windows - имеет доступ к VirtualBox, но не может ansible
Vagrant под WSL - не может использовать VirtualBox, но умеет ansible

Документация:
- https://www.vagrantup.com/docs/other/wsl.html
- https://github.com/hashicorp/vagrant/issues/8604
- https://github.com/joelhandwell/ubuntu_vagrant_boxes/issues/1
- http://michaelkant.com/blog/wsl-and-you/
- https://alchemist.digital/articles/vagrant-ansible-and-virtualbox-on-wsl-windows-subsystem-for-linux/
- https://github.com/JeffReeves/WSL-Ansible-Vagrant-VirtualBox

Устанавливаем обе версии одновременно:
``` text
C:> windows
choco install virtualbox --version 5.2.30
choco install vagrant --version 2.2.5

$ WSL
wget https://releases.hashicorp.com/vagrant/2.2.5/vagrant_2.2.5_x86_64.deb
sudo dpkg -i vagrant_2.2.5_x86_64.deb

export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
```

И добавляем кусочек в Vagrantfile ("is not a bug")
```
config.vm.provider "virtualbox" do |vb|
  vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
end
```

Альтернативный устаревший вариант для Windows без WSL
с использованием плагина vagrant-guest_ansible и
использованием ansible_local provisioner:
- https://github.com/vovimayhem/vagrant-guest_ansible
  `vagrant plugin install vagrant-guest_ansible`
- https://gist.github.com/tknerr/291b765df23845e56a29
- https://www.vagrantup.com/docs/provisioning/ansible_local.html
- https://blog.zencoffee.org/2016/08/ansible-vagrant-windows/


## Работа с virtualenv

Установка зависимостей в virtualenv
- https://docs.python-guide.org/dev/virtualenvs/
``` bash
sudo apt-get install python-virtualenv
sudo pip install virtualenv
sudo pip install pip-tools

cd ansible

virtualenv venv
source venv/bin/activate

pip-sync -n requirements.txt
pip install -r requirements.txt

pip freeze | less

deactivate

rm -rf venv
```

### Работа с molecule and testinfra

Дополнительные настройки для molecule (для WSL и устанавливаем размер VM,
но проблема с uartmode1 присутствует и для Linux инсталляций):
- https://github.com/ansible/molecule/issues/424
- https://github.com/ansible/molecule/issues/1556#issuecomment-441182444
- https://github.com/jonashackt/molecule-ansible-docker-vagrant

Дополнительные модули:
https://testinfra.readthedocs.io/en/latest/modules.html

Работаем в virtualenv в каталоге ansible (см.ранее)
``` bash
cd ansible
source venv/bin/activate

cd roles/db/
molecule init scenario --scenario-name default -r db -d vagrant
...
molecule create
molecule list
molecule login -h instance
molecule converge
molecule verify

deactivate
```

Примечание: molecule версии 2.20.1 использует зависимость на
очень старую версию testinfra==1.19.0, которая несовместима
с ansible версии 2.8
- `pip install molecule==2.19 ansible==2.7.11`
- https://github.com/ansible/molecule/issues/1727
- https://github.com/ansible/molecule/issues/2083
- https://github.com/ansible/molecule/pull/2034


## Дополнительное задание с двумя звездочками
- Вынести роль db в отдельный репозиторий: удалить роль из
  репозитория infra и сделать подключение роли через
  requirements.yml обоих окружений;
- Подключить TravisCI для созданного репозитория с ролью db
  для автоматического прогона тестов в GCE (нужно использовать
  соответсвующий драйвер в molecule).
- Пример, как это может выглядеть, можно посмотреть здесь
  https://github.com/Artemmkin/db-role-example/
  https://github.com/Artemmkin/test-ansible-role-with-travis
- Примерные шаги по настройке TravisCI указаны в данном gist
  https://gist.github.com/Artemmkin/e1c845e96589d5d71476f57ed931f1ac
- У роли должен быть бейдж со статусом билда
- Настроить оповещения о билде в slack, который использовали в предыдущих ДЗ;

Прочее от Artemmkin:
- https://github.com/Artemmkin/infrastructure-as-code-tutorial
- https://github.com/Artemmkin/infrastructure-as-code-example


## В процессе сделано:
- Создано локальное тестовое окружение из двух VM в virtualbox
  с использованием vagrant
- Конфиг ansible.cfg исправлен для работы и под vagrant
- Добавлен bootstrap плейбук для установки python, если его нет
- В роле db созданы таски для установки и конфига mongo
- В роле app созданы таски для установки и конфига ruby и puma
- Добавлена параметризация deploy_user для указания под
  каким пользователем выкатить приложение и установлено
  правильное значение
- Развернуты требуемые версии пакетов для прохождения тестов
  с использованием molecula и testinfra в virtualenv
- Добавлены тесты MongoDB на наличие файлов и запущенного
  сервиса и того, что порт 27017 прослушивается
- Переделаны плейбуки для packer на использование ролей
  и передачу тэгов (только для app передаём тэг ruby)

## Дополнительное задание
- Добавлена переменная окружения для правильного деплоя
  модуля nginx и запуска проксирования 80 порта

## Как запустить проект:

Запуск приложения в виртуальной среде на локальном компе
и последующее удаление хвостов:
``` bash
cd ansible
vagrant up
...
vagrant destroy -f
rm -rf .vagrant
```

## Как проверить работоспособность:
- Перейти по ссылке http://10.10.10.20/

[![Build Status](https://travis-ci.com/otus-devops-2019-02/nwton_infra.svg?branch=ansible-4)](https://travis-ci.com/otus-devops-2019-02/nwton_infra)
