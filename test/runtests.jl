using SimpleWeave
using SimpleWeave: Codeblock, Markdownblock
using Test

@testset "SimpleWeave.jl" begin
    blocks = SimpleWeave.convert_to_blocks("file_1.jl")
    @test blocks == [
        Codeblock("1 + 1"),
        Markdownblock("This is markdown"),
        Codeblock("2 + 3", "echo = false"),
        Markdownblock("Some\nmore\nmarkdown"),
        Codeblock("1 + 2"),
    ]

    io = IOBuffer()

    output = SimpleWeave.blocks_to_string(blocks)
    expected = """
    ```julia
    1 + 1
    ```

    This is markdown

    ```julia echo = false
    2 + 3
    ```

    Some
    more
    markdown

    ```julia
    1 + 2
    ```
    """

    @test output == expected
end
