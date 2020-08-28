# Configs.jl

## Opinionated tool for managing deployment configurations

Configurations are loaded by cascading overrides.  
These are defined in JSON files placed in a configurable folder location.

Further configurations can be added or overridden from your code.  
This allows for example, setting configurations after a database call.
```julia
Configs.set("database.connection.port", 3900)
```


The syntax for accessing configurations is minimal:
```julia
password = Configs.get("database.credentials.password")
```




**Immutability:**  
After the first call to ```Configs.get```, the configuration is immutable. Thus, you can not call ```set``` after calling ```get```. It will throw an error.

Conversely stated, you must complete all your ```set``` calls before accessing with ```get```.

## Installation
```bash
$> cd my/project/rootdir
$> julia --project=.
julia> ]
pkg> add Config
```
## Usage
```bash
#This is optional. The default config folder is expected to be at <my/project/rootdir>/config.
#Will throw an error if no valid config folder is found or provided
$> cd my/project/rootdir
$> mkdir config
```
```julia
using Config

#OPTIONAL custom init
Config.init(; config_key="MY_ENV", config_directory="relative_or_absolute/custom/configdirectory") 
# default config_key = "ENVIRONMENT"
# default config_directory = "<project rootdirectory>/config"

value = "item result from some database call"

Config.set("path.to.new", value)
Config.set("path.to.override", value)

newvalue = Config.get("path.to.new")
overriddenvalue = Config.get("path.to.override")

fromjsonvalue = Config.get("database.connection.port")
# OR
database = Config.get("database")
port = database.connection.port

# After the first call to get, the config is immutable, so:

Config.set("database.connection.port", 8000) # > Throws an error
```
Alternatively, a custom init can be defined through ENV:
```bash
$> cd my/project/rootdir

$> CONFIG_KEY=MY_ENV CONFIG_DIRECTORY=custom/configdirectory julia --project=. src/project.jl
```
```CONFIG_KEY``` defines which ```ENV``` key is used to state the deployment environment [development, staging, production, etc...]. The default is ```ENV["ENVIRONMENT"]```.
## JSON file definitions:

These provide cascading overrides in the order shown below: 

### [1] ```config/default.json```
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
### [2] ```config/<environment>.json```
Typically could be:
- development.json
- staging.json
- production.json
- testing.json

Define semi private, environment specific overrides. This would typically have a .gitignore exclusion, or be stored in a private repository only.


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
would merge the configuration defined in ```production.json```

### [3] ```config/custom-environment-variables.json```
Define private overides. This maps ENV variables to configuration variables.

```json
{
    "database": {
        "credentials": {
            "password": "DATABASE_PASSWORD"
        }
    }
}
```
Private variables are thus passed in explicitly by, for example, defining the environment variable in BASH.
```bash
DATABASE_PASSWORD=mysupersecretpasword julia --project=. src/myproject.jl
```

## Footnote
This is a methodology cloned from the excellent node.js [config](https://www.npmjs.com/package/config) package.