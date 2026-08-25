# ReServe

![ReServe](assets/banner-800w.jpeg)

**Table of Contents**

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [What is ReServe](#what-is-reserve)
- [Usage](#usage)
- [Config](#config)
- [Routes](#routes)
- [Interceptors](#interceptors)
  - [Built In Interceptors](#built-in-interceptors)
    - [cookie](#cookie)
    - [cors](#cors)
    - [remove-headers](#remove-headers)
    - [replace-body](#replace-body)
    - [replace-headers](#replace-headers)
    - [set-headers](#set-headers)
    - [set-response](#set-response)
- [HTTPS](#https)

<!-- END doctoc -->

## What is ReServe

ReServe is a server that acts as a reverse proxy, but can also alter the responses for things like secure cookies and redirects where the backend service provides domain names.

It supports either HTTP or HTTPS. It is designed for web developers who need to test against live APIs that don't support CORS for local development or utilize cookies that are locked to a domain or are secure.

---

## Usage

**Installing**

```bash
dart pub global activate reserve
```

**Running**

```bash
reserve [(-c || --config) configfile.yaml]
```

For more information on the configuration, see the [config](#config) section below.

---

## Config

The ReServe configuration has a search path. It utilizes a search path to locate the confiration which is:

1. If a `config` param is set, the file passed in that parameter.
1. `reserve.yaml` in the current directory.
1. `pubspec_overrides.yaml` in the current directory, utilizing the `reserve` key.
1. `pubspec.yaml` in the current directory, utilizing the `reserve` key.

**Schema**

| Key            | Default     | Example                           | Description                                                                                                                                                    |
| -------------- | ----------- | --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `host`         | `localhost` | `localhost.direct`                | The host name the server will listen on.                                                                                                                       |
| `port`         | `5433`      | `8080`                            | The port the server will listen on.                                                                                                                            |
| `log`          | `config`    | `finest`                          | The log level to emit server level events.                                                                                                                     |
| `origin`       | _n/a_       | `https://www.example.com`         | Used if this is a middleware proxy. The `origin` will be used as the origin, referer, and cookie domains when communicating between the caller and the target. |
| `proxy`        | _n/a_       | `localhost:8888`                  | Used if a web debugging proxy is being used to assist in debugging network issues. Omit otherwise.                                                             |
| `https`        | _n/a_       | See [HTTPS](#https)               | Include if, and only if, you wish ReServe to serve via HTTPS.                                                                                                  |
| `interceptors` | _n/a_       | See [Interceptors](#interceptors) | The list of interceptors to apply to all of the proxied requests and responses.                                                                                |

**Example**

```yaml
host: localhost
port: 8080
routes:
  /api/:
    log: fine
    redirect: https://api.example.com/
    interceptors:
      - type: cookie
        with:
          allow-secure: false
  /:
    log: warn
    redirect: https://www.example.com/
    interceptors:
      - type: remove-headers
        with:
          headers:
            - cache-control
            - pragma
      - type: cookie
        with:
          allow-secure: false
      - type: replace-body
        with:
          from: https://api.example.com
          replace: http://localhost:8080
```

---

## Routes

The routes are a key / value pair. The key is the path to listen on for the route. Every URL prefixed by that value will be matched to the route. In RegExp form, it's effectively `${key}.*`.

Routes are evaluated in order and the first match is used. If no route matches then a 404 will be thrown.

**Schema**

| Key            | Default  | Example                           | Description                                   |
| -------------- | -------- | --------------------------------- | --------------------------------------------- |
| `log`          | `config` | `finest`                          | The log level to emit server level events.    |
| `redirect`     | _n/a_    | `https://api.example.com`         | The URL to redirect the route to.             |
| `interceptors` | _n/a_    | See [Interceptors](#interceptors) | The interceptors to apply to just this route. |

---

## Interceptors

| Key    | Example  | Description                                  |
| ------ | -------- | -------------------------------------------- |
| `type` | `cookie` | The specific identifier for the interceptor. |
| `with` | _Map_    | The parameters to pass to the interceptor.   |

### Built In Interceptors

| Type              |      Request       |      Response      | Description                                                                                               |
| ----------------- | :----------------: | :----------------: | --------------------------------------------------------------------------------------------------------- |
| [cookie]          |        :x:         | :white_check_mark: | Alters the cookie headers to make them seem as if they are passed directly between the source and target. |
| [cors]            | :white_check_mark: | :white_check_mark: | Adds CORS related headers to requests and automatically handles OPTIONS calls.                            |
| [remove-headers]  | :white_check_mark: | :white_check_mark: | Removes a set of headers.                                                                                 |
| [replace-body]    |        :x:         | :white_check_mark: | Replaces text within the response body.                                                                   |
| [replace-headers] | :white_check_mark: | :white_check_mark: | Replaces the value of headers.                                                                            |
| [set-headers]     | :white_check_mark: | :white_check_mark: | Sets a mapping of key / value pairs on the request and/or response.                                       |
| [set-response]    |        :x:         | :white_check_mark: | Sets the entire response. Used mainly for mock responses.                                                 |

<!-- Links -->

[cookie]: #cookie
[cors]: #cors
[remove-headers]: #remove-headers
[replace-body]: #replace-body
[replace-headers]: #replace-headers
[set-headers]: #set-headers
[set-response]: #set-response

#### cookie

Performs cookie modifications to make it appear as if the cookies are sent directly between the source and target without any middleware.

**Parameters**

| Key            | Default | Description                                                                                                              |
| -------------- | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| `allow-secure` | `true`  | Set to `false` to remove the `Secure` attribute from `set-cookie` headers so that the cookies can be used by HTTP sites. |

#### cors

Automatically responds to `OPTIONS` based requests with CORS information and augments responses with the same CORS information.

**Parameters**

| Key                  | Default                                                                                          | Description                                                                                                |
| -------------------- | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- |
| `additional-headers` | `[]`                                                                                             | Convenience option to easily set additional headers in addition to the default headers.                    |
| `allow-credentials`  | `false`                                                                                          | Set to `true` to allow credentials to be sent from the client.                                             |
| `allow-headers`      | `accept, accept-encoding, accept-language, content-type, dnt, if-none-match, origin, user-agent` | Set to the base list of headers to allow. The `additional-headers` will be sent in addition to this value. |
| `allow-methods`      | `DELETE, GET, OPTIONS, PATCH, POST, PUT`                                                         | The list of methods to send to the client to be allowed.                                                   |
| `expose-headers`     | `[]`                                                                                             | Which response headers should be made available to scripts running in the browser.                         |
| `max-age`            | 24 Hours                                                                                         | Number of seconds the CORS request is valid for before a client should re-request.                         |

#### remove-headers

Removes the headers with the given keys from the request and / or response.

**Parameters**

| Key        | Default | Description                                 |
| ---------- | ------- | ------------------------------------------- |
| `headers`  | `[]`    | The set of case-insensitive keys to remove. |
| `request`  | `true`  | Alters the request headers when `true`.     |
| `response` | `true`  | Alters the response headers when `true`.    |

#### replace-body

Replaces all instances of `from` in the response body with the value in `replace`. No-ops when the body is not a textual content type.

**Parameters**

| Key       | Default | Description                                  |
| --------- | ------- | -------------------------------------------- |
| `from`    | _n/a_   | The value to find to replace.                |
| `replace` | _n/a_   | The replacement to apply to the found value. |

#### replace-headers

Replaces all instances of `from` in the headers with the value in `replace`.

**Parameters**

| Key        | Default | Description                                  |
| ---------- | ------- | -------------------------------------------- |
| `from`     | _n/a_   | The value to find to replace.                |
| `replace`  | _n/a_   | The replacement to apply to the found value. |
| `request`  | `true`  | Alters the request headers when `true`.      |
| `response` | `true`  | Alters the response headers when `true`.     |

#### set-headers

Sets the given headers on the request and / or response.

**Parameters**

| Key        | Default | Description                                 |
| ---------- | ------- | ------------------------------------------- |
| `headers`  | `{}`    | The key / value pair map of headers to set. |
| `request`  | `true`  | Alters the request headers when `true`.     |
| `response` | `true`  | Alters the response headers when `true`.    |

#### set-response

Performs cookie modifications to make it appear as if the cookies are sent directly between the source and target without any middleware.

**Parameters**

| Key           | Default | Description                                            |
| ------------- | ------- | ------------------------------------------------------ |
| `body`        | _n/a_   | The file name of the file to use as the response body. |
| `headers`     | `[]`    | The key / value pair map of headers to set.            |
| `status-code` | `200`   | The status code to set.                                |

---

## HTTPS

Information related to the security context that is built from a certificate chain and private key.

**Parameters**

| Key        | Description                                       |
| ---------- | ------------------------------------------------- |
| `certfile` | Path to the certificate chain file.               |
| `certpass` | Optional password for the certificate chain file. |
| `keyfile`  | Path to the private key file.                     |
| `keypass`  | Optional password for the private key file.       |
