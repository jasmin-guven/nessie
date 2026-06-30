
import logging
from rich.logging import RichHandler
from rich.console import Console


def _initialise_logger() -> logging.Logger:
    
    console = Console(force_terminal=True, color_system="truecolor")

    logging.basicConfig(
        level=logging.INFO,
        format="%(message)s",
        datefmt="[%X]",
        handlers=[RichHandler(console=console, rich_tracebacks=True, markup=True)],
        force=True,
    )

    return logging.getLogger("rich")
