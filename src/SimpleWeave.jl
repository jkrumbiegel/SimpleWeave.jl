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

function simpleweave(input, outputfolder; overwrite = true, remove_pdf_aux = true, doctype = "md2html", kwargs...)

    if isfile(outputfolder)
        error("$outputfolder is a file, not a folder")
    end
    if !isdir(outputfolder)
        @label question1
        print("Output folder $outputfolder doesn't exist. Create? y/n ")
        yn = readline()
        if yn == "n"
            return
        elseif yn != "y"
            @goto question1
        end
        mkdir(outputfolder)
    end

    blocks = convert_to_blocks(input)
    weavestring = blocks_to_string(blocks)

    jmd_filename = splitext(input)[1] * ".jmd"
    if isfile(jmd_filename)
        @label question
        print("Temporary jmd file $jmd_filename already exists. Delete? y/n ")
        yn = readline()
        if yn == "n"
            return
        elseif yn != "y"
            @goto question
        end
    end

    mktempdir() do path
        temp_output_path = joinpath(path, "weave_output")

        try
            open(jmd_filename, "w") do file
                write(file, weavestring)
            end

            Weave.weave(jmd_filename;
                doctype = doctype,
                out_path = temp_output_path,
                kwargs...
            )
        finally
            rm(jmd_filename)
        end

        # delete empty folders in the output that weave leaves there
        for (root, dirs, files) in walkdir(temp_output_path, topdown = false)
            for dir in dirs
                if isempty(readdir(joinpath(root, dir)))
                    rm(joinpath(root, dir))
                end
            end
            if remove_pdf_aux && doctype == "md2pdf"
                for file in files
                    if !endswith(file, ".pdf")
                        rm(joinpath(root, file))
                    end
                end
            end
        end

        for thing in readdir(temp_output_path)
            mv(
                joinpath(temp_output_path, thing),
                joinpath(outputfolder, thing),
                force = overwrite)
        end
    end
end

end
