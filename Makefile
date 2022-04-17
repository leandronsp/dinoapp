web.server:
	@docker run \
		--rm \
		-d \
		--name dinoapp \
		-it \
		-v $(CURDIR):/app \
		-w /app \
		-p 3000:3000 \
		ruby \
		bash -c "ruby web/server.rb"

bash:
	@docker run \
		--rm \
		-it \
		-v $(CURDIR):/app \
		-w /app \
		ruby \
		bash
