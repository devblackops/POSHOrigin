ConvertFrom-StringData -StringData @'

gpd_begin = Get-POSHDefault(): beginning
gpd_looking_for_config = Looking for {0}
gpd_config_not_found = Unable to resolve configuration [{0}]
gpd_end = Get-POSHDefault(): ending

gpoc_invalid_path = Invalid path [{0}]

gpos_cache_hit = Found credential [{0}] in cache
gpos_unknown_resolver = Unknown resolver [{0}]. Known resolvers are [{1}]

init_begin = Initialize-POSHOrigin(): beginning
init_create_repo = Creating POSHOrigin configuration repository: {0}
init_repo_already_exists = POSH origin configuration repository appears to already be created at [{0}]
init_end = Initialize-POSHOrigin(): ending

ipo_begin = Invoke-POSHOrigin(): beginning
ipo_makeitso = Making it so!`n
ipo_mof_generated = MOF file generated at {0}
ipo_should_msg = POSHOrigin configuration
ipo_mof_failure = Failed to create MOF file
ipo_end = Invoke-POSHOrigin(): ending

npor_resolved_defaults = {0} - Resolved defaults to [{1}]

nporff_module_not_found = Unable to find module: {0}
nporff_no_source = Module does not contain a source property

cc_begin = _CompileConfig(): beginning
cc_end = _CompileConfig(): ending
cc_dot_sourcing_config = Dot sourcing [{0}] configuration from [{1}]
cc_generating_config = Generating config for: [{0}]({1})

gh_file_not_found = File not found
gh_file_read_error = File not found or without permisions: [{0}]. {1}
gh_file_hash_error = Error reading or hashing the file: [{0}]

go_file_not_found = Unable to find [{0}]
go_config_folder_not_found = Undable to find POSHOrigin configuration folder at [{0}]

lc_processing_file = Processing file {0}
lc_processing_resource = Processing resource {0}
lc_processing_secret = Processing secret {0}.{1}
lc_cache_hit = Found credential [{0}] in cache

mo_index_not_hashtable = Index {0} is not of type [hashtable]

lcm_configuring_lcm = Configuring DSC LCM...
lcm_configuring_wsman = Configuration WSMAN...
lcm_configuring_trusted_hosts = Setting WSMan:\\localhost\\Client\\TrustedHosts to [*]

sbd_cyclic_error = Cyclic dependency found! Adjust resource dependencies via the 'DependsOn' property

rslv_passwordstate_begin = PasswordState resolver: beginning
rslv_passwordstate_resolving = Resolving credential for {0}
rslv_passwordstate_got_cred = Got credential for [{0}] - [{1}) - ********]
rslv_passwordstate_fail = Unable to resolve credential for password Id [{0}] and API key [{1}]
rslv_passwordstate_mod_missing = Unable to find required module [PasswordState] on system
rslv_passwordstate_end = PasswordState resolver: ending

rslv_pscredential_begin = PSCredential resolver: beginning
rslv_pscredential_got_cred = Got credential for [{0}] - ********]
rslv_pscredential_end = PSCredential resolver: ending

rslv_protecteddata_begin = ProtectedData resolver: beginning
rslv_protecteddata_end = PSCredential resolver: ending
'@
