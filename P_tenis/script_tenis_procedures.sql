/*
https://github.com/far0010/abd2025/tree/main/P_tenis

Paso 6: Podría darse el caso de que 2 sesiones intentasen realizar la reserva, ya que el 
cursor no permite el select for UPDATE, así que cambiamos el aislamiento por defecto a 
SERIALIZABLE, con lo que la primera transacción que consulte se quedará con el bloqueo 
hasta finalizar con commit o rollback

*/

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

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

/* PROCEDIMIENTO RESERVAR PISTAS */

create or replace procedure pReservarPista(
	argSocio reservas.socio%type,
        argFecha reservas.fecha%type,
        argHora  reservas.hora%type) is
/*
  exReservaInexistente exception;
  pragma exception_init (exReservaInexistente, -20000),
*/
  exSinPistaLibre exception;
  pragma exception_init (exSinPistaLibre, -20001),

  CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas 
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE 
                trunc(fecha) = trunc(argFecha) AND
                hora = argHora)
        order by nro;
            
  vPista INTEGER;

begin

   OPEN vPistasLibres;
   FETCH vPistasLibres INTO vPista;

   IF vPistasLibres%NOTFOUND
   THEN
        CLOSE vPistasLibres;
        raise_application_error(-20001, 'No quedan pistas libres en esa fecha y hora');
    ELSE
	INSERT INTO reservas VALUES (vPista, argFecha, argHora, argSocio);
    END IF;
    CLOSE vPistasLibres;
    COMMIT;
END;
/

/* PROCEDIMIENTO ANULAR RESERVAS */

create or replace procedure pAnularReserva(
	argSocio reservas.socio%type,
        argFecha reservas.fecha%type,
        argHora  reservas.hora%type,
	argPista reservas.pista%type) is

  exReservaInexistente exception;
  pragma exception_init (exReservaInexistente, -20000),

begin
	DELETE FROM reservas 
        WHERE
            trunc(fecha) = trunc(ArgFecha) AND
            pista = ArgPista AND
            hora = ArgHora AND
            socio = ArgSocio;

	if sql%rowcount = 1 then
		commit;
	else
		rollback;
		raise_application_error(-20000, 'Reserva inexistente');
	end if;
end;
/

SET SERVEROUTPUT ON


create or replace PROCEDURE TEST_PROCEDURES_TENIS AS 
 

BEGIN 
    pReservarPista( 'Socio 1', CURRENT_DATE, 12 );
    pReservarPista( 'Socio 2', CURRENT_DATE, 12 );
    preservarPista( 'Socio 4', CURRENT_DATE, 12 );
    preservarPista( 'Socio 3', CURRENT_DATE, 12 );
    pAnularreserva( 'Socio 1', CURRENT_DATE, 12, 1);
    pAnularreserva( 'Socio 1', date '1920-1-1', 12, 1);
    
    commit;
END;
/