# 0. Setup inicial ##########
## Carrega as bibliotecas
library(dplyr)
library(httr)
library(purrr)
library(readxl)
library(rvest)
library(tidyr)
library(xlsx)

## Carrega a lista municípios e estados e seus códigos
codigos <- readxl::read_excel("RELATORIO_DTB_BRASIL_MUNICIPIO.xls")

## Mantém apenas os municípios do estado do Acre
codigos <- codigos |> dplyr::filter(uf_ibge == 12)

# 1. Webscrap por request
## Define url para a qual fazer a requisição.
## Tal url indica que as tabelas a serem geradas são de "Valor Absoluto"
url <- "https://cecad.cidadania.gov.br/tab_cad_table.php?p_tipo=absoluto"

## Define função para fazer requisição à página
requisitor <- function(uf_ibge, nome_estado, p_ibge, nome_municipio) {
  
  ### Aguarda por 1s
  Sys.sleep(1)
  
  ### Define parâmetros de busca
  body <- list(
    schema = "PBF",
    uf_ibge = uf_ibge,
    nome_estado = nome_estado,
    nome_municipio = nome_municipio,
    p_ibge = p_ibge,
    var1 = "fx_rft"
  )
  
  ### Efeuta a requisição à página (POST)
  httr::POST(url, body = body, encode = "form")
  
}
safe_requisitor <- purrr::safely(requisitor)

## Efetua a extração com pausas de 1s a cada município
respostas <- purrr::pmap(codigos, safe_requisitor)

## Associa os códigos dos municípios aos resultados
names(respostas) <- codigos$p_ibge

## Elimina observações com extração mal-sucedida
respostas_final <- purrr::keep(respostas, ~is.null(.$error))

## Mantém apenas os pares de tabela para cada município
tabelas <- purrr::map(
  respostas_final,
  function(resp) {
    
    ### Extrai as tabelas
    tab = resp$result |> 
      httr::content() |> 
      rvest::html_table(header = FALSE)
    
    ## Nomeia as tabelas
    names(tab) = c("Família", "Pessoa")
    
    return(tab)
    
  })

## Efetua a limpeza dos resultados
tabela_final <- purrr::map2_dfr(
  tabelas, names(tabelas),
  function(pares, code) {
    
    ### Limpa e rearranja as tabelas
    dados = purrr::map2_dfr(
      pares, names(pares),
      function(tab, unid) {
        
        #### Elimina a 1a coluna
        tab = tab |> dplyr::select(-X1)
        
        #### Altera os nomes das colunas
        colnames(tab) = tab[2,]
        
        #### Mantém apenas as linhas com os valores
        tab = tab |> dplyr::slice(3L)
        
        #### Elimina os caracteres de ponto (.)
        #### e converte os valores a numérico
        tab = tab |>
          dplyr::mutate(across(.fns = ~as.numeric(stringr::str_remove_all(., "\\."))))
        
        #### Rearranja os dados
        tab = tab |> tidyr::pivot_longer(cols = everything(),
                                         names_to = "Categoria",
                                         values_to = "Valor")
        
        #### Insere a unidade
        tab = tab |> dplyr::mutate(unidade = unid)
        
      })
    
    ## Adiciona o código do município
    dados |> dplyr::mutate(p_ibge = code)
    
  })

## Adiciona o município e o estado
tabela_final <- tabela_final |> 
  dplyr::left_join(codigos) |> 
  as.data.frame()

## Salva o resultado obtido
xlsx::write.xlsx(tabela_final, "resultados/content_request.xlsx", row.names = FALSE)
