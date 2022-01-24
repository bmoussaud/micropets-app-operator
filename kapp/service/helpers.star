load("@ytt:struct", "struct")
load("@ytt:data", "data")


def deployment(service, environment):
    return "app-"+service+"-"+environment.name.replace('/','-')
end
