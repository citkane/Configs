# Configs.jl

## Opinionated tools for managing code deployment configurations

Configurations are loaded by cascading over-rides, managed through JSON file definitions placed in a configurable system folder. The syntax for accessing configurations is minimal:
```julia
password = Configs.get("database.credentials.password")
```

Further configurations can be added or overidden from your code:
```julia
Configs.set("database.connection.port", 3900)
```
This allows for example, loading configurations from a database and using them during runtime.

**Immutability:**  
After the first call to ```Configs.get```, the configuration becomes immutable. Thus, you can not call ```set``` after calling ```get```.

Conversely, you must make all you ```set``` calls before accessing any configuration with ```get```.

## JSON file definitions:
### ```default.json```
Define public configs. This is suitable for eg. storing in a public code repository.
```json
{
    "database": {
        "connection": {
            "url": "http://localhost",
            "port": 3600
        },
        "credentials": {
            "username": "guest",
            "password": "guestuserdefault"
        }
    },
    "otherstuff": {
        "defaultmessage": "Hello new user"
    }
}
```
### ```<environment>.json```
Typically could be:
- development.json
- staging.json
- production.json
- testing.json

Define semi private, environment specific overides. This would typically have a .gitignore entry, or be stored in a private repository only.


```json
{
    "database": {
        "connection": {
            "url": "https://secureserver.me/staging",
            "port": 3601
        },
        "credentials": {
            "username": "stagingadmin",
            "password": ""
        }
    }
}
```
The file is named in lowercase to correspond with any ```ENV["ENVIRONMENT"]``` found at runtime. Thus, running:
```bash
ENVIRONMENT=PrOdUcTiOn julia --project=. src/myproject.jl
```
would provide the overides defined in ```production.json```

### ```custom-environment-variables.json```
Define private overides. This maps ENV variables to configuration variables.

```json
{
    "database": {
        "connection": {
            "url": "DATABASE_URL",
            "port": "DATABASE_PORT"
        },
        "credentials": {
            "username": "DATABASE_USERNAME",
            "password": "DATABASE_PASSWORD"
        }
    }
}
```
Private variables are thus passed in explicitly by, for example, defining the environment variable in BASH.
```bash
DATABASE_PASSWORD=supersecretpasword julia --project=. src/myproject.jl
```