vsim +access+r;
run -all;
if {[catch {acdb save} acdb_error]} {
    puts "Cobertura omitida: no hay base ACDB activa para esta prueba."
} else {
    acdb report -db fcover.acdb -txt -o cov.txt -verbose
    exec cat cov.txt
}
exit
