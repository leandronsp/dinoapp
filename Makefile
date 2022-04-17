web.server:
	@docker build -t dinoapp --target base .
	@docker run \
		--rm \
		--name dinoapp \
		-it \
		-v $(CURDIR):/app \
		-w /app \
		-p 3000:3000 \
		dinoapp \
		bash -c "ruby web/server.rb"

bash:
	@docker build -t dinoapp --target base .
	@docker run \
		--rm \
		-it \
		-v $(CURDIR):/app \
		-w /app \
		dinoapp \
		bash
