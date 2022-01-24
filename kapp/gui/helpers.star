load("@ytt:struct", "struct")
load("@ytt:data", "data")


def deployment(service, environment):
    return service+"-"+environment.name.replace('/','-')
end
