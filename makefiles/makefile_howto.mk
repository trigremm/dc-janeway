# makefile_howto.mk
# `make howto-*` targets print copy-pasteable command sequences for common
# bootstrap/runtime flows on a fresh target host.

.PHONY: howto-deploy howto-up

howto-deploy:
	@echo 'ssh-keygen -t ed25519 -C "deploy-key-dc-janeway@$$(hostname)" -f ~/.ssh/deploy-key-dc-janeway'
	@echo 'eval "$$(ssh-agent -s)" && ssh-add ~/.ssh/deploy-key-dc-janeway && cat ~/.ssh/deploy-key-dc-janeway.pub'
	@echo "GIT_SSH_COMMAND='ssh -i ~/.ssh/deploy-key-dc-janeway' git clone git@github.com:trigremm/dc-janeway.git"
	@echo 'cd dc-janeway'
	@echo 'git config core.sshCommand "ssh -i ~/.ssh/deploy-key-dc-janeway"'
	@echo 'sudo usermod -aG docker $$USER'

howto-up:
	@echo 'cp .env.sample .env'
	@echo 'vim .env              # set POSTGRES_PASSWORD, SECRET_KEY, ALLOWED_HOSTS, DC_JANEWAY_HTTP_PORT'
	@echo 'make janeway-install  # clone BirkbeckCTP/janeway into backend/janeway/ at JANEWAY_REF'
	@echo 'make build            # pip install deps from backend/janeway/requirements.txt'
	@echo 'make up               # start db + janeway (entrypoint runs migrations)'
	@echo 'make janeway-setup    # install_janeway (initial press + admin)'
	@echo 'make janeway-createsuperuser'
