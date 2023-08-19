## services\.faasd\.enable

Lightweight faas engine



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.package

Faasd package to use.



*Type:*
package



*Default:*
` <derivation faasd-0.18.0> `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.basicAuth\.enable

Enable basicAuth

*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.basicAuth\.passwordFile

Path to file containing password



*Type:*
null or string



*Default:*
` null `



*Example:*
` "/etc/nixos/faasd-basic-auth-password" `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.basicAuth\.user

Basic-auth user



*Type:*
string



*Default:*
` "admin" `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers

OCI (Docker) containers to run as additional services on faasd.



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.cap_add

See link: [Compose Specification#cap_add](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#cap_add)



*Type:*
list of string



*Default:*
` [ ] `



*Example:*

```
[
  "CAP_NET_RAW"
  "SYS_ADMIN"
]
```

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.command

See link: [Compose Specification#command](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#command)



*Type:*
null or unspecified value



*Default:*
` null `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.depends_on

See link: [Compose Specification#depends_on](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#depends_on)



*Type:*
list of string



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.entrypoint

See link: [Compose Specification#entypoint](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#entypoint)



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.environment

See link: [Compose Specification#environment](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#environment)



*Type:*
(attribute set of (string or signed integer)) or list of string



*Default:*
` { } `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.image

See link: [Compose Specification#image](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#image)



*Type:*
string

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.imageFile

Path to an image file to load instead of pulling from a registry.
If defined, do not pull from registry.
You still need to set the <literal>image</literal> attribute, as it
will be used as the image name for faasd to start a container.




*Type:*
null or package



*Default:*
` null `



*Example:*
` pkgs.dockerTools.buildImage {...}; `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.ports

See link: [Compose Specification#ports](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#ports)



*Type:*
list of unspecified value



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.user

See link: [Compose Specification#user](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#user)



*Type:*
null or string



*Default:*
` null `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.containers\.\<name>\.volumes

See link: [Compose Specification#volumes](https://github.com/compose-spec/compose-spec/blob/master/spec.md?/#volumes)



*Type:*
list of unspecified value



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.defaultQueue\.maxInflight

Number of messages sent to queue worker and how many functions are invoked concurrently.



*Type:*
signed integer



*Default:*
` 1 `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker.nix)



## services\.faasd\.defaultQueue\.writeDebug

Print verbose logs



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker.nix)



## services\.faasd\.gateway\.readTimeout

HTTP timeout for reading the payload from the client caller (in seconds).



*Type:*
signed integer



*Default:*
` 60 `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/gateway\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/gateway.nix)



## services\.faasd\.gateway\.scaleFormZero

Enables an intercepting proxy which will scale any function from 0 replicas to the desired amount



*Type:*
boolean



*Default:*
` true `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/gateway\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/gateway.nix)



## services\.faasd\.gateway\.upstreamTimeout

Maximum duration of HTTP call to upstream URL (in seconds).



*Type:*
signed integer



*Default:*
` 65 `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/gateway\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/gateway.nix)



## services\.faasd\.gateway\.writeTimeout

HTTP timeout for writing a response body from your function (in seconds)



*Type:*
signed integer



*Default:*
` 60 `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/gateway\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/gateway.nix)



## services\.faasd\.nameserver

Nameserver to use



*Type:*
string



*Default:*
` "8.8.8.8" `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.namespaces

Openfaas function namespaces.
Namespaces listed here will be created of they do not exist and labeled
with `openfaas=true`.




*Type:*
list of string



*Default:*
` [ ] `



*Example:*

```
[
  "dev"
]
```

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.pullPolicy

Set to "Always" to force a pull of images upon deployment, or "IfNotPresent" to try to use a cached image.




*Type:*
one of “Always”, “IfNotPresent”



*Default:*
` "Always" `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.queues



*Type:*
attribute set of (submodule)



*Default:*
` { } `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker.nix)



## services\.faasd\.queues\.\<name>\.maxInflight

Number of messages sent to queue worker and how many functions are invoked concurrently.



*Type:*
signed integer



*Default:*
` 1 `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker.nix)



## services\.faasd\.queues\.\<name>\.natsChannel

Nats channel to use for the queue. Defaults to the queue name.



*Type:*
string



*Default:*
` "‹name›" `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker.nix)



## services\.faasd\.queues\.\<name>\.writeDebug

Print verbose logs



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/core-services/queue-worker.nix)



## services\.faasd\.seedCoreImages

Seed faasd core images



*Type:*
boolean



*Default:*
` false `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.seedDockerImages

List of docker images to preload on system



*Type:*
list of (submodule)



*Default:*
` [ ] `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.seedDockerImages\.\*\.imageFile

Path to the image file.



*Type:*
package

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)



## services\.faasd\.seedDockerImages\.\*\.namespace

Namespace to use when seeding image.



*Type:*
string



*Default:*
` "openfaas" `

*Declared by:*
 - [/nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module\.nix](file:///nix/store/yhi091hky92nzqsb2r1vwmi36689jv6b-source/modules/faasd-module.nix)


