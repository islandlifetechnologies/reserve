# ReServe

## What is ReServe

ReServe is a server that acts as a reverse proxy, but can also alter the responses for things like secure cookies and redirects where the backend service provides domain names.

For HTTPS, ReServe recomments the wonderful [localhost.direct](https://github.com/Upinel/localhost.direct) project. That greatly simplifies creating a cert for locally running servers w/o requiring any sort of certificate trust to be added to your development environment.
