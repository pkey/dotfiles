.PHONY: doc.serve
doc.serve: crd-doc.generate ## Run roadiehq/techdocs to test documentation locally; supports live reload
	docker run \
		-w /content \
		-v $$(pwd):/content \
		-p 8000:8000 \
		roadiehq/techdocs:latest \
		serve \
			-a 0.0.0.0:8000c
