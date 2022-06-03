load("@ytt:struct", "struct")
load("@ytt:data", "data")


def deployment(service, environment):
    return service+"-"+environment.name.replace('/','-')
end

def gen_labels(fixed_values):    
    labels.update(fixed_values)
    labels.update("app.kubernetes.io/name", data.values.service.name)
    labels.update("app.kubernetes.io/component", data.values.service.component)
    labels.update("app.kubernetes.io/part-of", data.values.application.name)
    labels.update("app.kubernetes.io/managed-by", "cartographer")
    return labels
end