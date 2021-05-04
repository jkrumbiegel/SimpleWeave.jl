module SimpleWeave

using Weave
using Markdown: @md_str

export @md_str # so one can run over the md blocks
export simpleweave

abstract type Block end

struct Codeblock <: Block
    block::String
    arguments::String
end

Codeblock(block) = Codeblock(block, "")

struct Markdownblock <: Block
    block::String
end

function convert_to_blocks(inputfile)

    blocks = Block[]

    io = IOBuffer()

    in_markdown = false
    arguments = ""

    newcode() = push!(blocks, Codeblock(strip(String(take!(io))), arguments))
    newmd() = push!(blocks, Markdownblock(strip(String(take!(io)))))

    for line in readlines(inputfile)
        if !in_markdown
            if startswith(line, "##")
                newcode()
                arguments = strip(line[3:end])
            elseif startswith(line, "md\"\"\"")
                newcode()
                in_markdown = true
            else
                println(io, line)
            end
        else
            if startswith(line, "\"\"\"")
                in_markdown = false
                newmd()
            else
                println(io, line)
            end
        end
    end

    in_markdown ? newmd() : newcode()

    blocks = filter(!isempty ∘ (x -> x.block), blocks)
end

function blocks_to_string(blocks)
    io = IOBuffer()

    for (i, block) in enumerate(blocks)
        i > 1 && println(io)
        print_block(io, block)
    end

    String(take!(io))
end

function print_block(io, c::Codeblock)
    print(io, "```julia")
    if !isempty(c.arguments)
        println(io, " ", c.arguments)
    else
        println(io)
    end
    println(io, c.block)
    println(io, "```")
end

function print_block(io, m::Markdownblock)
    println(io, m.block)
end

function simpleweave(input, output; doctype = "md2html", kwargs...)

    blocks = convert_to_blocks(input)
    weavestring = blocks_to_string(blocks)

    tempfile = String(rand('a':'z', 20)) * ".jmd"
    while isfile(tempfile)
        tempfile = String(rand('a':'z', 20)) * ".jmd"
    end

    try
        open(tempfile, "w") do file
            write(file, weavestring)
        end

        Weave.weave(tempfile;
            doctype = doctype,
            out_path = output,
            kwargs...
        )
    finally
        rm(tempfile)
    end
end

end
