# 0. Setup inicial ##########
## Carrega as bibliotecas
library(glue)
library(httr)
library(reticulate)

# 1. Webscrap ##########
## Define estado (abreviatura)
estado <- "PA"

## Define município (código IBGE)
codemuni <- 1500602

## Efetua uma requisição para a página do estado
url <- glue::glue('https://www.car.gov.br/publico/municipios/downloads?sigla={estado}')
resp <- httr::GET(url)

## Obtém o cookie da sessão
cookie_name <- httr::cookies(resp)$name[1]
cookie_value <- httr::cookies(resp)$value[1]
cookie <- glue::glue("{cookie_name}={cookie_value}")

## Gera uma id aleatoria para o captcha
idcaptcha <- sample.int(1000000, 1)
url <- glue::glue('https://www.car.gov.br/publico/municipios/captcha?id={idcaptcha}')

## Efetua uma requisição pela imagem do captcha
resp <- httr::GET(url, config = httr::set_cookies(Cookie = cookie),
                  httr::write_disk("imagem/captcha.png", overwrite = TRUE))

## Quebra o captcha através do script em python
lista <- reticulate::py_run_file("scripts/webscrap_captcha.py", convert = FALSE)
resultado <- lista$text$result

## Gera a url pra requerir o arquivo zipado
url <- glue::glue("https://www.car.gov.br/publico/municipios/shapefile?municipio[id]={codemuni}&email=usuarioteste@servico.com&captcha={resultado}")

## Efetua uma requisição pelo arquivo zipado
temp_file <- tempfile() 
resp <- httr::GET(url, config = httr::set_cookies(Cookie = cookie),
                  httr::write_disk(temp_file))

## Descompacta arquivos na pasta de destino
file <- glue::glue("resultados/content_captcha/{estado}/{codemuni}")
unzip(temp_file, exdir = file) 
file.remove(temp_file)
