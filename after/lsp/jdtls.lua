local java_home = require("utils.platform").jdtls_java_home()

-- Preserve the upstream workspace launcher while selecting an available modern JDK.
return { cmd_env = java_home and { JAVA_HOME = java_home } or nil }
