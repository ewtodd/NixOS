{
  lib,
  python3Packages,
  # Sourced from flake input (not PyPI) to fix PDF truncation in 0.5.0.
  src,
}:
let
  arxivRelaxed = python3Packages.arxiv.overridePythonAttrs (old: {
    pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [
      "requests"
    ];
  });
in
python3Packages.buildPythonApplication {
  pname = "arxiv-mcp-server";
  version = "0.5.0-unstable-${builtins.substring 0 8 (src.lastModifiedDate or "00000000")}";
  pyproject = true;

  inherit src;

  build-system = [ python3Packages.hatchling ];

  # nixpkgs ships mcp 1.26.0; upstream pins >=1.27.0 (compatible, relax it).
  # `black` is declared as a runtime dependency upstream (a packaging slip) --
  # it's a formatter, not imported at runtime, so drop it.
  pythonRelaxDeps = [
    "mcp"
    "arxiv"
    "anyio"
  ];
  pythonRemoveDeps = [ "black" ];

  dependencies = with python3Packages; [
    aiofiles
    aiohttp
    anyio
    arxivRelaxed
    httpx
    mcp
    pydantic-settings
    pydantic
    python-dateutil
    python-dotenv
    sse-starlette
    starlette
    uvicorn
    pymupdf4llm # [pdf] extra: extract full text of papers lacking an HTML version
  ];

  pythonImportsCheck = [ "arxiv_mcp_server" ];
  doCheck = false;

  meta = {
    description = "MCP server for arXiv search and paper analysis";
    homepage = "https://github.com/blazickjp/arxiv-mcp-server";
    license = lib.licenses.asl20;
    mainProgram = "arxiv-mcp-server";
  };
}
