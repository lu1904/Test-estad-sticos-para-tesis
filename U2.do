*=====================================
* Bases de datos del Banco Mundial
*=====================================

*Desempleo, total (% de la fuerza laboral total)
*https://datos.bancomundial.org/indicador/SL.UEM.TOTL.ZS

*PIB per cápita (US$ a precios actuales)
*https://datos.bancomundial.org/indicator/NY.GDP.PCAP.CD?_gl=1%2A18099ed%2A_gcl_au%2AMTk5MzQ0NzY5Ny4xNzE5NTE4ODU1

*=====================================
* Cambio a formato long
*=====================================

clear all
cls

global base "C:\Users\Det-Pc\Downloads\base"

*=== Desempleo ===
import excel "$base\desemd", sheet("Data") firstrow clear

drop IndicatorName IndicatorCode 


reshape long desem_, i(CountryName CountryCode) j(año) 

save "$base\desemd_long.dta", replace

*=== Pib per cápita  ===

import excel "$base\pibpcd.xls", sheet("Data") firstrow clear

drop IndicatorName IndicatorCode

reshape long pibpc_, i(CountryName CountryCode) j(año) 
save "$base\pibpc_long.dta", replace



*=====================================
* Clasificaciones en desempleo
*=====================================

import excel "$base\desemd.xls", sheet("Metadata - Countries") firstrow clear

save "$base\Clasificaciones.dta", replace

import excel "$base\regiones", sheet("List of economies") firstrow clear

rename Code CountryCode
rename Region Region2
drop Incomegroup Lendingcategory Economy
duplicates list CountryCode
drop in 219/220

save "$base\regiones.dta", replace
use "$base\regiones.dta", clear

use "$base\Clasificaciones.dta", clear


merge m:1 CountryCode using "$base\regiones.dta"
drop if Income_Group == "Agregados"
drop if _merge == 2
drop _merge

save "$base\Clasificaciones.dta", replace

use "$base\desemd_long.dta", clear

merge m:1 CountryCode using "$base\Clasificaciones.dta"
drop _merge
drop if Income_Group == ""
drop if missing(Income_Group)

encode CountryCode, gen(numeric_CountryCode)

gen time = año
format time %ty

xtset numeric_CountryCode time

drop Region

save "$base\desemd_long.dta", replace

*=====================================
* Uniendo todo en  desempleo
*=====================================

use "$base\pibpc_long.dta", clear
gen id = CountryCode + "-" + string(año)
save "$base\pibpc_long.dta", replace


use "$base\desemd_long.dta", clear
xtset
gen id = CountryCode + "-" + string(año)
save "$base\desemd_long.dta", replace

merge 1:1 id using "$base\pibpc_long.dta"
drop if _merge==2
order CountryName CountryCode año time id desem_ pibpc_   
drop _merge
save "$base\desemd_long.dta", replace


use "$base\desemd_long.dta", clear

tab Income_Group

reg desem_ pibpc_

gen Income_Group_New = Income_Group
br Income_Group_New Income_Group

replace Income_Group_New = "Ingreso mediano" if inlist(Income_Group, "Ingreso mediano alto", "Países de ingreso mediano bajo")
replace Income_Group_New = "Ingreso bajo" if Income_Group_New == "Países de ingreso bajo"


save "$base\desemd_long.dta", replace


use "$base\desemd_long.dta", clear


tsset

keep if año==2022

drop if desem_==.
drop if pibpc_==.

codebook desem_
codebook pibpc_

distinct CountryName
distinct Income_Group_New

tab Income_Group_New

codebook Region


fre Income_Group_New

tab Region

br CountryName if Region == ""

save "$base\depurada2022_long.dta", replace

use "$base\depurada2022_long.dta", clear




// rankings


format pibpc_ %15.0fc
format desem_ %15.2fc
gsort -pibpc_
list CountryName pibpc_ desem_ in 1/20

gsort -pibpc_
gen posicion = _n
list CountryName pibpc_ desem_ posicion if CountryName == "Ecuador"






// creando rangos 

collapse (mean) pibpc_ desem_ (first) CountryCode (first) Region2 (first) Income_Group_New, by(CountryName)

drop if missing(pibpc_) | missing(desem_)

xtile g_desem = desem_, nq(3)
label define rangos1 1 "Bajo" 2 "Medio" 3 "Alto"
label values g_desem rangos1

table g_desem Income_Group_New



xtile a_pibpc = pibpc_, nq(3)
label define rangos4 1 "Bajo" 2 "Medio" 3 "Alto"
label values a_pibpc rangos4

table a_pibpc Income_Group_New


// Resumenes por tipo de ingresos

drop if CountryName=="Venezuela"

sum desem_ pibpc_ if Income_Group_New=="Ingreso alto", d

sum desem_ pibpc_ if Income_Group_New=="Ingreso bajo"

sum desem_ pibpc_  if Income_Group_New=="Ingreso mediano"

sum desem_ pibpc_ if CountryName=="Ecuador"



// gráficos de dispersion 

twoway (scatter pibpc_ desem_, mlabel(CountryCode) mlabsize(tiny) legend(off)) (lfit pibpc_ desem_), ytitle(PIB per cápita) xtitle(Desempleo (%)) title("Relación entre PIB per cápita y Desempleo") subtitle("(Una perspectiva mundial)") caption("Fuente: Banco Mundial. Elaboración propia.") 



twoway ///
    (scatter pibpc_ desem_ if Income_Group_New == "Ingreso alto", mlabel(CountryCode) mlabsize(tiny)) ///
    (lfit pibpc_ desem_ if Income_Group_New == "Ingreso alto", lcolor(blue) lpattern(solid)) ///
    || ///
    (scatter pibpc_ desem_ if Income_Group_New == "Ingreso mediano", mlabel(CountryCode) mlabsize(tiny)) ///
    (lfit pibpc_ desem_ if Income_Group_New == "Ingreso mediano", lcolor(red) lpattern(dash)) ///
    || ///
    (scatter pibpc_ desem_ if Income_Group_New == "Ingreso bajo", mlabel(CountryCode) mlabsize(tiny)) ///
    (lfit pibpc_ desem_ if Income_Group_New == "Ingreso bajo", lcolor(black) lpattern(solid)) ///
    , ///
    ytitle("PIB per cápita") ///
    xtitle("Desempleo (%)") ///
    title("Relación entre PIB per cápita y Desempleo") ///
    subtitle("(Una perspectiva mundial)") ///
    caption("Fuente: Banco Mundial. Elaboración propia.") ///
    legend(order(2 "Ingreso alto" 4 "Ingreso mediano" 6 "Ingreso bajo") ///
           position(3) col(1))


// analisis de correlacion


reg pibpc_ desem_ if Income_Group_New == "Ingreso alto"
reg pibpc_ desem_ if Income_Group_New == "Ingreso mediano" 
reg pibpc_ desem_ if Income_Group_New == "Ingreso bajo" 



pwcorr pibpc_ desem_ if Income_Group_New == "Ingreso alto", sig
pwcorr pibpc_ desem_ if Income_Group_New == "Ingreso mediano", sig
pwcorr pibpc_ desem_ if Income_Group_New == "Ingreso bajo", sig



pwcorr pibpc_ desem_ if Income_Group_New == "Ingreso alto", sig star(.1) bonferroni
pwcorr pibpc_ desem_ if Income_Group_New == "Ingreso mediano", sig star(.1) bonferroni
pwcorr pibpc_ desem_ if Income_Group_New == "Ingreso bajo", sig star(.1) bonferroni





