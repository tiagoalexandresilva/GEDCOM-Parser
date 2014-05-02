V=wwwpfdogp.ged

gedcom: gedcom.l
	flex gedcom.l
	gcc -o ged2html lex.yy.c -lfl

test:$V gedcom
	./ged2html $V
	google-chrome Index.html
	
install:
	flex gedcom.l
	gcc -o ged2html lex.yy.c -lfl
	cp ged2html /usr/local/bin
	mkdir -m=rwx -p /usr/local/share/ged2html
	cp styles.css /usr/local/share/ged2html
	cp paper005.gif /usr/local/share/ged2html
			
clean:
	rm *.html
	rm lex.yy.c
	rm ged2html
