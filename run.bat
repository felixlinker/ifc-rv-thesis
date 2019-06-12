set input=model/min-rv
bash -c "cpp %input%.smv > %input%.o.smv"
nuXmv.exe %* %input%.o.smv
