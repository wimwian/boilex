# Boilex

Boilex is mix task to generate Elixir project development tools configuration boilerplate.

## Installation

Add the following parameters to `deps` function in `mix.exs` file

```
{:boilex, github: "tim2CF/boilex", only: [:dev, :test], runtime: false},
```

## Usage

### boilex.new

Command `mix boilex.new` generates development tools configuration files in already existing Elixir project. It can be used with any **Elixir** or **Phoenix** application except *umbrella* projects. To generate configuration execute this command and follow instructions.

```
cd ./myproject
mix deps.get && mix compile
mix boilex.new
```

- `Coveralls` tool will help you to check test coverage for each module of new project. Can be configured with `coveralls.json` file. It's recommended to keep minimal test coverage = 100%.
- `Dialyzer` is static analysis tool for BEAM bytecode. Most useful feature of this tool is perfect type inference what will work in your project from-the-box without writing any explicit function specs or any other overhead. Can be configured with `.dialyzer_ignore` file.
- `ExDoc` is a tool to generate beautiful documentation for your Elixir projects.
- `Credo` static code analysis tool will make your code pretty and consistent. Can be configured with `.credo.exs` file.
- `Changex` is changelog generator.
- `scripts` directory contains auto-generated bash helper scripts.

### scripts
- `pre-commit.sh` is git pre-commit hook. This script will compile project and execute all possible checks. Script will not let you make commits before all issues generated by compiler and static analysis tools will be fixed and all tests will pass.
- `.env` text file contains variables are required by some scripts.
- `remote-iex.sh` provides direct access to remote erlang node through `iex`.
- `cluster-iex.sh` connects current erlang node to remote erlang node. All local debug tools (for example Observer) are available to debug remote node. Hot code reloading is also available.
- `docs.sh` creates and opens project documentation.
- `coverage.sh` creates and opens project test coverage report.

## TODO

- `Dockerfile` template
- `docker-compose.yml` template
- `.circleci` yaml configs template
- `scripts/release.sh` script bumps version, creates new release, changelog and pushes to github.
