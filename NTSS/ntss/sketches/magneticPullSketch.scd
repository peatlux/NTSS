/*** circlepan:
magnetic pull toward integer radiuses
***/

(0, 0.01 .. 3).plot;

(0, 0.01 .. 3).collect { |val|
	val + ((val * -2pi).sin * 0.15);
}.plot
