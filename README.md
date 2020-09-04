# Configs.jl [![Build Status](https://travis-ci.org/citkane/Configs.svg?branch=master)](https://travis-ci.org/citkane/Configs) [![Coverage Status](https://coveralls.io/repos/github/citkane/Configs/badge.svg?branch=master)](https://coveralls.io/github/citkane/Configs?branch=master)

## Opinionated tool for managing deployment configurations

Deployment configurations are loaded by cascading overrides.
Overrides are inputed in order of:
1. Configuration files placed in a configurable folder location
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
julia> ]add Configs
```
## Usage
Create a ```configs``` directory in the project root.

The default configs folder is expected to be at `<project rootdir>/configs`.  
Configs will throw an error if no folder is found at the default path or a custom path is not explicitly provided.
```bash
$> cd my/project/rootdir
$> mkdir configs
```
OR..
```bash
$> cd my/project/rootdir
$> export DEPLOYMENT_KEY=MY_ENV
$> export CONFIGS_DIRECTORY="/opt/configs/myproject"
$> julia --project=. src/project.jl
```
OR...
```julia
using Configs

initconfig(; deployment_key="MY_ENV", configs_directory="customdir")
```
WHERE:

**`CONFIGS_DIRECTORY`** / **`configs_directory`**  
defines a custom path to the configs directory. This can be input as absolute path or relative to the project root. The default is ```<project root>/configs```

**`DEPLOYMENT_KEY`** / **`deployment_key`**    
defines which ```ENV``` key you intend to use to state the deployment environment [development, staging, production, etc...]. The default is ```ENV["DEPLOYMENT"]```.

Then manipulate and access your configs:
```julia
using Configs

value = myexternalcall(...)

setconfig!("path.to.new", value)
setconfig!("path.to.override", value)

newvalue = getconfig("path.to.new")
overriddenvalue = getconfig("path.to.override")

connection = getconfig("database.connection")
port = connection.port
# OR
conf = getconfig()
connection = conf.database.connection
port = connection.port
url = connection.url

if hasconfig("optional.setting")
    option = getconfig("optional.setting")
end

# After the first call to getconfig or hasconfig, configs are immutable, so:
setconfig!("database.connection.port", 8000) # Throws an error if called here
```

## File definitions:

Configurations can be independantly defined in any of the following file formats:
- JSON `.json`
- YAML `.yml`
- Julia `.jl`

These provide cascading overrides in the order shown below: 

### [1] `configs/`**default**`.yml`
Define public configs. This is suitable for eg. storing in a public code repository.
```yaml
timestamp: 2020-09-03T14:18:45.633
database:
    connection:
        url: "http://localhost"
        port: 3600
    credentials:
        username: "guest"
        password: "guestuserdefault"
otherstuff:
    defaultmessage: "Hello new user"
```
Configs does not support multi-doc yaml files.
### [2] `configs/`**\<deployment\>**`.jl`
Typically, would be:
- development.jl
- staging.jl
- production.jl
- testing.jl

Define semi private, deployment specific overrides. This would typically have a .gitignore exclusion, or be stored in a private repository only.

The file is named in lowercase to correspond with any `ENV["DEPLOYMENT"]` found at runtime. Thus, running:
```bash
$> export DEPLOYMENT=PrOdUcTiOn
$> julia --project=. src/myproject.jl
```
would merge the configuration defined in `production.jl`
```julia
(
    timestamp = now(),
    database = (
        connection = (
            url = "https://secureserver.me/staging",
            port = 3601,
        ),
        credentials = (
            username = "stagingadmin",
            pasword = "",
        )
    )
)
```
For `.jl` configuration files, any valid Julia collections [ `Array`, `Tuple`, `NamedTuple`, `Dict` ] may be used in any combination.

Valid `Dates` methods may be used in the configuration file.

### [3] `configs/`**custom-environment-variables**`.json`
Define private overrides. This maps ENV variables to configuration variables.

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
$> export DATABASE_PASSWORD=mysupersecretpasword
$> julia --project=. src/myproject.jl
```
```julia
using Configs
password = getconfig("database.credentials.password")
# password === "mysupersecretpasword"
```
## Advanced usaging
`setconfig!` has flexible input parameter types:
- Bool, Number, String
- JSON String
- Dict, Array
- Tuple, NamedTuple  

(with any depth / combination of nesting)
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
setconfig!("project", ( 
    credentials= ( 
        username="user",
        password="userpass",
    ), 
    pages=(1,2,3)
))

# Is the same as
setconfig!("project", Dict(
    :credentials => Dict(
        :username => "user",
        :password => "userpass"
    ),
    :pages => [1, 2, 3]
))

# Is the same as
setconfig!("project.credentials.username", "user")
setconfig!("project.credentials.password", "userpass")
setconfig!("project.pages", [1, 2, 3])
```
## Footnote
This is a deployment methodology cloned from the excellent node.js [config](https://www.npmjs.com/package/config) package.