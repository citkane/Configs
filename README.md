# Configs.jl [![Build Status](https://travis-ci.org/citkane/Configs.svg?branch=master)](https://travis-ci.org/citkane/Configs) [![Coverage Status](https://coveralls.io/repos/github/citkane/Configs/badge.svg?branch=master)](https://coveralls.io/github/citkane/Configs?branch=master)

## Opinionated tool for managing deployment configurations

Deployment configurations are loaded by cascading overrides.
Overrides are inputed in order of:
1. JSON files placed in a configurable folder location
2. ENV variable mapping
3. Function calls
  
The syntax for accessing configurations:
```julia
using Configs
password = getconfig("database.credentials.password")
username = getconfig("database.credentials.username")
# OR
credentials = getconfig("database.credentials")
username = credentials.username
password = credentials.password
```

Accessing non-existent configurations will throw an error, so:
```julia
using Configs
if hasconfig("optional.setting")
    setting = getconfig("optional.setting")
end
```
Setting configurations from external sources:
```julia
using Configs
port = myexternalcall(...)
setconfig!("database.connection.port", port)
```

**Immutability:**  
After the first call to ```getconfig``` or ```hasconfig```, the configuration is immutable. Thus, you can not call ```setconfig!``` after calling ```getconfig``` or ```hasconfig```. It will throw an error.

Conversely stated, you must complete all your ```setconfig!``` calls before accessing with ```getconfig``` or ```hasconfig```.

## Installation
```bash
$> cd my/project/rootdir
$> julia --project=.
julia> ]
pkg> add Configs
```
## Usage
OPTIONAL: Create a ```configs``` directory in the project root
```bash
#The default configs folder is expected to be at <my/project/rootdir>/configs.
#Will throw an error if no valid configs folder is found or provided
$> cd my/project/rootdir
$> mkdir configs
```
OPTIONAL custom init
```bash
$> cd my/project/rootdir

$> DEPLOYMENT_KEY=MY_ENV CONFIGS_DIRECTORY=custom/configdirectory julia --project=. src/project.jl
```
**```CONFIGS_DIRECTORY```** defines a custom path to the configs directory. This can be input as absolute or relative to the project root. The default is ```<project root>/configs```

**```DEPLOYMENT_KEY```** defines which ```ENV``` key you intend to use to state the deployment environment [development, staging, production, etc...]. The default is ```ENV["DEPLOYMENT"]```.

OR...
```julia
using Configs

initconfig(; deployment_key="MY_ENV", configs_directory="relative_or_absolute/custom/configdirectory") 
# default deployment_key = "DEPLOYMENT"
# default configs_directory = "<project rootdirectory>/configs"
```
Then manipulate and access your configs:
```julia
using Configs

value = myexternalcall(...)

setconfig!("path.to.new", value)
setconfig!("path.to.override", value)

newvalue = getconfig("path.to.new")
overriddenvalue = getconfig("path.to.override")

port = getconfig("database.connection.port")
# OR
database = getconfig("database")
connection = database.connection
port = connection.port
url = connection.url

if hasconfig("optional.setting")
    option = getconfig("optional.setting")
end

# After the first call to getconfig or hasconfig, configs are immutable, so:
setconfig!("database.connection.port", 8000) # Throws an error if called here
```

## JSON file definitions:

These provide cascading overrides in the order shown below: 

### [1] ```configs/default.json```
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
### [2] ```configs/<deployment>.json```
Typically, would be:
- development.json
- staging.json
- production.json
- testing.json

Define semi private, deployment specific overrides. This would typically have a .gitignore exclusion, or be stored in a private repository only.


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
The file is named in lowercase to correspond with any ```ENV["DEPLOYMENT"]``` found at runtime. Thus, running:
```bash
DEPLOYMENT=PrOdUcTiOn julia --project=. src/myproject.jl
```
would merge the configuration defined in ```production.json```

### [3] ```configs/custom-environment-variables.json```
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
```julia
using Configs
password = getconfig("database.credentials.password")
# password === "mysupersecretpasword"
```
## Advanced usaging
setconfig! is flexible and takes many input parameter types:
- Bool, Number, String
- JSON String
- Dict, Array
- Tuple, NamedTuple (with any depth / combination of nesting)
```julia
using Configs
# Thus
setconfig!("project", """{
    "credentials": {
        "username": "user",
        "password": "userpass"
    },
    "pages": [1, 2, 3]
}""")

# Is the same as
setconfig!("project", (; credentials= (; username="user", password="userpass"), pages=(1,2,3))

# Or

setconfig!("project", Dict(
    :credentials => Dict(
        :username => "user",
        :password => "userpass"
    ),
    :pages => [1, 2, 3]
))
```
## Footnote
This is a deployment methodology cloned from the excellent node.js [config](https://www.npmjs.com/package/config) package.