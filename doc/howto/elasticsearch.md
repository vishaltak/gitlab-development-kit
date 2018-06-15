# Elasticsearch

GitLab Enterprise Edition has Elasticsearch integration. In this
document we explain how to set this up in your development
environment.

## Installation: macOS

### Docker install (recommended)

```
docker run --name elastic55 -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:5.5.3
```

after the container is up you can control it with `docker start elastic55` and `docker stop elastic55`

### Host install
We need version 5.5.3 at the most but brew does not have that version available anymore, so you need to use an old brew - 

```
brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/f1a767645f61112762f05e68a610d89b161faa99/Formula/elasticsearch.rb
```

There is no need to install any plugins

## Setup

1. Go to **Admin > Application Settings** to enable Elasticsearch.

1. Start Elasticsearch by either running `elasticsearch` in a new terminal, or
   by adding it to your `Procfile`:

    ```
    elasticsearch: elasticsearch
    ```

1. Be sure to restart the GDK's `foreman` instance if it's running.

1. Perform a manual update of the Elasticsearch indexes:

    ```sh
    cd gitlab-ee && bundle exec rake gitlab:elastic:index
    ```
