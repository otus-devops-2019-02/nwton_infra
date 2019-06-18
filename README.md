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


# HW6. Основные сервисы Google Cloud Platform (GCP).

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
