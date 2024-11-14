---
marp: true
# theme: gaia
class: invert
headingDivider: 1
---


# NixOps4


![bg left:40% 80%](nixops4.svg)

<!--
_class: invert lead
-->

- Why
- What
- How
- Demo

Robert Hensing
@roberth

fediversity.eu


# Why

2013 - 2020

- NixOps 1 is a tool to deploy NixOS systems
- Provisioning, secrets
- Also resources, e.g. AWS Route53
- Call Nix evaluator twice (bad(TM))

<!--
  calling the evaluator twice is not good enough
-->


# Why

NixOps 2

2020 - ...

- Plugins
- Polyrepo

# Why

NixOps 2

2020 - ...

![bg right:66% height:80%](nixops2.png)

<!--

I sincerely apologize to the authors and previous maintainers.
They did a good job with the architecture they had.

- Plugin system
- Ossified the architecture
-->

# Why

2022

@roberth

- Still the only tool that integrates provisioning


# Step back

Nix

```




┌────────────┐                      ┌────────────────────┐
│ Nix        │---- instantiate ---->│ Derivations        │ ↺ store path
│ expression │                      └────────────────────┘
│ language   │                                ⇑ builds
│            │                      ┌────────────────────┐
│            │                      │ Nix sandbox, store │
└────────────┘                      └────────────────────┘
```

<!--
  TODO: Explain firmly
-->

# Architecture

NixOps4

```
┌────────────┐                      ┌────────────────────┐
│ Nix        │---- configure ------>│ Resources          │ ↺ nix value
│ expression │                      └────────────────────┘
│ language   │                                ⇑ run output
│            │                      ┌────────────────────┐
│            │---- instantiate ---->│ Derivations        │ ↺ store path
│            │                      └────────────────────┘
│            │                                ⇑ builds
│            │                      ┌────────────────────┐
│            │                      │ Nix sandbox, store │
└────────────┘                      └────────────────────┘
```

<!--

How done is it?

Adds new layer on top

Focus on `nix value` => precisely that; no tight coupling between NixOps and its resources

NixOps4 just manages the data flows generically

Another benefit
 - resource can be implemented in any language, with any library

Not comparable to NixOps 2 architecture image. NixOps 2 is "just a script" that grew until it failed to scale and then ossified with plugins.

-->


# Resource

- Declares the existence of a real world object
- Operations
  - Create
  - Read
  - Update
  - Delete

# Deployment

Collection of resources
- wired together with Nix expressions
- reflecting some area of the real world

# Operations

- CRUD

- "`nix run`"
  - backup
  - key rotation

<!--
  a. Arbitrary callable methods in resource provider
  b. Scripts depending on resource outputs 
-->

# Resource Provider

- Program built with Nix
- Called by NixOps
- Talks an IPC protocol


# Expressions

Simplified

```nix
{ # flake.nix
  outputs = inputs: {
    nixops4Deployments.default = { resources, ... }: {
      resources = {
        <resource name> = {
          ...
        };
      };
    };
  };
}
```

<!-- These are very abstract. Clarify why. -->


# Expressions

```nix
{ resources, ... }: {
  resources = {
    "nixos" = {
      imports = [ inputs.nixos.modules.nixops4Resource.nixos ];
      inputs = {
        ssh.privateKey = resources.sshkeypair.privateKey;
        ssh.host = resources.host;
        module = ./configuration.nix;
      };
    };
  };
}
```

# Expressions

```nix
{ resources, ... }: {
  resources = {
    "nixos" = ...;
    "sshkeypair" = {
      type = "ssh.keypair";
      inputs = {
        state = resources.state;
      };
    };
  };
}
```

# Expressions

```nix
{ resources, ... }: {
  resources = {
    "nixos" = ...;
    "sshkeypair" = ...;
    "state" = {
      type = "s3.object";
      inputs = {
        endpoint = "https://garage.example.com";
        bucket = "nixops4-my-project";
      };
    };
  };
}
```

# Expressions

```nix
{ config, resources, ... }: {
  options.customers = mkOption {
    type = attrsOf (submodule ./customer.nix);
  };
  config.resources = {
    "state" = ...;
    "sshkeypair" = ...;
    "nixos" = ... (foo config.customers) ...;
  };
}
```

# Expressions

```nix
{ resources, ... }: {
  imports = [
    ./data-model.nix
    ./applications/pixelfed.nix
    ./applications/mastodon.nix
    ./applications/peertube.nix
  ];
}
```

# Expressions

- `resources` monoid in the category of endofunctors :wink:
- Structural composition like `attrsOf` or `submodule`
  - `imports` is mix-ins

```nix
top@{ resources, ... }: {
  resources = {
    "state" = ...;
    "my-host" = mkSequence ({ resources, ... }: {
      "sshkeypair" = ... top.resources.state.handle ...;
      "nixos" = ... resources.sshkeypair.privateKey ...;
    });
  };
}
```

# Module author benefits

- All-Nix development experience
- No glue code
- All declarative

# Application benefits

"NixPanel"

- Structured logging

- Separate evaluator for stability

# Operator benefits

CLI for the backend

Integrate arbitrary scripts, no glue code

# Operator benefits

# Caveats

TBD
- `mkSequence` nesting / data dependencies
- Read, Update, Delete
- More resources
  - OpenTofu

# Demo?

# Not discussed

- Resource naming within the state
  - read multiple => migrations

- `resourceProviderSystem`

# Process Architecture

- `nixops4`
  - `nixops4-eval` -> `libnixexpr` etc (internal)
  - resource providers
    - `nixops4-resources-local`
    - `nixops4-resources-opentofu` (planned)
    - ...
