{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonApplication rec {
  pname = "arxiv-mcp-server";
  version = "0.5.0";
  pyproject = true;

  src = fetchPypi {
    pname = "arxiv_mcp_server";
    inherit version;
    hash = "sha256-vxrKyq+uOgVYtWrvikcIidLra6n0GFlFvfKztrc7GH8=";
  };

  build-system = [ python3Packages.hatchling ];

  # nixpkgs ships mcp 1.26.0; upstream pins >=1.27.0 (compatible, relax it).
  # `black` is declared as a runtime dependency upstream (a packaging slip) --
  # it's a formatter, not imported at runtime, so drop it.
  pythonRelaxDeps = [ "mcp" ];
  pythonRemoveDeps = [ "black" ];

  dependencies = with python3Packages; [
    aiofiles
    aiohttp
    anyio
    arxiv
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
