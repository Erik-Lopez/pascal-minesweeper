program Mine; (* All programs in PASCAL start with this line. *)

uses Termio;

type
	Cell = (Empty, Bomb);
	State = (Opened, Closed, Flagged);
	Field = record
		Cells: array of Cell;
		States: array of State;
		Rows: Integer;
		Cols: Integer;
		CursorRow: Integer;
		CursorCol: Integer;
	end;

	procedure FieldResize(var Field: Field; Rows, Cols: Integer);
	begin
		(* Resize Field. It'd be a dynamic array. *)
		SetLength(Field.Cells, Rows*Cols);	
		SetLength(Field.States, Rows*Cols);	
		Field.Rows := Rows;
		Field.Cols := Cols;
	end;

	function FieldStateGet(Field: Field; Row, Col: Integer): State;
	begin
		FieldStateGet := Field.States[Row*Field.Cols + Col];
	end;

	procedure FieldStateSet(Field: Field; Row, Col: Integer; State: State);
	begin
		Field.States[Row*Field.Cols + Col] := State;
	end;

	(* Usamos `;` para separar parámetros y `,` para agrupar parámetros que tienen un mismo tipo. *)
	function FieldCellGet(Field: Field; Row, Col: Integer): Cell;
	begin
		(* Para retornar un valor tenemos que asignárselo al nombre de la función. *)
		FieldCellGet := Field.Cells[Row*Field.Cols + Col];
	end;

	function FieldCellCheckBounds(Field: Field; Row, Col: Integer): Boolean;
	begin
		FieldCellCheckBounds := (Row >= 0) and (Col >= 0) and (Row < Field.Rows) and (Col < Field.Cols)
	end;

	function FieldCellOpen(Field: Field): Cell;
	begin
		FieldStateSet(Field, Field.CursorRow, Field.CursorCol, Opened);
		FieldCellOpen := FieldCellGet(Field, Field.CursorRow, Field.CursorCol);
	end;

	(* Una función sin valor de retorno se llama `procedure` *)
	(* Al usar `var` pasamos como referencia un parámetro. *)
	procedure FieldCellSet(var Field: Field; Row, Col: Integer; Cell: Cell);
	begin
		Field.Cells[Row*Field.Cols + Col] := Cell;
	end;

	function FieldCursorAt(Field: Field; Row, Col: Integer): Boolean;
	begin
		FieldCursorAt := (Row = Field.CursorRow) and (Col = Field.CursorCol);
	end;

	procedure FieldCursorMove(var Field: Field; DeltaRow, DeltaCol: Integer);
	var
		NewRow, NewCol: Integer;
	begin
		NewRow := Field.CursorRow + DeltaRow;	
		NewCol := Field.CursorCol + DeltaCol;	

		(* Check bounds *)
		if (NewRow >= Field.Rows) or (NewCol >= Field.Cols) or (NewRow < 0) or (NewCol < 0) then Exit();

		Field.CursorRow := NewRow;
		Field.CursorCol := NewCol;
	end;

	function FieldCellCountNeighbours(Field: Field; CellRow, CellCol: Integer): Integer;
	var
		BombCount, DeltaRow, DeltaCol, NeighbourRow, NeighbourCol: Integer;
		CurCell: Cell;
	begin	
		BombCount := 0;
		for DeltaRow := -1 to 1 do
		begin
			for DeltaCol := -1 to 1 do
			begin
				NeighbourRow := CellRow + DeltaRow;
				NeighbourCol := CellCol + DeltaCol;

				if (DeltaRow <> 0) or (DeltaCol <> 0) then 
				begin
					if FieldCellCheckBounds(Field, NeighbourRow, NeighbourCol) then
					begin
						CurCell := FieldCellGet(Field, NeighbourRow, NeighbourCol);
						if CurCell = Bomb then inc(BombCount);
					end;
				end;

			end;
		end;	
		FieldCellCountNeighbours := BombCount;
	end;

	procedure FieldInit(var Field: Field; BombToCellRatio: Real);
	var
		Row, Col: Integer;
		CellVal: Cell;
		Index: Integer;
	begin
		Field.CursorRow := 0;
		Field.CursorCol := 0;
		(* Clear the Field in the beginning. *)
		for Index := 0 to Field.Rows*Field.Cols do
		begin
			Field.Cells[Index] := Empty;
			Field.States[Index] := Closed;
		end;

		if BombToCellRatio > 1 then BombToCellRatio := 1;
		if BombToCellRatio < 0 then BombToCellRatio := 0;

		for Row := 0 to Field.Rows-1 do
			for Col := 0 to Field.Cols-1 do
			begin
				(* We generate a number from 0 to 100. If that number lands in a certain slice, then we'll put a bomb on it. The size of the slice is determined by BombToCellRatio. *)
				if random(100) < BombToCellRatio*100 then CellVal := Bomb else CellVal := Empty;
				FieldCellSet(Field, Row, Col, CellVal);
			end;
	end;

	procedure FieldWrite(Field: Field);
	var
		Row, Col, Neighbours: Integer;
		CellVal: Cell;
		CellState: State;
		Separator: Char;
	begin
		for Row := 0 to Field.Rows-1 do
		begin
			for Col := 0 to Field.Cols-1 do
			begin
				if FieldCursorAt(Field, Row, Col) then Separator := '|' else Separator := ' ';

				Write(Separator);
				CellState := FieldStateGet(Field, Row, Col);	
				CellVal := FieldCellGet(Field, Row, Col);

				(* Como un switch de C o un case de sh *)
				case CellState of
					Opened:	begin
						case CellVal of
							Empty: begin
								Neighbours := FieldCellCountNeighbours(Field, Row, Col);
								if Neighbours > 0 then Write(Neighbours) else Write('_');
							end;
							Bomb: Write('🌲');
						end;
					end;
					Closed: Write('#');
					Flagged: Write('x');
				end;
				Write(Separator);
			end;
			WriteLn;
		end;
		WriteLn('------------------------------');
	end;
	
	function CheckWin(Field: Field): Boolean;
	var
		Row, Col: Integer;
	begin
		CheckWin := True;
		for Row := 0 to Field.Rows-1 do
			for Col := 0 to Field.Cols-1 do
				if (FieldCellGet(Field, Row, Col) = Empty) and (FieldStateGet(Field, Row, Col) = Closed) then CheckWin := False;
	end;

(* Para cada función existe un apartado `var` y uno `const` para declarar todas las variables y constantes. *)
const
	STDIN_FD = 0;
	BOMB_TO_CELL_RATIO = 0.3;
var
	MainField: Field;
	Quit, Win: Boolean;
	Ch: Char;

	(* Stores settings for the terminal. *)
	TAttr: TermIOS;
begin (* entrypoint *)
	(* Terminal doesn't echo what you input. *)
	if IsATTY(STDIN_FD) = 0 then WriteLn('ERROR: Not a terminal.');
	TCGetAttr(STDIN_FD, TAttr);
	TAttr.c_lflag := TAttr.c_lflag and (not (ICANON or ECHO));
	TAttr.c_cc[VMIN] := 1;
	TAttr.c_cc[VTIME] := 0;
	TCSetAttr(STDIN_FD, TCSAFLUSH, &TAttr);

	randomize();
	FieldResize(MainField, 10, 10);
	FieldInit(MainField, BOMB_TO_CELL_RATIO);
	
	FieldWrite(MainField);

	Quit := False;
	Win := False;

	while not Quit do
	begin
		Read(Ch);
		case Ch of
			'h': FieldCursorMove(MainField, 0, -1);
			'j': FieldCursorMove(MainField, 1, 0);
			'k': FieldCursorMove(MainField, -1, 0);
			'l': FieldCursorMove(MainField, 0, 1);
			' ': if FieldCellOpen(MainField) = Bomb then Quit := True;
			'!': FieldStateSet(MainField, MainField.CursorRow, MainField.CursorCol, Flagged);
		end;

		(* Posicionar el cursor tal que se sobreescriba. *)
		Write(Chr(27), '[', MainField.Rows+1, 'A');
		Write(Chr(27), '[', MainField.Cols*3, 'D');
		FieldWrite(MainField);

		if CheckWin(MainField) then begin
			Quit := True;
			Win := True;
		end;
	end;

	if Win then WriteLn('¡You won 😊!') else WriteLn('¡You lost 😭!');
end.
