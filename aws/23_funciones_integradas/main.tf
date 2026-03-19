############################
# VARIABLES DE APOYO
############################

variable "project_name" {
  default = "demoProject"
}

variable "regions" {
  default = ["eu-west-1", "eu-west-2", "eu-west-3"]
}

variable "names" {
  default = ["app", "api", "worker"]
}

variable "environment_string" {
  default = "demo-dev-eu"
}

variable "default_tags" {
  default = {
    ManagedBy = "terraform"
    Owner     = "team-dev"
  }
}

variable "extra_tags" {
  default = {
    Environment = "dev"
  }
}

variable "allowed_envs" {
  default = ["dev", "staging", "prod"]
}

variable "environment" {
  default = "dev"
}

locals {
  numbers         = [1, 2, 3, 4, 5]
  bools           = [true, true, false]
  names_with_gaps = ["app", "", "api", null, "worker"]
  nested_list     = [["a", "b"], [], ["c", ["d", "e"]]]
  map_a           = { a = 1, b = 2 }
  map_b           = { b = 20, c = 30 }
  set_a           = toset(["dev", "staging"])
  set_b           = toset(["staging", "prod"])
  string_sample   = "  hello terraform  "
  csv_text        = <<-EOT
name,env
app,dev
api,prod
EOT

  json_text = jsonencode({
    project = "demo"
    env     = "dev"
  })

  yaml_text = <<-EOT
project: demo
env: dev
EOT

  base_ts = "2026-03-19T10:30:00Z"
}

############################
# 1) FUNCIONES NUMÉRICAS
############################

output "num_ceil" {
  value = ceil(10.2)
}

output "num_floor" {
  value = floor(10.8)
}

output "num_log" {
  value = log(8, 2)
}

output "num_max" {
  value = max(10, 50, 3, 21)
}

output "num_min" {
  value = min(10, 50, 3, 21)
}

output "num_parseint" {
  value = parseint("FF", 16)
}

output "num_pow" {
  value = pow(2, 5)
}

output "num_signum_negative" {
  value = signum(-25)
}

############################
# 2) FUNCIONES DE STRING
############################

# Originales
output "project_upper" {
  value = upper(var.project_name)
}

output "project_lower" {
  value = lower(var.project_name)
}

output "service_list" {
  value = join("-", var.names)
}

output "environment_parts" {
  value = split("-", var.environment_string)
}

# Resto
output "str_chomp" {
  value = chomp("linea con salto\n")
}

output "str_endswith" {
  value = endswith("main.tf", ".tf")
}

output "str_format" {
  value = format("app=%s env=%s replicas=%02d", "demo", "dev", 3)
}

output "str_formatlist" {
  value = formatlist("srv-%s", ["app", "api", "worker"])
}

output "str_indent" {
  value = indent(4, "linea1\nlinea2\nlinea3")
}

output "str_regex" {
  value = regex("([a-z]+)([0-9]+)", "app01")
}

output "str_regexall" {
  value = regexall("[a-z]+", "app01-api02-worker03")
}

output "str_replace" {
  value = replace("app-dev-app", "app", "svc")
}

output "str_startswith" {
  value = startswith("terraform-demo", "terra")
}

output "str_contains" {
  value = strcontains("terraform-demo", "demo")
}

output "str_reverse" {
  value = strrev("abcd")
}

output "str_substr" {
  value = substr("terraform", 0, 4)
}

locals {
  template_saludo = "Hola $${name}, entorno=$${env}"
}

output "str_templatestring" {
  value = templatestring(local.template_saludo, {
    name = "equipo"
    env  = "dev"
  })
}

output "str_title" {
  value = title("hola mundo terraform")
}

output "str_trim" {
  value = trim("...demo...", ".")
}

output "str_trimprefix" {
  value = trimprefix("env-dev", "env-")
}

output "str_trimsuffix" {
  value = trimsuffix("main.tf", ".tf")
}

output "str_trimspace" {
  value = trimspace(local.string_sample)
}

############################
# 3) FUNCIONES DE COLECCIONES
############################

# Originales
output "region_count" {
  value = length(var.regions)
}

output "all_tags" {
  value = merge(var.default_tags, var.extra_tags)
}

output "is_valid_environment" {
  value = contains(var.allowed_envs, var.environment)
}

# Resto
output "col_alltrue" {
  value = alltrue([true, true, true])
}

output "col_anytrue" {
  value = anytrue(local.bools)
}

output "col_chunklist" {
  value = chunklist(["a", "b", "c", "d", "e"], 2)
}

output "col_coalesce" {
  value = coalesce(null, "", "valor-final")
}

output "col_coalescelist" {
  value = coalescelist([], [], ["ok"])
}

output "col_compact" {
  value = compact(local.names_with_gaps)
}

output "col_concat" {
  value = concat(["app"], ["api"], ["worker"])
}

output "col_distinct" {
  value = distinct(["dev", "prod", "dev", "staging"])
}

output "col_element" {
  value = element(["a", "b", "c"], 4) # wrap-around => "b"
}

output "col_flatten" {
  value = flatten(local.nested_list)
}

output "col_index" {
  value = index(["dev", "staging", "prod"], "staging")
}

output "col_keys" {
  value = keys({ app = 1, api = 2, worker = 3 })
}

# deprecated: list()
# usar tolist([...]) en su lugar

output "col_lookup" {
  value = lookup({ dev = "small", prod = "large" }, "prod", "unknown")
}

# deprecated: map()
# usar tomap({...}) en su lugar

output "col_matchkeys" {
  value = matchkeys(
    ["vm-a", "vm-b", "vm-c"],
    ["dev", "prod", "dev"],
    ["dev"]
  )
}

output "col_one" {
  value = one(["solo-uno"])
}

output "col_range" {
  value = range(1, 10, 2)
}

output "col_reverse" {
  value = reverse(["a", "b", "c"])
}

output "col_setintersection" {
  value = setintersection(local.set_a, local.set_b)
}

output "col_setproduct" {
  value = setproduct(["dev", "prod"], ["eu-west-1", "eu-west-2"])
}

output "col_setsubtract" {
  value = setsubtract(local.set_a, local.set_b)
}

output "col_setunion" {
  value = setunion(local.set_a, local.set_b)
}

output "col_slice" {
  value = slice(["a", "b", "c", "d"], 1, 3)
}

output "col_sort" {
  value = sort(["worker", "api", "app"])
}

output "col_sum" {
  value = sum(local.numbers)
}

output "col_transpose" {
  value = transpose({
    admin = ["alice", "bob"]
    dev   = ["bob", "carol"]
  })
}

output "col_values" {
  value = values({ app = "10.0.0.10", api = "10.0.0.20" })
}

output "col_zipmap" {
  value = zipmap(["app", "api", "worker"], ["10.0.1.10", "10.0.1.20", "10.0.1.30"])
}

############################
# 4) FUNCIONES DE ENCODING
############################

output "enc_base64decode" {
  value = base64decode("SG9sYSBUZXJyYWZvcm0=")
}

output "enc_base64encode" {
  value = base64encode("Hola Terraform")
}

output "enc_base64gzip" {
  value = base64gzip("texto que será comprimido y codificado")
}

output "enc_csvdecode" {
  value = csvdecode(local.csv_text)
}

output "enc_jsondecode" {
  value = jsondecode(local.json_text)
}

output "enc_jsonencode" {
  value = jsonencode({
    app = "demo"
    env = "dev"
  })
}

output "enc_textdecodebase64" {
  value = textdecodebase64("SG9sYQ==", "UTF-8")
}

output "enc_textencodebase64" {
  value = textencodebase64("Hola", "UTF-8")
}

output "enc_urlencode" {
  value = urlencode("app demo/env=dev")
}

output "enc_yamldecode" {
  value = yamldecode(local.yaml_text)
}

output "enc_yamlencode" {
  value = yamlencode({
    app = "demo"
    env = "dev"
  })
}

############################
# 5) FUNCIONES DE FILESYSTEM
############################
# Estas requieren archivos reales dentro del módulo.

output "fs_abspath" {
  value = abspath("${path.module}/templates/app.conf")
}

output "fs_dirname" {
  value = dirname("${path.module}/templates/app.conf")
}

output "fs_pathexpand" {
  value = pathexpand("~/terraform-demo")
}

output "fs_basename" {
  value = basename("${path.module}/templates/app.conf")
}

# Requiere que exista el archivo
output "fs_file" {
  value = file("${path.module}/templates/app.conf")
}

output "fs_fileexists" {
  value = fileexists("${path.module}/templates/app.conf")
}

output "fs_fileset" {
  value = fileset("${path.module}/templates", "*.tftpl")
}

output "fs_filebase64" {
  value = filebase64("${path.module}/templates/app.conf")
}

output "fs_templatefile" {
  value = templatefile("${path.module}/templates/app.tftpl", {
    app = "demo"
    env = "dev"
  })
}

############################
# 6) FUNCIONES DE FECHA Y HORA
############################

output "time_formatdate" {
  value = formatdate("YYYY-MM-DD hh:mm ZZZ", local.base_ts)
}

# Devuelve el momento en que se creó el plan
output "time_plantimestamp" {
  value = plantimestamp()
}

output "time_timeadd" {
  value = timeadd(local.base_ts, "2h30m")
}

output "time_timecmp" {
  value = timecmp("2026-03-19T10:00:00Z", "2026-03-19T11:00:00Z")
}

# Devuelve la hora actual
output "time_timestamp" {
  value = timestamp()
}

############################
# 7) HASH Y CRYPTO
############################

output "hash_base64sha256" {
  value = base64sha256("terraform")
}

output "hash_base64sha512" {
  value = base64sha512("terraform")
}

output "hash_bcrypt" {
  value = bcrypt("super-secret-password")
}

# Requieren archivos reales
output "hash_filebase64sha256" {
  value = filebase64sha256("${path.module}/templates/app.conf")
}

output "hash_filebase64sha512" {
  value = filebase64sha512("${path.module}/templates/app.conf")
}

output "hash_filemd5" {
  value = filemd5("${path.module}/templates/app.conf")
}

output "hash_filesha1" {
  value = filesha1("${path.module}/templates/app.conf")
}

output "hash_filesha256" {
  value = filesha256("${path.module}/templates/app.conf")
}

output "hash_filesha512" {
  value = filesha512("${path.module}/templates/app.conf")
}

output "hash_md5" {
  value = md5("terraform")
}

# Requiere ciphertext RSA real y clave privada PEM válida
# output "hash_rsadecrypt" {
#   value = rsadecrypt(
#     "BASE64_RSA_CIPHERTEXT_AQUI",
#     file("${path.module}/keys/private.pem")
#   )
# }

output "hash_sha1" {
  value = sha1("terraform")
}

output "hash_sha256" {
  value = sha256("terraform")
}

output "hash_sha512" {
  value = sha512("terraform")
}

output "hash_uuid" {
  value = uuid()
}

output "hash_uuidv5" {
  value = uuidv5("dns", "example.com")
}

############################
# 8) RED / CIDR
############################

output "ip_cidrhost" {
  value = cidrhost("10.0.1.0/24", 10)
}

output "ip_cidrnetmask" {
  value = cidrnetmask("10.0.1.0/24")
}

output "ip_cidrsubnet" {
  value = cidrsubnet("10.0.0.0/16", 8, 2)
}

output "ip_cidrsubnets" {
  value = cidrsubnets("10.0.0.0/16", 4, 4, 4)
}

############################
# 9) CONVERSIÓN / CONTROL DE TIPOS
############################

output "type_can_true" {
  value = can(regex("[0-9]+", "abc123"))
}

# ephemeralasnull necesita un valor efímero real; ejemplo de sintaxis ilustrativa:
# output "type_ephemeralasnull" {
#   value = ephemeralasnull(<valor_efimero>)
# }

output "type_issensitive" {
  value = issensitive(sensitive("mi-secreto"))
}

output "type_nonsensitive" {
  value = nonsensitive(sensitive("mi-secreto"))
}

output "type_sensitive" {
  value     = sensitive("mi-secreto")
  sensitive = true
}

output "type_tobool" {
  value = tobool("true")
}

output "type_tolist" {
  value = tolist(toset(["a", "b", "c"]))
}

output "type_tomap" {
  value = tomap({
    app = "demo"
    env = "dev"
  })
}

output "type_tonumber" {
  value = tonumber("42")
}

output "type_toset" {
  value = toset(["dev", "dev", "prod"])
}

output "type_tostring" {
  value = tostring(12345)
}

output "type_try" {
  value = try(
    local.map_a["clave_inexistente"],
    "valor-por-defecto"
  )
}

############################
# 10) FUNCIONES provider::terraform::*
############################
# Requieren el provider hashicorp/terraform

output "tf_provider_encode_tfvars" {
  value = provider::terraform::encode_tfvars({
    app      = "demo"
    env      = "dev"
    replicas = 2
  })
}

output "tf_provider_decode_tfvars" {
  value = provider::terraform::decode_tfvars(<<-EOT
app      = "demo"
env      = "dev"
replicas = 2
EOT
  )
}

output "tf_provider_encode_expr" {
  value = provider::terraform::encode_expr({
    app      = "demo"
    env      = "dev"
    replicas = 2
    tags     = merge(var.default_tags, var.extra_tags)
  })
}