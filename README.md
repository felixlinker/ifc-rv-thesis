
# ifc-rv-thesis

This repository holds the master thesis of me, Felix Linker, and the code that comes with it.
The thesis is about information flow tracking for instruction set architectures using model checking.
I apply my approach to the RISC-V ISA.

This is the abstract of the thesis:

> This thesis proposes an approach to formally verifying instruction set architectures against higher level properties using the model checker nuXmv.
This was first proposed by [2].
The model checker nuXmv is used to perform information flow tracking in the architecture, thus the higher level properties will be given by information flow properties.
The concepts behind information flow tracking stem from [1] where information flow control was applied to hardware description languages.
>
> The threat model that is assumed in this thesis is that user-mode is adversarial to machine-mode and completely compromised.
In this scenario, it is considered whether a) user-mode can gain access to confidential data held by machine-mode and b) user-mode can gain control over machine-mode.
> Timing channels are excluded.
>
> Throughout the course of this thesis, aforementioned approach will be applied to a simplified version of the RISC-V architecture, the MINRV8 architecture.
Three information flow properties applying to this architecture will be developed and verified using nuXmv.
The result of this are eight assumptions that grant the absence of any information flow property violation by any program running on the MINRV8 architecture.
These results are tested by showing that our approach can detect the cache poisoning [3] and SYSRET vulnerabilities [4,5] applying to the x86 architecture without any manual intervention besides the implementation of the vulnerabilities.

For a more thorough introduction, I direct the reader to the thesis itself.
Compiled versions of the thesis can be found in the [release tab](https://github.com/felixlinker/ifc-rv-thesis/releases).

## Tools used & setup

### nuXmv

I use a model of a simplified RISC-V ISA written in nuXmv.
In order to run the proofs you will need to install nuXmv (cf. https://nuxmv.fbk.eu).

### pyexpander

nuXmv is a very lightweight language that has very few features to make life of programmers easier.
Therefore I used the `pyexpander` macro engine to make the model more flexible and less redundant.
You will need to preprocess the model with `expander.py -s`.

Additionally, the model supports dynamic assumptions and optional extensions.
These can be enabled by setting corresponding variables to `True`.
All assumptions and options can be found at the head of the model file, where default values are assigned to the corresponding variables.

Cf. http://pyexpander.sourceforge.net for more information on `pyexpander`.

### smvtrcviz

When nuXmv finds a property to be false, it generates a counter-example.
These counter-examples can be given in various forms, one of which is XML.
I wrote a command-line-tool that converts a trace given in XML into an HTML-table that can be looked at more easily.
This tool is completely optional but I found it to be very helpful.
You can find it under https://github.com/felixlinker/smvtrcviz.

## Structure of the repository

File/Folder             | Description
----------------------- | -----------
`README.md`             | You are reading this file
`mk-results.ps1`        | A script to generate counter-examples for the thesis by subsequently invoking the `trace.ps1` script
`model-fix-count.ps1`   | A PowerShell script that counts the number of commits that changed the `model/min-rv.smv` and contain the word "fix"; this number is used in the discussion section of my thesis
`trace-bmc.template`    | Template file that holds commands for nuXmv to run proofs; must be preprocessed with `pyexpander`
`trace.ps1`             | PowerShell-script that runs proofs, e.g. invokes `expander.py` and handles templating
`model/min-rv.smv`      | The actual model
`model/partial/`        | Other auxiliary proofs and helper files
`results/`              | nuXmv traces mapped to HTML and LaTeX tables
`thesis/`               | The thesis written in LaTeX
`thesis/sections/`      | Individual sections of the thesis

## Running the proofs

I wrote a runner script for PowerShell.
The syntax isn't too complicated so if you want to come up with a runner script for your platform, e.g. `trace.sh` please take the `.ps1` script as an example.

Also, `model/min-rv.smv` contains some inline documentation that should be helpful.

`trace.ps1` assumes that you have set python files to be executable in the PowerShell and that python files are associated with `python.exe`.
This can be done by adding the following line to your profile file (cf. https://superuser.com/questions/437790/run-python-scripts-in-powershell-directly/):
```ps
$env:PATHEXT += ";.py"
```

# References

```
1. Andrew Ferraiuolo, Rui Xu, Danfeng Zhang, Andrew C. Myers, and G. Edward Suh. 2017. Verification of a Practical Hardware Security Architecture Through Static Information Flow Analysis. SIGPLAN Not. 52, 4 (April 2017), 555–568. DOI:https://doi.org/10.1145/3093336.3037739

2. Alastair Reid. 2017. Who guards the guards? formal validation of the Arm v8-m architecture specification. Proc. ACM Program. Lang. 1, OOPSLA, Article 88 (October 2017), 24 pages. DOI:https://doi.org/10.1145/3133912

3. Rafal Wojtczuk, Joanna Rutkowska. 2009. Attacking SMM Memory via Intel CPU Cache Poisoning. https://invisiblethingslab.com/resources/misc09/smm_cache_fun.pdf

4. CVE-2012-2017. 2012. https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2012-0217

5. George Dunlap. The Intel Sysret Privilege Escalation. 2012. https://xenproject.org/2012/06/13/the-intel-sysret-privilege-escalation/
```
