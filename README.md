# README

[https://www.aykuli.su/](https://www.aykuli.su/)

```mermaid
classDiagram
  class User {
    integer id
    string email
    string password_digest
  }

  class Role {
    integer id
    string code
    string title
  }

  User "1" *-- "1" Role: has
```

## Development

## Deployment
