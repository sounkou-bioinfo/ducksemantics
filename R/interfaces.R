#' Provider interface generics
#'
#' These S7 generics are the behavior required by the structural interfaces.
#' Provider packages should define concrete S7 classes and methods for these
#' generics, then consuming code can assert the corresponding `Ducksemantics*`
#' interface.
#'
#' @param provider Prompt or embedding provider.
#' @param parser Judgment parser.
#' @param annotator Text-grounding provider.
#' @param prompt Prompt text.
#' @param response Raw model response text.
#' @param text Source text.
#' @param conn DBI connection.
#' @param document_id Optional document id.
#' @param prefix Semantic table prefix.
#' @param longest_match Drop matches contained by a longer span.
#' @param record Append returned rows to the semantic store?
#' @param ... Provider-specific arguments.
#' @return Provider-specific output: response text, embedding matrix, parsed
#'   judgment data frame, or grounded mention data frame.
#' @name ducksemantics_provider_generics
NULL

#' @rdname ducksemantics_provider_generics
#' @export
ducksemantics_run <- S7::new_generic(
  "ducksemantics_run",
  "provider",
  function(provider, prompt, ...) S7::S7_dispatch()
)

#' @rdname ducksemantics_provider_generics
#' @export
ducksemantics_embed <- S7::new_generic(
  "ducksemantics_embed",
  "provider",
  function(provider, text, ...) S7::S7_dispatch()
)

#' @rdname ducksemantics_provider_generics
#' @export
ducksemantics_parse <- S7::new_generic(
  "ducksemantics_parse",
  "parser",
  function(parser, response, ...) S7::S7_dispatch()
)

#' @rdname ducksemantics_provider_generics
#' @export
ducksemantics_ground <- S7::new_generic(
  "ducksemantics_ground",
  "annotator",
  function(annotator, conn, text, document_id = NULL, prefix = "semantic",
           longest_match = TRUE, record = FALSE, ...) S7::S7_dispatch()
)

#' Structural interface for prompt runners
#'
#' A prompt runner accepts a prompt string and returns response text. BebeLM is
#' one implementation; cloud LLMs, test fixtures, and other local models should
#' implement the same generic instead of changing downstream judgment code.
#'
#' @export
DucksemanticsPromptRunner <- s7contract::new_interface(
  "DucksemanticsPromptRunner",
  package = "ducksemantics",
  generics = list(
    run = s7contract::interface_requirement(
      ducksemantics_run,
      args = list(prompt = S7::class_character),
      returns = S7::class_character
    )
  )
)

#' Structural interface for embedding providers
#'
#' An embedding provider accepts a character vector and returns a numeric matrix
#' with one row per input text.
#'
#' @export
DucksemanticsEmbeddingProvider <- s7contract::new_interface(
  "DucksemanticsEmbeddingProvider",
  package = "ducksemantics",
  generics = list(
    embed = s7contract::interface_requirement(
      ducksemantics_embed,
      args = list(text = S7::class_character),
      returns = S7::class_any
    )
  )
)

#' Structural interface for judgment parsers
#'
#' A judgment parser turns raw model text into a data frame that includes
#' `mention_id` and `decision`.
#'
#' @export
DucksemanticsJudgmentParser <- s7contract::new_interface(
  "DucksemanticsJudgmentParser",
  package = "ducksemantics",
  generics = list(
    parse = s7contract::interface_requirement(
      ducksemantics_parse,
      args = list(response = S7::class_character),
      returns = S7::class_data.frame
    )
  )
)

#' Structural interface for text annotators
#'
#' An annotator grounds text against the semantic store and returns mention
#' rows. The default implementation is the DuckDB lexical alias index.
#'
#' @export
DucksemanticsAnnotator <- s7contract::new_interface(
  "DucksemanticsAnnotator",
  package = "ducksemantics",
  generics = list(
    ground = s7contract::interface_requirement(
      ducksemantics_ground,
      args = list(
        conn = S7::class_any,
        text = S7::class_character,
        document_id = S7::new_union(NULL, S7::class_character),
        prefix = S7::class_character,
        longest_match = S7::class_logical,
        record = S7::class_logical
      ),
      returns = S7::class_data.frame
    )
  )
)

ducksemantics_function_prompt_runner_class <- S7::new_class(
  "ducksemantics_function_prompt_runner",
  package = "ducksemantics",
  properties = list(
    fun = S7::class_function,
    label = S7::class_character
  )
)

ducksemantics_bebel_runner_class <- S7::new_class(
  "ducksemantics_bebel_runner",
  package = "ducksemantics",
  properties = list(
    agent = S7::class_any,
    on_event = S7::new_union(NULL, S7::class_function)
  )
)

ducksemantics_function_embedding_provider_class <- S7::new_class(
  "ducksemantics_function_embedding_provider",
  package = "ducksemantics",
  properties = list(
    fun = S7::class_function,
    label = S7::class_character
  )
)

ducksemantics_bebel_embedding_provider_class <- S7::new_class(
  "ducksemantics_bebel_embedding_provider",
  package = "ducksemantics",
  properties = list(
    model = S7::class_any,
    add_bos = S7::class_logical,
    normalize = S7::class_logical,
    pooling = S7::class_character
  )
)

ducksemantics_json_judgment_parser_class <- S7::new_class(
  "ducksemantics_json_judgment_parser",
  package = "ducksemantics"
)

ducksemantics_bebel_tool_judgment_parser_class <- S7::new_class(
  "ducksemantics_bebel_tool_judgment_parser",
  package = "ducksemantics",
  properties = list(
    tool_name = S7::new_union(NULL, S7::class_character)
  )
)

ducksemantics_lexical_annotator_class <- S7::new_class(
  "ducksemantics_lexical_annotator",
  package = "ducksemantics"
)

#' Wrap a prompt function as a typed prompt runner
#'
#' @param fun Function accepting `prompt` and returning response text.
#' @param label Provider label for reports.
#' @return An object implementing [DucksemanticsPromptRunner].
#' @export
ducksemantics_prompt_runner <- function(fun, label = "function") {
  if (!is.function(fun)) stop("`fun` must be a function.", call. = FALSE)
  S7::prop(DucksemanticsScalarText(value = label), "value")
  ducksemantics_function_prompt_runner_class(fun = fun, label = label)
}

#' Wrap an embedding function as a typed embedding provider
#'
#' @param fun Function accepting a character vector and returning a numeric
#'   matrix with one row per input text.
#' @param label Provider label for reports.
#' @return An object implementing [DucksemanticsEmbeddingProvider].
#' @export
ducksemantics_embedding_provider <- function(fun, label = "function") {
  if (!is.function(fun)) stop("`fun` must be a function.", call. = FALSE)
  S7::prop(DucksemanticsScalarText(value = label), "value")
  ducksemantics_function_embedding_provider_class(fun = fun, label = label)
}

#' Create a BebeLM embedding provider
#'
#' @param model A `Rbebelm` `BebelModel` object.
#' @param add_bos Include BOS in tokenization?
#' @param normalize L2-normalize embeddings?
#' @param pooling Hidden-state pooling strategy: `mean` or `last`.
#' @return An object implementing [DucksemanticsEmbeddingProvider].
#' @export
ducksemantics_bebel_embedding_provider <- function(model,
                                                   add_bos = TRUE,
                                                   normalize = TRUE,
                                                   pooling = c("mean", "last")) {
  if (!requireNamespace("Rbebelm", quietly = TRUE)) {
    stop("Rbebelm is required for the BebeLM embedding provider.", call. = FALSE)
  }
  S7::prop(DucksemanticsFlag(value = add_bos), "value")
  S7::prop(DucksemanticsFlag(value = normalize), "value")
  pooling <- match.arg(pooling)
  ducksemantics_bebel_embedding_provider_class(
    model = model,
    add_bos = add_bos,
    normalize = normalize,
    pooling = pooling
  )
}

#' Create the default JSON judgment parser
#'
#' @return An object implementing [DucksemanticsJudgmentParser].
#' @export
ducksemantics_json_judgment_parser <- function() {
  ducksemantics_json_judgment_parser_class()
}

#' Create a BebeLM tool-call judgment parser
#'
#' @param tool_name Optional accepted tool-call name or names.
#' @return An object implementing [DucksemanticsJudgmentParser].
#' @export
ducksemantics_bebel_tool_judgment_parser <- function(tool_name = NULL) {
  if (!is.null(tool_name) && (!is.character(tool_name) || anyNA(tool_name) || any(!nzchar(tool_name)))) {
    stop("`tool_name` must be NULL or a character vector of non-empty names.", call. = FALSE)
  }
  ducksemantics_bebel_tool_judgment_parser_class(tool_name = tool_name)
}

#' Create the default DuckDB lexical annotator
#'
#' @return An object implementing [DucksemanticsAnnotator].
#' @export
ducksemantics_lexical_annotator <- function() {
  ducksemantics_lexical_annotator_class()
}

S7::method(ducksemantics_run, ducksemantics_function_prompt_runner_class) <- function(provider, prompt, ...) {
  S7::prop(DucksemanticsScalarText(value = prompt), "value")
  ducksemantics_response_text(provider@fun(prompt, ...))
}

S7::method(ducksemantics_run, ducksemantics_bebel_runner_class) <- function(provider, prompt, ...) {
  S7::prop(DucksemanticsScalarText(value = prompt), "value")
  if (!requireNamespace("Rbebelm", quietly = TRUE)) {
    stop("Rbebelm is required for BebeLM judgment.", call. = FALSE)
  }
  Rbebelm::bebel_append_user(provider@agent, prompt)
  turn <- Rbebelm::bebel_assistant_turn(provider@agent, on_event = provider@on_event)
  ducksemantics_response_text(turn)
}

S7::method(ducksemantics_embed, ducksemantics_function_embedding_provider_class) <- function(provider, text, ...) {
  if (!is.character(text) || anyNA(text)) {
    stop("`text` must be a character vector without NA.", call. = FALSE)
  }
  out <- provider@fun(text, ...)
  if (is.data.frame(out)) out <- as.matrix(out)
  S7::prop(DucksemanticsEmbeddingMatrix(embeddings = out, rows = length(text)), "embeddings")
}

S7::method(ducksemantics_embed, ducksemantics_bebel_embedding_provider_class) <- function(provider, text, ...) {
  if (!is.character(text) || anyNA(text)) {
    stop("`text` must be a character vector without NA.", call. = FALSE)
  }
  out <- Rbebelm::bebel_embed(
    provider@model,
    text,
    add_bos = provider@add_bos,
    normalize = provider@normalize,
    pooling = provider@pooling
  )
  S7::prop(DucksemanticsEmbeddingMatrix(embeddings = out, rows = length(text)), "embeddings")
}

S7::method(ducksemantics_parse, ducksemantics_json_judgment_parser_class) <- function(parser, response, ...) {
  parsed <- ducksemantics_parse_json_response(response)
  parsed <- ducksemantics_normalize_judgment_payload(parsed)
  S7::prop(DucksemanticsTable(value = parsed, required = character(), allow_empty = TRUE), "value")
}

S7::method(ducksemantics_parse, ducksemantics_bebel_tool_judgment_parser_class) <- function(parser, response, ...) {
  if (!requireNamespace("Rbebelm", quietly = TRUE)) {
    stop("Rbebelm is required to parse BebeLM tool calls.", call. = FALSE)
  }
  blocks <- ducksemantics_bebel_tool_blocks(response)
  calls <- tryCatch(
    ducksemantics_parse_bebel_tool_call_blocks(blocks),
    error = function(e) list()
  )
  if (length(calls)) {
    if (!is.null(parser@tool_name)) {
      keep <- vapply(calls, function(call) call$name %in% parser@tool_name, logical(1))
      calls <- calls[keep]
    }
    if (length(calls)) {
      rows <- lapply(calls, function(call) call$arguments)
      return(ducksemantics_lists_to_data_frame(rows))
    }
  }
  ducksemantics_parse_json_candidates(c(blocks, response))
}

S7::method(ducksemantics_ground, ducksemantics_lexical_annotator_class) <- function(annotator,
                                                                                    conn,
                                                                                    text,
                                                                                    document_id = NULL,
                                                                                    prefix = "semantic",
                                                                                    longest_match = TRUE,
                                                                                    record = FALSE,
                                                                                    ...) {
  ducksemantics_annotate(
    conn = conn,
    text = text,
    document_id = document_id,
    prefix = prefix,
    longest_match = longest_match,
    record = record
  )
}

ducksemantics_parse_bebel_tool_calls <- function(response) {
  S7::prop(DucksemanticsScalarText(value = response), "value")
  ducksemantics_parse_bebel_tool_call_blocks(ducksemantics_bebel_tool_blocks(response))
}

ducksemantics_parse_bebel_tool_call_blocks <- function(blocks) {
  calls <- unlist(
    lapply(blocks, Rbebelm::bebel_parse_tool_calls),
    recursive = FALSE,
    use.names = FALSE
  )
  calls
}

ducksemantics_parse_json_candidates <- function(candidates) {
  for (candidate in candidates[nzchar(trimws(candidates))]) {
    parsed <- try(ducksemantics_parse_json_response(candidate), silent = TRUE)
    if (inherits(parsed, "try-error")) {
      next
    }
    parsed <- ducksemantics_normalize_judgment_payload(parsed)
    return(S7::prop(DucksemanticsTable(value = parsed, required = character(), allow_empty = TRUE), "value"))
  }
  stop("BebeLM response did not contain judgment tool calls or JSON.", call. = FALSE)
}

ducksemantics_bebel_tool_blocks <- function(response) {
  start_token <- "<|tool_call_start|>"
  end_token <- "<|tool_call_end|>"
  blocks <- character()
  cursor <- 1L
  repeat {
    rest <- substring(response, cursor)
    start <- regexpr(start_token, rest, fixed = TRUE)[[1L]]
    if (identical(start, -1L)) break
    content_start <- cursor + start + nchar(start_token, type = "chars") - 1L
    after_start <- substring(response, content_start)
    end <- regexpr(end_token, after_start, fixed = TRUE)[[1L]]
    if (identical(end, -1L)) break
    content_end <- content_start + end - 2L
    blocks <- c(blocks, substring(response, content_start, content_end))
    cursor <- content_end + nchar(end_token, type = "chars") + 1L
  }
  if (!length(blocks)) {
    blocks <- trimws(response)
  }
  blocks[nzchar(trimws(blocks))]
}

ducksemantics_lists_to_data_frame <- function(rows) {
  columns <- unique(unlist(lapply(rows, names), use.names = FALSE))
  if (!length(columns)) {
    return(data.frame())
  }
  out <- lapply(columns, function(column) {
    vapply(rows, function(row) {
      value <- row[[column]]
      if (is.null(value) || length(value) == 0L || is.na(value[[1L]])) {
        NA_character_
      } else {
        as.character(value[[1L]])
      }
    }, character(1))
  })
  names(out) <- columns
  data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}
