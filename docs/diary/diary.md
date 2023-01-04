# Github Actions новичкам от новичка

Относительно недавно, как сказал мой тимлид, я "перешла на темную сторону" - делала клиентские приложения, сейчас делаю серверное. Соответственно, мне надо соотвествовать - читай, учиться и разививаться в этом направлении, делать какие-то проекты помимо работы. Еще не придумала какой, но пусть,скажем, это будет блог. Для этого я арендовала сервер VDS, надо значит автомитизировать процесс деплоя при появлении новых изменений. На github для этого есть `actions`.
Итого - здесь я буду расссказывать о [CD(continuous deployment)](https://ru.wikipedia.org/wiki/CI/CD) c помощью [GitHub Actions](https://docs.github.com/ru/actions).

1.  Создаете свой проект.
    Практикую я Ruby on Rails на текущий момент, сгенерировала проект с возможность разработки веб-интерфейса, чтобы сразу было видно хоть что-то, залила в репозиторий на github.

2.  Создаю action.
    Для этого я перешла на вкладку `Actions` на странице репозитория. На базе вашего кода, там предлагаются разные варианты, но можно начать с `Simple workflow`.
    ![Simple workflow](img/2.png)
    Я начала с предложенного wokflow файла "Ruby on Rails CI".
    Есть [краткое руководство](https://docs.github.com/ru/actions/quickstart#creating-your-first-workflow) по написанию и чтению файла workflow.

    Прежде, чем изменять что-то в сгенерированном файле, надо прояснить, что я хочу сделать:

- скопировать нужные файлы на мой удаленный сервер
- запустить код там.

Для выполнения этих действий обычно пользуют [ssh](https://en.wikipedia.org/wiki/OpenSSH).

<details>
   <summary>
   /.github/workflows/rubyonrails.yml
   </summary>

```
name: "Ruby on Rails CI"
on:
   push:
      branches: [ "main" ]
   pull_request:
      branches: [ "main" ]
jobs:
   joba_joba:
      runs-on: ubuntu-latest
      services:
         postgres:
         image: postgres:11-alpine
         ports:
            - "5432:5432"
         env:
            POSTGRES_DB: rails_test
            POSTGRES_USER: rails
            POSTGRES_PASSWORD: password
      env:
         RAILS_ENV: test
         DATABASE_URL: "postgres://rails:password@localhost:5432/rails_test"
      steps:
         - name: Checkout code
         uses: actions/checkout@v3
         # Add or replace dependency steps here
         - name: Install Ruby and gems
         uses: ruby/setup-ruby@ee2113536afb7f793eed4ce60e8d3b26db912da4 # v1.127.0
         with:
            bundler-cache: true
         # Add or replace database setup steps here
         - name: Set up database schema
         run: bin/rails db:schema:load
         # Add or replace test runners here
         - name: Run tests
         run: bin/rake
```

Читаю код: Процесс, с названием "Ruby on Rails CI" при событиях push и pull_request на ветках main, запускает job (у меня только 1) c названием `joba_joba`. Эта работа запускается в операционной системе, маркированная как ubuntu-latest в github. Есть переменные

</details>

Для того, чтобы код работал на удаленном сервере, как минимум, надо скопировать нужные файлы на этот удаленный сервер и запустить код там. Для этого есть [ssh](https://en.wikipedia.org/wiki/OpenSSH).

1. На своем арендованном сервере сгенерировала публичный ssh-ключ. Вот он в списке:
   ![List of keys on my server](img/0.png)
   Публичный ключ - это содержимое файла `*.pub`
2. Копирую содержимое публичного ключа
   ![Public key content](img/3.png)
3. В секретные ключи проекта `Settings > Secrets > Actions`. Как видите, назвала его `SSH_PRIVATE_KEY`. Также я туда добавила `SSH_USER` и `SSH_HOST` - ваш пользователь на вашем сервере и IP-адрес того сервера.
   ![Actions secrets](img/1.png)

Я хотела сделать с github-actions сделать такие шаги:

1. Проверка кода линтером (`rubocop`)
2. Тестирование
3. Деплой
4. Добавляю `SSH_PRIVATE_KEY` в ключи операционки в контейнере, который создается на github.
5. Добавляю `SSH_HOST` в список доверенных адресов:
6. Копирую код своего проекта на свой сервер в определенную папку.

Для работы с SSH ищу подходящий `action` на [GitHub Marketplace page](https://github.com/marketplace?type=actions&query=ssh+) (я в ссылку сразу добавила квери, по которому искала нужный экшн).
Я сейчас пробую [SSH Action](https://github.com/marketplace/actions/ssh-action). На странице экшна можно перейти на страницу экшна и посмотреть, что выполняет этот экшн. В частности этот экшн делает то, что мне нужно:

- копирует SHH ключ из secrets в ssh конфигурации контейнера.
- добавляет SSH_HOST в доверенные адреса в операционке контейнера.
- записывает все в ssh конфиг файл.

Чтение воркфлоу в репе очень полезно при возникновении ошибок.
