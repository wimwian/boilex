defmodule Boilex.Generator.Circleci do

  import Mix.Generator

  def run(assigns) do
    create_directory  ".circleci"
    create_file       ".circleci/config.yml",   circleci_config_template(assigns)

    :ok
  end

  embed_template :circleci_config, """
  defaults: &defaults
    working_directory: /app
    docker:
      - image: heathmont/elixir-builder:<%= @elixir_version %><%= if @include_postgres, do: "\n"<>postgres_circleci_image() %>

  check_vars: &check_vars
    run:
      name:       Check variables
      command:    ./scripts/check-vars.sh "in system" "ROBOT_SSH_KEY" "DOCKER_EMAIL" "DOCKER_ORG" "DOCKER_PASS" "DOCKER_USER"

  setup_ssh_key: &setup_ssh_key
    run:
      name:       Setup robot SSH key
      command:    echo "$ROBOT_SSH_KEY" | base64 --decode > $HOME/.ssh/id_rsa.robot && chmod 600 $HOME/.ssh/id_rsa.robot && ssh-add $HOME/.ssh/id_rsa.robot

  setup_ssh_config: &setup_ssh_config
    run:
      name:        Setup SSH config
      command:     echo -e "Host *\\n IdentityFile $HOME/.ssh/id_rsa.robot\\n IdentitiesOnly yes" > $HOME/.ssh/config

  fetch_submodules: &fetch_submodules
    run:
      name:       Fetch submodules
      command:    git submodule update --init --recursive

  hex_auth: &hex_auth
    run:
      name:       Hex auth
      command:    mix hex.organization auth <%= @hex_organization %> --key $HEX_API_KEY

  fetch_dependencies: &fetch_dependencies
    run:
      name:       Fetch dependencies
      command:    mix deps.get

  compile_dependencies: &compile_dependencies
    run:
      name:       Compile dependencies
      command:    mix deps.compile

  compile_protocols: &compile_protocols
    run:
      name:       Compile protocols
      command:    mix compile.protocols --warnings-as-errors

  version: 2
  jobs:
    test:
      <<: *defaults
      working_directory: /app
      environment:
        MIX_ENV: test
      steps:
        - checkout
        - run:
            name:       Check variables
            command:    ./scripts/check-vars.sh "in system" "ROBOT_SSH_KEY" <%= if @include_coveralls_push, do: "\\"COVERALLS_REPO_TOKEN\\"" %>
        - <<: *setup_ssh_key
        - <<: *setup_ssh_config
        - <<: *fetch_submodules
        - restore_cache:
            keys:
              - v1-test-{{ checksum "mix.lock" }}-{{ .Revision }}
              - v1-test-{{ checksum "mix.lock" }}-
              - v1-test-
        <%= if not(@include_hex_auth), do: "# " %>- <<: *hex_auth
        - <<: *fetch_dependencies
        - <<: *compile_dependencies
        - <<: *compile_protocols
        # - run:
        #     name:       Create test DB
        #     command:    mix ecto.create
        # - run:
        #     name:       Migrate test DB
        #     command:    mix ecto.migrate
        - run:
            name:       Run tests
            command:    mix coveralls<%= if @include_coveralls_push, do: ".circle" %>
        - run:
            name:       Run style checks
            command:    mix credo --strict
        - run:
            name:       Run Dialyzer type checks
            command:    mix dialyzer --halt-exit-status
            no_output_timeout: 15m
        - save_cache:
            key: v1-test-{{ checksum "mix.lock" }}-{{ .Revision }}
            paths:
              - _build
              - deps
              - ~/.mix

    build_qa:
      <<: *defaults
      environment:
        MIX_ENV: qa
      steps:
        - checkout
        - setup_remote_docker
        - <<: *check_vars
        - <<: *setup_ssh_key
        - <<: *setup_ssh_config
        - <<: *fetch_submodules
        - restore_cache:
            keys:
              - v1-qa-{{ checksum "mix.lock" }}-{{ .Revision }}
              - v1-qa-{{ checksum "mix.lock" }}-
              - v1-qa-
        <%= if not(@include_hex_auth), do: "# " %>- <<: *hex_auth
        - <<: *fetch_dependencies
        - <<: *compile_dependencies
        - <<: *compile_protocols
        - save_cache:
            key: v1-qa-{{ checksum "mix.lock" }}-{{ .Revision }}
            paths:
              - _build
              - deps
              - ~/.mix
        - persist_to_workspace:
            root: ./
            paths:
              - _build/qa
              - deps

    build_prelive:
      <<: *defaults
      environment:
        MIX_ENV: prelive
      steps:
        - checkout
        - setup_remote_docker
        - <<: *check_vars
        - <<: *setup_ssh_key
        - <<: *setup_ssh_config
        - <<: *fetch_submodules
        - restore_cache:
            keys:
              - v1-prelive-{{ checksum "mix.lock" }}-{{ .Revision }}
              - v1-prelive-{{ checksum "mix.lock" }}-
              - v1-prelive-
        <%= if not(@include_hex_auth), do: "# " %>- <<: *hex_auth
        - <<: *fetch_dependencies
        - <<: *compile_dependencies
        - <<: *compile_protocols
        - save_cache:
            key: v1-prelive-{{ checksum "mix.lock" }}-{{ .Revision }}
            paths:
              - _build
              - deps
              - ~/.mix
        - persist_to_workspace:
            root: ./
            paths:
              - _build/prelive

    build_staging:
      <<: *defaults
      environment:
        MIX_ENV: staging
      steps:
        - checkout
        - setup_remote_docker
        - <<: *check_vars
        - <<: *setup_ssh_key
        - <<: *setup_ssh_config
        - <<: *fetch_submodules
        - restore_cache:
            keys:
              - v1-staging-{{ checksum "mix.lock" }}-{{ .Revision }}
              - v1-staging-{{ checksum "mix.lock" }}-
              - v1-staging-
        <%= if not(@include_hex_auth), do: "# " %>- <<: *hex_auth
        - <<: *fetch_dependencies
        - <<: *compile_dependencies
        - <<: *compile_protocols
        - save_cache:
            key: v1-staging-{{ checksum "mix.lock" }}-{{ .Revision }}
            paths:
              - _build
              - deps
              - ~/.mix
        - persist_to_workspace:
            root: ./
            paths:
              - _build/staging

    build_prod:
      <<: *defaults
      environment:
        MIX_ENV: prod
      steps:
        - checkout
        - setup_remote_docker
        - <<: *check_vars
        - <<: *setup_ssh_key
        - <<: *setup_ssh_config
        - <<: *fetch_submodules
        - restore_cache:
            keys:
              - v1-prod-{{ checksum "mix.lock" }}-{{ .Revision }}
              - v1-prod-{{ checksum "mix.lock" }}-
              - v1-prod-
        <%= if not(@include_hex_auth), do: "# " %>- <<: *hex_auth
        - <<: *fetch_dependencies
        - <<: *compile_dependencies
        - <<: *compile_protocols
        - save_cache:
            key: v1-prod-{{ checksum "mix.lock" }}-{{ .Revision }}
            paths:
              - _build
              - deps
              - ~/.mix
        - persist_to_workspace:
            root: ./
            paths:
              - _build/prod

    docker_build:
      <<: *defaults
      environment:
        MIX_ENV: prod
      steps:
        - checkout
        - setup_remote_docker
        - attach_workspace:
            at: ./
        - run:
            name:       Login to docker
            command:    docker login -e $DOCKER_EMAIL -u $DOCKER_USER -p $DOCKER_PASS
        - run:
            name:       Building docker image
            command:    export $(cat "./scripts/.env" | xargs) && mix boilex.ci.docker.build "$CIRCLE_TAG"
        - run:
            name:       Push image to docker hub
            command:    export $(cat "./scripts/.env" | xargs) && mix boilex.ci.docker.push "$CIRCLE_TAG"

    doc:
      <<: *defaults
      environment:
        MIX_ENV: dev
      working_directory: /app
      steps:
        - checkout
        - run:
            name:       Check variables
            command:    ./scripts/check-vars.sh "in system" "ROBOT_SSH_KEY"
        - <<: *setup_ssh_key
        - <<: *setup_ssh_config
        - <<: *fetch_submodules
        - restore_cache:
            keys:
              - v1-doc-{{ checksum "mix.lock" }}-{{ .Revision }}
              - v1-doc-{{ checksum "mix.lock" }}-
              - v1-doc-
        <%= if not(@include_hex_auth), do: "# " %>- <<: *hex_auth
        - <<: *fetch_dependencies
        - <<: *compile_dependencies
        - <<: *compile_protocols
        - save_cache:
            key: v1-doc-{{ checksum "mix.lock" }}-{{ .Revision }}
            paths:
              - _build
              - deps
              - ~/.mix
        - run:
            name:       Compile documentation
            command:    mix docs<%= if @include_postgres, do: "\n"<>postgres_circleci_erd() %>

  workflows:
    version: 2
    test:
      jobs:
        - test:
            context: global
            filters:
              branches:
                only: /^([A-Z]{2,}-[0-9]+|hotfix-.+|feature-.*)$/
    test-build:
      jobs:
        - test:
            context: global
            filters:
              branches:
                only: /^(build-.+)$/
        - build_qa:
            context: global
            filters:
              branches:
                only: /^(build-.+)$/

        - build_prelive:
            context: global
            filters:
              branches:
                only: /^(build-.+)$/

        - build_staging:
            context: global
            filters:
              branches:
                only: /^(build-.+)$/

        - build_prod:
            context: global
            filters:
              branches:
                only: /^(build-.+)$/

        - docker_build:
            context: global
            filters:
              branches:
                only: /^(build-.+)$/
            requires:
              - test
              - build_qa
              - build_prelive
              - build_staging
              - build_prod
    test-build-doc:
      jobs:
        - test:
            context: global
            filters:
              tags:
                only: /.*/
              branches:
                only: /^master$/

        - build_qa:
            context: global
            filters:
              tags:
                only: /.*/
              branches:
                only: /^master$/

        - build_prelive:
            context: global
            filters:
              tags:
                only: /.*/
              branches:
                only: /^master$/

        - build_staging:
            context: global
            filters:
              tags:
                only: /.*/
              branches:
                only: /^master$/

        - build_prod:
            context: global
            filters:
              tags:
                only: /.*/
              branches:
                only: /^master$/

        - docker_build:
            context: global
            filters:
              tags:
                only: /.*/
              branches:
                only: /^master$/
            requires:
              - test
              - build_qa
              - build_prelive
              - build_staging
              - build_prod
        - doc:
            context: global
            filters:
              tags:
                only: /.*/
              branches:
                only: /^master$/
  """

  defp postgres_circleci_image do
    """
          environment:
            POSTGRES_URL: ecto://postgres:postgres@localhost/platform88
        - image: circleci/postgres:9.6.5-alpine-ram
    """
    |> String.trim("\n")
  end

  defp postgres_circleci_erd do
    """
          - run:
              name:       Setup test DB
              command:    mix ecto.setup
          - run:
              name:       Generate database ERD
              command:    export PROJECT_DIRECTORY="$(pwd)" && pushd /schemacrawler-14.19.01-distribution/_schemacrawler/ && ./schemacrawler.sh -server=postgresql -host=127.0.0.1 -user=postgres -password=postgres -database=platform88 -infolevel=standard -routines= -command=schema -outputformat=png -o "$PROJECT_DIRECTORY/doc/database-ERD.png" && popd
    """
    |> String.trim("\n")
  end

end
