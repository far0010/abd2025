/*
Script para dar derechos debugger a usuario HR
*/
connect system/Abd2025*;
grant debug connect session to HR;
grant debug any procedure to HR;
exit;