# Makefile
include makefiles/makefile_docker_compose.mk
include makefiles/makefile_docker.mk
include makefiles/makefile_format.mk
include makefiles/makefile_git.mk
include makefiles/makefile_howto.mk
include makefiles/makefile_janeway.mk
include makefiles/makefile_nginx.mk

.PHONY: ssh

ssh:
	ssh test-asmo-server
