# Github Actions новичкам от новичка

## Содержание

1. Введедние
2. Цель
3. Workflow файлы
4. Actions
5. Secrets
6. Заключение

## 1.Введение

Относительно недавно, как сказал мой тимлид, я "перешла на темную сторону" - делала клиентские приложения, сейчас делаю серверное. Соответственно, мне надо соотвествовать - читать, учиться, практиковать и развиваться в этом направлении, делать какие-то проекты помимо работы. Еще не придумала какой, но пусть, скажем, это будет блог. Для этого я арендовала сервер VDS. Решила начать с автомитизирации процесса деплоя при появлении новых изменений. На github для этого есть `actions`, так как репозиторий с проектом я буду хранить там.
Итого - здесь я буду расссказывать о [CD(continuous deployment)](https://ru.wikipedia.org/wiki/CI/CD) c помощью [GitHub Actions](https://docs.github.com/ru/actions).

## 2. Цель

Я буду считать, что этот тутор нашли люди, которые уже создали репозиторий на гитхабе. Мой проект создан генератором для Ruby on Rails. Но это не главное, главное - понять, как работают Github Actions и уметь применить его для любого проекта, найдя нужные `actions` из [Github Marketplace](https://github.com/marketplace/).
Деплой происходит при определенном действий, например, при мерже рабочей ветки в ветку main:

- проверить кода линтером
- запустить тесты
- притянуть изменения в файлах в папку проекта на удаленном сервере.
- перезапустить там контейнер с проектом, чтоб изменения встпуили в силу.

## 3. Создание workflow файлов

Workflow файлами github запускает как раз Actions, выполняющие интересующие нас действия.

Для этого я перешла на вкладку `Actions` на странице репозитория. На базе вашего кода там предлагаются разные варианты, но можно начать с `Simple workflow`.
![Simple workflow](img/2.png)
Я начала с предложенного wokflow файла "Ruby on Rails CI".
Есть [краткое руководство](https://docs.github.com/ru/actions/quickstart#creating-your-first-workflow) по написанию и чтению файла workflow. Воспользуйтесь.

После создания name-of-your-wokflow-file.yml файла, в репозиторий у вас появится папка `.github/workflows/name-of-your-wokflow-file.yml`.

<details>
   <summary>Почитать `blank.yml`</summary>
   
   ```javascript
name: CI
on:
   # События, которые запускают jobs
   push:
      branches: [ "main" ]
   pull_request:
      branches: [ "main" ]

# jobs запускаются параллельно, если не указана последовательность

jobs: # Название job вы можете назвать как угодно
build: # Операционная система, в которой запускаются процессы
runs-on: ubuntu-latest

         # Шаги
         steps:
            # Actions от github: проверяет репозиторий, гит и т.д.
            - uses: actions/checkout@v3

            # Пример однолинейного простого скрипта shell
            - name: Run a one-line script
              run: echo Hello, world!

            # Пример многолинейного скрипта shell
            - name: Run a multi-line script
              run: |
                 echo Add other actions to build,
                 echo test, and deploy your project.

```
</details>

Самое интересное тут `actions` в строке `uses`. В простейшем примере выше это - [actions/checkout@v3](https://github.com/actions/checkout). Код этого экшна написан на TypeScript. Можно посмотреть в исходниках, что делает экшн. Но проще посмотреть на странице выполнения `job`, после того, как вы его запустите:
   * копирует переменные внутрь контейнера
   * проверяет версию гита
   * проверяет есть ли репозиторий
   * авторизируется
   * копирует репозиторий внутрь контейнера
   * переходит на ветку main
![actions/checkout@v3](img/6.png)

Существует множество экшнов, созданные разработчиками, которые можно использовать, выбрав на [Github Marketplace](https://github.com/marketplace/), точно также как мы выбираем библотеки для JavaScript проектов на [https://www.npmjs.com/](https://www.npmjs.com/) или гемы на [https://rubygems.org/](https://rubygems.org/).
Например, в своих нуждах я использовала [D3rHase/ssh-command-action@v0.2.2](https://github.com/marketplace/actions/ssh-command), который запускает консольную команду через [ssh](https://en.wikipedia.org/wiki/OpenSSH).

## Мои нужды
Вернемся к моему списку требуемых действии для деплоя.

<details>
<summary>.github/workflows/rubyonrails.yml</summary>

```

# This workflow will install a prebuilt Ruby version, install dependencies, and

# run tests and linters. Then it pulls new features from my repo and

# rebuild containers on remote server through ssh.

name: "Ruby on Rails CI"
on:
push:
branches: ["main"]
pull_request:
branches: ["main"]

jobs:
lint:
runs-on: ubuntu-latest
steps: - name: Checkout code
uses: actions/checkout@v3 - name: Install Ruby and gems
uses: ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4 # v1.127.0
with:
bundler-cache: true - name: Lint Ruby files
run: bundle exec rubocop

test:
needs: lint
runs-on: ubuntu-latest
services:
postgres:
image: postgres:14
ports: - "5432:5432"
env:
POSTGRES_DB: rails_test
POSTGRES_USER: rails
POSTGRES_PASSWORD: password
env:
POSTGRES_DB: rails_test
POSTGRES_USER: rails
POSTGRES_PASSWORD: password
RAILS_ENV: test
DATABASE_URL: "postgres://rails:password@localhost:5432/rails_test"
steps: - name: Checkout code
uses: actions/checkout@v3 - name: Install Ruby and gems
uses: ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4 # v1.127.0
with:
bundler-cache: true - name: Set up database schema
run: bin/rails db:schema:load - name: Run tests
run: bin/rake

deploy:
needs: test
runs-on: ubuntu-latest
steps: - name: Checkout code
uses: actions/checkout@v3 - name: Install Ruby and gems
uses: ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4 # v1.127.0
with:
bundler-cache: true

      - name: Run command on remote server
        uses: D3rHase/ssh-command-action@v0.2.2
        with:
          host: ${{secrets.SSH_HOST}}
          user: ${{secrets.SSH_USER}}
          private_key: ${{secrets.SSH_PRIVATE_KEY}}
          command: cd /home/projects/aykuli.su/;git co dev;git pull; cp ../aykuli.su.env .env; docker ps; docker container stop ror nginx postgres; docker ps; docker-compose --file docker-compose.prod.yml up -d

```
</details>

Если почитать файл выше, то последовательность процессов такая:

1. Проверила линтером код
2. Запуситла тесты
3. Деплой

Визуально это выглядит симпатично.
![Runners in interface](img/7.png)

Процессы выполняются последовательно, для этого используется ключевое слово `needs` в теле `job`.

Можно зайти в кажый прямоугольник и посмотреть детальнее, что там происходит. Во время дебажжинга я для себя в скриптах писала визуальные делители или выводила список полученных файлов.

<details>
<summary>
Пример шага с дебажжинговыми строками
</summary>

```

- name: Run command on remote server
  uses: D3rHase/ssh-command-action@v0.2.2
  with:
  host: ${{secrets.SSH_HOST}}
  user: ${{secrets.SSH_USER}}
  private_key: ${{secrets.SSH_PRIVATE_KEY}}
  command: |
  echo '--- HERE WE START WORK ON REMOTE SERVER ---'
  cd /home/projects/aykuli.su/
  git co dev
  git pull
  cp ../aykuli.su.env .env
  ls -al | grep '.env'
  echo '--- I WANNA BE SURE THAT I COPIED SOME FILE ---'
  sudo docker-compose pull
  sudo docker-compose --file docker-compose.prod.yml up -d
  echo '--- LIST OF DOCKER CONTAINERS ON REMOTE SERVER ---'  
   sudo docker ps

```
</details>

## Secrets
В rubyinrails.yml файле есть переменные, которые вызываются из объекта `secrets`. Эти пемренные нужны для того, чтобы подружить ваш удаленный сервер с создающимися контейнерами на github на время выполнения действии. Для этого я сделала шаги:

1. Сгенерировала SSH ключ на удаленном сервере:

```

cd ~/.ssh; ssh-keygen -t ed25519 -C "your_email@example.com"

```

Я назвала ключ test и получила 2 файла - приватный и публичные ключи.
![Public and private keys](img/4.png)

2. Содержимое приватного ключа я скопировала в переменную в `SSH_PRIVATE_KEY` во вкладке `Settings ->Secrets -> Actions`
  ![](img/5.png)
3. Создала еще перменные `SSH_HOST` и `SSH_USER` с соответствующим содержимым.

## Заключение
Стоит сказать, что тут предполагается, что ваш репозиторий склонирован в ваш удаленный сервер, и он подружен с github через ssh. На вашем удаленном сервере установлен git и другие нужные вам инстурменты, например, docker, docker-compose как в моем примере rubyonrails.yml.

Вот теперь пазл собрался.
- Вы знаете, как создавать workflow.yml файлы, что будет запускать нужные вам действия.
- Вы знаете, где и как искать нужные вам экшны или самому написать скрипт, если задача простая.
- Вы знаете, где хранить секреные перменные для экшнов
- Вы знаете, как дебажить в случае ошибок.



TODO:

- посмотреть другие статьи, как называются сущности job action
```
