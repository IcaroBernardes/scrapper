# 0. Setup inicial ##########
## Carrega as bibliotecas
library(dplyr)
library(purrr)
library(rvest)
library(webdriver)
library(xml2)
library(xlsx)

## Inicia o headless browser
pjs <- webdriver::run_phantomjs()

## Inicia a sessão no navegador
ses <- Session$new(port = pjs$port)

# 1. Webscrap ##########
## Navega até a página com o formulário
ses$go("https://reducaopressao.sabesp.com.br")

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

## Define unidade de busca
aplicar("#ContentPlaceHolder1_DropDownListTipo",
        "css",
        "Pesquisar por bairro")

## Clica no botão que inicia o processo de busca e
## exibe a tela que confirma carregamento do modal
botao <- ses$findElement(css = "#ContentPlaceHolder1_UpdatePanel1 a.btn")
botao$moveMouseTo()
botao$click()
ses$takeScreenshot()

## Define município
aplicar("#ContentPlaceHolder1_DropDownListMunicipio", "css", "São Paulo")

## Busca o html da página e o lê
doc <- ses$getSource() |> 
  rvest::read_html()

## Lista os bairros do município
bairros <- rvest::html_elements(doc, "#ContentPlaceHolder1_PanelSetores option")
bairros <- bairros[-1]
bairros <- purrr::map_chr(bairros, ~xml2::xml_attr(., "value"))

## Define função para extração das tabelas
extrator <- function(bairro) {
  
  ### Define bairro
  aplicar("#ContentPlaceHolder1_DropDownListSetor", "css", bairro)
  
  ### Aguarda por 1s
  Sys.sleep(1)
  
  ### Busca o html da página e o lê
  doc <- ses$getSource() |> 
    rvest::read_html()
  
  ### Extrai a tabela gerada
  doc |> 
    rvest::html_element("table") |> 
    rvest::html_table()
  
}
safe_extrator <- purrr::safely(extrator)

## Efetua a extração com pausas de 1s a cada bairro
tabela <- purrr::map(bairros, safe_extrator)

## Associa os nomes dos bairros aos resultados
names(tabela) <- bairros

## Elimina observações com extração mal-sucedida
tabela_final <- purrr::keep(tabela, ~is.null(.$error))

## Gera versão final como dataframe
tabela_final <- purrr::map2_dfr(
  tabela_final,
  names(tabela_final),
  function(tab, bar) {
    tab$result |> dplyr::mutate(bairro = bar)
  }
)
tabela_final <- as.data.frame(tabela_final)

## Salva o resultado obtido
xlsx::write.xlsx(tabela_final, "resultados/content_headless_browser.xlsx", row.names = FALSE)
