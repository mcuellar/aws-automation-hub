PYTHON=python3
VENV=.venv

.PHONY: install test package clean

install:
	$(PYTHON) -m pip install --upgrade pip
	if [ -f requirements.txt ]; then $(PYTHON) -m pip install -r requirements.txt; fi

test:
	$(PYTHON) -m pytest -q

package:
	rm -rf build
	mkdir -p build
	zip -r build/lambda.zip handler.py

clean:
	rm -rf build $(VENV)
