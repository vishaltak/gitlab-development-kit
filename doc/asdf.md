# `asdf`

## What is `asdf`?

[`asdf`](https://asdf-vm.com/) is a command line tool for installing and updating software such as Ruby, PostgreSQL, Node.js and many others.

`asdf` defers the management of installing and updating software to [plugins](https://github.com/asdf-vm/asdf-plugins).

The GDK currently leverages the following `asdf` plugins:

- [`golang`](https://github.com/kennyp/asdf-golang)
- [`minio`](https://github.com/aeons/asdf-minio)
- [`nodejs`](https://github.com/asdf-vm/asdf-nodejs)
- [`postgres`](https://github.com/smashedtoatoms/asdf-postgres)
- [`redis`](https://github.com/smashedtoatoms/asdf-redis)
- [`ruby`](https://github.com/asdf-vm/asdf-ruby)
- [`rust`](https://github.com/asdf-community/asdf-rust)
- [`yarn`](https://github.com/twuni/asdf-yarn)

The [GDK `.tool-versions` file](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/.tool-versions) contains the specifics plugins and versions GDK requires.

## `asdf` benefits

- Written in Shell, which requires no additional software to get started.
- Cross platform support, including macOS and Linux.
- Many `asdf` plugins are available, like the ones listed above.
- Support for defining required software _and_ versions with a `.tool-versions` file.
- Allows team members to use the same exact versions of software.

## `asdf` limitations

- Some `asdf` plugins require software to be compiled from source which can at times fail or be slow.
- Some `asdf` plugins are not well maintained.
- Some software does not currently have `asdf` plugins, such as `jaeger` and `OpenLDAP`.

## Reason for `asdf` as the standard for installing software in the GDK

Before `asdf` was integrated into the GDK, the related software had to be installed manually. This offered great flexibility of choice for our users, but made things difficult for users who were inexperienced with installing the software requirements.

We chose `asdf` as the standard for installing software for the GDK because:

- It's the only cross platform solution that provides support for _all_ of the required software.
- It supports installing multiple versions of software, which is critical in the testing and verification before we move to newer versions of software, something other tools did not support.

## `.tool-versions` file

The `.tool-versions` file is a plaintext file that is typically checked into a project at the root directory, but can exist in any directory. The file describes the software and versions a project requires. If the file is present, `asdf` inspects the file and attempts to make the software and the version available at the command line. The following is an example of the `.tool-versions` file:

```plaintext
# <software> <default-version> <other-version(s)>
golang       1.18.3            1.17.9
nodejs       16.15.0
postgres     12.10             13.6
ruby         2.7.5             3.0.4 2.7.6
rust         1.65.0
```

We can summarize the contents as:

- Require `golang`, versions `1.18.3` and `1.17.9`, making `1.18.3` the default version available
- Require `nodejs`, versions `16.15.0`, making `16.15.0` the default version available
- Require `postgres`, versions `12.10` and `13.6`, making `12.10` the default version available
- Require `ruby`, versions `2.7.5`, `3.0.4` and `2.7.6`, making `2.7.5` the default version available
- Require `rust`, versions `1.65.0`, making `1.65.0` the default version available

The `.tool-versions` file describes the project's software requirements, but it does not install them. To install the project's software requirements, run:

```shell
asdf install
```

## How GDK manages the `.tool-versions` file

The GDK clones and updates a number of Git repositories, like [`gitlab`](https://gitlab.com/gitlab-org/gitlab), [`gitlab-workhorse`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/workhorse), and [`gitaly`](https://gitlab.com/gitlab-org/gitaly). Each repository has their own software requirements that their `.tool-versions` files define.

The GDK only requires Shell and Ruby, with Ruby being the only additional software required and defined in [`.tool-versions-gdk`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/.tool-versions-gdk).

The `.tool-versions` file in the root of the GDK project is generated with the `support/asdf-combine` tool, which consults each Git repository's `.tool-versions` file. The `support/asdf-combine` tool merges, consolidates, and adds comments to provide context about where each software and version is defined.

After `support/asdf-combine` executes, the resulting `.tool-versions` file has all required software. The file has all the related context about software and their versions. To process these, you can run `asdf install`.
