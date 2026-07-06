# Wrap a prompt function as a typed prompt runner

Wrap a prompt function as a typed prompt runner

## Usage

``` r
ducksemantics_prompt_runner(fun, label = "function")
```

## Arguments

- fun:

  Function accepting `prompt` and returning response text.

- label:

  Provider label for reports.

## Value

An object implementing
[DucksemanticsPromptRunner](https://sounkou-bioinfo.github.io/ducksemantics/reference/DucksemanticsPromptRunner.md).
