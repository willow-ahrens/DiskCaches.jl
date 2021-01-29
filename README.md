# DiskCaches

<!---
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://peterahrens.github.io/DiskCaches.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://peterahrens.github.io/DiskCaches.jl/dev)
--->
[![Build Status](https://github.com/peterahrens/DiskCaches.jl/workflows/CI/badge.svg)](https://github.com/peterahrens/DiskCaches.jl/actions)
[![Coverage](https://codecov.io/gh/peterahrens/DiskCaches.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/peterahrens/DiskCaches.jl)

Basic Julia implementation of a cache mapped to the filesystem, for persistence across multiple julia sessions. This implementation is intended to be thread and process safe, and files are formatted with `Serialization`.

A `DiskCache` can associate keys with values, but cannot modify existing associations. Reading entries already on chip is fast, but writing values to disk is quite slow. The cache follows the `AbstractDict` interface, but methods which modify existing associations in the dictionary will error.

This package was desined with memoization in mind via [MemoizedMethods.jl](https://github.com/peterahrens/MemoizedMethods.jl).

## Usage

```julia
julia> using DiskCaches

julia> c = DiskCache("path_to_cache.jls")
DiskCache{Any,Any,Dict{Any,Any}}()

julia> c[1] = 2
2

julia> c[2] = 3
3

julia> c[1]
2

julia> c[1] = 0
ERROR: To ensure the validity of the on-chip cache, DiskCaches do not support value modification.
```

Again, these caches don't support modifications to existing key-value pairs. It's easiest to atomically "add a value if the key doesn't exist yet" with the `get!` functions.

```julia
julia> get!(c, 1, 42)
2

julia> get!(c, 3) do 4 end
4
```

Multiple caches pointed at the same file will shadow each other.

```
julia> c_shadow = DiskCache("path_to_cache.jls")
DiskCache{Any,Any,Dict{Any,Any}} with 3 entries:
  2 => 3
  3 => 4
  1 => 2

julia> c_shadow[4] = 5
5

julia> c
DiskCache{Any,Any,Dict{Any,Any}} with 3 entries:
  2 => 3
  3 => 4
  4 => 5
  1 => 2
```

... in a separate Julia session ...

```julia
julia> using DiskCaches

julia> c = DiskCache("path_to_cache.jls")
DiskCache{Any,Any,Dict{Any,Any}} with 3 entries:
  2 => 3
  3 => 4
  4 => 5
  1 => 2
```

DiskCaches use an on-chip cache which also defines the behavior (e.g. `==` vs. `===`) of the associative collection. By default, DiskCaches use `Dict` (not `IdDict`) as the on-chip cache. You may provide a specialized AbstractDict type to be used by DiskCaches, as long as it may be serialized, does not delete its values, and supports a no-argument constructor. Nesting DiskCaches with the same file will result in deadlock.

```julia
julia> c = DiskCache{Int,Int,IdDict{Int,Int}}("path_to_special_cache.jls")
DiskCache{Int64,Int64,IdDict{Int64,Int64}}()
```

If you want to delete a `DiskCache` and are sure that no other caches with the same path will be used in the future, `rm` the file and make a new `DiskCache` with the same filename. This is a relatively unsafe operation.

```
julia> c = DiskCache("path_to_cache.jls")
DiskCache{Any,Any,Dict{Any,Any}} with 3 entries:
  2 => 3
  3 => 4
  4 => 5
  1 => 2

julia> rm("path_to_cache.jls")

julia> c = DiskCache("path_to_cache.jls")
DiskCache{Any,Any,Dict{Any,Any}}()
```