# SimpleWeave

This package offers a simplified syntax to create documents for use with `Weave.jl`.

```julia
using SimpleWeave
simpleweave(input_jl, output_file; doctype = "md2html", weave_kwargs...)
```

The rules are different:

Text in

```
md"""
"""
```

blocks is treated as markdown.

All other code is treated as code cells, either limited by markdown, or by lines starting with `##`.

So this:

```
f(x) = x ^ 2

md"""
This is some explanation of the code.
"""

f(3)

##

f(4)
```

becomes:

````
```julia
f(x) = x ^ 2
```

This is some explanation of the code.

```julia
f(3)
```

```julia
f(4)
```
````

The reason is that it's annoying to write the code fences all the time.
On the other hand, in Literate.jl it's also annoying that one has to prefix all markdown with `#` which is confusing with normal comments.
The `md` string macro doesn't conflict with any other syntax but `md` strings themselves, which are usually not just sitting around without being assigned to anything.
Also, code editors often offer nicer markdown highlighting for `md` blocks, which can help to spot syntax errors in the markdown.