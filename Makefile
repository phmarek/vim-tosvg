
release: zip

zip: /tmp/to-svg-$(shell date +%F).zip

/tmp/%.zip:
	zip $@ README.md autoload/tosvg.vim
