print("LOAD_SOURCE:", debug.info(loadstring or load, "s"))
print("LOAD_NAME:", debug.info(loadstring or load, "n"))
print("ENV_KEYS:")
for k,v in pairs(getfenv()) do print(" - ", k) end
