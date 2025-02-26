/* 2025_v1 */
/*Francisco J. Arroyo Redondo https://github.com/far0010/abd2025 
  1º 
   1.-	la función TRUNC, nos permite eliminar, las horas, minutos y segudos así podemos comparar fechas:
   	así TRUNC(CAMPO) = TO_DATE('18042025', 'DDMMYYYY') compara si el campo es esa fecha
   2.-	sql%rowcount, nos indica las filas que se han añadido, por ejemplo al hacer un update, podemos preguntar si la variable vale 1 hacer commit
   3.-	Una variable tipo cursor es la que sirve para almacenar un dato de una consulta, puede ser implícito, para una fila explícito que almacenan
	más de una fila 
	vPistasLibres es un cursor explícito, OPEN abre el cursor, FETCH lo recorre y CLOSE lo cierra.
	FOUND es true si hay elementos en el curos y false al contrario. NOTFOUND justo al reves, si no hay elementos en el cursor es true.
   4.-	En anular reservas se hace un borrado de fila si coincide con una fecha, hora y socio, en ese caso sql%rowcount=1, en caso contrario no ha 
	ejecutado nada con lo cual da lo mismo rollback que commit
   5.-	La inserción de reserva en la función se realiza sí o sí ya que en caso negativo intentaría hacerlo sin éxito y al saltar excepción quedaría
	abierto el cursor. Con un else para el caso afirmativo lo arreglamos.
*/

drop table reservas;
drop table pistas;
drop sequence seq_pistas;

create table pistas (
	nro integer primary key
	);
	
create table reservas (
	pista integer references pistas(nro),
	fecha date,
	hora integer check (hora >= 0 and hora <= 23),
	socio varchar(20),
	primary key (pista, fecha, hora)
	);
	
create sequence seq_pistas;

insert into pistas values (seq_pistas.nextval);
insert into reservas 
	values (seq_pistas.currval, '20/03/2018', 14, 'Pepito');
insert into pistas values (seq_pistas.nextval);
insert into reservas 
	values (seq_pistas.currval, '24/03/2018', 18, 'Pepito');
insert into reservas 
	values (seq_pistas.currval, '21/03/2018', 14, 'Juan');
insert into pistas values (seq_pistas.nextval);
insert into reservas 
	values (seq_pistas.currval, '22/03/2018', 13, 'Lola');
insert into reservas 
	values (seq_pistas.currval, '22/03/2018', 12, 'Pepito');

commit;

create or replace function anularReserva( 
	p_socio varchar,
	p_fecha date,
	p_hora integer, 
	p_pista integer ) 
return integer is

begin
	DELETE FROM reservas 
        WHERE
            trunc(fecha) = trunc(p_fecha) AND
            pista = p_pista AND
            hora = p_hora AND
            socio = p_socio;

	if sql%rowcount = 1 then
		commit;
		return 1;
	else
		rollback;
		return 0;
	end if;
end;
/

create or replace FUNCTION reservarPista(
        p_socio VARCHAR,
        p_fecha DATE,
        p_hora INTEGER
    ) 
RETURN INTEGER IS

    CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas 
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE 
                trunc(fecha) = trunc(p_fecha) AND
                hora = p_hora)
        order by nro;
            
    vPista INTEGER;

BEGIN
    OPEN vPistasLibres;
    FETCH vPistasLibres INTO vPista;

    IF vPistasLibres%NOTFOUND
    THEN
        CLOSE vPistasLibres;
        RETURN 0;
    ELSE
	INSERT INTO reservas VALUES (vPista, p_fecha, p_hora, p_socio);
    END IF;
    CLOSE vPistasLibres;
    COMMIT;
    RETURN 1;
END;
/

SET SERVEROUTPUT ON

create or replace PROCEDURE TEST_FUNCIONES_TENIS AS

resultado integer;

begin
 
     resultado := reservarPista( 'Socio 1', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;

     resultado := reservarPista( 'Socio 2', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;
     
     resultado := reservarPista( 'Socio 3', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;
     
     resultado := reservarPista( 'Socio 4', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;      

     resultado := anularreserva( 'Socio 1', CURRENT_DATE, 12, 1);
     if resultado=1 then
        dbms_output.put_line('Reserva 1 anulada: OK');
     else
        dbms_output.put_line('Reserva 1 anulada: MAL');
     end if;
  
     resultado := anularreserva( 'Socio 1', date '1920-1-1', 12, 1);
     if resultado=1 then
        dbms_output.put_line('Reserva 1 anulada: OK');
     else
        dbms_output.put_line('Reserva 1 anulada: MAL');
     end if;
     commit;
END TEST_FUNCIONES_TENIS;


/* bloque anónimo

SET SERVEROUTPUT ON
declare
 resultado integer;
begin
 
     resultado := reservarPista( 'Socio 1', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;

     resultado := reservarPista( 'Socio 2', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;
     
     resultado := reservarPista( 'Socio 3', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;
     
     resultado := reservarPista( 'Socio 4', CURRENT_DATE, 12 );
     if resultado=1 then
        dbms_output.put_line('Reserva 1: OK');
     else
        dbms_output.put_line('Reserva 1: MAL');
     end if;      

     resultado := anularreserva( 'Socio 1', CURRENT_DATE, 12, 1);
     if resultado=1 then
        dbms_output.put_line('Reserva 1 anulada: OK');
     else
        dbms_output.put_line('Reserva 1 anulada: MAL');
     end if;
  
     resultado := anularreserva( 'Socio 1', date '1920-1-1', 12, 1);
     if resultado=1 then
        dbms_output.put_line('Reserva 1 anulada: OK');
     else
        dbms_output.put_line('Reserva 1 anulada: MAL');
     end if;
     commit;
end;
/
select * from reservas;
commit;
*/

