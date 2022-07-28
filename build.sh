if [ ! -d bin ]
then
	mkdir bin
fi

fpc pinesweeper.pas
mv pinesweeper bin/
mv *.o bin
