load("@ytt:struct", "struct")
load("@ytt:data", "data")


def deployment(service, environment):
    return service+"-"+environment.name.replace('/','-')
end

def merge_labels(fixed_values):
    labels = {}
    if hasattr(data.values.deliverable.metadata, "labels"):
        labels.update(data.values.deliverable.metadata.labels)
    end
    labels.update(fixed_values)
    labels.update("app.kubernetes.io/component", data.values.service.name)
    labels.update("app.kubernetes.io/part-of", data.values.application.name)
    labels.update("app.kubernetes.io/managed-by", "cartographer")
    return labels
end