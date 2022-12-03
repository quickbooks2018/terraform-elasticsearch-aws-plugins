locals {
  original_tags    = join(var.delimiter, compact(concat(tolist([var.namespace, var.name]), var.attributes)))
  transformed_tags = var.convert_case ? (local.original_tags) : local.original_tags
}

locals {
  id = var.enabled ? local.transformed_tags : ""

  name       = var.enabled ? (var.convert_case ? (format("%v", var.name)) : format("%v", var.name)) : ""
  namespace  = var.enabled ? (var.convert_case ? (format("%v", var.namespace)) : format("%v", var.namespace)) : ""
  delimiter  = var.enabled ? (var.convert_case ? (format("%v", var.delimiter)) : format("%v", var.delimiter)) : ""
  attributes = var.enabled ? (var.convert_case ? (format("%v", join(var.delimiter, compact(var.attributes)))) : format("%v", join(var.delimiter, compact(var.attributes)))) : ""

  tags = var.tags
}
