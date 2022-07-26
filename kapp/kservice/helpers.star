load("@ytt:struct", "struct")
load("@ytt:data", "data")


def deployment(service, environment):
    return service+"-"+environment.name.replace('/','-')
end

def gen_labels(fixed_values):  
    labels = {}
    labels.update(fixed_values)
    labels["app.kubernetes.io/name"]=data.values.service.name
    labels["app.kubernetes.io/component"]=data.values.service.component
    labels["micropets/kind"]=data.values.service.component
    labels["app.kubernetes.io/part-of"]= data.values.application.name
    labels["app.kubernetes.io/managed-by"]="cartographer"
    return labels
end