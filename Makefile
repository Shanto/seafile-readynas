all:
	(cd src; make $@)

install:
	(cd src; make $@)
	cp -pr files/* $(DESTDIR)
	cp -pr src/files/* $(DESTDIR)

clean:
	(cd src; make $@)

veryclean:
	dh clean

builddeps:
	dpkg-checkbuilddeps
