# Structural interface for prompt runners

A prompt runner accepts a prompt string and returns response text.
BebeLM is one implementation; cloud LLMs, test fixtures, and other local
models should implement the same generic instead of changing downstream
judgment code.

## Usage

``` r
DucksemanticsPromptRunner
```
