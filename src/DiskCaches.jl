module DiskCaches

using Serialization
using Pidfile

export DiskCache

struct DiskCache{K,V,D<:AbstractDict{K, V}} <: AbstractDict{K,V}
    path::String
    data::D
    function DiskCache{K,V,D}(path::AbstractString) where {K,V,D}
        path, ext = splitext(path)
        if !(ext == ".jls" || ext == "")
            throw(ArgumentError("Extension for DiskCache files is .jls"))
        end
        path = "$path.jls"

        dir = splitdir(path)[1]
        mkpath(dir)
        data = mkpidlock("$(path).lock") do
            if !(ispath(path))
                data = D()
                serialize(path, data)
            end
            deserialize(path)
        end
        return new{K,V,D}(String(path), data)
    end
end

DiskCache{K, V}(path) where {K, V} = DiskCache{K, V, Dict{K, V}}(path)
DiskCache(path) = DiskCache{Any, Any}(path)

function _load(c)
    _data = deserialize(c.path)
    for (key, value) in pairs(_data)
        if !haskey(c.data, key)
            c.data[key] = value
        end
    end
end

function _save(c)
    serialize(c.path, c.data)
end

function Base.length(c::DiskCache)
    mkpidlock("$(c.path).lock") do
        _load(c)
    end
    length(c.data)
end

function Base.isempty(c::DiskCache)
    if !isempty(c.data)
        return false
    else
        mkpidlock("$(c.path).lock") do
            _load(c)
        end
        return isempty(c.data)
    end
end

function Base.haskey(c::DiskCache, key)
    mkpidlock("$(c.path).lock") do
        _load(c)
    end
    return haskey(c.data, key)
end

function Base.get(c::DiskCache, key, default)
    if haskey(c.data, key)
        return c.data[key]
    else
        mkpidlock("$(c.path).lock") do
            _load(c)
        end
        return get(c.data, key, default)
    end
end

function Base.get(f::Union{Function, Type}, c::DiskCache, key)
    if haskey(c.data, key)
        return c.data[key]
    else
        mkpidlock("$(c.path).lock") do
            _load(c)
        end
        return get(f, c.data, key)
    end
end

function Base.getindex(c::DiskCache, key)
    if haskey(c.data, key)
        return c.data[key]
    else
        mkpidlock("$(c.path).lock") do
            _load(c)
        end
        if haskey(c.data, key)
            return c.data[key]
        else
            throw(KeyError(key))
        end
    end
end

function Base.keys(c::DiskCache)
    mkpidlock("$(c.path).lock") do
        _load(c)
    end
    keys(c.data)
end
function Base.values(c::DiskCache)
    mkpidlock("$(c.path).lock") do
        _load(c)
    end
    values(c.data)
end
Base.pairs(c::DiskCache) = c
function Base.iterate(c::DiskCache)
    mkpidlock("$(c.path).lock") do
        _load(c)
    end
    iterate(c.data)
end
Base.iterate(c::DiskCache, state) = iterate(c.data, state)

function Base.get!(c::DiskCache, key, default)
    if haskey(c.data, key)
        return c.data[key]
    else
        mkpidlock("$(c.path).lock") do
            _load(c)
            if !haskey(c.data, key)
                c.data[key] = default
                _save(c)
            end
        end
        return c.data[key]
    end
end

function Base.get!(f::Union{Function, Type}, c::DiskCache, key)
    if haskey(c.data, key)
        return c.data[key]
    else
        mkpidlock("$(c.path).lock") do
            _load(c)
            if !haskey(c.data, key)
                c.data[key] = f()
                _save(c)
            end
        end
        return c.data[key]
    end
end

function Base.setindex!(c::DiskCache, value, key)
    mkpidlock("$(c.path).lock") do
        _load(c)
        if haskey(c.data, key)
            throw(ErrorException("To ensure the validity of the on-chip cache, DiskCaches do not support value modification."))
        else
            c.data[key] = value
            _save(c)
        end
    end
    return c.data[key]
end

function Base.delete!(c::DiskCache, key)
    throw(ErrorException("To ensure the validity of the on-chip cache, DiskCaches do not support value modification."))
end

function Base.pop!(c::DiskCache)
    throw(ErrorException("To ensure the validity of the on-chip cache, DiskCaches do not support value modification."))
end

function Base.pop!(c::DiskCache, key)
    throw(ErrorException("To ensure the validity of the on-chip cache, DiskCaches do not support value modification."))
end

function Base.pop!(c::DiskCache, key, default)
    throw(ErrorException("To ensure the validity of the on-chip cache, DiskCaches do not support value modification."))
end

function Base.empty!(c::DiskCache) where {K, V}
    throw(ErrorException("To ensure the validity of the on-chip cache, DiskCaches do not support value modification."))
end

end
