# ReServe

![ReServe](assets/banner-800w.jpeg)

## What is ReServe

ReServe is a server that acts as a reverse proxy, but can also alter the responses for things like secure cookies and redirects where the backend service provides domain names.

For HTTPS, one simple option is the [localhost.direct](https://github.com/Upinel/localhost.direct#a-self-signed-certificate--recommended) Self-Signed Certificate. The pre-built certificate is valid until 2034, and can be regenerated as needed. As of the time of writing this document, the Public CA Certificate is [currently expired](https://github.com/Upinel/localhost.direct/issues/22).
