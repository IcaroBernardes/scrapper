# 0. Setup inicial ##########
## Carrega as bibliotecas
library(dplyr)
library(rvest)
library(webdriver)

## Inicia o headless browser
pjs <- webdriver::run_phantomjs()

## Inicia a sessão no navegador
ses <- Session$new(port = pjs$port)

# 1. Webscrap com headless browser
## Navega até a página com o formulário
ses$go("https://cecad.cidadania.gov.br/tab_cad.php")

## Cria função para aplicar valores no formulário
aplicar <- function(seletor, tipo, valor, exibir = FALSE) {
  
  ### Aplica o seletor que busca um elemento em função do tipo
  elemento = switch(tipo,
                    css = ses$findElement(css = seletor),
                    xpath = ses$findElement(xpath = seletor))
  
  ### Define o valor no elemento selecionado
  elemento$setValue(valor)
  
  ### Exibe a tela caso demandado
  if (exibir) ses$takeScreenshot()
  
}

## Define UF
aplicar("#estadoSAGIUFMU", "css", "AM - Amazonas")

## Define município(s)
aplicar("#municipioSAGIUFMU", "css", "------")

## Define coluna
aplicar('//*[@id="data"]/div/div[1]/div[3]/div[2]/select',
        "xpath",
        "Bloco 2 - Forma de abastecimento de água")

## Clica no 2o botão ("Valor Absoluto")
botao <- ses$findElements(css = "button")[[3]]
botao$click()


ses$takeScreenshot()

# Get source

doc <- ses$getSource()[1]

doc <- read_html(doc)

tabelas <- doc %>%
  html_nodes("table") 
