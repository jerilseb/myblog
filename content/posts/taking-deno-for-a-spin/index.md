+++
title = "Taking Deno for a spin"
description = "Write a Linux shell using go programming language"
tags = [
    "deno",
    "typescript"
]
date = "2019-12-04"
categories = [
    "Deno",
]
draft = true
+++

I've been hearing about [Deno](https://github.com/denoland/deno) for quite a while in the dev circles, and decided it take it for a spin. But what's Deno anyway?

> TLDR; Deno is a TypeScript runtime, based on Google's V8 engine, developed with the Rust language, and uses Tokio library for the event-loop.

Deno was presented by Ryan Dahl, the creator of Node.js at the European JSConf in June 2018 in a talk named '10 things I regret about Node.js'

{{< youtube M3BM9TB-8yA >}}

<br/>

Being a node lover, this exactly wasn't music to my ears. Below are some of the key things Ryan pointed out in this talk.

* Node.js core uses callbacks everywhere at the expense of the Promise API that was present in the first versions of V8.

* Node programs cannot be run in a secure sandbox despite V8 being a secure sandox itself. Any node application can access disk, network, environment variables etc.

* The dependency manager, NPM, intrinsically linked to the Node require system. NPM modules are stored, until now, on a single centralized service and managed by a private company.

* The node_modules folder became much [too heavy](http://i.imgur.com/lrgCHVu.jpg) and complex with the years making the module resolution algorithm complicated. And above all, the use of node_modules and the require mentioned above is a divergence of the standards established by browsers.

* The require syntax omitting .js extensions in files, which, like the last point, differs from the browser standard. In addition, the module resolution algorithm is forced to browse several folders and files before finding the requested module.

* The entry point named index.js became useless after the require became able to support the package.json file

<br>

## Installation

Installing Deno is just one command

```
# Shell
curl -fsSL https://deno.land/x/install/install.sh | sh

# Homebrew
brew install deno
```

You can test whether Deno is installed correctly using the simple command <br/>
`deno https://deno.land/std/examples/welcome.ts`.


One of the strengths of Deno immediately becomes apparent here. We can directly refer files over the network by their urls. On the first run, Deno will download the files and cache it for subsequent runs. Now moving onto something more functional, let's write a simple http server. Create a file `server.js` with the following contents.

```typescript
import { serve } from "https://deno.land/std/http/server.ts";
const s = serve({ port: 8000 });

for await (const req of s) {
  req.respond({ body: "Hello World\n" });
}
```

Try running this file as `deno server.js`. You'll see that it fails with an error ` PermissionDenied: run again with the --allow-net flag`. This is another great feature of Deno. By default, Deno applications don't have permissions to access the network and needs to be explicitly granted. Now, as the error message says, run the program as `deno --allow-net server.js`. The http server should start listening on port 8000.