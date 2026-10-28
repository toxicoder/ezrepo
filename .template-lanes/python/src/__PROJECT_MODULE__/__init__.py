"""__PROJECT_NAME__ - __PROJECT_DESCRIPTION__.

The package holds one public surface: the version string and the CLI in
:mod:`__PROJECT_MODULE__.cli`. Nothing in here reads the environment, opens a
file or prints, so importing the package from another program is free.

The version is defined here and imported by the CLI, so `__PROJECT_NAME__
--version`, `__PROJECT_MODULE__.__version__` and the pyproject metadata all read
one number and cannot drift apart.
"""

__version__ = "0.1.0"

__all__ = ["__version__"]
