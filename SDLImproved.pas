{
* Copyright © 2015 Samuel Guillaume <samuel.guillaumes@eisti.eu> 
* This work is free. You can redistribute it and/or modify it under the
* terms of the Do What The Fuck You Want To Public License, Version 2,
* as published by Sam Hocevar. See the LICENSE file for more details.
}

{$MODE ObjFPC} 
Unit SDLImproved;

Interface

uses crt,math, sysutils, gLib2D,GL, SDL, SDL_TTF, SDL_Addon;

Type
	loadType = Procedure (); 
	updateType = Procedure (dt : Real); 
	drawType = Procedure (fps : Real);
	mousepressedType = Procedure (left : Boolean ; x,y : real ; release : Boolean);
	keypressedType = Procedure (key : Word ; release : Boolean);

	Point = Record
			x,y : Real;
		End;

	Vertices = Array of Point;

Procedure StartApp(load : loadType ; update : updateType ; draw : drawType ; mousepressed : mousepressedType; keypressed : keypressedType);
Procedure StartApp(load : loadType ; update : updateType ; draw : drawType ; mousepressed : mousepressedType);
	Procedure StartApp(load : loadType ; update : updateType ; draw : drawType ; keypressed : keypressedType);
Procedure StartApp(load : loadType ; update : updateType ; draw : drawType);

Procedure StopApp();
	
Procedure WindowSetting(Caption : PChar);
Procedure WindowSetting(Caption : PChar; width,height : Word);

Function isKeyDown(k : Word) : Boolean;
Function GetMouseXY() : Point;
Function IsVisible() : Boolean;

// Shortcuts
Procedure gDrawText(s : String; font : PTTF_Font; x,y : Real; color : gColor; mode : byte);
Procedure gDrawPoint(x,y : Real; color : gColor);
Procedure gDrawLine(x1,y1,x2,y2 : Real; color : gColor);
Procedure gDrawTriangle(x1,y1,x2,y2,x3,y3 : Real; color : gColor);
Procedure gFillTriangle(x1,y1,x2,y2,x3,y3 : Real; color : gColor);
Procedure gDrawPoly(points : Vertices; color : gColor);
Procedure gFillPoly(v : Vertices; color : gColor);
Procedure gDrawImage(img : gImage; x,y : Real; mode : byte; scaleX,scaleY : Real);
Procedure gDrawImage(img : gImage; x,y : Real; mode : byte; scale : Real);
Procedure gDrawImage(img : gImage; x,y : Real; scale : Real);
Procedure gDrawImage(img : gImage; x,y : Real; mode : byte);
Procedure gDrawImage(img : gImage; x,y : Real);


Implementation

Var
	i : Word;
	AppStarted,focus : Boolean;
	keymap : array[0..512] of Boolean;
	mousePosition : Point;
	stop : Boolean;

Function TimeMS() : Real;
Begin 
	exit(TimeStampToMSecs(DateTimeToTimeStamp(Now)));
End;

Procedure WindowSetting(Caption : PChar);
Begin
	SDL_WM_SetCaption(Caption, nil);
End;

Procedure WindowSetting(Caption : PChar; width,height : Word);
Begin
	SDL_WM_SetCaption(Caption, nil);
	If(not AppStarted) Then
	Begin
		G_SCR_W := width;
	  G_SCR_H := height;
	End;
End;

Procedure StartApp(load : loadType ; update : updateType ; draw : drawType ; mousepressed : mousepressedType; keypressed : keypressedType);
Var
	k : Integer;
	delatimer,dt,fpstimer : Real;
	mousep,mouseLeft : Boolean;
Begin
	AppStarted := True;
	mousep := False;
	mouseLeft := False;

	gClear(BLACK);
	load;
	delatimer := TimeMS;
	fpstimer := TimeMS;
	Repeat
		focus := (sdl_get_mouse_x <> 0) and (sdl_get_mouse_y <> 0);
		If(focus) Then
		Begin
			mousePosition.x := sdl_get_mouse_x;
			mousePosition.y := sdl_get_mouse_y;
		End;

		If(mousep and (sdl_mouse_left_click_released or sdl_mouse_right_click_released)) Then
		Begin
			mousepressed(sdl_mouse_left_click_released,sdl_get_mouse_x,sdl_get_mouse_y,True);
			mousep := False;
		End
		Else If(mousep) Then
			mousepressed(mouseLeft,sdl_get_mouse_x,sdl_get_mouse_y,False)
		Else If(not mousep) Then
		Begin
			mousep := (sdl_mouse_left_click or sdl_mouse_right_click);
			mouseLeft := sdl_mouse_left_click;
		End;

		k := sdl_get_keypressed;
		If(k <> -1) Then
			keymap[k] := True;

		k := sdl_get_keyreleased;
		If(k <> -1) Then
			If(keymap[k]) Then
			Begin
				keypressed(k, True);
				keymap[k] := False;
			End;

		For i := 0 to Length(keymap)-1 do
			If(keymap[i]) Then
				keypressed(i, False);

		dt := TimeMS - delatimer;
		If(dt <> 0) Then
		Begin
			update(dt);
			delatimer := TimeMS;
		End;

		If(((TimeMS - fpstimer) > (1000/60) )and (dt <> 0)) Then
		Begin
			gClear(BLACK);
			draw(1000/(TimeMS - fpstimer));
			gFlip();

			While ((sdl_update = 1) or stop) Do
			Begin
				If (sdl_do_quit or stop) Then
					exit;
			End;
			fpstimer := TimeMS;
		End;
	Until False;
End;

Procedure emptykeypressed(key : Word ; release : Boolean);
Begin
End;

Procedure emptymousepressed(left : Boolean; x,y : real ; release : Boolean);
Begin
End;

Procedure StartApp(load : loadType ; update : updateType ; draw : drawType ; mousepressed : mousepressedType);
Begin
	StartApp(load,update,draw,mousepressed,@emptykeypressed);
End;

Procedure StartApp(load : loadType ; update : updateType ; draw : drawType ; keypressed : keypressedType);
Begin
	StartApp(load,update,draw,@emptymousepressed,keypressed);
End;

Procedure StartApp(load : loadType ; update : updateType ; draw : drawType );
Begin
	StartApp(load,update,draw,@emptymousepressed,@emptykeypressed);
End;

Procedure StopApp();
Begin
	stop := True;
End;

Function isKeyDown(k : Word) : Boolean;
Begin
	If(k < Length(keymap)) Then
		exit(keymap[k])
	Else
		exit(False);
End;

Function GetMouseXY() : Point;
Begin
	exit(mousePosition);
End;

Function IsVisible() : Boolean;
Begin
	exit(focus);
End;

// Shortcuts
Procedure gDrawText(s : String; font : PTTF_Font; x,y : Real; color : gColor; mode : byte);
Var
	text : gImage;
Begin
	text := gTextLoad(s, font);
	gBeginRects(text);
		gSetCoordMode(mode);
		gSetCoord(x,y);
		gSetColor(color);
		gAdd();
	gEnd();
End;

Procedure gDrawPoint(x,y : Real; color : gColor);
Begin
 	gBeginPoints();
 		gSetColor(color);
		gSetCoord(x,y);
		gAdd();
	gEnd;
End;

Procedure gDrawLine(x1,y1,x2,y2 : Real; color : gColor);
Begin
	gBeginLines(G_STRIP);
		gSetColor(color);
		gSetCoord(x1, y1);
		gAdd();
		gSetCoord(x2, y2);
		gAdd();
	gEnd();
End;

Procedure gDrawTriangle(x1,y1,x2,y2,x3,y3 : Real; color : gColor);
Begin
	gBeginLines(G_STRIP);
		gSetColor(color);
		gSetCoord(x1, y1);
		gAdd();
		gSetCoord(x2, y2);
		gAdd();
		gSetCoord(x3, y3);
		gAdd();
		gSetCoord(x1, y1);
		gAdd();
	gEnd();
End;

Procedure gFillTriangle(x1,y1,x2,y2,x3,y3 : Real; color : gColor);
Var
	centerX,centerY,i,ix1,ix2,ix3,iy1,iy2,iy3 : Real;
	j : byte;
	steps : Word;
	dists : array[0..5] of Word;
Begin
	i := 0.1;
	centerX := (x1 + x2 + x3)/3;
	centerY := (y1 + y2 + y3)/3;

	dists[0] := Floor(ABS(x1-centerX));
	dists[1] := Floor(ABS(x2-centerX));
	dists[2] := Floor(ABS(x3-centerX));
	dists[3] := Floor(ABS(y1-centerY));
	dists[4] := Floor(ABS(y2-centerY));
	dists[5] := Floor(ABS(y3-centerY));
	
	steps := 1;
	For j := 0 to 5 do
	Begin
		If(steps < dists[j]) Then
			steps := dists[j];
	End;

	ix1 := ABS(x1-centerX)/steps;
	ix2 := ABS(x2-centerX)/steps;
	ix3 := ABS(x3-centerX)/steps;

	iy1 := ABS(y1-centerY)/steps;
	iy2 := ABS(y2-centerY)/steps;
	iy3 := ABS(y3-centerY)/steps;

	Repeat
		gDrawTriangle(x1,y1,x2,y2,x3,y3,color);
		If(x1 > centerX + i) Then x1 := x1 - ix1
		Else If(x1 < centerX - i) Then x1 := x1 + ix1;
		If(x2 > centerX + i) Then x2 := x2 - ix2
		Else If(x2 < centerX - i) Then x2 := x2 + ix2;
		If(x3 > centerX + i) Then x3 := x3 - ix3
		Else If(x3 < centerX - i) Then x3 := x3 + ix3;

		If(y1 > centerY + i) Then y1 := y1 - iy1
		Else If(y1 < centerY - i) Then y1 := y1 + iy1;
		If(y2 > centerY + i) Then y2 := y2 - iy2
		Else If(y2 < centerY - i) Then y2 := y2 + iy2;
		If(y3 > centerY + i) Then y3 := y3 - iy3
		Else If(y3 < centerY - i) Then y3 := y3 + iy3;
	Until ((ABS(x1-centerX) < i) and ((ABS(x2-centerX) < i)) and (ABS(x3-centerX) < i)) and ((ABS(y1-centerY) < i) and ((ABS(y2-centerY) < i)) and (ABS(y3-centerY) < i));
End;

Procedure gDrawPoly(points : Vertices; color : gColor);
Var
	i : Word;
Begin
	For i := 0 to Length(points)-2 do
		gDrawLine(points[i].x,points[i].y,points[i+1].x,points[i+1].y,color);
	gDrawLine(points[Length(points)-1].x,points[Length(points)-1].y,points[0].x,points[0].y,color);
End;

Procedure gFillPoly(v : Vertices; color : gColor);
Var
	i,j,steps : Word;
	center : point;
	points : Vertices;
	delta : array of point;
Begin
	SetLength(points, Length(v));

	center.x := 0;
	center.y := 0;
	For i := 0 to Length(points)-1 do
	Begin
		points[i].x := v[i].x;
		points[i].y := v[i].y;
		center.x += points[i].x;
		center.y += points[i].y;
	End;
	center.x /= Length(points);
	center.y /=  Length(points);
	steps := 0;
	For i := 0 to Length(points)-1 do
	Begin
		If(ABS(points[i].x - center.x) > steps) Then 
			steps := Floor(ABS(points[i].x - center.x));
		If(ABS(points[i].y - center.y) > steps) Then 
			steps := Floor(ABS(points[i].y - center.y));
	End;

	SetLength(delta,Length(points));
	For i := 0 to Length(points)-1 do
	Begin
		delta[i].x := (center.x-points[i].x)/steps;
		delta[i].y := (center.y-points[i].y)/steps;
	End;

	gDrawPoly(points,color);
	For i := 0 to steps - 2 do
	Begin
		For j := 0 to Length(points)-1 do
		Begin
			If(ABS(center.x - points[j].x) > (delta[j].x*1.2)) Then
				points[j].x += delta[j].x;

			If(ABS(center.y - points[j].y) > (delta[j].y*1.2)) Then
				points[j].y += delta[j].y;
		End;
		gDrawPoly(points,color);
	End;
End;

Procedure gDrawImage(img : gImage; x,y : Real; mode : byte; scaleX,scaleY : Real);
begin
	gBeginRects(img);
	  gSetScaleWH(scaleX, scaleY);
		gSetCoordMode(mode);
		gSetCoord(x, y);
		gAdd();
	gEnd();
end;

Procedure gDrawImage(img : gImage; x,y : Real; mode : byte; scale : Real);
Begin
	gDrawImage(img,x,y,mode,img^.w*scale,img^.h*scale);
End;

Procedure gDrawImage(img : gImage; x,y : Real; scale : Real);
Begin
	gDrawImage(img,x,y,G_UP_LEFT,img^.w*scale,img^.h*scale);
End;

Procedure gDrawImage(img : gImage; x,y : Real; mode : byte);
Begin
	gDrawImage(img,x,y,mode,img^.w,img^.h);
End;

Procedure gDrawImage(img : gImage; x,y : Real);
Begin
	gDrawImage(img,x,y,G_UP_LEFT,img^.w,img^.h);
End;

Initialization
	AppStarted := False;
	focus := True;
	For i := 0 to Length(keymap)-1 do
		keymap[i] := False;

	mousePosition.x := 0;
	mousePosition.y := 0;
End.